#include "draminspector/api/host_interface/host_interface.h"

#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <exception>
#include <fcntl.h>
#include <memory>
#include <poll.h>
#include <stdexcept>
#include <string>
#include <sys/eventfd.h>
#include <system_error>
#include <thread>
#include <unistd.h>

namespace DRAMBender {
namespace {

inline constexpr size_t max_zero_write_retries = 1'000'000;
inline constexpr size_t max_drain_reads = 16'384;

struct FreeDeleter {
  void operator()(std::byte* ptr) const noexcept {
    std::free(ptr);
  }
};

class XDMA : public IHostInterface {
 public:
  explicit XDMA(int instance_id,
                size_t send_buffer_size = 32 * 2048,
                size_t recv_buffer_size = 32 * 1024)
      : instance_id_(instance_id),
        send_buffer_size_(send_buffer_size),
        recv_buffer_size_(recv_buffer_size) {}

  ~XDMA() override {
    if (m_to_card_fd_ >= 0) {
      ::close(m_to_card_fd_);
    }
    if (m_from_card_fd_ >= 0) {
      ::close(m_from_card_fd_);
    }
    if (m_cancel_fd_ >= 0) {
      ::close(m_cancel_fd_);
    }
  }

  void init() override {
    if (m_to_card_fd_ >= 0 && m_from_card_fd_ >= 0 && m_cancel_fd_ >= 0 &&
        m_send_buf_ && m_recv_buf_) {
      return;
    }

    const std::string to_fpga_file = to_FPGA_prefix_ + std::to_string(instance_id_);
    m_to_card_fd_ = ::open(to_fpga_file.c_str(), O_RDWR);
    if (m_to_card_fd_ < 0) {
      throw std::system_error(errno, std::generic_category(),
                              "Failed to open XDMA host-to-card device " + to_fpga_file);
    }

    const std::string from_fpga_file = from_FPGA_prefix_ + std::to_string(instance_id_);
    m_from_card_fd_ = ::open(from_fpga_file.c_str(), O_RDWR);
    if (m_from_card_fd_ < 0) {
      throw std::system_error(errno, std::generic_category(),
                              "Failed to open XDMA card-to-host device " + from_fpga_file);
    }

    if (m_cancel_fd_ < 0) {
      m_cancel_fd_ = ::eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);
      if (m_cancel_fd_ < 0) {
        throw std::system_error(errno, std::generic_category(),
                                "Failed to create XDMA receive-cancel eventfd");
      }
    }

    m_send_buf_ = allocateAlignedBuffer_(send_buffer_size_);
    m_recv_buf_ = allocateAlignedBuffer_(recv_buffer_size_);
  }

  size_t send(std::span<const std::byte> data) override {
    if (m_to_card_fd_ < 0) {
      throw std::logic_error("XDMA board is not initialized for sending.");
    }
    if (data.size() > send_buffer_size_) {
      throw std::invalid_argument("XDMA send request exceeds the aligned send buffer size.");
    }

    std::memcpy(m_send_buf_.get(), data.data(), data.size());

    size_t zero_write_retries = 0;
    while (true) {
      const ssize_t rc = ::write(m_to_card_fd_, m_send_buf_.get(), data.size());
      if (rc < 0) {
        throw std::system_error(errno, std::generic_category(), "XDMA write failed");
      }
      if (rc == 0) {
        ++zero_write_retries;
        if (zero_write_retries >= max_zero_write_retries) {
          throw std::runtime_error(
              "XDMA write made no forward progress after 1000000 zero-byte retries.");
        }
        std::this_thread::yield();
        continue;
      }
      if (static_cast<size_t>(rc) != data.size()) {
        throw std::runtime_error("XDMA write completed with a short transfer.");
      }

      return static_cast<size_t>(rc);
    }
  }

  void begin_receive() override {
    clearCancelEvent_();
  }

  size_t recv(std::span<std::byte> dst) override {
    if (m_from_card_fd_ < 0) {
      throw std::logic_error("XDMA board is not initialized for receiving.");
    }
    if (m_cancel_fd_ < 0) {
      throw std::logic_error("XDMA receive cancellation is not initialized.");
    }
    if (dst.size() > recv_buffer_size_) {
      throw std::invalid_argument("XDMA receive request exceeds the aligned receive buffer size.");
    }

    pollfd fds[2] = {
        {.fd = m_from_card_fd_, .events = POLLIN, .revents = 0},
        {.fd = m_cancel_fd_, .events = POLLIN, .revents = 0},
    };

    while (true) {
      const int poll_rc = ::poll(fds, 2, -1);
      if (poll_rc < 0) {
        if (errno == EINTR) {
          continue;
        }
        throw std::system_error(errno, std::generic_category(), "XDMA receive poll failed");
      }

      if ((fds[1].revents & POLLIN) != 0) {
        clearCancelEvent_();
        return 0;
      }
      if ((fds[1].revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) {
        throw std::runtime_error("XDMA receive cancel eventfd reported an invalid poll state.");
      }
      if ((fds[0].revents & POLLNVAL) != 0) {
        throw std::runtime_error("XDMA receive fd reported POLLNVAL.");
      }
      if ((fds[0].revents & (POLLIN | POLLERR | POLLHUP)) != 0) {
        break;
      }
    }

    const ssize_t rc = ::read(m_from_card_fd_, m_recv_buf_.get(), dst.size());
    if (rc < 0) {
      throw std::system_error(errno, std::generic_category(), "XDMA read failed");
    }

    const size_t recv_count = static_cast<size_t>(rc);
    if (recv_count > dst.size()) {
      throw std::runtime_error("XDMA read exceeded the requested receive size.");
    }

    std::memcpy(dst.data(), m_recv_buf_.get(), recv_count);
    return recv_count;
  }

  void cancel_receive() override {
    if (m_cancel_fd_ < 0) {
      return;
    }

    const uint64_t value = 1;
    while (true) {
      const ssize_t rc = ::write(m_cancel_fd_, &value, sizeof(value));
      if (rc == static_cast<ssize_t>(sizeof(value))) {
        return;
      }
      if (rc < 0 && errno == EINTR) {
        continue;
      }
      if (rc < 0 && errno == EAGAIN) {
        return;  // Counter is saturated; cancellation is already signaled.
      }
      if (rc < 0) {
        throw std::system_error(errno, std::generic_category(),
                                "XDMA receive cancel eventfd write failed");
      }
      throw std::runtime_error("XDMA receive cancel eventfd write was short.");
    }
  }

  void drain() override {
    if (m_from_card_fd_ < 0) {
      return;
    }
    // Temporarily set the FD to non-blocking, read and discard all available
    // data, then restore blocking mode. fcntl() failures must not be silent —
    // a user whose FD is in the wrong mode after drain gets very confusing
    // downstream errors. Real read errors (EIO, EBADF, …) are likewise
    // distinguished from EAGAIN.
    const int old_flags = ::fcntl(m_from_card_fd_, F_GETFL);
    if (old_flags == -1) {
      throw std::system_error(errno, std::system_category(),
                              "XDMA drain: fcntl(F_GETFL) failed");
    }
    if (::fcntl(m_from_card_fd_, F_SETFL, old_flags | O_NONBLOCK) == -1) {
      throw std::system_error(errno, std::system_category(),
                              "XDMA drain: fcntl(F_SETFL, O_NONBLOCK) failed");
    }

    std::exception_ptr read_error;
    size_t drain_reads = 0;
    while (true) {
      const ssize_t rc = ::read(m_from_card_fd_, m_recv_buf_.get(), recv_buffer_size_);
      if (rc > 0) {
        ++drain_reads;
        if (drain_reads >= max_drain_reads) {
          read_error = std::make_exception_ptr(std::runtime_error(
              "XDMA drain did not quiesce after 16384 reads; hardware may still be "
              "producing readback data."));
          break;
        }
        continue;
      }
      if (rc == 0) {
        break;  // EOF
      }
      // rc < 0 — distinguish "no data right now" from a real error.
      if (errno == EAGAIN || errno == EWOULDBLOCK) {
        break;  // drained
      }
      read_error = std::make_exception_ptr(std::system_error(
          errno, std::system_category(), "XDMA drain: read() failed"));
      break;
    }

    // Restore blocking mode even on read error, so the FD is left in a
    // known-good state; then propagate the error.
    if (::fcntl(m_from_card_fd_, F_SETFL, old_flags) == -1) {
      if (!read_error) {
        throw std::system_error(errno, std::system_category(),
                                "XDMA drain: fcntl(F_SETFL restore) failed");
      }
      // If we already have a read error, prefer it (read errors are the
      // proximate cause); the restore failure is logged to stderr.
      std::fprintf(
          stderr,
          "[draminspector] XDMA drain: fcntl(F_SETFL restore) failed: %s\n",
          std::strerror(errno));
    }
    if (read_error) {
      std::rethrow_exception(read_error);
    }
  }

 private:
  static std::unique_ptr<std::byte, FreeDeleter> allocateAlignedBuffer_(size_t size) {
    void* raw_ptr = nullptr;
    const size_t aligned_size = ((size + 4095U) / 4096U) * 4096U;
    if (::posix_memalign(&raw_ptr, 4096, aligned_size) != 0) {
      throw std::bad_alloc();
    }

    return std::unique_ptr<std::byte, FreeDeleter>(static_cast<std::byte*>(raw_ptr));
  }

  void clearCancelEvent_() {
    if (m_cancel_fd_ < 0) {
      return;
    }

    while (true) {
      uint64_t value = 0;
      const ssize_t rc = ::read(m_cancel_fd_, &value, sizeof(value));
      if (rc == static_cast<ssize_t>(sizeof(value))) {
        continue;
      }
      if (rc < 0 && errno == EINTR) {
        continue;
      }
      if (rc < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
        return;
      }
      if (rc < 0) {
        throw std::system_error(errno, std::generic_category(),
                                "XDMA receive cancel eventfd read failed");
      }
      throw std::runtime_error("XDMA receive cancel eventfd read was short.");
    }
  }

  const int instance_id_;
  const size_t send_buffer_size_;
  const size_t recv_buffer_size_;
  std::unique_ptr<std::byte, FreeDeleter> m_send_buf_;
  std::unique_ptr<std::byte, FreeDeleter> m_recv_buf_;
  int m_to_card_fd_ = -1;
  int m_from_card_fd_ = -1;
  int m_cancel_fd_ = -1;
  const std::string to_FPGA_prefix_ = "/dev/xdma0_h2c_";
  const std::string from_FPGA_prefix_ = "/dev/xdma0_c2h_";
};

}  // namespace

std::unique_ptr<IHostInterface> make_xdma_host_interface(int instance_id) {
  return std::make_unique<XDMA>(instance_id);
}

}  // namespace DRAMBender
