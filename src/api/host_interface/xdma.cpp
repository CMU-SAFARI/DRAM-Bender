#include "drambender/api/host_interface/host_interface.h"

#include <algorithm>
#include <atomic>
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

#include "api/host_interface/byte_stream_buffer.h"

namespace DRAMBender {
namespace {

inline constexpr size_t max_zero_write_retries = 1'000'000;
inline constexpr size_t max_drain_reads = 16'384;
inline constexpr size_t c2h_read_quantum = 4096;
inline constexpr int receive_cancel_poll_ms = 50;
inline constexpr int drain_quiet_poll_ms = 1;
inline constexpr int drain_required_quiet_polls = 500;

struct FreeDeleter {
  void operator()(std::byte* ptr) const noexcept {
    std::free(ptr);
  }
};

class XDMA : public IHostInterface {
 public:
  explicit XDMA(int board_id,
                int instance_id,
                size_t send_buffer_size = 32 * 2048,
                size_t recv_buffer_size = 32 * 1024)
      : board_id_(board_id),
        instance_id_(instance_id),
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

    // Claim C2H first. The driver treats the streaming C2H endpoint as the
    // execution-session lease, so another DRAM-Bender process cannot acquire
    // the same channel while this instance proceeds to open H2C.
    openFromCard_();

    const std::string to_fpga_file = devicePath_("h2c");
    m_to_card_fd_ = ::open(to_fpga_file.c_str(), O_RDWR | O_CLOEXEC);
    if (m_to_card_fd_ < 0) {
      throw std::system_error(errno, std::generic_category(),
                              "Failed to open XDMA host-to-card device " + to_fpga_file);
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

    size_t bytes_sent = 0;
    size_t zero_write_retries = 0;
    while (bytes_sent < data.size()) {
      const ssize_t rc =
          ::write(m_to_card_fd_, m_send_buf_.get() + bytes_sent, data.size() - bytes_sent);
      if (rc < 0) {
        if (errno == EINTR) {
          continue;
        }
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

      bytes_sent += static_cast<size_t>(rc);
      zero_write_retries = 0;
    }

    return bytes_sent;
  }

  void begin_receive() override {
    m_receive_cancelled_.store(false, std::memory_order_release);
    clearCancelEvent_();
    m_recv_pending_.clear();
  }

  size_t recv(std::span<std::byte> dst) override {
    if (m_from_card_fd_ < 0) {
      throw std::logic_error("XDMA board is not initialized for receiving.");
    }
    if (m_cancel_fd_ < 0) {
      throw std::logic_error("XDMA receive cancellation is not initialized.");
    }
    if (dst.empty()) {
      return 0;
    }

    // recv() is a byte-stream "read some" operation. Packet boundaries belong
    // to the metadata protocol above this transport and must never be inferred
    // from a short read or a period with no C2H data.
    //
    // Check cancellation even when buffered or continuously arriving data is
    // available. Otherwise the old fill-the-entire-destination loop could
    // starve full_reset()/close() indefinitely while the FPGA kept producing
    // readback data.
    if (receiveCancelled_()) {
      return 0;
    }

    const size_t buffered_count = m_recv_pending_.read(dst);
    if (buffered_count > 0) {
      return receiveCancelled_() ? 0 : buffered_count;
    }

    while (true) {
      if (!waitForReceiveReady_()) {
        return 0;
      }

      // Cancellation may have raced with poll() returning C2H readiness.
      if (receiveCancelled_()) {
        return 0;
      }

      const size_t request_size =
          std::min(recv_buffer_size_, std::max(c2h_read_quantum, dst.size()));
      ssize_t rc = ::read(m_from_card_fd_, m_recv_buf_.get(), request_size);
      if (rc < 0 && errno == EINTR) {
        continue;
      }
      if (rc < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
        continue;
      }
      if (rc < 0) {
        throw std::system_error(errno, std::generic_category(), "XDMA read failed");
      }
      if (rc == 0) {
        throw std::runtime_error("XDMA read made no forward progress.");
      }

      const size_t recv_count = static_cast<size_t>(rc);
      if (recv_count > request_size) {
        throw std::runtime_error("XDMA read exceeded the requested receive size.");
      }

      m_recv_pending_.append(std::span<const std::byte>(m_recv_buf_.get(), recv_count));
      if (receiveCancelled_()) {
        return 0;
      }
      return m_recv_pending_.read(dst);
    }
  }

  void cancel_receive() noexcept override {
    m_receive_cancelled_.store(true, std::memory_order_release);
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
        std::fprintf(stderr,
                     "[drambender] XDMA receive cancel eventfd write failed: %s\n",
                     std::strerror(errno));
        return;
      }
      std::fprintf(stderr,
                   "[drambender] XDMA receive cancel eventfd write was short\n");
      return;
    }
  }

  void drain() override {
    if (m_from_card_fd_ < 0) {
      return;
    }
    m_recv_pending_.clear();
    size_t drain_reads = 0;
    int quiet_polls = 0;
    while (true) {
      const ssize_t rc = ::read(m_from_card_fd_, m_recv_buf_.get(), recv_buffer_size_);
      if (rc > 0) {
        quiet_polls = 0;
        ++drain_reads;
        if (drain_reads >= max_drain_reads) {
          throw std::runtime_error(
              "XDMA drain did not quiesce after 16384 reads; hardware may still be "
              "producing readback data.");
        }
        continue;
      }
      if (rc == 0) {
        break;  // EOF
      }
      if (rc < 0 && errno == EINTR) {
        continue;
      }
      if (errno == EAGAIN || errno == EWOULDBLOCK) {
        pollfd fd = {.fd = m_from_card_fd_, .events = POLLIN, .revents = 0};
        const int poll_rc = ::poll(&fd, 1, drain_quiet_poll_ms);
        if (poll_rc < 0) {
          if (errno == EINTR) {
            continue;
          }
          throw std::system_error(errno, std::system_category(),
                                  "XDMA drain: poll() failed");
        }
        if (poll_rc == 0) {
          ++quiet_polls;
          if (quiet_polls >= drain_required_quiet_polls) {
            break;  // drained
          }
          continue;
        }
        if ((fd.revents & POLLNVAL) != 0) {
          throw std::runtime_error("XDMA drain: receive fd reported POLLNVAL.");
        }
        if ((fd.revents & (POLLIN | POLLERR | POLLHUP)) != 0) {
          quiet_polls = 0;
          continue;
        }
        continue;
      }
      throw std::system_error(errno, std::system_category(), "XDMA drain: read() failed");
    }

    reopenFromCard_();
    m_recv_pending_.clear();
  }

 private:
  void openFromCard_() {
    const std::string from_fpga_file = devicePath_("c2h");
    m_from_card_fd_ = ::open(from_fpga_file.c_str(), O_RDWR | O_CLOEXEC | O_NONBLOCK);
    if (m_from_card_fd_ < 0) {
      throw std::system_error(errno, std::generic_category(),
                              "Failed to open XDMA card-to-host device " + from_fpga_file);
    }
  }

  void reopenFromCard_() {
    if (m_from_card_fd_ >= 0) {
      if (::close(m_from_card_fd_) != 0) {
        throw std::system_error(errno, std::generic_category(),
                                "Failed to close XDMA card-to-host device during drain");
      }
      m_from_card_fd_ = -1;
    }
    openFromCard_();
  }

  bool waitForReceiveReady_() {
    while (true) {
      if (receiveCancelled_()) {
        return false;
      }

      pollfd fds[2] = {
          {.fd = m_from_card_fd_, .events = POLLIN, .revents = 0},
          {.fd = m_cancel_fd_, .events = POLLIN, .revents = 0},
      };

      // The timeout is a fallback for the extremely unlikely case where the
      // eventfd notification itself fails. cancel_receive() is deliberately
      // noexcept so reset/close can always progress to joining the receiver.
      const int poll_rc = ::poll(fds, 2, receive_cancel_poll_ms);
      if (poll_rc < 0) {
        if (errno == EINTR) {
          continue;
        }
        throw std::system_error(errno, std::generic_category(), "XDMA receive poll failed");
      }
      if (poll_rc == 0) {
        continue;
      }
      if ((fds[1].revents & POLLIN) != 0) {
        clearCancelEvent_();
        return false;
      }
      if ((fds[1].revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) {
        throw std::runtime_error("XDMA receive cancel eventfd reported an invalid poll state.");
      }
      if ((fds[0].revents & POLLNVAL) != 0) {
        throw std::runtime_error("XDMA receive fd reported POLLNVAL.");
      }
      if ((fds[0].revents & (POLLIN | POLLERR | POLLHUP)) != 0) {
        return true;
      }
    }
  }

  static std::unique_ptr<std::byte, FreeDeleter> allocateAlignedBuffer_(size_t size) {
    void* raw_ptr = nullptr;
    const size_t aligned_size = ((size + 4095U) / 4096U) * 4096U;
    if (::posix_memalign(&raw_ptr, 4096, aligned_size) != 0) {
      throw std::bad_alloc();
    }

    return std::unique_ptr<std::byte, FreeDeleter>(static_cast<std::byte*>(raw_ptr));
  }

  std::string devicePath_(std::string_view direction) const {
    return "/dev/xdma" + std::to_string(board_id_) + "_" + std::string(direction) + "_" +
           std::to_string(instance_id_);
  }

  bool receiveCancelled_() const noexcept {
    return m_receive_cancelled_.load(std::memory_order_acquire);
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

  const int board_id_;
  const int instance_id_;
  const size_t send_buffer_size_;
  const size_t recv_buffer_size_;
  std::unique_ptr<std::byte, FreeDeleter> m_send_buf_;
  std::unique_ptr<std::byte, FreeDeleter> m_recv_buf_;
  host_interface_internal::ByteStreamBuffer m_recv_pending_;
  int m_to_card_fd_ = -1;
  int m_from_card_fd_ = -1;
  int m_cancel_fd_ = -1;
  std::atomic<bool> m_receive_cancelled_{false};
};

}  // namespace

std::unique_ptr<IHostInterface> make_xdma_host_interface(int board_id, int instance_id) {
  return std::make_unique<XDMA>(board_id, instance_id);
}

}  // namespace DRAMBender
