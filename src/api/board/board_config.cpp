#include "drambender/api/board/board_config.h"

#include <array>
#include <iomanip>
#include <sstream>
#include <stdexcept>

namespace DRAMBender {
namespace {

constexpr std::array<BoardConfig, 3> k_board_configs{{
    {
        .name = "U200",
        .board_type = BoardType::U200,
        .memory_type = MemoryType::DDR4,
        .instruction_capacity = 32768,
        .dram_command_slot_ns = 1.5,
        .dram_slots_per_fabric_cycle = 4,
        .readback_buffer_capacity = 1024,
        .hbm_channel_count = 0,
        .hbm_pseudo_channel_count = 0,
        .hbm_sid_count = 0,
        .broadcast_supported = false,
        .power_telemetry_supported = false,
    },
    {
        .name = "U50",
        .board_type = BoardType::U50,
        .memory_type = MemoryType::HBM2,
        .instruction_capacity = 2048,
        .dram_command_slot_ns = 5.0 / 3.0,
        .dram_slots_per_fabric_cycle = 4,
        .readback_buffer_capacity = 1024,
        .hbm_channel_count = 16,
        .hbm_pseudo_channel_count = 2,
        .hbm_sid_count = 1,
        .broadcast_supported = false,
        .power_telemetry_supported = false,
    },
    {
        .name = "U55C",
        .board_type = BoardType::U55C,
        .memory_type = MemoryType::HBM2,
        .instruction_capacity = 131072,
        .dram_command_slot_ns = 5.0 / 3.0,
        .dram_slots_per_fabric_cycle = 4,
        .readback_buffer_capacity = 1024,
        .hbm_channel_count = 16,
        .hbm_pseudo_channel_count = 2,
        .hbm_sid_count = 2,
        .broadcast_supported = true,
        .power_telemetry_supported = true,
    },
}};

constexpr std::string_view yes_no(bool value) noexcept {
  return value ? "yes" : "no";
}

}  // namespace

std::string BoardConfig::summary() const {
  std::ostringstream output;
  output << "Board:                      " << name << '\n'
         << "Memory type:                " << to_string(memory_type) << '\n'
         << "Instruction capacity:       " << instruction_capacity << '\n'
         << "DRAM command slot:          " << std::fixed << std::setprecision(6)
         << dram_command_slot_ns << " ns\n"
         << "DRAM slots/fabric cycle:    " << dram_slots_per_fabric_cycle << '\n'
         << "Readback buffer capacity:   " << readback_buffer_capacity << '\n'
         << "HBM channels:               " << hbm_channel_count << '\n'
         << "HBM pseudo-channels:        " << hbm_pseudo_channel_count << '\n'
         << "HBM stack IDs:              " << hbm_sid_count << '\n'
         << "Broadcast supported:        " << yes_no(broadcast_supported) << '\n'
         << "Power telemetry supported:  " << yes_no(power_telemetry_supported);
  return output.str();
}

const BoardConfig& get_board_config(BoardType board_type) {
  switch (board_type) {
    case BoardType::U200:
      return k_board_configs[0];
    case BoardType::U50:
      return k_board_configs[1];
    case BoardType::U55C:
      return k_board_configs[2];
  }

  throw std::invalid_argument("Unsupported board type requested.");
}

}  // namespace DRAMBender
