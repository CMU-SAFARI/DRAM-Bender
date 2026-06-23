// Single-sided RowHammer — minimal reference.
//
// For each victim row in [start_row, start_row + num_victims):
//   1. Write the victim row with 0x00000000.
//   2. Write the aggressor row (victim + 1) with 0xFFFFFFFF.
//   3. Hammer the aggressor hammer_count times.
//   4. Read the victim back and count any bit flips.
//
// The physical -> logical mapping is MI1 (parity XOR of bit 0x5408 -> XOR 0x6);
// see python/drambender/rows/mappings/mi1.py for the Python counterpart.

#include <charconv>
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

constexpr int k_bytes_per_cacheline  = 64;
constexpr int k_cachelines_per_row   = 128;
constexpr int k_words_per_cacheline  = 16;
constexpr int k_row_bytes            = k_bytes_per_cacheline * k_cachelines_per_row;
constexpr int k_column_stride        = 8;

constexpr uint32_t k_victim_pattern    = 0x00000000;
constexpr uint32_t k_aggressor_pattern = 0xFFFFFFFF;

// Register IDs used by the hand-authored program below.
constexpr int CASR       = 0;
constexpr int CAR        = 3;
constexpr int BAR        = 4;
constexpr int RAR        = 5;
constexpr int PATTERN    = 6;
constexpr int NUM_HAMMER = 7;
constexpr int HAMMER_CTR = 8;

struct Options {
  int board_id     = 0;
  int instance_id  = 0;
  int bank         = 0;
  int start_row    = 81;
  int num_victims  = 30;
  int hammer_count = 500000;
};

bool parse_int(const char* text, int* value) {
  const std::string_view input(text);
  if (input.empty()) return false;
  int parsed = 0;
  const auto result = std::from_chars(input.data(), input.data() + input.size(), parsed);
  if (result.ec != std::errc() || result.ptr != input.data() + input.size()) return false;
  *value = parsed;
  return true;
}

bool parse_args(int argc, char** argv, Options* opts) {
  for (int i = 1; i < argc; ++i) {
    const std::string_view arg(argv[i]);
    int* target = nullptr;
    if      (arg == "--board-id")     target = &opts->board_id;
    else if (arg == "--instance-id")  target = &opts->instance_id;
    else if (arg == "--bank")         target = &opts->bank;
    else if (arg == "--start-row")    target = &opts->start_row;
    else if (arg == "--num-victims")  target = &opts->num_victims;
    else if (arg == "--hammer-count") target = &opts->hammer_count;
    else {
      std::fprintf(stderr, "Unknown argument: %.*s\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }
    if (i + 1 >= argc || !parse_int(argv[i + 1], target)) {
      std::fprintf(stderr, "Invalid value for %.*s\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }
    ++i;
  }
  return true;
}

// MI1 row mapping — parity(physical_id & 0x5408) ? physical ^ 0x6 : physical.
int mi1_map(int physical_id) {
  const int parity =
      __builtin_popcount(static_cast<unsigned>(physical_id) & 0x5408u) & 1;
  return physical_id ^ (parity * 0x6);
}

// Build a single monolithic program that initialises the two rows, hammers
// the aggressor, and reads the victim back.
FinalProgram build_program(int bank,
                           int victim_row,
                           int aggressor_row,
                           int hammer_count) {
  Program p;

  p.add_inst(SMC_LI(bank, BAR));
  p.add_inst(SMC_LI(k_column_stride, CASR));

  auto init_row = [&](int row_addr, uint32_t word_pattern) {
    p.add_inst(SMC_LI(row_addr, RAR));
    p.add_inst(SMC_LI(word_pattern, PATTERN));
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
    for (int cl = 0; cl < k_cachelines_per_row; ++cl) {
      p.add_inst(SMC_WRITE(BAR, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
      p.add_inst(all_nops());
    }
    p.add_inst(SMC_SLEEP(8));
    p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    p.add_inst(all_nops());
    p.add_inst(all_nops());
  };

  init_row(victim_row,    k_victim_pattern);
  init_row(aggressor_row, k_aggressor_pattern);

  // Hammer loop — byte-for-byte equivalent of
  // drambender.builtin_programs.single_sided_rowhammer.
  p.add_inst(SMC_LI(aggressor_row, RAR));
  p.add_inst(SMC_LI(0, HAMMER_CTR));
  p.add_inst(SMC_LI(hammer_count, NUM_HAMMER));
  p.add_label("HMR_BEGIN");
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(SMC_ADDI(HAMMER_CTR, 1, HAMMER_CTR));
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_ACT(BAR, 0, RAR, 0));
  p.add_branch(Program::BR_TYPE::BL, HAMMER_CTR, NUM_HAMMER, "HMR_BEGIN");

  // Read the victim row back.
  p.add_inst(SMC_LI(victim_row, RAR));
  p.add_inst(SMC_LI(0, CAR));
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  p.add_inst(SMC_ACT(BAR, 0, RAR, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());
  for (int cl = 0; cl < k_cachelines_per_row; ++cl) {
    p.add_inst(SMC_READ(BAR, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    p.add_inst(all_nops());
  }
  p.add_inst(SMC_SLEEP(4));
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());

  return p.conclude();
}

size_t count_bitflips(std::span<const std::byte> row_buffer, uint32_t expected) {
  size_t flips = 0;
  const auto* words = reinterpret_cast<const uint32_t*>(row_buffer.data());
  const size_t num_words = row_buffer.size() / sizeof(uint32_t);
  for (size_t i = 0; i < num_words; ++i) {
    flips += static_cast<size_t>(__builtin_popcount(words[i] ^ expected));
  }
  return flips;
}

}  // namespace

int main(int argc, char** argv) {
  Options opts;
  if (!parse_args(argc, argv, &opts)) {
    std::fprintf(stderr,
                 "Usage: %s [--board-id N] [--instance-id N] [--bank N] [--start-row N] "
                 "[--num-victims N] [--hammer-count N]\n",
                 argv[0]);
    return 2;
  }

  try {
    auto board = create_board(BoardType::DDR4, opts.board_id, opts.instance_id, HostInterface::XDMA);
    board->reset_fpga();

    std::vector<std::byte> row_buffer(k_row_bytes);
    size_t total_flips = 0;
    size_t vulnerable_rows = 0;

    for (int v = 0; v < opts.num_victims; ++v) {
      const int victim_physical    = opts.start_row + v;
      const int aggressor_physical = victim_physical + 1;
      const int victim_logical     = mi1_map(victim_physical);
      const int aggressor_logical  = mi1_map(aggressor_physical);

      board->execute(build_program(
          opts.bank, victim_logical, aggressor_logical, opts.hammer_count));
      board->receive(std::span(row_buffer));
      board->synchronize();

      const size_t flips = count_bitflips(row_buffer, k_victim_pattern);
      total_flips += flips;
      if (flips > 0) {
        ++vulnerable_rows;
        std::printf("  row %5d -> %5d (aggressor %d -> %d): %zu bitflips\n",
                    victim_physical, victim_logical,
                    aggressor_physical, aggressor_logical, flips);
      }
    }

    std::printf("\nResult: %zu/%d rows vulnerable, %zu total bitflips\n",
                vulnerable_rows, opts.num_victims, total_flips);
    return vulnerable_rows > 0 ? 1 : 0;
  } catch (const std::exception& e) {
    std::fprintf(stderr, "runtime failure: %s\n", e.what());
    return 2;
  }
}
