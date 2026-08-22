#ifndef DRAMBENDER_API_PROGRAM_PROGRAM_H
#define DRAMBENDER_API_PROGRAM_PROGRAM_H

#include <cstddef>
#include <map>
#include <span>
#include <string>
#include <utility>
#include <vector>

#include "drambender/api/board/board_config.h"
#include "drambender/api/program/instruction.h"

namespace DRAMBender {

class Program;
class FinalProgram;

namespace debug {

std::string format_program(const Program& program);
std::string format_program(const FinalProgram& program);
std::string format_program_binary(const Program& program);
std::string format_program_binary(const FinalProgram& program);
Program& append_register_dump(Program& program);

}  // namespace debug

class FinalProgram {
 public:
  explicit FinalProgram(std::vector<Inst> instructions)
      : program_(std::move(instructions)) {}

  FinalProgram(std::vector<Inst> instructions,
               std::map<std::string, size_t> labels,
               std::map<size_t, std::string> branches)
      : program_(std::move(instructions)),
        labels_(std::move(labels)),
        branches_(std::move(branches)) {}

  [[nodiscard]] std::span<const Inst> instructions() const noexcept {
    return program_;
  }

  [[nodiscard]] size_t instruction_count() const noexcept {
    return program_.size();
  }

  [[nodiscard]] size_t size() const noexcept {
    return program_.size() * sizeof(Inst);
  }

  // DRAM command slot duration (ns) of the target this program was built
  // for. The software VM uses it when no explicit latency is passed.
  [[nodiscard]] double default_dram_inst_latency() const noexcept {
    return default_dram_inst_latency_;
  }

  void set_default_dram_inst_latency(double latency_ns) noexcept {
    default_dram_inst_latency_ = latency_ns;
  }

 private:
  std::vector<Inst> program_;
  std::map<std::string, size_t> labels_;
  std::map<size_t, std::string> branches_;
  double default_dram_inst_latency_ =
      get_board_config(BoardType::U200).dram_command_slot_ns;

  friend std::string debug::format_program(const FinalProgram& program);
  friend std::string debug::format_program_binary(const FinalProgram& program);
};

class Program {
 public:
  enum BR_TYPE { BEQ, BL, JUMP };

  Program() = default;

  Program& add_mininst(Mininst mi, int delay);
  // Pad the in-progress mini-program with N NOP mini-instructions (DRAM-level
  // slots; 4 slots = 1 FPGA fabric cycle). Used for DRAMSEQ-to-fabric-boundary
  // padding and explicit slot-level delays.
  Program& add_DRAM_wait(int wait_slots);
  Program& add_inst(Inst i);
  Program& add_inst(Mininst m1, Mininst m2, Mininst m3, Mininst m4);
  Program& add_label(std::string name);
  Program& add_branch(BR_TYPE bt, int rs1, int rs2, std::string tgt);
  Program& add_below(const Program& p);
  Program& flush();

 FinalProgram conclude();

 private:
  void appendInstNoFlush_(Inst inst);
  void flushMinprogram_();
  void preprocess_branches_();
  void linear_analysis_();
  void insert_generated_();
  void ensureNotConcluded_() const;

  std::map<std::string, size_t> labels_;
  std::map<size_t, std::string> branches_;
  std::map<size_t, Inst> warnings_;
  std::vector<Inst> program_;
  std::vector<Mininst> minprogram_;
  bool concluded_ = false;

  friend std::string debug::format_program(const Program& program);
  friend std::string debug::format_program_binary(const Program& program);
};

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_PROGRAM_PROGRAM_H
