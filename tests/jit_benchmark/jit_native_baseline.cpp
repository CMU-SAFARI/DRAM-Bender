#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <numeric>
#include <string>
#include <vector>

#include "draminspector/api/program/instruction.h"
#include "draminspector/api/program/program.h"

using namespace DRAMBender;

namespace {

constexpr int k_casr = 0;
constexpr int k_car = 3;
constexpr int k_bar = 4;
constexpr int k_rar = 5;
constexpr int k_pattern_reg = 6;
constexpr int k_num_hammer_reg = 7;
constexpr int k_hammer_ctr_reg = 8;
constexpr int k_cachelines_per_row = 128;

FinalProgram build_tiny_scalar_program(int bank, int row, int delay) {
  Program program;
  program.add_inst(SMC_LI(bank, k_bar));
  program.add_inst(SMC_LI(row, k_rar));
  program.add_mininst(SMC_PRE(k_bar, 0, 0), delay);
  program.add_mininst(SMC_ACT(k_bar, 0, k_rar, 0), delay);
  // SLEEP(6) = 36 ns meets tRAS before the closing PRE; SLEEP(3) = 18 ns
  // after the PRE gives tRP cushion for any subsequent program.
  program.add_inst(SMC_SLEEP(6));
  program.add_inst(SMC_PRE(k_bar, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_SLEEP(3));
  return program.conclude();
}

FinalProgram build_pattern_program(const std::vector<uint32_t>& pattern_words) {
  Program program;
  for (size_t index = 0; index < pattern_words.size(); ++index) {
    program.add_inst(SMC_LI(pattern_words[index], k_pattern_reg));
    program.add_inst(SMC_LDWD(k_pattern_reg, static_cast<int>(index)));
  }
  return program.conclude();
}

void load_pattern(Program& program, int source_reg) {
  for (int index = 0; index < 16; ++index) {
    program.add_inst(SMC_LDWD(source_reg, index));
  }
}

FinalProgram build_rowhammer_program(
    int bank,
    int victim_row,
    int aggressor_row,
    uint32_t victim_pattern,
    uint32_t aggressor_pattern,
    int hammer_count) {
  Program program;
  program.add_inst(SMC_LI(bank, k_bar));
  program.add_inst(SMC_LI(8, k_casr));
  program.add_inst(SMC_LI(hammer_count, k_num_hammer_reg));
  program.add_inst(SMC_LI(0, k_hammer_ctr_reg));

  program.add_inst(SMC_LI(victim_row, k_rar));
  program.add_inst(SMC_LI(victim_pattern, k_pattern_reg));
  load_pattern(program, k_pattern_reg);
  program.add_mininst(SMC_PRE(k_bar, 0, 0), 11);
  program.add_mininst(SMC_ACT(k_bar, 0, k_rar, 0), 11);
  program.add_inst(SMC_LI(0, k_car));
  for (int index = 0; index < k_cachelines_per_row; ++index) {
    program.add_mininst(SMC_WRITE(k_bar, 0, k_car, 1, 0, 0), 7);
  }
  program.add_DRAM_wait(8);
  program.add_mininst(SMC_PRE(k_bar, 0, 0), 11);

  program.add_inst(SMC_LI(aggressor_row, k_rar));
  program.add_inst(SMC_LI(aggressor_pattern, k_pattern_reg));
  load_pattern(program, k_pattern_reg);
  program.add_mininst(SMC_PRE(k_bar, 0, 0), 11);
  program.add_mininst(SMC_ACT(k_bar, 0, k_rar, 0), 11);
  program.add_inst(SMC_LI(0, k_car));
  for (int index = 0; index < k_cachelines_per_row; ++index) {
    program.add_mininst(SMC_WRITE(k_bar, 0, k_car, 1, 0, 0), 7);
  }
  program.add_DRAM_wait(8);
  program.add_mininst(SMC_PRE(k_bar, 0, 0), 11);

  program.add_inst(SMC_LI(aggressor_row, k_rar));
  program.add_inst(SMC_LI(0, k_hammer_ctr_reg));
  program.add_mininst(SMC_ACT(k_bar, 0, k_rar, 0), 23);
  program.add_label("HAMMER");
  program.add_mininst(SMC_PRE(k_bar, 0, 0), 3);
  program.add_inst(SMC_ADDI(k_hammer_ctr_reg, 1, k_hammer_ctr_reg));
  program.add_mininst(SMC_ACT(k_bar, 0, k_rar, 0), 3);
  program.add_branch(Program::BR_TYPE::BL, k_hammer_ctr_reg, k_num_hammer_reg, "HAMMER");
  program.add_mininst(SMC_PRE(k_bar, 0, 0), 11);

  program.add_inst(SMC_LI(victim_row, k_rar));
  program.add_inst(SMC_LI(0, k_car));
  program.add_mininst(SMC_PRE(k_bar, 0, 0), 11);
  program.add_mininst(SMC_ACT(k_bar, 0, k_rar, 0), 11);
  for (int index = 0; index < k_cachelines_per_row; ++index) {
    program.add_mininst(SMC_READ(k_bar, 0, k_car, 1, 0, 0), 7);
  }
  program.add_DRAM_wait(4);
  program.add_mininst(SMC_PRE(k_bar, 0, 0), 11);
  return program.conclude();
}

double percentile(std::vector<double> values, double fraction) {
  if (values.empty()) {
    return 0.0;
  }

  std::sort(values.begin(), values.end());
  const double index = (values.size() - 1) * fraction;
  const size_t lower = static_cast<size_t>(index);
  const size_t upper = static_cast<size_t>(std::ceil(index));
  if (lower == upper) {
    return values[lower];
  }

  const double weight = index - static_cast<double>(lower);
  return values[lower] * (1.0 - weight) + values[upper] * weight;
}

int parse_int_arg(char** begin, char** end, const std::string& flag, int default_value) {
  for (auto* it = begin; it != end; ++it) {
    if (flag == *it && it + 1 != end) {
      return std::atoi(*(it + 1));
    }
  }
  return default_value;
}

std::string parse_string_arg(char** begin, char** end, const std::string& flag, std::string default_value) {
  for (auto* it = begin; it != end; ++it) {
    if (flag == *it && it + 1 != end) {
      return *(it + 1);
    }
  }
  return default_value;
}

}  // namespace

int main(int argc, char** argv) {
  const std::string workload =
      parse_string_arg(argv + 1, argv + argc, "--workload", "rowhammer");
  const int batch_size = parse_int_arg(argv + 1, argv + argc, "--batch-size", 64);
  const int pattern_length =
      parse_int_arg(argv + 1, argv + argc, "--pattern-length", 4);
  const int hammer_count =
      parse_int_arg(argv + 1, argv + argc, "--hammer-count", 250000);

  std::vector<double> times_us;
  times_us.reserve(batch_size);
  size_t instruction_count = 0;

  for (int index = 0; index < batch_size; ++index) {
    const auto start = std::chrono::high_resolution_clock::now();

    FinalProgram program(std::vector<Inst>{});
    if (workload == "tiny_scalar") {
      program = build_tiny_scalar_program(0, index, 11 + (index % 3));
    } else if (workload == "pattern") {
      std::vector<uint32_t> pattern_words;
      pattern_words.reserve(pattern_length);
      for (int word = 0; word < pattern_length; ++word) {
        pattern_words.push_back(
            static_cast<uint32_t>(((index + 1) * 0x11111111u) + word * 0x01010101u));
      }
      program = build_pattern_program(pattern_words);
    } else if (workload == "rowhammer") {
      program = build_rowhammer_program(
          0,
          index,
          index + 1,
          0x00000000u,
          0xFFFFFFFFu,
          hammer_count);
    } else {
      std::cerr << "Unknown workload: " << workload << std::endl;
      return 1;
    }

    const auto end = std::chrono::high_resolution_clock::now();
    instruction_count = program.instruction_count();
    times_us.push_back(
        std::chrono::duration<double, std::micro>(end - start).count());
  }

  const double batch_ms =
      std::accumulate(times_us.begin(), times_us.end(), 0.0) / 1000.0;
  const double min_us = *std::min_element(times_us.begin(), times_us.end());
  std::vector<double> ordered = times_us;
  std::sort(ordered.begin(), ordered.end());
  const double median_us =
      ordered.size() % 2 == 0
          ? (ordered[ordered.size() / 2 - 1] + ordered[ordered.size() / 2]) / 2.0
          : ordered[ordered.size() / 2];
  const double p95_us = percentile(times_us, 0.95);

  std::cout << "{"
            << "\"workload\":\"" << workload << "\","
            << "\"batch_size\":" << batch_size << ","
            << "\"instruction_count\":" << instruction_count << ","
            << "\"batch_ms\":" << batch_ms << ","
            << "\"min_us\":" << min_us << ","
            << "\"median_us\":" << median_us << ","
            << "\"p95_us\":" << p95_us
            << "}" << std::endl;
  return 0;
}
