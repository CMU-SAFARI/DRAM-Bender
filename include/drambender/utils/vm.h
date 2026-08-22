#ifndef DRAMBENDER_UTILS_VM_H
#define DRAMBENDER_UTILS_VM_H

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "drambender/api/board/board_config.h"
#include "drambender/api/program/program.h"

namespace DRAMBender::vm {

inline constexpr size_t k_register_count = 16;
inline constexpr size_t k_dram_command_count = 7;
inline constexpr size_t k_default_max_instructions = 100000000;
inline constexpr std::array<std::string_view, k_dram_command_count> k_dram_command_names = {
    "WR",
    "RD",
    "PRE",
    "ACT",
    "SEL_CH",
    "REF",
    "NOP",
};

struct ExecutionResult {
  uint64_t total_cycles = 0;
  double total_ns = 0.0;
  std::array<uint32_t, k_register_count> registers{};
  std::array<uint64_t, k_dram_command_count> dram_cmd_counts{};
  uint64_t instructions_executed = 0;
  uint64_t branches_taken = 0;
};

struct DRAMCommandEvent {
  std::string command;
  size_t pc = 0;
  int slot = 0;
  double time_ns = 0.0;
  double delta_ns = 0.0;
  int bank = -1;
  int row = -1;
  int column = -1;
  int rank = -1;
  int channel = -1;
  int pseudo_channel = -1;
  bool auto_precharge = false;
  bool precharge_all = false;
};

struct DRAMCommandTrace {
  std::vector<DRAMCommandEvent> events;
  bool truncated = false;
  uint64_t instructions_executed = 0;
  uint64_t total_cycles = 0;
  double total_ns = 0.0;
};

// Wall-clock latency of one DRAM mini-instruction and the number of
// mini-instructions packed into one fabric cycle. Defaults come from the
// built-in U200 BoardConfig. Override both fields when modeling a bitstream
// with different timing or packing.
struct TimingConfig {
  double dram_inst_latency_ns =
      get_board_config(BoardType::U200).dram_command_slot_ns;
  int num_dram_insts_per_fabric_cycle = static_cast<int>(
      get_board_config(BoardType::U200).dram_slots_per_fabric_cycle);

  double ns_per_cycle() const {
    return dram_inst_latency_ns *
           static_cast<double>(num_dram_insts_per_fabric_cycle);
  }
};

ExecutionResult execute(const FinalProgram& program, size_t max_instructions,
                        const TimingConfig& timing = {});
DRAMCommandTrace trace_dram_commands(const FinalProgram& program,
                                     size_t max_instructions,
                                     const TimingConfig& timing = {});
std::string format_execution_result(const ExecutionResult& result);
std::string format_dram_command_trace(const DRAMCommandTrace& trace);

}  // namespace DRAMBender::vm

#endif  // DRAMBENDER_UTILS_VM_H
