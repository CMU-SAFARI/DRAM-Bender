#include "drambender/api/board/board.h"

#include <algorithm>
#include <array>
#include <cstdio>
#include <cstring>
#include <exception>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include "drambender/api/board/DDR4.h"
#include "drambender/api/board/HBM2.h"
#include "c2h_protocol.h"
#include "h2c_protocol.h"

namespace DRAMBender {

namespace {

inline constexpr std::chrono::milliseconds interruption_poll_interval{50};

}  // namespace

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
  if (!m_host_interface_) {
    return;
  }
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
  if (m_faulted_) {
    throw std::runtime_error(
        "Board recovery failed and this handle is no longer usable. Close it "
        "and open a new board.");
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
  synchronizeImpl_({});
}

void IBoard::synchronize_interruptibly(
    const InterruptionPoint& interruption_point) {
  synchronizeImpl_(interruption_point);
}

void IBoard::synchronizeImpl_(
    const InterruptionPoint& interruption_point) {
  ensureOpen_();

  try {
    if (m_receiver_thread_.joinable() && interruption_point) {
      std::unique_lock<std::mutex> lock(m_recv_mutex_);
      auto next_interruption_check =
          std::chrono::steady_clock::now() + interruption_poll_interval;
      while (!m_receive_complete_) {
        m_recv_cv_.wait_until(lock, next_interruption_check);
        const auto now = std::chrono::steady_clock::now();
        if (!m_receive_complete_ && now >= next_interruption_check) {
          next_interruption_check = now + interruption_poll_interval;
          lock.unlock();
          interruption_point();
          lock.lock();
        }
      }
    }

    joinReceiver_(true);
  } catch (...) {
    // A failed metadata session can leave unread bytes behind just like an
    // interrupted one. Use the same single recovery primitive.
    recoverAndRethrow_(std::current_exception());
  }
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
  if (!instructions.empty()) {
    h2c_protocol::set_control(
        std::span<std::byte>(
            m_send_buffer_.data() + (instructions.size() - 1) * axi_datapath_byte_width,
            axi_datapath_byte_width),
        h2c_protocol::execute_program_control);
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
    // A partial instruction upload leaves FPGA execution state ambiguous.
    // Use the same recovery primitive as interrupted/failed readback and
    // preserve the original send exception for the caller.
    recoverAndRethrow_(std::current_exception());
  }
}

size_t IBoard::receive(std::span<std::byte> dst) {
  return receiveImpl_(dst, {});
}

size_t IBoard::receive_interruptibly(
    std::span<std::byte> dst,
    const InterruptionPoint& interruption_point) {
  return receiveImpl_(dst, interruption_point);
}

size_t IBoard::receiveImpl_(
    std::span<std::byte> dst,
    const InterruptionPoint& interruption_point) {
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
  auto next_interruption_check =
      std::chrono::steady_clock::now() + interruption_poll_interval;

  std::unique_lock<std::mutex> lock(m_recv_mutex_);
  while (m_recv_words_.size() < num_words_to_read) {
    if (m_receiver_exception_) {
      std::exception_ptr exception = m_receiver_exception_;
      m_receiver_exception_ = nullptr;
      lock.unlock();
      recoverAndRethrow_(exception);
    }

    if (!m_receive_started_ && m_recv_words_.empty()) {
      throw std::logic_error("No receive operation is currently active.");
    }

    if (m_receive_complete_) {
      lock.unlock();
      recoverAndRethrow_(std::make_exception_ptr(std::runtime_error(
          "Receive stream ended before the requested amount of data arrived.")));
    }

    const auto wake_deadline = interruption_point
                                   ? std::min(deadline, next_interruption_check)
                                   : deadline;
    m_recv_cv_.wait_until(lock, wake_deadline);

    auto now = std::chrono::steady_clock::now();
    if (interruption_point && now >= next_interruption_check) {
      next_interruption_check = now + interruption_poll_interval;
      lock.unlock();
      try {
        interruption_point();
      } catch (...) {
        recoverAndRethrow_(std::current_exception());
      }
      lock.lock();
      now = std::chrono::steady_clock::now();
    }

    // Give data and receiver terminal states precedence over a deadline that
    // became due in the same wake-up. The top of the loop reports the precise
    // protocol/short-stream result (or copies newly available data).
    if (m_recv_words_.size() >= num_words_to_read || m_receiver_exception_ ||
        m_receive_complete_) {
      continue;
    }

    if (now >= deadline) {
      lock.unlock();
      recoverAndRethrow_(std::make_exception_ptr(std::runtime_error(
          "Timed out while waiting for readback data from the platform.")));
    }
  }

  for (size_t word_id = 0; word_id < num_words_to_read; ++word_id) {
    dst_words[word_id] = m_recv_words_.front();
    m_recv_words_.pop_front();
  }

  return dst.size_bytes();
}

std::optional<IBoard::ReadbackPacket> IBoard::receiveReadbackPacket_() {
  std::array<std::byte, axi_datapath_byte_width> metadata{};

  auto read_exact = [this](std::span<std::byte> dst) {
    size_t total_read = 0;
    while (total_read < dst.size_bytes()) {
      const size_t recv_count = m_host_interface_->recv(dst.subspan(total_read));
      if (recv_count == 0) {
        return total_read;
      }
      total_read += recv_count;
    }
    return total_read;
  };

  const size_t metadata_bytes = read_exact(metadata);
  if (metadata_bytes == 0) {
    return std::nullopt;
  }
  if (metadata_bytes != metadata.size()) {
    throw std::runtime_error("Platform readback metadata packet ended early.");
  }

  const auto parsed_metadata = c2h_protocol::parse_readback_metadata(metadata);
  if (parsed_metadata.payload_bytes % sizeof(Word_t) != 0) {
    throw std::runtime_error("Platform readback payload size is not word-aligned.");
  }
  if (parsed_metadata.payload_bytes == 0 && !parsed_metadata.is_last) {
    throw std::runtime_error(
        "Platform readback metadata declares an empty non-final packet.");
  }

  std::vector<std::byte> payload(parsed_metadata.payload_bytes);
  const size_t payload_bytes = read_exact(payload);
  if (payload_bytes != payload.size()) {
    throw std::runtime_error("Platform readback payload ended before the metadata-declared size.");
  }

  return ReadbackPacket{
      .payload = std::move(payload),
      .is_last = parsed_metadata.is_last,
  };
}

void IBoard::consumeData_() {
  try {
    consumeMetadataPacketData_();

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

void IBoard::consumeMetadataPacketData_() {
  while (true) {
    const std::optional<ReadbackPacket> packet = receiveReadbackPacket_();
    if (!packet.has_value()) {
      break;
    }

    if (!packet->payload.empty()) {
      std::vector<Word_t> words(packet->payload.size() / sizeof(Word_t));
      std::memcpy(words.data(), packet->payload.data(), packet->payload.size());

      {
        std::lock_guard<std::mutex> lock(m_recv_mutex_);
        m_recv_words_.insert(m_recv_words_.end(), words.begin(), words.end());
      }
      m_recv_cv_.notify_all();
    }

    if (packet->is_last) {
      break;
    }
  }
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
  h2c_protocol::set_control(reset_packet, h2c_protocol::reset_control);
  sendControlPacket_(reset_packet);
}

void IBoard::full_reset() {
  ensureOpen_();

  try {
    m_host_interface_->cancel_receive();
    joinReceiver_(false);

    std::array<std::byte, axi_datapath_byte_width> reset_packet{};
    h2c_protocol::set_control(reset_packet, h2c_protocol::reset_control);
    sendControlPacketRaw_(reset_packet);

    m_host_interface_->drain();
    clearReceiveState_();
    m_faulted_ = false;
  } catch (...) {
    m_faulted_ = true;
    throw;
  }
}

[[noreturn]] void IBoard::recoverAndRethrow_(
    std::exception_ptr original_exception) {
  try {
    full_reset();
  } catch (const std::exception& recovery_error) {
    std::fprintf(stderr,
                 "[drambender] full_reset after an interrupted wait failed: %s\n",
                 recovery_error.what());
    try {
      close();
    } catch (...) {
      // full_reset() has already marked the surviving handle faulted. Preserve
      // the operation's original exception, which is the actionable error for
      // the caller.
    }
  } catch (...) {
    std::fprintf(stderr,
                 "[drambender] full_reset after an interrupted wait failed\n");
    try {
      close();
    } catch (...) {
    }
  }

  std::rethrow_exception(original_exception);
}

void IBoard::set_aref(bool is_on) {
  std::array<std::byte, axi_datapath_byte_width> aref_packet{};
  h2c_protocol::set_control(aref_packet, h2c_protocol::auto_refresh_control);
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
