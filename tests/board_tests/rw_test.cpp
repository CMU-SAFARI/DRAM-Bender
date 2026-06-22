#include <algorithm>
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

// Default test configuration
constexpr int k_default_instance_id = 0;
constexpr int k_default_bank = 0;
constexpr int k_default_num_rows = 65536;
constexpr int k_default_num_cls = 128;
constexpr int k_bytes_per_cacheline = 64;
constexpr int k_wide_register_words = 16;
constexpr int k_column_stride = 8;
constexpr uint32_t k_test_data = 0xdeadbeefu;
constexpr size_t k_max_reported_mismatches = 32;
constexpr int k_progress_bar_width = 40;

// Named register IDs
constexpr int k_casr_reg = 0;
constexpr int k_bar_reg = 7;
constexpr int k_rar_reg = 6;
constexpr int k_car_reg = 4;
constexpr int k_num_rows_reg = 8;
constexpr int k_num_cols_reg = 14;
constexpr int k_loop_cols_reg = 13;
constexpr int k_pattern_reg = 12;
constexpr int k_temp_pattern_reg = 15;

enum ExitCode {
  kSuccess = 0,
  kMismatch = 1,
  kUsageOrRuntimeFailure = 2,
};

struct Options {
  int instance_id = k_default_instance_id;
  int bank = k_default_bank;
  int num_rows = k_default_num_rows;
  int num_cls = k_default_num_cls;
};

void print_usage(const char* argv0) {
  std::fprintf(stderr,
               "Usage: %s [--instance-id N] [--bank N] [--num-rows N] [--num-cls N]\n",
               argv0);
}

bool parse_non_negative_int(const char* text, int* value) {
  const std::string_view input(text);
  if (input.empty()) {
    return false;
  }

  int parsed = 0;
  const auto result = std::from_chars(input.data(), input.data() + input.size(), parsed);
  if (result.ec != std::errc() || result.ptr != input.data() + input.size() || parsed < 0) {
    return false;
  }

  *value = parsed;
  return true;
}

bool parse_args(int argc, char** argv, Options* options) {
  for (int arg_index = 1; arg_index < argc; ++arg_index) {
    const std::string_view arg(argv[arg_index]);
    if (arg == "--instance-id") {
      if (arg_index + 1 >= argc ||
          !parse_non_negative_int(argv[arg_index + 1], &options->instance_id)) {
        std::fprintf(stderr, "Invalid value for --instance-id.\n");
        return false;
      }
      ++arg_index;
      continue;
    }

    if (arg == "--bank") {
      if (arg_index + 1 >= argc || !parse_non_negative_int(argv[arg_index + 1], &options->bank)) {
        std::fprintf(stderr, "Invalid value for --bank.\n");
        return false;
      }
      ++arg_index;
      continue;
    }

    if (arg == "--num-rows") {
      if (arg_index + 1 >= argc ||
          !parse_non_negative_int(argv[arg_index + 1], &options->num_rows)) {
        std::fprintf(stderr, "Invalid value for --num-rows.\n");
        return false;
      }
      ++arg_index;
      continue;
    }

    if (arg == "--num-cls") {
      if (arg_index + 1 >= argc || !parse_non_negative_int(argv[arg_index + 1], &options->num_cls)) {
        std::fprintf(stderr, "Invalid value for --num-cls.\n");
        return false;
      }
      ++arg_index;
      continue;
    }

    std::fprintf(stderr, "Unknown argument: %.*s\n", static_cast<int>(arg.size()), arg.data());
    return false;
  }

  if (options->num_rows <= 0) {
    std::fprintf(stderr, "num_rows must be greater than 0.\n");
    return false;
  }

  if (options->num_cls <= 0) {
    std::fprintf(stderr, "num_cls must be greater than 0.\n");
    return false;
  }

  return true;
}

uint32_t rotate_pattern_right(uint32_t pattern) {
  return (pattern >> 1U) | (pattern << 31U);
}

void print_progress(size_t completed_rows, size_t total_rows) {
  const size_t filled_width =
      (completed_rows * static_cast<size_t>(k_progress_bar_width)) / total_rows;
  const double percent = (100.0 * static_cast<double>(completed_rows)) / static_cast<double>(total_rows);

  std::printf("\r[");
  for (int index = 0; index < k_progress_bar_width; ++index) {
    std::printf("%c", static_cast<size_t>(index) < filled_width ? '=' : ' ');
  }
  std::printf("] %6.2f%% (%zu/%zu rows)", percent, completed_rows, total_rows);
  std::fflush(stdout);
}

FinalProgram build_rw_program(int bank, int num_rows, int num_cls) {
  Program program;

  program.add_inst(SMC_LI(num_rows, k_num_rows_reg));
  program.add_inst(SMC_LI(bank, k_bar_reg));
  program.add_inst(SMC_LI(k_column_stride, k_casr_reg));
  program.add_inst(SMC_LI(num_cls, k_num_cols_reg));
  program.add_inst(SMC_LI(k_test_data, k_pattern_reg));

  for (int word = 0; word < k_wide_register_words; ++word) {
    program.add_inst(SMC_LDWD(k_pattern_reg, word));
  }

  program.add_inst(SMC_LI(0, k_rar_reg));
  program.add_label("ROW_BEGIN");
  program.add_inst(SMC_LI(0, k_car_reg));

  // Each row is written in full, then read back in full before advancing to the next row.
  program.add_inst(SMC_PRE(k_bar_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(all_nops());
  program.add_inst(all_nops());

  program.add_inst(SMC_ACT(k_bar_reg, 0, k_rar_reg, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(all_nops());
  program.add_inst(all_nops());

  program.add_inst(SMC_LI(0, k_loop_cols_reg));
  program.add_label("WRITE_BEGIN");
  program.add_inst(SMC_WRITE(k_bar_reg, 0, k_car_reg, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_SRC(k_pattern_reg, k_pattern_reg));
  for (int word = 0; word < k_wide_register_words; ++word) {
    program.add_inst(SMC_LDWD(k_pattern_reg, word));
  }
  program.add_inst(SMC_ADDI(k_loop_cols_reg, 1, k_loop_cols_reg));
  program.add_branch(Program::BR_TYPE::BL, k_loop_cols_reg, k_num_cols_reg, "WRITE_BEGIN");

  program.add_inst(SMC_MV(k_pattern_reg, k_temp_pattern_reg));
  program.add_inst(SMC_ADD(k_pattern_reg, k_temp_pattern_reg, k_pattern_reg));
  program.add_inst(SMC_ADD(k_pattern_reg, k_temp_pattern_reg, k_pattern_reg));
  for (int word = 0; word < k_wide_register_words; ++word) {
    program.add_inst(SMC_LDWD(k_pattern_reg, word));
  }

  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(SMC_PRE(k_bar_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());

  program.add_inst(SMC_LI(0, k_car_reg));
  program.add_inst(SMC_PRE(k_bar_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(all_nops());
  program.add_inst(all_nops());

  program.add_inst(SMC_ACT(k_bar_reg, 0, k_rar_reg, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(all_nops());
  program.add_inst(all_nops());

  program.add_inst(SMC_LI(0, k_loop_cols_reg));
  program.add_label("READ_BEGIN");
  program.add_inst(SMC_READ(k_bar_reg, 0, k_car_reg, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(all_nops());
  program.add_inst(SMC_ADDI(k_loop_cols_reg, 1, k_loop_cols_reg));
  program.add_branch(Program::BR_TYPE::BL, k_loop_cols_reg, k_num_cols_reg, "READ_BEGIN");

  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(SMC_PRE(k_bar_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());

  program.add_inst(SMC_ADDI(k_rar_reg, 1, k_rar_reg));
  program.add_branch(Program::BR_TYPE::BL, k_rar_reg, k_num_rows_reg, "ROW_BEGIN");

  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(all_nops());
  program.add_inst(all_nops());
  return program.conclude();
}

void report_mismatch(size_t mismatch_index,
                     size_t* reported_mismatches,
                     int bank,
                     int row,
                     int cacheline,
                     int byte_index,
                     uint8_t expected,
                     uint8_t observed) {
  if (*reported_mismatches >= k_max_reported_mismatches) {
    return;
  }

  std::fprintf(stderr,
               "Mismatch %zu: bank=%d row=%d cacheline=%d byte=%d expected=0x%02x read=0x%02x\n",
               mismatch_index,
               bank,
               row,
               cacheline,
               byte_index,
               expected,
               observed);
  ++(*reported_mismatches);
}

size_t verify_row(std::span<const std::byte> row_buffer,
                  int bank,
                  int row,
                  int num_cls,
                  uint32_t row_pattern,
                  size_t initial_mismatch_count,
                  size_t* reported_mismatches) {
  size_t mismatch_count = 0;
  uint32_t pattern = row_pattern;

  for (int cacheline = 0; cacheline < num_cls; ++cacheline) {
    const size_t cacheline_offset = static_cast<size_t>(cacheline) * k_bytes_per_cacheline;
    for (int byte_index = 0; byte_index < k_bytes_per_cacheline; ++byte_index) {
      const uint8_t expected = static_cast<uint8_t>(pattern >> ((byte_index % 4) * 8));
      const uint8_t observed = std::to_integer<uint8_t>(
          row_buffer[cacheline_offset + static_cast<size_t>(byte_index)]);
      if (expected != observed) {
        ++mismatch_count;
        report_mismatch(initial_mismatch_count + mismatch_count,
                        reported_mismatches,
                        bank,
                        row,
                        cacheline,
                        byte_index,
                        expected,
                        observed);
      }
    }
    pattern = rotate_pattern_right(pattern);
  }

  return mismatch_count;
}

}  // namespace

int main(int argc, char** argv) {
  Options options;
  if (!parse_args(argc, argv, &options)) {
    print_usage(argv[0]);
    return kUsageOrRuntimeFailure;
  }

  try {
    auto board = create_board(BoardType::DDR4, options.instance_id, HostInterface::XDMA);
    board->reset_fpga();

    const FinalProgram program = build_rw_program(options.bank, options.num_rows, options.num_cls);
    board->execute(program);

    std::vector<std::byte> row_buffer(static_cast<size_t>(options.num_cls) * k_bytes_per_cacheline);
    size_t total_mismatches = 0;
    size_t reported_mismatches = 0;
    uint32_t row_pattern = k_test_data;
    const int progress_interval = std::max(1, options.num_rows / 200);

    std::printf("rw_test config: instance=%d bank=%d rows=%d cls=%d bytes-per-row=%zu\n",
                options.instance_id,
                options.bank,
                options.num_rows,
                options.num_cls,
                row_buffer.size());
    print_progress(0, static_cast<size_t>(options.num_rows));
    for (int row = 0; row < options.num_rows; ++row) {
      board->receive(std::span(row_buffer));
      total_mismatches += verify_row(
          row_buffer, options.bank, row, options.num_cls, row_pattern, total_mismatches,
          &reported_mismatches);
      row_pattern *= 3U;

      const int completed_rows = row + 1;
      if (completed_rows == options.num_rows || completed_rows % progress_interval == 0) {
        print_progress(static_cast<size_t>(completed_rows), static_cast<size_t>(options.num_rows));
      }
    }

    board->synchronize();
    std::printf("\n");

    if (total_mismatches == 0) {
      std::printf("rw_test passed: instance=%d bank=%d rows=%d cls=%d bytes=%llu\n",
                  options.instance_id,
                  options.bank,
                  options.num_rows,
                  options.num_cls,
                  static_cast<unsigned long long>(static_cast<uint64_t>(options.num_rows) *
                                                 static_cast<uint64_t>(options.num_cls) *
                                                 k_bytes_per_cacheline));
      return kSuccess;
    }

    if (total_mismatches > reported_mismatches) {
      std::fprintf(stderr,
                   "Suppressed %zu additional mismatches after the first %zu reports.\n",
                   total_mismatches - reported_mismatches,
                   reported_mismatches);
    }
    std::fprintf(stderr,
                 "rw_test failed: instance=%d bank=%d rows=%d cls=%d total_mismatches=%zu bytes=%llu\n",
                 options.instance_id,
                 options.bank,
                 options.num_rows,
                 options.num_cls,
                 total_mismatches,
                 static_cast<unsigned long long>(static_cast<uint64_t>(options.num_rows) *
                                                static_cast<uint64_t>(options.num_cls) *
                                                k_bytes_per_cacheline));
    return kMismatch;
  } catch (const std::exception& exception) {
    std::fprintf(stderr, "rw_test runtime failure: %s\n", exception.what());
    return kUsageOrRuntimeFailure;
  }
}
