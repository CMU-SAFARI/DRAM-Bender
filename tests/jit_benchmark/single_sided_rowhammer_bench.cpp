/**
 * Single-sided RowHammer example.
 *
 * For each victim row in [start_row, start_row + num_victims):
 *   1. Initialize victim row with the victim pattern (0x00000000).
 *   2. Initialize aggressor row (victim + 1) with the aggressor pattern (0xFFFFFFFF).
 *   3. Hammer the aggressor row `hammer_count` times.
 *   4. Read the victim row back and count bit flips.
 *
 * C++ equivalent of examples/single_sided_rowhammer.py.
 */

#include <charconv>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <exception>
#include <span>
#include <string_view>
#include <vector>

#include "drambender/api/board/board.h"

using namespace DRAMBender;

namespace {

constexpr int k_bytes_per_cacheline = 64;
constexpr int k_cachelines_per_row = 128;
constexpr int k_row_bytes = k_bytes_per_cacheline * k_cachelines_per_row;
constexpr int k_words_per_cacheline = 16;
constexpr int k_column_stride = 8;

constexpr uint32_t k_victim_pattern = 0x00000000;
constexpr uint32_t k_aggressor_pattern = 0xFFFFFFFF;

constexpr int k_default_instance_id = 0;
constexpr int k_default_bank = 0;
constexpr int k_default_start_row = 81;
constexpr int k_default_num_victims = 30;
constexpr int k_default_hammer_count = 500000;

// Register IDs
constexpr int CASR = 0;
constexpr int CAR = 3;
constexpr int BAR = 4;
constexpr int RAR = 5;
constexpr int PATTERN = 6;
constexpr int NUM_HAMMER = 7;
constexpr int HAMMER_CTR = 8;

struct Options {
  int instance_id = k_default_instance_id;
  int bank = k_default_bank;
  int start_row = k_default_start_row;
  int num_victims = k_default_num_victims;
  int hammer_count = k_default_hammer_count;
};

void print_usage(const char* argv0) {
  std::fprintf(stderr,
               "Usage: %s [--instance-id N] [--bank N] [--start-row N] "
               "[--num-victims N] [--hammer-count N]\n",
               argv0);
}

bool parse_int(const char* text, int* value) {
  const std::string_view input(text);
  if (input.empty()) {
    return false;
  }
  int parsed = 0;
  const auto result = std::from_chars(input.data(), input.data() + input.size(), parsed);
  if (result.ec != std::errc() || result.ptr != input.data() + input.size()) {
    return false;
  }
  *value = parsed;
  return true;
}

bool parse_args(int argc, char** argv, Options* opts) {
  for (int i = 1; i < argc; ++i) {
    const std::string_view arg(argv[i]);
    int* target = nullptr;
    if (arg == "--instance-id") target = &opts->instance_id;
    else if (arg == "--bank") target = &opts->bank;
    else if (arg == "--start-row") target = &opts->start_row;
    else if (arg == "--num-victims") target = &opts->num_victims;
    else if (arg == "--hammer-count") target = &opts->hammer_count;
    else {
      std::fprintf(stderr, "Unknown argument: %.*s\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }
    if (i + 1 >= argc) {
      std::fprintf(stderr, "Missing value for %.*s\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }
    if (!parse_int(argv[i + 1], target)) {
      std::fprintf(stderr, "Invalid value for %.*s\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }
    ++i;
  }
  if (opts->num_victims <= 0) {
    std::fprintf(stderr, "--num-victims must be greater than 0.\n");
    return false;
  }
  if (opts->hammer_count <= 0) {
    std::fprintf(stderr, "--hammer-count must be greater than 0.\n");
    return false;
  }
  return true;
}

// Build a program that: init victim, init aggressor, hammer aggressor, read victim.
FinalProgram build_single_sided_rowhammer_program(int bank,
                                                  int victim_row,
                                                  int aggressor_row,
                                                  uint32_t victim_pattern,
                                                  uint32_t aggressor_pattern,
                                                  int hammer_count) {
  Program p;

  p.add_inst(SMC_LI(bank, BAR));
  p.add_inst(SMC_LI(k_column_stride, CASR));
  p.add_inst(SMC_LI(hammer_count, NUM_HAMMER));
  p.add_inst(SMC_LI(0, HAMMER_CTR));

  // --- Initialize victim row ---
  p.add_inst(SMC_LI(victim_row, RAR));
  p.add_inst(SMC_LI(victim_pattern, PATTERN));
  for (int w = 0; w < k_words_per_cacheline; ++w) {
    p.add_inst(SMC_LDWD(PATTERN, w));
  }

  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(SMC_LI(0, CAR));
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  p.add_inst(SMC_ACT(BAR, 0, RAR, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  for (int i = 0; i < k_cachelines_per_row; ++i) {
    p.add_inst(SMC_WRITE(BAR, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    p.add_inst(all_nops());
  }
  p.add_inst(SMC_SLEEP(8));
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());

  // --- Initialize aggressor row ---
  p.add_inst(SMC_LI(aggressor_row, RAR));
  p.add_inst(SMC_LI(aggressor_pattern, PATTERN));
  for (int w = 0; w < k_words_per_cacheline; ++w) {
    p.add_inst(SMC_LDWD(PATTERN, w));
  }

  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(SMC_LI(0, CAR));
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  p.add_inst(SMC_ACT(BAR, 0, RAR, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  for (int i = 0; i < k_cachelines_per_row; ++i) {
    p.add_inst(SMC_WRITE(BAR, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    p.add_inst(all_nops());
  }
  p.add_inst(SMC_SLEEP(8));
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());

  // --- Hammer aggressor ---
  // Byte-for-byte equivalent of drambender.builtin_programs.single_sided_rowhammer.
  p.add_inst(SMC_LI(bank, BAR));
  p.add_inst(SMC_LI(aggressor_row, RAR));
  p.add_inst(SMC_LI(0, HAMMER_CTR));
  p.add_inst(SMC_LI(hammer_count, NUM_HAMMER));

  p.add_label("HMR_BEGIN");
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(SMC_ADDI(HAMMER_CTR, 1, HAMMER_CTR));
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_ACT(BAR, 0, RAR, 0));
  p.add_branch(Program::BR_TYPE::BL, HAMMER_CTR, NUM_HAMMER, "HMR_BEGIN");

  // --- Read victim row back ---
  p.add_inst(SMC_LI(victim_row, RAR));
  p.add_inst(SMC_LI(0, CAR));
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  p.add_inst(SMC_ACT(BAR, 0, RAR, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  for (int i = 0; i < k_cachelines_per_row; ++i) {
    p.add_inst(SMC_READ(BAR, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    p.add_inst(all_nops());
  }
  p.add_inst(SMC_SLEEP(4));
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());

  return p.conclude();
}

// MI1 row mapping — mirrors python/drambender/rows/mappings/mi1.py.
// parity = popcount(physical_id & 0x5408) & 1; logical = physical ^ (parity * 6).
int mi1_map(int physical_id) {
  const int parity =
      __builtin_popcount(static_cast<unsigned>(physical_id) & 0x5408u) & 1;
  return physical_id ^ (parity * 0x6);
}

size_t count_bitflips(std::span<const std::byte> row_buffer, uint32_t expected_pattern) {
  size_t flips = 0;
  const auto* words = reinterpret_cast<const uint32_t*>(row_buffer.data());
  const size_t num_words = row_buffer.size() / sizeof(uint32_t);
  for (size_t i = 0; i < num_words; ++i) {
    flips += static_cast<size_t>(__builtin_popcount(words[i] ^ expected_pattern));
  }
  return flips;
}

}  // namespace

int main(int argc, char** argv) {
  Options opts;
  if (!parse_args(argc, argv, &opts)) {
    print_usage(argv[0]);
    return 2;
  }

  try {
    auto board = create_board(BoardType::DDR4, opts.instance_id, HostInterface::XDMA);
    board->reset_fpga();

    std::printf("single_sided_rowhammer: instance=%d bank=%d start_row=%d "
                "num_victims=%d hammer_count=%d\n",
                opts.instance_id, opts.bank, opts.start_row,
                opts.num_victims, opts.hammer_count);

    std::vector<std::byte> row_buffer(k_row_bytes);
    size_t total_flips = 0;
    size_t vulnerable_rows = 0;

    using clock = std::chrono::steady_clock;
    using ns = std::chrono::nanoseconds;
    ns t_build{0}, t_execute{0}, t_receive{0}, t_sync{0}, t_count{0};
    const auto t_loop_start = clock::now();

    for (int v = 0; v < opts.num_victims; ++v) {
      const int victim_physical    = opts.start_row + v;
      const int aggressor_physical = victim_physical + 1;
      const int victim_logical     = mi1_map(victim_physical);
      const int aggressor_logical  = mi1_map(aggressor_physical);

      const auto t0 = clock::now();
      auto program = build_single_sided_rowhammer_program(
          opts.bank, victim_logical, aggressor_logical,
          k_victim_pattern, k_aggressor_pattern, opts.hammer_count);
      const auto t1 = clock::now();
      board->execute(program);
      const auto t2 = clock::now();
      board->receive(std::span(row_buffer));
      const auto t3 = clock::now();
      board->synchronize();
      const auto t4 = clock::now();
      const size_t flips = count_bitflips(row_buffer, k_victim_pattern);
      const auto t5 = clock::now();

      t_build   += std::chrono::duration_cast<ns>(t1 - t0);
      t_execute += std::chrono::duration_cast<ns>(t2 - t1);
      t_receive += std::chrono::duration_cast<ns>(t3 - t2);
      t_sync    += std::chrono::duration_cast<ns>(t4 - t3);
      t_count   += std::chrono::duration_cast<ns>(t5 - t4);

      total_flips += flips;
      if (flips > 0) {
        ++vulnerable_rows;
        std::printf("  row %5d -> %5d (aggressor %d -> %d): %zu bitflips\n",
                    victim_physical, victim_logical,
                    aggressor_physical, aggressor_logical, flips);
      }
    }

    const auto t_loop_end = clock::now();
    const auto t_total = std::chrono::duration_cast<ns>(t_loop_end - t_loop_start);

    std::printf("\nResult: %zu/%d rows vulnerable, %zu total bitflips\n",
                vulnerable_rows, opts.num_victims, total_flips);

    auto ms = [](ns v) { return static_cast<double>(v.count()) / 1.0e6; };
    auto pct = [&](ns v) { return 100.0 * static_cast<double>(v.count()) /
                                  static_cast<double>(t_total.count()); };
    const double n = static_cast<double>(opts.num_victims);
    std::printf("\nRuntime breakdown (%d victims):\n", opts.num_victims);
    std::printf("  %-12s %10.3f ms total %10.3f ms/iter %6.2f%%\n",
                "build",   ms(t_build),   ms(t_build)   / n, pct(t_build));
    std::printf("  %-12s %10.3f ms total %10.3f ms/iter %6.2f%%\n",
                "execute", ms(t_execute), ms(t_execute) / n, pct(t_execute));
    std::printf("  %-12s %10.3f ms total %10.3f ms/iter %6.2f%%\n",
                "receive", ms(t_receive), ms(t_receive) / n, pct(t_receive));
    std::printf("  %-12s %10.3f ms total %10.3f ms/iter %6.2f%%\n",
                "sync",    ms(t_sync),    ms(t_sync)    / n, pct(t_sync));
    std::printf("  %-12s %10.3f ms total %10.3f ms/iter %6.2f%%\n",
                "count",   ms(t_count),   ms(t_count)   / n, pct(t_count));
    std::printf("  %-12s %10.3f ms total %10.3f ms/iter\n",
                "TOTAL",   ms(t_total),   ms(t_total)   / n);

    return vulnerable_rows > 0 ? 1 : 0;
  } catch (const std::exception& e) {
    std::fprintf(stderr, "single_sided_rowhammer runtime failure: %s\n", e.what());
    return 2;
  }
}
