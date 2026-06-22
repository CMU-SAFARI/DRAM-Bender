#include "drambender/api/program/program.h"

#include <stdexcept>
#include <utility>

#include "instruction_internal.h"

namespace DRAMBender {

using namespace InstrEncoding;

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

void Program::ensureNotConcluded_() const {
  if (concluded_) {
    throw std::logic_error(
        "Program is single-use; conclude() was already called. "
        "Construct a new Program to continue authoring.");
  }
}

void Program::appendInstNoFlush_(Inst inst) {
  program_.push_back(inst);
  if (is_load(inst)) {
    program_.push_back(all_nops());
  }
}

void Program::flushMinprogram_() {
  while (minprogram_.size() >= 4) {
    appendInstNoFlush_(pack_mininsts(minprogram_[0], minprogram_[1],
                                     minprogram_[2], minprogram_[3]));
    minprogram_.erase(minprogram_.begin(), minprogram_.begin() + 4);
  }

  switch (minprogram_.size()) {
    case 0: break;
    case 1: appendInstNoFlush_(pack_mininsts(minprogram_[0], SMC_NOP(), SMC_NOP(), SMC_NOP())); break;
    case 2: appendInstNoFlush_(pack_mininsts(minprogram_[0], minprogram_[1], SMC_NOP(), SMC_NOP())); break;
    case 3: appendInstNoFlush_(pack_mininsts(minprogram_[0], minprogram_[1], minprogram_[2], SMC_NOP())); break;
  }

  minprogram_.clear();
}

// ---------------------------------------------------------------------------
// Builder methods
// ---------------------------------------------------------------------------

Program& Program::add_mininst(Mininst mi, int delay) {
  ensureNotConcluded_();
  if (delay < 1) {
    throw std::invalid_argument("delay must be at least one cycle.");
  }
  minprogram_.push_back(mi);
  for (int w = delay - 1; w > 0; --w) {
    minprogram_.push_back(SMC_NOP());
  }
  return *this;
}

Program& Program::add_DRAM_wait(int wait_slots) {
  ensureNotConcluded_();
  if (wait_slots < 0) {
    throw std::invalid_argument("wait_slots cannot be negative.");
  }
  for (; wait_slots > 0; --wait_slots) {
    minprogram_.push_back(SMC_NOP());
  }
  return *this;
}

Program& Program::add_inst(Inst inst) {
  ensureNotConcluded_();
  // Switching from mini-instruction assembly back to full-width instructions
  // must preserve the pending timing stream instead of rejecting the mix.
  flushMinprogram_();
  appendInstNoFlush_(inst);
  return *this;
}

Program& Program::add_inst(Mininst m1, Mininst m2, Mininst m3, Mininst m4) {
  ensureNotConcluded_();
  flushMinprogram_();
  appendInstNoFlush_(pack_mininsts(m1, m2, m3, m4));
  return *this;
}

Program& Program::add_label(std::string name) {
  ensureNotConcluded_();
  flushMinprogram_();
  if (labels_.contains(name)) {
    throw std::invalid_argument("Trying to add duplicate label: " + name);
  }
  labels_[std::move(name)] = program_.size();
  return *this;
}

Program& Program::add_branch(BR_TYPE bt, int rs1, int rs2, std::string tgt) {
  ensureNotConcluded_();
  flushMinprogram_();

  Inst place_holder = 0;
  switch (bt) {
    case BR_TYPE::BL:   place_holder = SMC_BL(rs1, rs2, 0); break;
    case BR_TYPE::BEQ:  place_holder = SMC_BEQ(rs1, rs2, 0); break;
    case BR_TYPE::JUMP: place_holder = SMC_JUMP(0); break;
  }

  branches_[program_.size()] = std::move(tgt);
  appendInstNoFlush_(place_holder);
  return *this;
}

Program& Program::add_below(const Program& p) {
  ensureNotConcluded_();
  // DRAM authoring is timing-critical: silently flushing pending mini-insts
  // on either side would inject padding NOPs and shift the exact cycle
  // schedule of every downstream DRAM command. Require the caller to flush
  // explicitly so the timing is always authored, never inferred.
  if (!minprogram_.empty()) {
    throw std::invalid_argument(
        "add_below: receiver program has pending mini-instructions. "
        "Call flush() first — silent flushing would inject padding NOPs "
        "and change command timing.");
  }
  if (!p.minprogram_.empty()) {
    throw std::invalid_argument(
        "add_below: source program has pending mini-instructions. "
        "Call flush() on it first — silent flushing would inject padding "
        "NOPs and change command timing.");
  }

  const size_t base_pc = program_.size();
  program_.insert(program_.end(), p.program_.begin(), p.program_.end());

  for (const auto& [label_name, label_pc] : p.labels_) {
    if (labels_.contains(label_name)) {
      throw std::invalid_argument("Cannot append program with duplicate label: " + label_name);
    }
    labels_[label_name] = label_pc + base_pc;
  }

  for (const auto& [branch_pc, label_name] : p.branches_) {
    branches_[branch_pc + base_pc] = label_name;
  }
  return *this;
}

Program& Program::flush() {
  ensureNotConcluded_();
  flushMinprogram_();
  return *this;
}

// ---------------------------------------------------------------------------
// Analysis pipeline (private)
// ---------------------------------------------------------------------------

void Program::preprocess_branches_() {
  for (const auto& [branch_pc, label_name] : branches_) {
    if (branch_pc >= program_.size()) {
      throw std::logic_error("Branch PC is out of bounds during branch preprocessing.");
    }

    const auto label_it = labels_.find(label_name);
    if (label_it == labels_.end()) {
      throw std::invalid_argument("Unknown branch target label: " + label_name);
    }

    Inst branch_inst = program_[branch_pc];
    if (!is_branch(branch_inst)) {
      throw std::logic_error("Attempted to patch a non-branch instruction as a branch.");
    }

    // Target field must be zero before we OR in the resolved PC; otherwise
    // the instruction at branch_pc has been corrupted between add_branch
    // and conclude.
    constexpr Inst k_branch_target_bits_mask = Inst(0x7ffff) << k_branch_target_shift;
    constexpr Inst k_jump_target_bits_mask   = Inst(0x7ffff) << k_jump_target_shift;
    const Inst expected_zero_mask = is_conditional_branch(branch_inst)
                                        ? k_branch_target_bits_mask
                                        : k_jump_target_bits_mask;
    if ((branch_inst & expected_zero_mask) != 0) {
      throw std::logic_error(
          "Branch target bits were not zero at patch time; program may have "
          "been corrupted after add_branch.");
    }

    const uint64_t target_b = Inst(label_it->second) << k_branch_target_shift;
    const uint64_t target_j = Inst(label_it->second);
    branch_inst |= is_conditional_branch(branch_inst) ? target_b : target_j;
    program_[branch_pc] = branch_inst;
  }
}

void Program::linear_analysis_() {
  warnings_.clear();

  bool in_sequence = false;
  size_t seq_pc = 0;
  int read_counter = 0;

  for (size_t pc = 0; pc < program_.size(); ++pc) {
    const Inst cur_inst = program_[pc];
    if (!in_sequence) {
      if (is_ddr(cur_inst)) {
        in_sequence = true;
        seq_pc = pc;
        read_counter = count_ddr_reads(cur_inst);
      }
      continue;
    }

    if (!is_ddr(cur_inst) && !is_sleep(cur_inst)) {
      in_sequence = false;
      if (read_counter > 0 && read_counter <= 1024) {
        warnings_[seq_pc] = SMC_INFO(read_counter);
      }
    } else {
      read_counter += count_ddr_reads(cur_inst);
    }
  }
}

void Program::insert_generated_() {
  size_t inserted_count = 0;
  for (const auto& [warn_pc, warn_inst] : warnings_) {
    const size_t insertion_pc = warn_pc + inserted_count;
    program_.insert(program_.begin() + static_cast<std::ptrdiff_t>(insertion_pc), warn_inst);

    for (auto& [label_name, label_pc] : labels_) {
      (void)label_name;
      if (label_pc > insertion_pc) {
        ++label_pc;
      }
    }

    std::map<size_t, std::string> shifted_branches;
    for (const auto& [branch_pc, label_name] : branches_) {
      const size_t shifted_pc = branch_pc >= insertion_pc ? branch_pc + 1 : branch_pc;
      shifted_branches[shifted_pc] = label_name;
    }
    branches_ = std::move(shifted_branches);
    ++inserted_count;
  }

  warnings_.clear();
}

// ---------------------------------------------------------------------------
// conclude → FinalProgram
// ---------------------------------------------------------------------------

FinalProgram Program::conclude() {
  ensureNotConcluded_();
  flushMinprogram_();
  appendInstNoFlush_(SMC_END());
  linear_analysis_();
  insert_generated_();
  preprocess_branches_();
  concluded_ = true;
  return FinalProgram(std::move(program_), std::move(labels_), std::move(branches_));
}

}  // namespace DRAMBender
