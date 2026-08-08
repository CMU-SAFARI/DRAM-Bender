/**
 * Minimal read/write check using ad hoc DRAM Bender programs.
 *
 * Writes `pattern` to every word of a single row, reads it back, and
 * verifies the readback matches.
 *
 * C++ equivalent of examples/read_write.py.
 */

#include <charconv>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <exception>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "drambender/api/board/board.h"

using namespace DRAMBender;

namespace {

constexpr int k_cachelines_per_row = 128;
constexpr int k_words_per_cacheline = 16;
constexpr int k_column_stride = 8;

constexpr int k_default_bank = 0;
constexpr int k_default_row = 0;
constexpr uint32_t k_default_pattern = 0xDEADBEEFu;

// Register IDs
constexpr int CASR = 0;
constexpr int CAR = 3;
constexpr int BAR = 4;
constexpr int RAR = 5;
constexpr int PATTERN_REG = 6;

struct Options {
  std::string pci_bdf;
  int xdma_channel = 0;
  int bank = k_default_bank;
  int row = k_default_row;
  uint32_t pattern = k_default_pattern;
};

void print_usage(const char* argv0) {
  std::fprintf(stderr,
               "Usage: %s --pci-bdf dddd:bb:ss.f [--xdma-channel N] [--bank N] [--row N] [--pattern HEX_OR_DEC]\n",
               argv0);
}

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
    if (i + 1 >= argc) {
      std::fprintf(stderr, "Missing value for %.*s\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }
    bool ok = true;
    if (arg == "--pci-bdf") opts->pci_bdf = argv[i + 1];
    else if (arg == "--xdma-channel") ok = parse_int(argv[i + 1], &opts->xdma_channel);
    else if (arg == "--bank") ok = parse_int(argv[i + 1], &opts->bank);
    else if (arg == "--row") ok = parse_int(argv[i + 1], &opts->row);
    else if (arg == "--pattern") ok = parse_uint32_any_base(argv[i + 1], &opts->pattern);
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
  return !opts->pci_bdf.empty();
}

FinalProgram build_write_program(int bank, int row, uint32_t pattern) {
  Program p;

  p.add_inst(SMC_LI(bank, BAR));
  p.add_inst(SMC_LI(row, RAR));
  p.add_inst(SMC_LI(k_column_stride, CASR));

  // Load the full 16-word wide register with the pattern word.
  for (int index = 0; index < k_words_per_cacheline; ++index) {
    p.add_inst(SMC_LI(pattern, PATTERN_REG));
    p.add_inst(SMC_LDWD(PATTERN_REG, index));
  }

  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(SMC_LI(0, CAR));
  p.add_inst(all_nops());
  p.add_inst(all_nops());

  // ACT with delay=12 slots (the ACT itself plus two full-NOP cycles).
  p.add_inst(SMC_ACT(BAR, 0, RAR, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  p.add_inst(all_nops());
  p.add_inst(all_nops());

  // 128 WR commands, each with delay=8 slots (WR + one all_nops cycle).
  for (int i = 0; i < k_cachelines_per_row; ++i) {
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

  for (int i = 0; i < k_cachelines_per_row; ++i) {
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
    print_usage(argv[0]);
    return 2;
  }

  try {
    auto board = create_board(
        BoardType::DDR4, opts.pci_bdf, opts.xdma_channel, HostInterface::XDMA);
    board->reset_fpga();

    std::printf("read_write: pci_bdf=%s xdma_channel=%d bank=%d row=%d pattern=0x%08x\n",
                opts.pci_bdf.c_str(), opts.xdma_channel, opts.bank, opts.row, opts.pattern);

    const size_t total_words =
        static_cast<size_t>(k_cachelines_per_row) * k_words_per_cacheline;
    std::vector<uint32_t> readback(total_words);

    using clock = std::chrono::steady_clock;
    using ns = std::chrono::nanoseconds;

    const auto t_start = clock::now();
    const FinalProgram write_program = build_write_program(opts.bank, opts.row, opts.pattern);
    const auto t_build_w = clock::now();
    const FinalProgram read_program = build_read_program(opts.bank, opts.row);
    const auto t_build_r = clock::now();
    board->execute(write_program);
    const auto t_exec_w = clock::now();
    board->execute(read_program);
    const auto t_exec_r = clock::now();
    board->receive(std::span<std::byte>(
        reinterpret_cast<std::byte*>(readback.data()),
        readback.size() * sizeof(uint32_t)));
    const auto t_recv = clock::now();
    board->synchronize();
    const auto t_sync = clock::now();
    size_t mismatches = 0;
    for (size_t i = 0; i < total_words; ++i) {
      if (readback[i] != opts.pattern) ++mismatches;
    }
    const auto t_verify = clock::now();

    if (mismatches == 0) {
      std::printf("PASS: %zu words matched\n", total_words);
    } else {
      std::printf("FAIL: %zu/%zu words mismatched\n", mismatches, total_words);
    }

    auto us = [](auto a, auto b) {
      return static_cast<double>(std::chrono::duration_cast<ns>(b - a).count()) / 1.0e3;
    };
    const double t_total_us = us(t_start, t_verify);
    auto pct = [&](double phase_us) { return 100.0 * phase_us / t_total_us; };

    std::printf("\nRuntime breakdown:\n");
    std::printf("  %-16s %9.3f us %6.2f%%\n", "build_write",  us(t_start,  t_build_w), pct(us(t_start,  t_build_w)));
    std::printf("  %-16s %9.3f us %6.2f%%\n", "build_read",   us(t_build_w, t_build_r), pct(us(t_build_w, t_build_r)));
    std::printf("  %-16s %9.3f us %6.2f%%\n", "execute_write",us(t_build_r, t_exec_w), pct(us(t_build_r, t_exec_w)));
    std::printf("  %-16s %9.3f us %6.2f%%\n", "execute_read", us(t_exec_w,  t_exec_r), pct(us(t_exec_w,  t_exec_r)));
    std::printf("  %-16s %9.3f us %6.2f%%\n", "receive",      us(t_exec_r,  t_recv),   pct(us(t_exec_r,  t_recv)));
    std::printf("  %-16s %9.3f us %6.2f%%\n", "synchronize",  us(t_recv,    t_sync),   pct(us(t_recv,    t_sync)));
    std::printf("  %-16s %9.3f us %6.2f%%\n", "verify",       us(t_sync,    t_verify), pct(us(t_sync,    t_verify)));
    std::printf("  %-16s %9.3f us\n",         "TOTAL",        t_total_us);

    return mismatches == 0 ? 0 : 1;
  } catch (const std::exception& e) {
    std::fprintf(stderr, "read_write runtime failure: %s\n", e.what());
    return 2;
  }
}
