#include <charconv>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <exception>
#include <span>
#include <string>
#include <string_view>
#include <thread>
#include <vector>

#include "drambender/api/board/board.h"

using namespace DRAMBender;
using namespace std::chrono_literals;

namespace {

constexpr int k_cachelines_per_row = 128;
constexpr int k_words_per_cacheline = 16;
constexpr int k_column_stride = 8;

constexpr int CASR = 0;
constexpr int CAR = 3;
constexpr int BAR = 4;
constexpr int RAR = 5;
constexpr int PATTERN_REG = 6;

struct Options {
  std::string pci_bdf;
  int xdma_channel = 0;
  int bank = 0;
  int row = 32;
  uint32_t pattern = 0x13579bdfu;
};

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

bool parse_uint32_any_base(const char* text, uint32_t* value) {
  std::string_view input(text);
  if (input.empty()) {
    return false;
  }
  int base = 10;
  if (input.size() >= 2 && input[0] == '0' && (input[1] == 'x' || input[1] == 'X')) {
    base = 16;
    input.remove_prefix(2);
  }
  uint32_t parsed = 0;
  const auto result = std::from_chars(input.data(), input.data() + input.size(), parsed, base);
  if (result.ec != std::errc() || result.ptr != input.data() + input.size()) {
    return false;
  }
  *value = parsed;
  return true;
}

bool parse_args(int argc, char** argv, Options* opts) {
  for (int i = 1; i < argc; ++i) {
    const std::string_view arg(argv[i]);
    if (i + 1 >= argc) {
      return false;
    }

    bool ok = true;
    if (arg == "--pci-bdf") {
      opts->pci_bdf = argv[i + 1];
    } else if (arg == "--xdma-channel") {
      ok = parse_int(argv[i + 1], &opts->xdma_channel);
    } else if (arg == "--bank") {
      ok = parse_int(argv[i + 1], &opts->bank);
    } else if (arg == "--row") {
      ok = parse_int(argv[i + 1], &opts->row);
    } else if (arg == "--pattern") {
      ok = parse_uint32_any_base(argv[i + 1], &opts->pattern);
    } else {
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

  return !opts->pci_bdf.empty();
}

FinalProgram build_long_no_read_program() {
  Program p;
  p.add_inst(SMC_SLEEP(100000000));
  return p.conclude();
}

FinalProgram build_write_program(int bank, int row, uint32_t pattern) {
  Program p;
  p.add_inst(SMC_LI(bank, BAR));
  p.add_inst(SMC_LI(row, RAR));
  p.add_inst(SMC_LI(k_column_stride, CASR));

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

bool run_verified_read_write(IBoard& board, int bank, int row, uint32_t pattern) {
  const FinalProgram write_program = build_write_program(bank, row, pattern);
  const FinalProgram read_program = build_read_program(bank, row);

  const size_t total_words =
      static_cast<size_t>(k_cachelines_per_row) * k_words_per_cacheline;
  std::vector<uint32_t> readback(total_words);

  board.execute(write_program);
  board.execute(read_program);
  board.receive(std::span<std::byte>(
      reinterpret_cast<std::byte*>(readback.data()), readback.size() * sizeof(uint32_t)));
  board.synchronize();

  size_t mismatches = 0;
  for (uint32_t word : readback) {
    if (word != pattern) {
      ++mismatches;
    }
  }

  if (mismatches != 0) {
    std::fprintf(stderr, "read/write verification failed: %zu/%zu words mismatched\n",
                 mismatches, total_words);
    return false;
  }

  return true;
}

void print_usage(const char* argv0) {
  std::fprintf(stderr,
               "Usage: %s --pci-bdf dddd:bb:ss.f [--xdma-channel N] [--bank N] "
               "[--row N] [--pattern HEX_OR_DEC]\n",
               argv0);
}

}  // namespace

int main(int argc, char** argv) {
  Options opts;
  if (!parse_args(argc, argv, &opts)) {
    print_usage(argv[0]);
    return 2;
  }

  try {
    auto board = create_board(
        BoardType::U200, opts.pci_bdf, opts.xdma_channel, HostInterface::XDMA);
    board->full_reset();

    board->execute(build_long_no_read_program());
    std::this_thread::sleep_for(20ms);
    board->full_reset();
    std::printf("PASS: full_reset canceled active no-read receiver\n");

    board->execute(build_read_program(opts.bank, opts.row));
    std::this_thread::sleep_for(20ms);
    board->full_reset();
    std::printf("PASS: full_reset cleared stale readback\n");

    if (!run_verified_read_write(*board, opts.bank, opts.row + 1, opts.pattern)) {
      return 1;
    }
    std::printf("PASS: read/write works after full_reset (pattern=0x%08x)\n", opts.pattern);

    return 0;
  } catch (const std::exception& e) {
    std::fprintf(stderr, "runtime failure: %s\n", e.what());
    return 2;
  }
}
