#include "draminspector/utils/vm.h"

#include <algorithm>
#include <iomanip>
#include <sstream>
#include <unordered_map>

#include "api/program/instruction_internal.h"
#include "formatting_internal.h"

namespace DRAMBender::vm {

using namespace InstrEncoding;

namespace {

inline constexpr uint64_t k_mask4 = 0xf;
inline constexpr uint64_t k_mask16 = 0xffff;
inline constexpr uint32_t k_mask32 = 0xffffffffu;
inline constexpr uint64_t k_branch_mask = 0x7ffff;
inline constexpr uint64_t k_jump_mask = 0x7ffffff;
inline constexpr uint64_t k_taken_branch_cycles = 6;

inline constexpr uint32_t k_casr_register = 0;
inline constexpr uint32_t k_basr_register = 1;
inline constexpr uint32_t k_rasr_register = 2;

struct VMState {
  uint64_t total_cycles = 0;
  uint64_t elapsed_slots = 0;
  std::array<uint32_t, k_register_count> registers{};
  std::array<uint64_t, k_dram_command_count> dram_cmd_counts{};
  uint64_t instructions_executed = 0;
  uint64_t branches_taken = 0;
  std::unordered_map<uint32_t, uint32_t> memory;
  TimingConfig timing{};
};

uint64_t opcode(Inst inst) {
  return (inst >> k_opcode_shift) & 0x1f;
}

uint64_t function_code(Inst inst) {
  return (inst >> k_function_code_shift) & 0x7ff;
}

uint32_t rs1(Inst inst) {
  return static_cast<uint32_t>((inst >> k_rs1_shift) & k_mask4);
}

uint32_t rs2(Inst inst) {
  return static_cast<uint32_t>((inst >> k_rs2_shift) & k_mask4);
}

uint32_t rt(Inst inst) {
  return static_cast<uint32_t>((inst >> k_rt_shift) & k_mask4);
}

uint32_t imm_low(Inst inst) {
  return static_cast<uint32_t>((inst >> k_immediate_low_shift) & k_mask16);
}

uint32_t imm_high(Inst inst) {
  return static_cast<uint32_t>((inst >> k_immediate_high_shift) & k_mask16);
}

uint32_t li_immediate(Inst inst) {
  return (imm_high(inst) << 16) | imm_low(inst);
}

size_t branch_target(Inst inst) {
  return static_cast<size_t>((inst >> k_branch_target_shift) & k_branch_mask);
}

size_t jump_target(Inst inst) {
  return static_cast<size_t>((inst >> k_jump_target_shift) & k_jump_mask);
}

uint32_t sleep_amount(Inst inst) {
  return static_cast<uint32_t>(inst & k_mask32) + 2;
}

uint32_t dram_command(Mininst mininst) {
  return static_cast<uint32_t>((mininst >> k_ddr_command_shift) & k_mask4);
}

uint32_t dram_bank_reg(Mininst mininst) {
  return static_cast<uint32_t>(mininst & k_mask4);
}

uint32_t dram_row_reg(Mininst mininst) {
  return static_cast<uint32_t>((mininst >> k_ddr_row_shift) & k_mask4);
}

uint32_t dram_column_reg(Mininst mininst) {
  return static_cast<uint32_t>((mininst >> k_ddr_column_shift) & k_mask4);
}

bool dram_ibar(Mininst mininst) {
  return ((mininst >> k_ddr_increment_bank_shift) & 1) != 0;
}

bool dram_icar(Mininst mininst) {
  return ((mininst >> k_ddr_increment_column_shift) & 1) != 0;
}

bool dram_irar(Mininst mininst) {
  return ((mininst >> k_ddr_increment_row_shift) & 1) != 0;
}

bool dram_pall(Mininst mininst) {
  return ((mininst >> k_ddr_precharge_all_shift) & 1) != 0;
}

bool dram_ap(Mininst mininst) {
  return ((mininst >> k_ddr_auto_precharge_shift) & 1) != 0;
}

uint32_t dram_rank(Mininst mininst) {
  return static_cast<uint32_t>((mininst >> k_ddr_rank_shift) & 1);
}

size_t dram_command_index(Mininst mininst) {
  switch (dram_command(mininst)) {
    case k_write: return 0;
    case k_read: return 1;
    case k_pre: return 2;
    case k_act: return 3;
    case k_sel_ch: return 4;
    case k_ref: return 5;
    case k_nop: return 6;
    default: return k_dram_command_count;
  }
}

double slots_to_ns(uint64_t slots, const TimingConfig& timing) {
  return static_cast<double>(slots) * timing.dram_inst_latency_ns;
}

void advance_cycles(VMState& state, uint64_t cycles) {
  state.total_cycles += cycles;
  state.elapsed_slots +=
      cycles * static_cast<uint64_t>(state.timing.num_dram_insts_per_fabric_cycle);
}

uint32_t register_value(const VMState& state, uint32_t register_id) {
  return state.registers[register_id];
}

void apply_register_increment(VMState& state, uint32_t target_register, uint32_t stride_register) {
  state.registers[target_register] += state.registers[stride_register];
}

void maybe_record_event(DRAMCommandTrace* trace,
                        const DRAMCommandEvent& event) {
  if (trace == nullptr) {
    return;
  }

  DRAMCommandEvent traced_event = event;
  if (!trace->events.empty()) {
    traced_event.delta_ns = traced_event.time_ns - trace->events.back().time_ns;
  }
  trace->events.push_back(std::move(traced_event));
}

void trace_dram_mininst(const VMState& state,
                        DRAMCommandTrace* trace,
                        size_t pc,
                        int slot,
                        Mininst mininst) {
  if (trace == nullptr) {
    return;
  }

  const uint32_t command = dram_command(mininst);
  if (command == k_nop) {
    return;
  }

  DRAMCommandEvent event;
  event.pc = pc;
  event.slot = slot;
  event.time_ns = slots_to_ns(state.elapsed_slots + static_cast<uint64_t>(slot),
                              state.timing);

  switch (command) {
    case k_write:
      event.command = "WR";
      event.bank = static_cast<int>(register_value(state, dram_bank_reg(mininst)));
      event.column = static_cast<int>(register_value(state, dram_column_reg(mininst)));
      event.rank = static_cast<int>(dram_rank(mininst));
      event.auto_precharge = dram_ap(mininst);
      break;
    case k_read:
      event.command = "RD";
      event.bank = static_cast<int>(register_value(state, dram_bank_reg(mininst)));
      event.column = static_cast<int>(register_value(state, dram_column_reg(mininst)));
      event.rank = static_cast<int>(dram_rank(mininst));
      event.auto_precharge = dram_ap(mininst);
      break;
    case k_pre:
      event.command = "PRE";
      event.bank = static_cast<int>(register_value(state, dram_bank_reg(mininst)));
      event.rank = static_cast<int>(dram_rank(mininst));
      event.precharge_all = dram_pall(mininst);
      break;
    case k_act:
      event.command = "ACT";
      event.bank = static_cast<int>(register_value(state, dram_bank_reg(mininst)));
      event.row = static_cast<int>(register_value(state, dram_row_reg(mininst)));
      event.rank = static_cast<int>(dram_rank(mininst));
      break;
    case k_sel_ch:
      event.command = "SEL_CH";
      event.channel = static_cast<int>(dram_bank_reg(mininst));
      event.pseudo_channel = static_cast<int>(dram_rank(mininst));
      break;
    case k_ref:
      event.command = "REF";
      event.rank = static_cast<int>(dram_rank(mininst));
      break;
    default:
      return;
  }

  maybe_record_event(trace, event);
}

void apply_dram_side_effects(VMState& state, Mininst mininst) {
  const uint32_t command = dram_command(mininst);

  switch (command) {
    case k_write:
    case k_read:
      if (dram_ibar(mininst)) {
        apply_register_increment(state, dram_bank_reg(mininst), k_basr_register);
      }
      if (dram_icar(mininst)) {
        apply_register_increment(state, dram_column_reg(mininst), k_casr_register);
      }
      break;
    case k_pre:
      if (dram_ibar(mininst)) {
        apply_register_increment(state, dram_bank_reg(mininst), k_basr_register);
      }
      break;
    case k_act:
      if (dram_ibar(mininst)) {
        apply_register_increment(state, dram_bank_reg(mininst), k_basr_register);
      }
      if (dram_irar(mininst)) {
        apply_register_increment(state, dram_row_reg(mininst), k_rasr_register);
      }
      break;
    default:
      break;
  }
}

void execute_dram_word(VMState& state,
                       DRAMCommandTrace* trace,
                       size_t pc,
                       Inst inst) {
  for (int slot = 0; slot < 4; ++slot) {
    const Mininst mininst = static_cast<Mininst>((inst >> (slot * 16)) & k_mask16);
    const size_t command_index = dram_command_index(mininst);
    if (command_index < state.dram_cmd_counts.size()) {
      ++state.dram_cmd_counts[command_index];
    }
    trace_dram_mininst(state, trace, pc, slot, mininst);
    apply_dram_side_effects(state, mininst);
  }

  advance_cycles(state, 1);
}

ExecutionResult build_execution_result(const VMState& state) {
  ExecutionResult result;
  result.total_cycles = state.total_cycles;
  result.total_ns = slots_to_ns(state.elapsed_slots, state.timing);
  result.registers = state.registers;
  result.dram_cmd_counts = state.dram_cmd_counts;
  result.instructions_executed = state.instructions_executed;
  result.branches_taken = state.branches_taken;
  return result;
}

ExecutionResult run_program(const FinalProgram& program,
                            size_t max_instructions,
                            DRAMCommandTrace* trace,
                            const TimingConfig& timing) {
  VMState state;
  state.timing = timing;
  const auto instructions = program.instructions();
  size_t pc = 0;
  bool terminated_by_end = false;

  while (pc < instructions.size() && state.instructions_executed < max_instructions) {
    const Inst inst = instructions[pc];
    ++state.instructions_executed;

    if (inst == SMC_END()) {
      terminated_by_end = true;
      break;
    }

    if (is_ddr(inst)) {
      execute_dram_word(state, trace, pc, inst);
      ++pc;
      continue;
    }

    const uint64_t opc = opcode(inst);
    const uint64_t fc = function_code(inst);

    if (opc == 0x8) {
      if (fc == k_sleep) {
        advance_cycles(state, sleep_amount(inst));
      } else if (fc == k_jump) {
        advance_cycles(state, k_taken_branch_cycles);
        ++state.branches_taken;
        pc = jump_target(inst);
        continue;
      } else if (fc == k_bl) {
        if (state.registers[rs1(inst)] < state.registers[rs2(inst)]) {
          advance_cycles(state, k_taken_branch_cycles);
          ++state.branches_taken;
          pc = branch_target(inst);
          continue;
        }
        advance_cycles(state, 1);
      } else if (fc == k_beq) {
        if (state.registers[rs1(inst)] == state.registers[rs2(inst)]) {
          advance_cycles(state, k_taken_branch_cycles);
          ++state.branches_taken;
          pc = branch_target(inst);
          continue;
        }
        advance_cycles(state, 1);
      } else {
        advance_cycles(state, 1);
      }
      ++pc;
      continue;
    }

    if (opc == 0x0) {
      advance_cycles(state, 1);
      const uint32_t destination = rt(inst);
      if (fc == k_add) {
        state.registers[destination] = state.registers[rs1(inst)] + state.registers[rs2(inst)];
      } else if (fc == k_addi) {
        state.registers[destination] = state.registers[rs1(inst)] + imm_low(inst);
      } else if (fc == k_sub) {
        state.registers[destination] = state.registers[rs1(inst)] - state.registers[rs2(inst)];
      } else if (fc == k_subi) {
        state.registers[destination] = state.registers[rs1(inst)] - imm_low(inst);
      } else if (fc == k_mv) {
        state.registers[destination] = state.registers[rs1(inst)];
      } else if (fc == k_src) {
        const uint32_t value = state.registers[rs1(inst)];
        state.registers[destination] = (value >> 1) | ((value & 1u) << 31);
      } else if (fc == k_li) {
        state.registers[destination] = li_immediate(inst);
      }

      ++pc;
      continue;
    }

    if (opc == 0x1) {
      advance_cycles(state, 1);
      const uint32_t destination = rt(inst);
      if (fc == k_and) {
        state.registers[destination] = state.registers[rs1(inst)] & state.registers[rs2(inst)];
      } else if (fc == k_or) {
        state.registers[destination] = state.registers[rs1(inst)] | state.registers[rs2(inst)];
      } else if (fc == k_xor) {
        state.registers[destination] = state.registers[rs1(inst)] ^ state.registers[rs2(inst)];
      }

      ++pc;
      continue;
    }

    if (opc == 0x2) {
      advance_cycles(state, 1);
      const uint32_t address = state.registers[rs1(inst)] + imm_low(inst);
      if (fc == k_ld) {
        const auto memory_it = state.memory.find(address);
        state.registers[rt(inst)] = memory_it == state.memory.end() ? 0 : memory_it->second;
      } else if (fc == k_st) {
        state.memory[address] = state.registers[rt(inst)];
      }

      ++pc;
      continue;
    }

    // Misc, self-refresh, and unknown instructions preserve the current
    // lightweight VM timing model: one cycle and no additional visible state.
    advance_cycles(state, 1);
    ++pc;
  }

  if (trace != nullptr) {
    trace->instructions_executed = state.instructions_executed;
    trace->total_cycles = state.total_cycles;
    trace->total_ns = slots_to_ns(state.elapsed_slots, state.timing);
    trace->truncated =
        !terminated_by_end && pc < instructions.size() && state.instructions_executed >= max_instructions;
  }

  return build_execution_result(state);
}

std::string format_decimal(uint64_t value) {
  std::string digits = std::to_string(value);
  for (int index = static_cast<int>(digits.size()) - 3; index > 0; index -= 3) {
    digits.insert(static_cast<size_t>(index), ",");
  }
  return digits;
}

std::string format_trace_ns(double value) {
  std::ostringstream output;
  output << std::fixed << std::setprecision(1) << value << " ns";
  return output.str();
}

std::string format_dram_event_details(const DRAMCommandEvent& event) {
  std::ostringstream output;
  bool need_separator = false;
  auto append_field = [&](std::string_view key, int value) {
    if (need_separator) {
      output << ' ';
    }
    output << key << '=' << value;
    need_separator = true;
  };
  auto append_flag = [&](std::string_view flag) {
    if (need_separator) {
      output << ' ';
    }
    output << flag;
    need_separator = true;
  };

  if (event.channel >= 0) {
    append_field("ch", event.channel);
  }
  if (event.pseudo_channel >= 0) {
    append_field("pch", event.pseudo_channel);
  }
  if (event.bank >= 0) {
    append_field("ba", event.bank);
  }
  if (event.row >= 0) {
    append_field("row", event.row);
  }
  if (event.column >= 0) {
    append_field("col", event.column);
  }
  if (event.rank >= 0 && (event.command == "REF" || event.rank != 0)) {
    append_field("rk", event.rank);
  }
  if (event.auto_precharge) {
    append_flag("ap");
  }
  if (event.precharge_all) {
    append_flag("all");
  }
  return output.str();
}

}  // namespace

ExecutionResult execute(const FinalProgram& program, size_t max_instructions,
                        const TimingConfig& timing) {
  return run_program(program, max_instructions, nullptr, timing);
}

DRAMCommandTrace trace_dram_commands(const FinalProgram& program,
                                     size_t max_instructions,
                                     const TimingConfig& timing) {
  DRAMCommandTrace trace;
  (void)run_program(program, max_instructions, &trace, timing);
  return trace;
}

std::string format_execution_result(const ExecutionResult& result) {
  std::ostringstream output;
  output << "Execution result:\n";
  output << "  Total cycles         : " << format_decimal(result.total_cycles) << '\n';
  output << std::fixed << std::setprecision(3);
  output << "  Total time           : " << (result.total_ns / 1e6) << " ms (";
  output << std::setprecision(6) << (result.total_ns / 1e9) << " s)\n";
  output << "  Instructions executed: " << format_decimal(result.instructions_executed) << '\n';
  output << "  Branches taken       : " << format_decimal(result.branches_taken) << '\n';
  output << "  DRAM commands:\n";
  for (size_t index = 0; index < k_dram_command_names.size(); ++index) {
    if (result.dram_cmd_counts[index] == 0) {
      continue;
    }
    output << "    " << std::left << std::setw(8) << k_dram_command_names[index]
           << ": " << format_decimal(result.dram_cmd_counts[index]) << '\n';
  }

  output << "  Nonzero registers:\n";
  bool printed_any_register = false;
  for (size_t index = 0; index < result.registers.size(); ++index) {
    if (result.registers[index] == 0) {
      continue;
    }

    printed_any_register = true;
    output << "    " << std::left << std::setw(16) << formatting::format_register_listing(index)
           << " = 0x"
           << std::right << std::hex << std::nouppercase << std::setfill('0') << std::setw(8)
           << result.registers[index] << std::dec << std::setfill(' ')
           << " (" << result.registers[index] << ")\n";
  }
  if (!printed_any_register) {
    output << "    none\n";
  }
  return output.str();
}

std::string format_dram_command_trace(const DRAMCommandTrace& trace) {
  std::ostringstream output;
  output << "DRAM command trace:\n";

  if (trace.events.empty()) {
    output << "  no DRAM commands\n";
  } else {
    size_t delta_width = 0;
    size_t detail_width = 0;
    size_t time_width = 0;
    for (const DRAMCommandEvent& event : trace.events) {
      delta_width = std::max(delta_width, format_trace_ns(event.delta_ns).size() + 1);
      detail_width = std::max(detail_width, format_dram_event_details(event).size());
      time_width = std::max(time_width, format_trace_ns(event.time_ns).size() + 2);
    }

    for (size_t index = 0; index < trace.events.size(); ++index) {
      const DRAMCommandEvent& event = trace.events[index];
      const std::string delta = "+" + format_trace_ns(event.delta_ns);
      const std::string details = format_dram_event_details(event);
      const std::string time = "t=" + format_trace_ns(event.time_ns);
      output << "  " << std::left << std::setw(static_cast<int>(delta_width)) << delta
             << " | " << std::left << std::setw(6) << event.command
             << " | " << std::left << std::setw(static_cast<int>(detail_width)) << details
             << " | " << std::right << std::setw(static_cast<int>(time_width)) << time << '\n';
    }
  }

  output << "Summary:\n";
  output << "  Instructions executed: " << format_decimal(trace.instructions_executed) << '\n';
  output << "  Total cycles         : " << format_decimal(trace.total_cycles) << '\n';
  output << std::fixed << std::setprecision(1);
  output << "  Total time           : " << trace.total_ns << " ns\n";
  output << "  Truncated            : " << (trace.truncated ? "yes" : "no") << '\n';
  return output.str();
}

}  // namespace DRAMBender::vm
