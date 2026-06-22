#include "drambender/utils/debug.h"

#include <cstring>
#include <iomanip>
#include <map>
#include <sstream>
#include <stdexcept>
#include <utility>
#include <vector>

#include "api/program/instruction_internal.h"
#include "formatting_internal.h"

namespace DRAMBender::debug {

using namespace InstrEncoding;

namespace {

struct ResolvedTarget {
  std::string label;
  size_t pc = 0;
};

uint64_t function_code(Inst inst) {
  return (inst >> k_function_code_shift) & 0x7ff;
}

uint64_t opcode(Inst inst) {
  return inst >> k_opcode_shift;
}

uint32_t raw_rs1(Inst inst) {
  return static_cast<uint32_t>((inst >> k_rs1_shift) & 0xf);
}

uint32_t raw_rs2(Inst inst) {
  return static_cast<uint32_t>((inst >> k_rs2_shift) & 0xf);
}

uint32_t raw_rt(Inst inst) {
  return static_cast<uint32_t>((inst >> k_rt_shift) & 0xf);
}

uint32_t imm_low(Inst inst) {
  return static_cast<uint32_t>((inst >> k_immediate_low_shift) & 0xffff);
}

uint32_t imm_high(Inst inst) {
  return static_cast<uint32_t>((inst >> k_immediate_high_shift) & 0xffff);
}

uint64_t imm_full(Inst inst) {
  return (uint64_t(imm_high(inst)) << 16) | imm_low(inst);
}

size_t raw_branch_target(Inst inst) {
  return static_cast<size_t>((inst >> k_branch_target_shift) & 0x7ffff);
}

size_t raw_jump_target(Inst inst) {
  return static_cast<size_t>((inst >> k_jump_target_shift) & 0x7ffffff);
}

uint32_t info_read_count(Inst inst) {
  return static_cast<uint32_t>(inst);
}

std::string maybe_incremented_register(uint32_t register_id, bool incremented) {
  std::string name = formatting::format_register_operand(register_id);
  if (incremented) {
    name += "++";
  }
  return name;
}

std::string format_address_operand(uint32_t base_register, uint32_t offset) {
  std::ostringstream out;
  out << '[' << formatting::format_register_operand(base_register);
  if (offset != 0) {
    out << " + " << offset;
  }
  out << ']';
  return out.str();
}

std::string format_target_suffix(const ResolvedTarget* target, size_t raw_target_pc) {
  std::ostringstream out;
  if (target != nullptr) {
    out << " -> " << target->label << " (pc=" << target->pc << ')';
  } else {
    out << " -> pc=" << raw_target_pc;
  }
  return out.str();
}

std::string format_mininst(Mininst inst) {
  const uint32_t command = static_cast<uint32_t>((inst >> k_ddr_command_shift) & 0xf);
  const uint32_t bar = static_cast<uint32_t>(inst & 0xf);
  const uint32_t car = static_cast<uint32_t>((inst >> k_ddr_column_shift) & 0xf);
  const uint32_t rar = static_cast<uint32_t>((inst >> k_ddr_row_shift) & 0xf);
  const bool ibar = ((inst >> k_ddr_increment_bank_shift) & 1) != 0;
  const bool icar = ((inst >> k_ddr_increment_column_shift) & 1) != 0;
  const bool irar = ((inst >> k_ddr_increment_row_shift) & 1) != 0;
  const bool pall = ((inst >> k_ddr_precharge_all_shift) & 1) != 0;
  const bool ap = ((inst >> k_ddr_auto_precharge_shift) & 1) != 0;
  const uint32_t rank = static_cast<uint32_t>((inst >> k_ddr_rank_shift) & 1);

  std::ostringstream out;
  switch (command) {
    case k_write:
      out << "WR " << maybe_incremented_register(bar, ibar) << ", "
          << maybe_incremented_register(car, icar);
      if (ap) {
        out << ", AP";
      }
      if (rank != 0) {
        out << ", rank=" << rank;
      }
      break;
    case k_read:
      out << "RD " << maybe_incremented_register(bar, ibar) << ", "
          << maybe_incremented_register(car, icar);
      if (ap) {
        out << ", AP";
      }
      if (rank != 0) {
        out << ", rank=" << rank;
      }
      break;
    case k_pre:
      out << "PRE " << maybe_incremented_register(bar, ibar);
      if (pall) {
        out << ", PALL";
      }
      if (rank != 0) {
        out << ", rank=" << rank;
      }
      break;
    case k_act:
      out << "ACT " << maybe_incremented_register(bar, ibar) << ", "
          << maybe_incremented_register(rar, irar);
      if (rank != 0) {
        out << ", rank=" << rank;
      }
      break;
    case k_sel_ch:
      out << "SEL_CH channel=" << bar << ", pseudo_channel=" << rank;
      break;
    case k_ref:
      out << "REF";
      if (rank != 0) {
        out << " rank=" << rank;
      }
      break;
    case k_nop:
      out << "NOP";
      if (rank != 0) {
        out << " rank=" << rank;
      }
      break;
    default:
      out << "UNKNOWN_DRAM(cmd=0x" << std::hex << command << std::dec << ')';
      break;
  }
  return out.str();
}

std::string format_inst(Inst inst, const ResolvedTarget* target = nullptr) {
  if (is_ddr(inst)) {
    std::ostringstream out;
    for (int slot = 0; slot < 4; ++slot) {
      if (slot > 0) {
        out << " | ";
      }
      out << format_mininst(static_cast<Mininst>((inst >> (slot * 16)) & 0xffff));
    }
    return out.str();
  }

  std::ostringstream out;
  const int fc = static_cast<int>(function_code(inst));
  const int opc = static_cast<int>(opcode(inst));

  if (opc == 0x0) {
    switch (fc) {
      case k_add:
        if (inst == 0) {
          out << "END";
        } else {
          out << "ADD " << formatting::format_register_operand(raw_rt(inst)) << ", "
              << formatting::format_register_operand(raw_rs1(inst)) << ", "
              << formatting::format_register_operand(raw_rs2(inst));
        }
        break;
      case k_addi:
        out << "ADDI " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << formatting::format_register_operand(raw_rs1(inst)) << ", " << imm_low(inst);
        break;
      case k_sub:
        out << "SUB " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << formatting::format_register_operand(raw_rs1(inst)) << ", "
            << formatting::format_register_operand(raw_rs2(inst));
        break;
      case k_subi:
        out << "SUBI " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << formatting::format_register_operand(raw_rs1(inst)) << ", " << imm_low(inst);
        break;
      case k_mv:
        out << "MV " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << formatting::format_register_operand(raw_rs1(inst));
        break;
      case k_li:
        out << "LI " << formatting::format_register_operand(raw_rt(inst)) << ", " << imm_full(inst);
        break;
      case k_src:
        out << "SRC " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << formatting::format_register_operand(raw_rs1(inst));
        break;
      case k_ldwd:
        out << "LDWD " << formatting::format_register_operand(raw_rs1(inst)) << ", lane="
            << raw_rt(inst);
        break;
      case k_ldpc: {
        constexpr const char* counters[] = {
            "WRITE_COUNTER",
            "READ_COUNTER",
            "PRE_COUNTER",
            "ACT_COUNTER",
            "SEL_CH_COUNTER",
            "REF_COUNTER",
            "TOTAL_CYCLES",
        };
        const uint32_t counter_index = raw_rs1(inst);
        out << "LDPC " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << (counter_index < 7 ? counters[counter_index] : "UNKNOWN_COUNTER");
        break;
      }
      case k_sre: out << "SRE"; break;
      case k_srx: out << "SRX"; break;
      default: out << "UNKNOWN_ARITH(fc=0x" << std::hex << fc << std::dec << ')'; break;
    }
  } else if (opc == 0x8) {
    switch (fc) {
      case k_bl:
        out << "BL " << formatting::format_register_operand(raw_rs1(inst)) << ", "
            << formatting::format_register_operand(raw_rs2(inst))
            << format_target_suffix(target, raw_branch_target(inst));
        break;
      case k_beq:
        out << "BEQ " << formatting::format_register_operand(raw_rs1(inst)) << ", "
            << formatting::format_register_operand(raw_rs2(inst))
            << format_target_suffix(target, raw_branch_target(inst));
        break;
      case k_jump:
        out << "JUMP" << format_target_suffix(target, raw_jump_target(inst));
        break;
      case k_sleep:
        out << "SLEEP " << (static_cast<uint32_t>(inst) + 2) << " cycles";
        break;
      default:
        out << "UNKNOWN_BRANCH(fc=0x" << std::hex << fc << std::dec << ')';
        break;
    }
  } else if (opc == 0x4) {
    switch (fc) {
      case k_info:
        out << "AUTOGEN: INFO read_count=" << info_read_count(inst);
        break;
      default:
        out << "UNKNOWN_MISC(fc=0x" << std::hex << fc << std::dec << ')';
        break;
    }
  } else if (opc == 0x2) {
    switch (fc) {
      case k_ld:
        out << "LD " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << format_address_operand(raw_rs1(inst), imm_low(inst));
        break;
      case k_st:
        out << "ST " << format_address_operand(raw_rs1(inst), imm_low(inst)) << ", "
            << formatting::format_register_operand(raw_rt(inst));
        break;
      default:
        out << "UNKNOWN_MEM(fc=0x" << std::hex << fc << std::dec << ')';
        break;
    }
  } else if (opc == 0x1) {
    switch (fc) {
      case k_and:
        out << "AND " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << formatting::format_register_operand(raw_rs1(inst)) << ", "
            << formatting::format_register_operand(raw_rs2(inst));
        break;
      case k_or:
        out << "OR " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << formatting::format_register_operand(raw_rs1(inst)) << ", "
            << formatting::format_register_operand(raw_rs2(inst));
        break;
      case k_xor:
        out << "XOR " << formatting::format_register_operand(raw_rt(inst)) << ", "
            << formatting::format_register_operand(raw_rs1(inst)) << ", "
            << formatting::format_register_operand(raw_rs2(inst));
        break;
      default:
        out << "UNKNOWN_BW(fc=0x" << std::hex << fc << std::dec << ')';
        break;
    }
  } else {
    out << "UNKNOWN 0x" << std::hex << inst << std::dec;
  }

  return out.str();
}

std::map<size_t, std::vector<std::string>> labels_by_pc(const std::map<std::string, size_t>& labels) {
  std::map<size_t, std::vector<std::string>> grouped;
  for (const auto& [label_name, label_pc] : labels) {
    grouped[label_pc].push_back(label_name);
  }
  return grouped;
}

std::string format_program_impl(std::span<const Inst> instructions,
                                const std::map<std::string, size_t>& labels,
                                const std::map<size_t, std::string>& branches,
                                bool include_binary) {
  std::ostringstream output;
  const auto grouped_labels = labels_by_pc(labels);
  const size_t width = formatting::pc_width(instructions.size());

  for (size_t pc = 0; pc < instructions.size(); ++pc) {
    const auto label_it = grouped_labels.find(pc);
    if (label_it != grouped_labels.end()) {
      for (const std::string& label_name : label_it->second) {
        output << label_name << ":\n";
      }
    }

    ResolvedTarget target;
    const ResolvedTarget* target_ptr = nullptr;
    const auto branch_it = branches.find(pc);
    if (branch_it != branches.end()) {
      target.label = branch_it->second;
      const auto target_label_it = labels.find(branch_it->second);
      if (target_label_it != labels.end()) {
        target.pc = target_label_it->second;
      } else if (is_conditional_branch(instructions[pc])) {
        target.pc = raw_branch_target(instructions[pc]);
      } else {
        target.pc = raw_jump_target(instructions[pc]);
      }
      target_ptr = &target;
    }

    output << std::setw(static_cast<int>(width)) << std::setfill('0') << pc
           << std::setfill(' ') << " | ";
    if (include_binary) {
      output << "0x" << std::hex << std::setw(16) << std::setfill('0') << instructions[pc]
             << std::dec << std::setfill(' ') << " | ";
    }
    output << format_inst(instructions[pc], target_ptr) << '\n';
  }

  return output.str();
}

std::string format_wdata(const std::array<std::byte, 64>& wdata) {
  std::ostringstream output;
  output << std::hex << std::setfill('0');
  for (int word = 15; word >= 0; --word) {
    if (word % 4 == 3) {
      output << "  0x";
    }
    for (int byte = 3; byte >= 0; --byte) {
      const size_t index = static_cast<size_t>(word * 4 + byte);
      output << std::setw(2)
             << static_cast<unsigned int>(std::to_integer<unsigned char>(wdata[index]));
    }
    if (word % 4 == 0) {
      output << '\n';
    } else {
      output << ' ';
    }
  }
  return output.str();
}

}  // namespace

std::string format_program(const Program& program) {
  Program snapshot = program;
  if (!snapshot.minprogram_.empty()) {
    snapshot.flushMinprogram_();
  }
  return format_program_impl(snapshot.program_, snapshot.labels_, snapshot.branches_, false);
}

std::string format_program(const FinalProgram& program) {
  return format_program_impl(program.instructions(), program.labels_, program.branches_, false);
}

std::string format_program_binary(const Program& program) {
  Program snapshot = program;
  if (!snapshot.minprogram_.empty()) {
    snapshot.flushMinprogram_();
  }
  return format_program_impl(snapshot.program_, snapshot.labels_, snapshot.branches_, true);
}

std::string format_program_binary(const FinalProgram& program) {
  return format_program_impl(program.instructions(), program.labels_, program.branches_, true);
}

Program& append_register_dump(Program& program) {
  program.add_inst(SMC_LI(15, 13));
  program.add_inst(SMC_LI(0, 14));
  program.add_inst(SMC_LI(0, 15));

  program.add_inst(SMC_PRE(13, 0, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_ACT(13, 0, 14, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_WRITE(13, 0, 15, 0, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_READ(13, 0, 15, 0, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());

  for (int reg = 0; reg < 16; ++reg) {
    program.add_inst(SMC_LDWD(reg, reg));
  }

  program.add_inst(SMC_WRITE(13, 0, 15, 0, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_READ(13, 0, 15, 0, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());

  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_PRE(13, 0, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  return program;
}

RegisterDump read_register_dump(IBoard& board) {
  RegisterDump dump{};
  if (board.receive(std::span(dump.wdata)) != dump.wdata.size()) {
    throw std::runtime_error("Short read while receiving WDATA for register dump.");
  }

  std::array<std::byte, 64> register_bytes{};
  if (board.receive(std::span(register_bytes)) != register_bytes.size()) {
    throw std::runtime_error("Short read while receiving register payload for register dump.");
  }

  std::memcpy(dump.registers.data(), register_bytes.data(), register_bytes.size());
  return dump;
}

std::string format_register_dump(const RegisterDump& dump) {
  std::ostringstream output;
  output << "WDATA:\n" << format_wdata(dump.wdata);
  output << "Registers:\n";

  for (size_t reg = 0; reg < dump.registers.size(); ++reg) {
    output << "  " << std::left << std::setw(16) << formatting::format_register_listing(reg)
           << " = 0x" << std::right << std::hex << std::nouppercase << std::setfill('0')
           << std::setw(8) << dump.registers[reg] << std::dec << std::setfill(' ')
           << " (" << dump.registers[reg] << ")\n";
  }

  return output.str();
}

}  // namespace DRAMBender::debug
