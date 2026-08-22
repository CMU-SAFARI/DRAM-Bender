#ifndef DRAMBENDER_API_BOARD_BOARD_CONFIG_H
#define DRAMBENDER_API_BOARD_BOARD_CONFIG_H

#include <cstddef>
#include <string>
#include <string_view>

namespace DRAMBender {

enum class BoardType {
  U200,
  U50,
  U55C,
};

constexpr std::string_view to_string(BoardType board_type) noexcept {
  switch (board_type) {
    case BoardType::U200:
      return "U200";
    case BoardType::U50:
      return "U50";
    case BoardType::U55C:
      return "U55C";
  }

  return "Unknown";
}

enum class MemoryType {
  DDR4,
  HBM2,
};

constexpr std::string_view to_string(MemoryType memory_type) noexcept {
  switch (memory_type) {
    case MemoryType::DDR4:
      return "DDR4";
    case MemoryType::HBM2:
      return "HBM2";
  }

  return "Unknown";
}

/**
 * @brief API-side description of the hardware implemented by a board bitstream.
 *
 * These values are assumptions made by the software, not capabilities detected
 * from the programmed FPGA. Custom bitstreams must provide a matching entry.
 */
struct BoardConfig {
  std::string_view name;                       ///< Human-readable board name.
  BoardType board_type;                        ///< Public board selector.
  MemoryType memory_type;                      ///< Memory technology on the board.
  std::size_t instruction_capacity;            ///< Encoded instructions in instruction RAM.
  double dram_command_slot_ns;                 ///< Duration of one DRAM command slot.
  std::size_t dram_slots_per_fabric_cycle;     ///< Command slots packed per fabric cycle.
  std::size_t readback_buffer_capacity;        ///< Entries in the FPGA readback buffer.
  std::size_t hbm_channel_count;               ///< HBM channels; zero for non-HBM boards.
  std::size_t hbm_pseudo_channel_count;        ///< Pseudo-channels per HBM channel.
  std::size_t hbm_sid_count;                   ///< Addressable HBM stack IDs.
  bool broadcast_supported;                    ///< HBM command broadcast support.
  bool power_telemetry_supported;              ///< On-card power telemetry support.

  /** @brief Return a human-readable, multiline description of this configuration. */
  std::string summary() const;
};

/** @brief Return the built-in configuration for a supported board. */
const BoardConfig& get_board_config(BoardType board_type);

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_BOARD_BOARD_CONFIG_H
