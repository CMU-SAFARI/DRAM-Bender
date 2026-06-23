#include "drambender/api/board/board.h"

#include <array>
#include <cstdio>
#include <cstring>
#include <exception>
#include <stdexcept>
#include <string>
#include <vector>

#include "drambender/api/board/DDR4.h"
#include "drambender/api/board/HBM2.h"

namespace DRAMBender {

IBoard::IBoard(std::unique_ptr<IHostInterface> host_interface,
               int max_num_insts_per_prog,
               int readback_buffer_size,
               std::chrono::milliseconds receive_timeout)
    : m_host_interface_(std::move(host_interface)),
      max_num_insts_per_prog_(max_num_insts_per_prog),
      m_send_buffer_(axi_datapath_byte_width * static_cast<size_t>(max_num_insts_per_prog_)),
      readback_buffer_size_(readback_buffer_size),
      receive_timeout_(receive_timeout) {
  if (!m_host_interface_) {
    throw std::invalid_argument("IBoard requires a non-null host interface.");
  }
}

IBoard::~IBoard() {
  // Share shutdown logic with close(). Any exception is logged rather than
  // rethrown — a destructor cannot propagate — but must not be swallowed
  // silently. Professional users need to see fatal DMA faults, plugin ABI
  // mismatches, etc.
  try {
    close();
  } catch (const std::exception& e) {
    std::fprintf(stderr,
                 "[drambender] ~IBoard: exception during shutdown: %s\n",
                 e.what());
  } catch (...) {
    std::fprintf(stderr,
                 "[drambender] ~IBoard: unknown exception during shutdown\n");
  }
}

void IBoard::close() {
  // Idempotent. Safe to call from destructor after an explicit close().
  if (!m_host_interface_) {
    return;
  }
  // Interrupt and join any in-flight receiver work first so the thread cannot
  // touch the host interface after we release it. Cannot use the public
  // synchronize() here because that asserts the board is still open.
  m_host_interface_->cancel_receive();
  joinReceiver_(true);
  m_host_interface_.reset();
}

bool IBoard::is_closed() const noexcept {
  return m_host_interface_ == nullptr;
}

void IBoard::ensureOpen_() const {
  if (!m_host_interface_) {
    throw std::runtime_error(
        "Board is closed. Open a new board via open_board(...) to run more "
        "programs.");
  }
}

IHostInterface& IBoard::hostInterface() const {
  ensureOpen_();
  return *m_host_interface_;
}

int IBoard::readback_buffer_size() const noexcept {
  return readback_buffer_size_;
}

void IBoard::rethrowReceiverException_() {
  if (m_receiver_exception_) {
    std::exception_ptr exception = m_receiver_exception_;
    m_receiver_exception_ = nullptr;
    std::rethrow_exception(exception);
  }
}

void IBoard::synchronize() {
  ensureOpen_();
  joinReceiver_(true);
}

void IBoard::joinReceiver_(bool rethrow_receiver_exception) {
  if (m_receiver_thread_.joinable()) {
    m_receiver_thread_.join();
  }

  {
    std::lock_guard<std::mutex> lock(m_recv_mutex_);
    m_receive_started_ = false;
    if (!rethrow_receiver_exception) {
      m_receiver_exception_ = nullptr;
    }
  }

  if (rethrow_receiver_exception) {
    rethrowReceiverException_();
  }
}

void IBoard::clearReceiveState_() {
  {
    std::lock_guard<std::mutex> lock(m_recv_mutex_);
    m_recv_words_.clear();
    m_receive_complete_ = true;
    m_receive_started_ = false;
    m_receiver_exception_ = nullptr;
  }
  m_recv_cv_.notify_all();
}

void IBoard::execute(const std::vector<FinalProgram>& prog_queue) {
  for (const FinalProgram& prog : prog_queue) {
    execute(prog);
  }
}

void IBoard::execute(const FinalProgram& prog) {
  synchronize();

  const std::span<const Inst> instructions = prog.instructions();
  if (instructions.size() > static_cast<size_t>(max_num_insts_per_prog_)) {
    throw std::invalid_argument("Program exceeds the maximum supported instruction count.");
  }

  const size_t send_size = instructions.size() * axi_datapath_byte_width;
  if (send_size > m_send_buffer_.size()) {
    throw std::invalid_argument("Program exceeds the maximum host-side send buffer size.");
  }

  std::fill(m_send_buffer_.begin(), m_send_buffer_.begin() + static_cast<std::ptrdiff_t>(send_size),
            std::byte{0});
  for (size_t inst_id = 0; inst_id < instructions.size(); ++inst_id) {
    std::memcpy(m_send_buffer_.data() + inst_id * axi_datapath_byte_width,
                &instructions[inst_id],
                sizeof(Inst_t));
  }

  m_host_interface_->begin_receive();

  {
    std::lock_guard<std::mutex> lock(m_recv_mutex_);
    m_receive_complete_ = false;
    m_receive_started_ = true;
    m_receiver_exception_ = nullptr;
  }

  m_receiver_thread_ = std::thread(&IBoard::consumeData_, this);
  try {
    const size_t bytes_sent =
        m_host_interface_->send(std::span<const std::byte>(m_send_buffer_.data(), send_size));
    if (bytes_sent != send_size) {
      throw std::runtime_error("Board reported a short send while executing a program.");
    }
  } catch (...) {
    m_host_interface_->cancel_receive();
    joinReceiver_(false);
    clearReceiveState_();
    throw;
  }
}

size_t IBoard::receive(std::span<std::byte> dst) {
  ensureOpen_();
  if (dst.data() == nullptr && !dst.empty()) {
    throw std::invalid_argument("receive destination buffer cannot be null.");
  }
  if (dst.size_bytes() % sizeof(Word_t) != 0) {
    throw std::invalid_argument("receive expects a byte count that is a multiple of 4.");
  }
  if (dst.empty()) {
    return 0;
  }

  auto* dst_words = reinterpret_cast<Word_t*>(dst.data());
  const size_t num_words_to_read = dst.size_bytes() / sizeof(Word_t);
  const auto deadline = std::chrono::steady_clock::now() + receive_timeout_;

  std::unique_lock<std::mutex> lock(m_recv_mutex_);
  while (m_recv_words_.size() < num_words_to_read) {
    if (m_receiver_exception_) {
      std::exception_ptr exception = m_receiver_exception_;
      m_receiver_exception_ = nullptr;
      lock.unlock();
      std::rethrow_exception(exception);
    }

    if (!m_receive_started_ && m_recv_words_.empty()) {
      throw std::logic_error("No receive operation is currently active.");
    }

    if (m_receive_complete_) {
      throw std::runtime_error("Receive stream ended before the requested amount of data arrived.");
    }

    if (m_recv_cv_.wait_until(lock, deadline) == std::cv_status::timeout) {
      throw std::runtime_error("Timed out while waiting for readback data from the platform.");
    }
  }

  for (size_t word_id = 0; word_id < num_words_to_read; ++word_id) {
    dst_words[word_id] = m_recv_words_.front();
    m_recv_words_.pop_front();
  }

  return dst.size_bytes();
}

void IBoard::consumeData_() {
  try {
    std::vector<std::byte> recv_buffer(
        static_cast<size_t>(readback_buffer_size_) * axi_datapath_byte_width);
    const size_t requested_bytes = recv_buffer.size();

    while (true) {
      const size_t recv_count = m_host_interface_->recv(recv_buffer);
      if (recv_count == 0) {
        break;
      }

      if (recv_count % sizeof(Word_t) != 0) {
        throw std::runtime_error("Platform received a byte count that is not word-aligned.");
      }

      size_t payload_bytes = recv_count;
      const bool is_final_transfer = recv_count != requested_bytes;
      if (is_final_transfer) {
        if (recv_count < axi_datapath_byte_width) {
          throw std::runtime_error("Platform received a short final packet smaller than one AXI beat.");
        }
        payload_bytes = recv_count - axi_datapath_byte_width;
      }

      if (payload_bytes > 0) {
        std::vector<Word_t> words(payload_bytes / sizeof(Word_t));
        std::memcpy(words.data(), recv_buffer.data(), payload_bytes);

        {
          std::lock_guard<std::mutex> lock(m_recv_mutex_);
          m_recv_words_.insert(m_recv_words_.end(), words.begin(), words.end());
        }
        m_recv_cv_.notify_all();
      }

      if (is_final_transfer) {
        break;
      }
    }

    {
      std::lock_guard<std::mutex> lock(m_recv_mutex_);
      m_receive_complete_ = true;
    }
  } catch (...) {
    {
      std::lock_guard<std::mutex> lock(m_recv_mutex_);
      m_receive_complete_ = true;
      m_receiver_exception_ = std::current_exception();
    }
  }

  m_recv_cv_.notify_all();
}

void IBoard::sendControlPacket_(std::span<const std::byte> control_packet) {
  synchronize();
  sendControlPacketRaw_(control_packet);
}

void IBoard::sendControlPacketRaw_(std::span<const std::byte> control_packet) {
  const size_t sent = hostInterface().send(control_packet);
  if (sent != control_packet.size()) {
    throw std::runtime_error("Board reported a short control-packet send.");
  }
}

void IBoard::reset_fpga() {
  std::array<std::byte, axi_datapath_byte_width> reset_packet{};
  reset_packet[8] = static_cast<std::byte>(1);
  sendControlPacket_(reset_packet);
}

void IBoard::full_reset() {
  ensureOpen_();

  // Recovery path: interrupt a blocked C2H readback session, wait for the
  // receiver thread to exit, and intentionally discard stale async errors.
  m_host_interface_->cancel_receive();
  joinReceiver_(false);

  std::array<std::byte, axi_datapath_byte_width> reset_packet{};
  reset_packet[8] = static_cast<std::byte>(1);
  sendControlPacketRaw_(reset_packet);

  m_host_interface_->drain();
  clearReceiveState_();
}

void IBoard::set_aref(bool is_on) {
  std::array<std::byte, axi_datapath_byte_width> aref_packet{};
  aref_packet[8] = static_cast<std::byte>(0x8);
  aref_packet[0] = static_cast<std::byte>(is_on ? 1 : 0);
  sendControlPacket_(aref_packet);
}

std::unique_ptr<IBoard> create_board(BoardType board_type,
                                     int board_id,
                                     int instance_id,
                                     HostInterface host_interface) {
  switch (board_type) {
    case BoardType::DDR4:
      return std::make_unique<DDR4>(board_id, instance_id, host_interface);
    case BoardType::HBM2:
      return std::make_unique<HBM2>(board_id, instance_id, host_interface);
  }

  throw std::runtime_error("Unsupported board type requested.");
}

}  // namespace DRAMBender
