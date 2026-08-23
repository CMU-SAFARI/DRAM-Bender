#include "drambender/api/program/instruction.h"
#include "drambender/api/program/program.h"

#include <exception>
#include <iostream>
#include <stdexcept>
#include <string>
#include <utility>

namespace {

DRAMBender::Inst read_inst() {
  return DRAMBender::SMC_READ(0, 0, 0, 0, 0, 0);
}

void add_reads(DRAMBender::Program& program, int count) {
  for (int i = 0; i < count; ++i) {
    program.add_inst(read_inst(),
                     DRAMBender::SMC_NOP(),
                     DRAMBender::SMC_NOP(),
                     DRAMBender::SMC_NOP());
  }
}

bool expect_conclude_ok(const std::string& name, DRAMBender::Program program) {
  try {
    (void)program.conclude();
    return true;
  } catch (const std::exception& error) {
    std::cerr << name << " unexpectedly failed: " << error.what() << '\n';
    return false;
  }
}

bool expect_conclude_invalid(const std::string& name,
                             DRAMBender::Program program) {
  try {
    (void)program.conclude();
  } catch (const std::invalid_argument&) {
    return true;
  } catch (const std::exception& error) {
    std::cerr << name << " threw the wrong exception: " << error.what()
              << '\n';
    return false;
  }

  std::cerr << name << " unexpectedly succeeded\n";
  return false;
}

}  // namespace

int main() {
  bool ok = true;

  {
    DRAMBender::Program program;
    add_reads(program, 1023);
    ok &= expect_conclude_ok("1023-read segment", std::move(program));
  }

  {
    DRAMBender::Program program;
    add_reads(program, 1024);
    ok &= expect_conclude_invalid("1024-read segment", std::move(program));
  }

  {
    DRAMBender::Program program;
    program.add_label("READ_LOOP");
    add_reads(program, 8);
    program.add_branch(DRAMBender::Program::BR_TYPE::BL, 1, 2, "READ_LOOP");
    ok &= expect_conclude_ok("looped read segment", std::move(program));
  }

  return ok ? 0 : 1;
}
