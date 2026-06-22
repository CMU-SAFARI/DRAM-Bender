// Minimal read/write check.
//
// Writes a 32-bit pattern to every word of a single DRAM row, reads the row
// back, and verifies the readback matches. Useful as a first-run check after
// bringing up a new board or after touching the read/write pipeline.

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

constexpr int k_cachelines_per_row  = 128;
constexpr int k_words_per_cacheline = 16;
constexpr int k_column_stride       = 8;

// Register IDs used by the hand-authored program below.
constexpr int CASR        = 0;
constexpr int CAR         = 3;
constexpr int BAR         = 4;
constexpr int RAR         = 5;
constexpr int PATTERN_REG = 6;

struct Options {
  int instance_id = 0;
  int bank        = 0;
  int row         = 0;
  uint32_t pattern = 0xDEADBEEFu;
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

bool parse_uint32_any_base(const char* text, uint32_t* value) {
  std::string_view input(text);
  if (input.empty()) return false;
  int base = 10;
  if (input.size() >= 2 && input[0] == '0' && (input[1] == 'x' || input[1] == 'X')) {
    base = 16;
    input.remove_prefix(2);
  }
  uint32_t parsed = 0;
  const auto result = std::from_chars(input.data(), input.data() + input.size(), parsed, base);
  if (result.ec != std::errc() || result.ptr != input.data() + input.size()) return false;
  *value = parsed;
  return true;
}

bool parse_args(int argc, char** argv, Options* opts) {
  for (int i = 1; i < argc; ++i) {
    const std::string_view arg(argv[i]);
    if (i + 1 >= argc) return false;
    bool ok = true;
    if      (arg == "--instance-id") ok = parse_int(argv[i + 1], &opts->instance_id);
    else if (arg == "--bank")        ok = parse_int(argv[i + 1], &opts->bank);
    else if (arg == "--row")         ok = parse_int(argv[i + 1], &opts->row);
    else if (arg == "--pattern")     ok = parse_uint32_any_base(argv[i + 1], &opts->pattern);
    else {
      std::fprintf(stderr, "Unknown argument: %.*s\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }
    if (!ok) {
      std::fprintf(stderr, "Invalid value for %.*s\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }
    ++i;
  }
  return true;
}

FinalProgram build_write_program(int bank, int row, uint32_t pattern) {
  Program p;
  p.add_inst(SMC_LI(bank, BAR));
  p.add_inst(SMC_LI(row, RAR));
  p.add_inst(SMC_LI(k_column_stride, CASR));

  // Fill the 16-word wide register with the pattern.
  for (int word = 0; word < k_words_per_cacheline; ++word) {
    p.add_inst(SMC_LI(pattern, PATTERN_REG));
    p.add_inst(SMC_LDWD(PATTERN_REG, word));
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
  return p.conclude();
}

FinalProgram build_read_program(int bank, int row) {
  Program p;
  p.add_inst(SMC_LI(bank, BAR));
  p.add_inst(SMC_LI(row, RAR));
  p.add_inst(SMC_LI(k_column_stride, CASR));

  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(SMC_LI(0, CAR));
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
  p.add_inst(SMC_SLEEP(3));
  return p.conclude();
}

}  // namespace

int main(int argc, char** argv) {
  Options opts;
  if (!parse_args(argc, argv, &opts)) {
    std::fprintf(stderr,
                 "Usage: %s [--instance-id N] [--bank N] [--row N] "
                 "[--pattern HEX_OR_DEC]\n",
                 argv[0]);
    return 2;
  }

  try {
    auto board = create_board(BoardType::DDR4, opts.instance_id, HostInterface::XDMA);
    board->reset_fpga();

    const FinalProgram write_program = build_write_program(opts.bank, opts.row, opts.pattern);
    const FinalProgram read_program  = build_read_program(opts.bank, opts.row);

    const size_t total_words =
        static_cast<size_t>(k_cachelines_per_row) * k_words_per_cacheline;
    std::vector<uint32_t> readback(total_words);

    board->execute(write_program);
    board->execute(read_program);
    board->receive(std::span<std::byte>(
        reinterpret_cast<std::byte*>(readback.data()),
        readback.size() * sizeof(uint32_t)));
    board->synchronize();

    size_t mismatches = 0;
    for (size_t i = 0; i < total_words; ++i) {
      if (readback[i] != opts.pattern) ++mismatches;
    }

    if (mismatches == 0) {
      std::printf("PASS: %zu words matched (pattern=0x%08x)\n",
                  total_words, opts.pattern);
      return 0;
    }
    std::printf("FAIL: %zu/%zu words mismatched\n", mismatches, total_words);
    return 1;
  } catch (const std::exception& e) {
    std::fprintf(stderr, "runtime failure: %s\n", e.what());
    return 2;
  }
}
