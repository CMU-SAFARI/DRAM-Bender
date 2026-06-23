#include <algorithm>
#include <charconv>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <exception>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "drambender/api/board/HBM2.h"
#include "drambender/api/program/instruction.h"
#include "drambender/api/program/program.h"
#include "drambender/utils/vm.h"

using namespace DRAMBender;

namespace {

constexpr int k_num_columns = 32;
constexpr int k_words_per_cacheline = 16;
constexpr int k_bytes_per_hbm_column_pair = 64;
constexpr int k_bytes_per_pseudo_channel_chunk = 32;
constexpr uint32_t k_default_pattern = 0xdeadbeefu;
constexpr size_t k_max_reported_mismatches = 32;

constexpr int CASR = 0;
constexpr int BASR = 1;
constexpr int RASR = 2;
constexpr int CAR = 3;
constexpr int BAR = 4;
constexpr int RAR = 5;
constexpr int PATTERN_REG = 6;

struct Options {
  int board_id = 0;
  int instance_id = 0;
  int channel = 0;
  int pseudo_channel = 0;
  int sid = 1;
  int bank = 0;
  int row = 0;
  int row_count = 1;
  int iterations = 2;
  int progress_interval = 256;
  size_t receive_bytes = 2048;
  uint32_t pattern = k_default_pattern;
  bool static_only = false;
  bool skip_temperature = false;
};

void print_usage(const char* argv0) {
  std::fprintf(stderr,
               "Usage: %s [--board-id N] [--instance-id N] [--channel N] "
               "[--pseudo-channel N] [--sid N] [--bank N] [--row N] "
               "[--row-count N] [--pattern HEX_OR_DEC] [--receive-bytes N] "
               "[--iterations N] [--progress-interval N] [--static-only] "
               "[--skip-temperature]\n",
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

bool parse_size(const char* text, size_t* value) {
  const std::string_view input(text);
  if (input.empty()) {
    return false;
  }

  size_t parsed = 0;
  const auto result = std::from_chars(input.data(), input.data() + input.size(), parsed);
  if (result.ec != std::errc() || result.ptr != input.data() + input.size()) {
    return false;
  }

  *value = parsed;
  return true;
}

bool parse_u32(const char* text, uint32_t* value) {
  std::string_view input(text);
  if (input.empty()) {
    return false;
  }

  int base = 10;
  if (input.size() >= 2 && input[0] == '0' && (input[1] == 'x' || input[1] == 'X')) {
    base = 16;
    input.remove_prefix(2);
    if (input.empty()) {
      return false;
    }
  }

  uint64_t parsed = 0;
  const auto result = std::from_chars(input.data(), input.data() + input.size(), parsed, base);
  if (result.ec != std::errc() || result.ptr != input.data() + input.size() ||
      parsed > 0xffffffffull) {
    return false;
  }

  *value = static_cast<uint32_t>(parsed);
  return true;
}

bool parse_value_arg(int argc, char** argv, int* arg_index, std::string_view arg) {
  if (*arg_index + 1 >= argc) {
    std::fprintf(stderr, "Missing value for %.*s.\n", static_cast<int>(arg.size()), arg.data());
    return false;
  }
  ++(*arg_index);
  return true;
}

bool parse_args(int argc, char** argv, Options* options) {
  for (int arg_index = 1; arg_index < argc; ++arg_index) {
    const std::string_view arg(argv[arg_index]);

    if (arg == "--static-only") {
      options->static_only = true;
      continue;
    }
    if (arg == "--skip-temperature") {
      options->skip_temperature = true;
      continue;
    }

    if (!parse_value_arg(argc, argv, &arg_index, arg)) {
      return false;
    }

    bool ok = true;
    if (arg == "--board-id") {
      ok = parse_int(argv[arg_index], &options->board_id);
    } else if (arg == "--instance-id") {
      ok = parse_int(argv[arg_index], &options->instance_id);
    } else if (arg == "--channel") {
      ok = parse_int(argv[arg_index], &options->channel);
    } else if (arg == "--pseudo-channel") {
      ok = parse_int(argv[arg_index], &options->pseudo_channel);
    } else if (arg == "--sid") {
      ok = parse_int(argv[arg_index], &options->sid);
    } else if (arg == "--bank") {
      ok = parse_int(argv[arg_index], &options->bank);
    } else if (arg == "--row") {
      ok = parse_int(argv[arg_index], &options->row);
    } else if (arg == "--row-count") {
      ok = parse_int(argv[arg_index], &options->row_count);
    } else if (arg == "--pattern") {
      ok = parse_u32(argv[arg_index], &options->pattern);
    } else if (arg == "--receive-bytes") {
      ok = parse_size(argv[arg_index], &options->receive_bytes);
    } else if (arg == "--iterations") {
      ok = parse_int(argv[arg_index], &options->iterations);
    } else if (arg == "--progress-interval") {
      ok = parse_int(argv[arg_index], &options->progress_interval);
    } else {
      std::fprintf(stderr, "Unknown argument: %.*s\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }

    if (!ok) {
      std::fprintf(stderr, "Invalid value for %.*s.\n",
                   static_cast<int>(arg.size()), arg.data());
      return false;
    }
  }

  if (options->receive_bytes <
      static_cast<size_t>(k_num_columns) * k_bytes_per_hbm_column_pair) {
    std::fprintf(stderr, "receive-bytes must be at least %d for 32 HBM column reads.\n",
                 k_num_columns * k_bytes_per_hbm_column_pair);
    return false;
  }
  if (options->channel < 0 || options->channel > 15) {
    std::fprintf(stderr, "channel must be in range 0..15 for the latest U55 HBM2 image.\n");
    return false;
  }
  if (options->pseudo_channel != 0 && options->pseudo_channel != 1) {
    std::fprintf(stderr, "pseudo-channel must be 0 or 1 for HBM2.\n");
    return false;
  }
  if (options->sid != 0 && options->sid != 1) {
    std::fprintf(stderr, "sid must be 0 or 1 for the latest U55 SID bitstream.\n");
    return false;
  }
  if (options->bank < 0 || options->bank > 15) {
    std::fprintf(stderr, "bank must be in range 0..15; sid is encoded separately in BAR[4].\n");
    return false;
  }
  if (options->row < 0) {
    std::fprintf(stderr, "row must be non-negative.\n");
    return false;
  }
  if (options->row_count <= 0) {
    std::fprintf(stderr, "row-count must be greater than 0.\n");
    return false;
  }
  if (options->iterations <= 0) {
    std::fprintf(stderr, "iterations must be greater than 0.\n");
    return false;
  }
  if (options->progress_interval < 0) {
    std::fprintf(stderr, "progress-interval must be non-negative.\n");
    return false;
  }

  return true;
}

FinalProgram build_hbm2_rw_program(int channel,
                                   int pseudo_channel,
                                   int physical_bank,
                                   int row,
                                   uint32_t pattern) {
  Program program;
  program.add_inst(SMC_LI(static_cast<uint32_t>(physical_bank), BAR));
  program.add_inst(SMC_LI(static_cast<uint32_t>(row), RAR));
  program.add_inst(SMC_LI(1, CASR));
  program.add_inst(SMC_LI(1, BASR));
  program.add_inst(SMC_LI(1, RASR));

  program.add_inst(SMC_LI(pattern, PATTERN_REG));
  for (int index = 0; index < k_words_per_cacheline; ++index) {
    program.add_inst(SMC_LDWD(PATTERN_REG, index));
  }

  program.add_inst(SMC_SEL_CH(channel, pseudo_channel), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_SLEEP(10));

  program.add_inst(SMC_LI(0, CAR));
  program.add_inst(SMC_PRE(BAR, 0, 0, pseudo_channel), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_ACT(BAR, 0, RAR, 0, pseudo_channel), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());

  for (int column = 0; column < k_num_columns; ++column) {
    program.add_inst(SMC_WRITE(BAR, 0, CAR, 1, pseudo_channel, 0),
                     SMC_NOP(),
                     SMC_NOP(),
                     SMC_NOP());
    program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  }

  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_PRE(BAR, 0, 0, pseudo_channel), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());

  program.add_inst(SMC_LI(0, CAR));
  program.add_inst(SMC_ACT(BAR, 0, RAR, 0, pseudo_channel), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());

  for (int column = 0; column < k_num_columns; ++column) {
    program.add_inst(SMC_READ(BAR, 0, CAR, 1, pseudo_channel, 0),
                     SMC_NOP(),
                     SMC_NOP(),
                     SMC_NOP());
    program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  }

  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_PRE(BAR, 0, 0, pseudo_channel), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());

  return program.conclude();
}

bool verify_static_trace(const FinalProgram& program,
                         int channel,
                         int pseudo_channel,
                         int physical_bank,
                         bool quiet) {
  const auto trace = vm::trace_dram_commands(program, vm::k_default_max_instructions);

  int sel_count = 0;
  int wr_count = 0;
  int rd_count = 0;
  std::vector<int> wr_columns;
  std::vector<int> rd_columns;
  std::vector<std::string> errors;

  for (const auto& event : trace.events) {
    if (event.command == "SEL_CH") {
      ++sel_count;
      if (event.channel != channel || event.pseudo_channel != pseudo_channel) {
        errors.push_back("SEL_CH channel/pseudo-channel mismatch");
      }
    }

    if (event.command == "WR") {
      ++wr_count;
      wr_columns.push_back(event.column);
      if (event.rank != pseudo_channel) {
        errors.push_back("WR used the wrong pseudo-channel rank");
      }
    }
    if (event.command == "RD") {
      ++rd_count;
      rd_columns.push_back(event.column);
      if (event.rank != pseudo_channel) {
        errors.push_back("RD used the wrong pseudo-channel rank");
      }
    }

    if ((event.command == "PRE" || event.command == "ACT" ||
         event.command == "WR" || event.command == "RD") &&
        event.bank != physical_bank) {
      errors.push_back("row command used the wrong physical bank/BAR");
    }
  }

  if (sel_count != 1) {
    errors.push_back("expected exactly one SEL_CH event");
  }
  if (wr_count != k_num_columns) {
    errors.push_back("expected 32 WR events");
  }
  if (rd_count != k_num_columns) {
    errors.push_back("expected 32 RD events");
  }
  for (int column = 0; column < k_num_columns; ++column) {
    if (column >= static_cast<int>(wr_columns.size()) || wr_columns[column] != column) {
      errors.push_back("WR column sequence mismatch");
      break;
    }
  }
  for (int column = 0; column < k_num_columns; ++column) {
    if (column >= static_cast<int>(rd_columns.size()) || rd_columns[column] != column) {
      errors.push_back("RD column sequence mismatch");
      break;
    }
  }

  if (!errors.empty()) {
    for (const auto& error : errors) {
      std::fprintf(stderr, "static trace failure: %s\n", error.c_str());
    }
    return false;
  }

  if (!quiet) {
    std::printf("PASS: static trace SEL_CH channel=%d pch=%d, physical_bar=%d, "
                "%d WR, %d RD, CASR=1 inferred from columns\n",
                channel,
                pseudo_channel,
                physical_bank,
                wr_count,
                rd_count);
  }
  return true;
}

size_t verify_readback(std::span<const std::byte> readback,
                       int pseudo_channel,
                       uint32_t pattern,
                       int row,
                       size_t* reported_mismatches) {
  size_t mismatches = 0;
  const size_t pseudo_channel_offset =
      static_cast<size_t>(pseudo_channel) * k_bytes_per_pseudo_channel_chunk;

  for (int column = 0; column < k_num_columns; ++column) {
    const size_t column_base =
        static_cast<size_t>(column) * k_bytes_per_hbm_column_pair + pseudo_channel_offset;
    for (int byte = 0; byte < k_bytes_per_pseudo_channel_chunk; ++byte) {
      const uint8_t expected = static_cast<uint8_t>(pattern >> ((byte % 4) * 8));
      const uint8_t observed = std::to_integer<uint8_t>(
          readback[column_base + static_cast<size_t>(byte)]);
      if (observed == expected) {
        continue;
      }

      ++mismatches;
      if (*reported_mismatches < k_max_reported_mismatches) {
        std::fprintf(stderr,
                     "Mismatch %zu: row=%d column=%d byte=%d raw_offset=%zu "
                     "expected=0x%02x read=0x%02x\n",
                     *reported_mismatches + 1,
                     row,
                     column,
                     byte,
                     column_base + static_cast<size_t>(byte),
                     expected,
                     observed);
        ++(*reported_mismatches);
      }
    }
  }

  return mismatches;
}

size_t execute_and_verify(HBM2& board,
                          const FinalProgram& program,
                          int pseudo_channel,
                          uint32_t pattern,
                          int row,
                          size_t receive_bytes,
                          size_t* reported_mismatches) {
  std::vector<std::byte> readback(receive_bytes);
  board.execute(program);
  board.receive(std::span<std::byte>(readback.data(), readback.size()));
  board.synchronize();
  return verify_readback(readback, pseudo_channel, pattern, row, reported_mismatches);
}

}  // namespace

int main(int argc, char** argv) {
  Options options;
  if (!parse_args(argc, argv, &options)) {
    print_usage(argv[0]);
    return 2;
  }

  const int physical_bank = options.bank + 16 * options.sid;
  const FinalProgram first_program = build_hbm2_rw_program(
      options.channel, options.pseudo_channel, physical_bank, options.row, options.pattern);
  if (!verify_static_trace(first_program,
                           options.channel,
                           options.pseudo_channel,
                           physical_bank,
                           options.row_count > 1)) {
    return 2;
  }
  if (options.static_only) {
    return 0;
  }

  std::printf("hbm2_rw_test: board=%d instance=%d channel=%d pch=%d sid=%d "
              "bank=%d physical_bar=%d rows=%d..%d pattern=0x%08x receive_bytes=%zu\n",
              options.board_id,
              options.instance_id,
              options.channel,
              options.pseudo_channel,
              options.sid,
              options.bank,
              physical_bank,
              options.row,
              options.row + options.row_count - 1,
              static_cast<unsigned int>(options.pattern),
              options.receive_bytes);

  try {
    HBM2 board(options.board_id, options.instance_id);
    if (!options.skip_temperature) {
      try {
        const HBMTemperature temp = board.read_temperature();
        std::printf("HBM temperature: stack0=%dC stack1=%dC\n",
                    temp.stack0_celsius,
                    temp.stack1_celsius);
      } catch (const std::exception& exception) {
        std::fprintf(stderr, "WARN: HBM temperature read failed: %s\n", exception.what());
      }
    }

    size_t total_mismatches = 0;
    size_t reported_mismatches = 0;
    if (options.row_count == 1) {
      for (int iteration = 1; iteration <= options.iterations; ++iteration) {
        board.full_reset();
        board.discard_readback_data(false);
        total_mismatches += execute_and_verify(board,
                                               first_program,
                                               options.pseudo_channel,
                                               options.pattern,
                                               options.row,
                                               options.receive_bytes,
                                               &reported_mismatches);
        if (total_mismatches != 0) {
          break;
        }
        std::printf("PASS: iteration %d: %zu readback bytes verified\n",
                    iteration,
                    options.receive_bytes);
      }
    } else {
      board.full_reset();
      board.discard_readback_data(false);
      for (int row_offset = 0; row_offset < options.row_count; ++row_offset) {
        const int row = options.row + row_offset;
        const FinalProgram program = row_offset == 0
                                         ? first_program
                                         : build_hbm2_rw_program(options.channel,
                                                                 options.pseudo_channel,
                                                                 physical_bank,
                                                                 row,
                                                                 options.pattern);
        total_mismatches += execute_and_verify(board,
                                               program,
                                               options.pseudo_channel,
                                               options.pattern,
                                               row,
                                               options.receive_bytes,
                                               &reported_mismatches);
        if (total_mismatches != 0) {
          break;
        }

        const int rows_done = row_offset + 1;
        if (rows_done == options.row_count ||
            (options.progress_interval > 0 && rows_done % options.progress_interval == 0)) {
          std::printf("PASS: rows %d..%d: %d/%d rows verified\n",
                      options.row,
                      row,
                      rows_done,
                      options.row_count);
        }
      }
    }

    if (total_mismatches != 0) {
      std::fprintf(stderr,
                   "hbm2_rw_test failed: total_mismatches=%zu reported=%zu\n",
                   total_mismatches,
                   reported_mismatches);
      return 1;
    }

    return 0;
  } catch (const std::exception& exception) {
    std::fprintf(stderr, "hbm2_rw_test runtime failure: %s\n", exception.what());
    return 2;
  }
}
