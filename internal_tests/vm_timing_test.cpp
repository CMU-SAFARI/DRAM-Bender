#include "drambender/api/program/instruction.h"
#include "drambender/api/program/program.h"
#include "drambender/utils/vm.h"

#include <cstdint>
#include <iostream>
#include <string>
#include <utility>

namespace {

constexpr uint64_t k_one_cycle = 1;
constexpr uint64_t k_branch_resolve_cycles = 6;

struct ExpectedTiming {
  uint64_t total_cycles;
  uint64_t branches_taken;
};

DRAMBender::FinalProgram make_conditional_branch_program(
    DRAMBender::Program::BR_TYPE branch_type,
    uint32_t lhs,
    uint32_t rhs) {
  DRAMBender::Program program;
  program.add_inst(DRAMBender::SMC_LI(lhs, 1));
  program.add_inst(DRAMBender::SMC_LI(rhs, 2));
  program.add_branch(branch_type, 1, 2, "DONE");
  program.add_label("DONE");
  return program.conclude();
}

DRAMBender::FinalProgram make_jump_program() {
  DRAMBender::Program program;
  program.add_branch(DRAMBender::Program::BR_TYPE::JUMP, 0, 0, "DONE");
  program.add_label("DONE");
  return program.conclude();
}

bool expect_timing(const std::string& name,
                   DRAMBender::FinalProgram program,
                   ExpectedTiming expected) {
  const auto result = DRAMBender::vm::execute(program, 100);
  bool ok = true;

  if (result.total_cycles != expected.total_cycles) {
    std::cerr << name << " total cycles: expected "
              << expected.total_cycles << ", got "
              << result.total_cycles << '\n';
    ok = false;
  }

  if (result.branches_taken != expected.branches_taken) {
    std::cerr << name << " branches taken: expected "
              << expected.branches_taken << ", got "
              << result.branches_taken << '\n';
    ok = false;
  }

  return ok;
}

}  // namespace

int main() {
  bool ok = true;

  const uint64_t two_loads_plus_branch =
      (2 * k_one_cycle) + k_branch_resolve_cycles;

  ok &= expect_timing(
      "BL taken",
      make_conditional_branch_program(DRAMBender::Program::BR_TYPE::BL, 0, 1),
      {two_loads_plus_branch, 1});

  ok &= expect_timing(
      "BL not taken",
      make_conditional_branch_program(DRAMBender::Program::BR_TYPE::BL, 1, 1),
      {two_loads_plus_branch, 0});

  ok &= expect_timing(
      "BEQ taken",
      make_conditional_branch_program(DRAMBender::Program::BR_TYPE::BEQ, 1, 1),
      {two_loads_plus_branch, 1});

  ok &= expect_timing(
      "BEQ not taken",
      make_conditional_branch_program(DRAMBender::Program::BR_TYPE::BEQ, 1, 2),
      {two_loads_plus_branch, 0});

  ok &= expect_timing(
      "JUMP",
      make_jump_program(),
      {k_branch_resolve_cycles, 1});

  return ok ? 0 : 1;
}
