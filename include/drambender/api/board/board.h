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
 *
 * A board owns the host connection, sends programs to the FPGA, and buffers
 * readback data until the caller receives it. 
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

  /**
   * @brief Send one finalized program to the board.
   *
   * The call waits for any previous readback session to finish before it sends
   * the new program. If the program returns data, a background receiver starts
   * collecting it immediately; call receive() to copy the bytes you expect and
   * synchronize() as a barrier.
   */
  virtual void execute(const FinalProgram& prog);

  /**
   * @brief Execute a queue of finalized programs in order.
   *
   * This is a convenience wrapper around execute(program). Readback data from
   * each program remains queued for receive() in the same order the programs
   * ran.
   */
  void execute(const std::vector<FinalProgram>& prog_queue);

  /**
   * @brief Copy queued readback bytes into a caller-owned buffer.
   *
   * The destination size must be a multiple of four bytes. The call blocks
   * until that many bytes are available, the FPGA finishes too early, the
   * receive timeout expires, or the receiver thread reports an error.
   *
   * @return The number of bytes copied, which equals dst.size_bytes().
   */
  virtual size_t receive(std::span<std::byte> dst);

  /**
   * @brief Wait for the active readback session to finish.
   *
   * Any asynchronous receive error is rethrown here. Queued readback data is
   * left intact, so it is fine to receive() first and synchronize() afterward.
   */
  void synchronize();

  /**
   * @brief Send the FPGA reset control packet.
   *
   * This path first synchronizes normal in-flight work. Use full_reset() when
   * recovering from stale data, a stuck readback, or a failed receive session.
   */
  virtual void reset_fpga();

  /**
   * @brief Recover the board and discard any pending readback.
   *
   * full_reset() cancels active receive work, resets FPGA logic, drains stale
   * data from the host interface, and clears the software readback queue.
   */
  void full_reset();

  /**
   * @brief Enable or disable FPGA-managed DRAM auto-refresh.
   */
  virtual void set_aref(bool is_on);

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
    int board_id,
    int instance_id,
    HostInterface host_interface);

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_BOARD_BOARD_H
