/**
 * Single-sided RowHammer test.
 *
 * For each victim row in [start_row, start_row + num_victims):
 *   1. Initialize victim row with DATA pattern
 *   2. Initialize aggressor row (victim + 1) with ~DATA pattern
 *   3. Hammer the aggressor row N times
 *   4. Read back the victim row
 *   5. Report bitflips
 */

#include <algorithm>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
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

// Default config
constexpr int k_default_bank = 0;
constexpr int k_default_start_row = 0;
constexpr int k_default_num_victims = 64;
constexpr int k_default_hammer_count = 150000;
constexpr uint32_t k_victim_data = 0x00000000;
constexpr uint32_t k_aggressor_data = 0xFFFFFFFF;

// Register IDs
constexpr int CASR = 0;
constexpr int BASR = 1;
constexpr int RASR = 2;
constexpr int CAR = 3;
constexpr int BAR = 4;
constexpr int RAR = 5;
constexpr int PATTERN = 6;
constexpr int NUM_HAMMER = 7;
constexpr int HAMMER_CTR = 8;

struct Options {
  int instance_id = 0;
  int bank = k_default_bank;
  int start_row = k_default_start_row;
  int num_victims = k_default_num_victims;
  int hammer_count = k_default_hammer_count;
};

bool parse_int(const char* text, int* value) {
  std::string_view input(text);
  int parsed = 0;
  auto result = std::from_chars(input.data(), input.data() + input.size(), parsed);
  if (result.ec != std::errc() || result.ptr != input.data() + input.size()) return false;
  *value = parsed;
  return true;
}

bool parse_args(int argc, char** argv, Options* opts) {
  for (int i = 1; i < argc; i += 2) {
    std::string_view arg(argv[i]);
    if (i + 1 >= argc) { std::fprintf(stderr, "Missing value for %.*s\n", (int)arg.size(), arg.data()); return false; }
    int* target = nullptr;
    if (arg == "--instance-id") target = &opts->instance_id;
    else if (arg == "--bank") target = &opts->bank;
    else if (arg == "--start-row") target = &opts->start_row;
    else if (arg == "--num-victims") target = &opts->num_victims;
    else if (arg == "--hammer-count") target = &opts->hammer_count;
    else { std::fprintf(stderr, "Unknown argument: %.*s\n", (int)arg.size(), arg.data()); return false; }
    if (!parse_int(argv[i + 1], target)) { std::fprintf(stderr, "Invalid value for %.*s\n", (int)arg.size(), arg.data()); return false; }
  }
  return true;
}

// Build a program that: init victim, init aggressor, hammer, read victim
FinalProgram build_rowhammer_program(int bank, int victim_row, int aggressor_row,
                                     uint32_t victim_pattern, uint32_t aggressor_pattern,
                                     int hammer_count) {
  Program p;

  p.add_inst(SMC_LI(bank, BAR));
  p.add_inst(SMC_LI(k_column_stride, CASR));
  p.add_inst(SMC_LI(hammer_count, NUM_HAMMER));
  p.add_inst(SMC_LI(0, HAMMER_CTR));

  // --- Initialize victim row ---
  p.add_inst(SMC_LI(victim_row, RAR));
  p.add_inst(SMC_LI(victim_pattern, PATTERN));
  for (int w = 0; w < k_words_per_cacheline; ++w)
    p.add_inst(SMC_LDWD(PATTERN, w));

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
  for (int w = 0; w < k_words_per_cacheline; ++w)
    p.add_inst(SMC_LDWD(PATTERN, w));

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
  // Loop body: PRE → (increment) → ACT → (branch back to PRE)
  // This ensures ACT is always followed by PRE on the next iteration.
  p.add_inst(SMC_LI(aggressor_row, RAR));
  p.add_inst(SMC_LI(0, HAMMER_CTR));

  // Prime: first ACT before entering the loop (tRAS satisfied by loop body)
  p.add_inst(SMC_ACT(BAR, 0, RAR, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  p.add_inst(all_nops());

  p.add_label("HAMMER");
  // PRE (row was activated above or at bottom of loop)
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(SMC_ADDI(HAMMER_CTR, 1, HAMMER_CTR));
  p.add_inst(all_nops());
  // ACT at end of word — next iteration starts with PRE
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_ACT(BAR, 0, RAR, 0));
  p.add_branch(Program::BR_TYPE::BL, HAMMER_CTR, NUM_HAMMER, "HAMMER");

  // Final PRE after loop exits (last ACT needs closing)
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());

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

size_t count_bitflips(std::span<const std::byte> row_buffer, uint32_t expected_pattern) {
  size_t flips = 0;
  const auto* words = reinterpret_cast<const uint32_t*>(row_buffer.data());
  size_t num_words = row_buffer.size() / sizeof(uint32_t);
  for (size_t i = 0; i < num_words; ++i) {
    uint32_t xored = words[i] ^ expected_pattern;
    flips += __builtin_popcount(xored);
  }
  return flips;
}

}  // namespace

int main(int argc, char** argv) {
  Options opts;
  if (!parse_args(argc, argv, &opts)) return 2;

  try {
    auto board = create_board(BoardType::DDR4, opts.instance_id, HostInterface::XDMA);
    board->reset_fpga();

    std::printf("rowhammer_test: bank=%d start_row=%d num_victims=%d hammer_count=%d\n",
                opts.bank, opts.start_row, opts.num_victims, opts.hammer_count);

    std::vector<std::byte> row_buffer(k_row_bytes);
    size_t total_flips = 0;
    size_t vulnerable_rows = 0;

    for (int v = 0; v < opts.num_victims; ++v) {
      int victim_row = opts.start_row + v;
      int aggressor_row = victim_row + 1;

      auto program = build_rowhammer_program(
          opts.bank, victim_row, aggressor_row,
          k_victim_data, k_aggressor_data, opts.hammer_count);
      board->execute(program);
      board->receive(std::span(row_buffer));
      board->synchronize();

      size_t flips = count_bitflips(row_buffer, k_victim_data);
      total_flips += flips;
      if (flips > 0) {
        ++vulnerable_rows;
        std::printf("  row %5d: %zu bitflips (aggressor=%d)\n",
                    victim_row, flips, aggressor_row);
      }

      if ((v + 1) % 10 == 0 || v + 1 == opts.num_victims) {
        std::printf("\r  [%d/%d victims tested, %zu vulnerable, %zu total bitflips]",
                    v + 1, opts.num_victims, vulnerable_rows, total_flips);
        std::fflush(stdout);
      }
    }

    std::printf("\n\nResult: %zu/%d rows vulnerable, %zu total bitflips\n",
                vulnerable_rows, opts.num_victims, total_flips);
    return vulnerable_rows > 0 ? 1 : 0;
  } catch (const std::exception& e) {
    std::fprintf(stderr, "Error: %s\n", e.what());
    return 2;
  }
}
