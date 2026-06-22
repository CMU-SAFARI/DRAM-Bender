#ifndef DRAMBENDER_API_BOARD_BOARD_H
#define DRAMBENDER_API_BOARD_BOARD_H

#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <deque>
#include <memory>
#include <mutex>
#include <span>
#include <string_view>
#include <thread>
#include <vector>

#include "drambender/api/host_interface/host_interface.h"
#include "drambender/api/program/program.h"

namespace DRAMBender {

using Word_t = uint32_t;
using Inst_t = uint64_t;

inline constexpr size_t axi_datapath_byte_width = 32;

enum class BoardType {
  DDR4,
  HBM2,
};

constexpr std::string_view to_string(BoardType board_type) noexcept {
  switch (board_type) {
    case BoardType::DDR4:
      return "DDR4";
    case BoardType::HBM2:
      return "HBM2";
  }

  return "Unknown";
}

/**
 * @brief Abstract interface for FPGA boards.
 */
class IBoard {
 protected:
  explicit IBoard(std::unique_ptr<IHostInterface> host_interface,
                  int max_num_insts_per_prog = 2048,
                  int readback_buffer_size = 1024,
                  std::chrono::milliseconds receive_timeout = std::chrono::seconds(5));

  IHostInterface& hostInterface() const;
  int readback_buffer_size() const noexcept;
  void sendControlPacket_(std::span<const std::byte> control_packet);
  void sendControlPacketRaw_(std::span<const std::byte> control_packet);
  void ensureOpen_() const;

  std::unique_ptr<IHostInterface> m_host_interface_;
  const int max_num_insts_per_prog_;
  std::vector<std::byte> m_send_buffer_;
  const int readback_buffer_size_;
  const std::chrono::milliseconds receive_timeout_;

 public:
  virtual ~IBoard();

  // Wait for the active readback session to finish and rethrow async receive
  // errors. This does not consume, discard, or drain queued readback data.
  void synchronize();

  virtual void execute(const FinalProgram& prog);
  void execute(const std::vector<FinalProgram>& prog_queue);
  virtual size_t receive(std::span<std::byte> dst);
  // Send the FPGA reset control packet after synchronizing normal in-flight
  // readback. Use full_reset() for recovery from stale or stuck readback.
  virtual void reset_fpga();

  // Recovery path: cancel active readback, reset the FPGA, drain stale host
  // readback, and clear queued software readback.
  void full_reset();
  virtual void set_aref(bool is_on);

  // Release the underlying host interface (closes DMA device file descriptors,
  // joins the receiver thread). Idempotent. After close(), every method that
  // touches the host interface raises `std::runtime_error`.
  void close();
  bool is_closed() const noexcept;

 private:
  void consumeData_();
  void rethrowReceiverException_();
  void joinReceiver_(bool rethrow_receiver_exception);
  void clearReceiveState_();

  std::deque<Word_t> m_recv_words_;
  std::mutex m_recv_mutex_;
  std::condition_variable m_recv_cv_;
  std::thread m_receiver_thread_;
  std::exception_ptr m_receiver_exception_;
  bool m_receive_complete_ = true;
  bool m_receive_started_ = false;
};

std::unique_ptr<IBoard> create_board(
    BoardType board_type,
    int instance_id,
    HostInterface host_interface);

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_BOARD_BOARD_H
