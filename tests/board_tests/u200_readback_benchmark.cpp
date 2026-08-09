// Reproducible U200 host/readback performance benchmark for the native C++ API.
//
// This is the direct-C++ counterpart of u200_readback_benchmark.py.  The two
// harnesses deliberately generate the same fabric instruction streams and the
// same deterministic row/lane data.  The timed region begins immediately
// before execute() and ends after synchronize(); setup and verification are
// outside it.  Use --dry-run-only to VM-validate every program without opening
// an FPGA.

#include <algorithm>
#include <array>
#include <charconv>
#include <chrono>
#include <cctype>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <memory>
#include <optional>
#include <random>
#include <span>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>
#include <system_error>
#include <utility>
#include <vector>

#include <sys/utsname.h>
#include <sched.h>
#include <unistd.h>

#include "drambender/api/board/board.h"
#include "drambender/utils/vm.h"

using namespace DRAMBender;

namespace {

constexpr std::string_view k_schema = "drambender.u200-readback-benchmark.v1";
constexpr size_t k_bytes_per_cacheline = 64;
constexpr size_t k_words_per_cacheline = 16;
constexpr size_t k_cachelines_per_row = 128;
constexpr uint32_t k_column_stride = 8;
constexpr int k_max_bank = 15;
constexpr int k_max_row = 65535;
constexpr uint32_t k_default_seed = UINT32_C(0x55423230);
constexpr size_t k_vm_max_instructions = 2'000'000;

// Register IDs are intentionally identical to ProgramBuilder's allocation.
constexpr int CASR = 0;
constexpr int CAR = 3;
constexpr int BAR = 4;
constexpr int RAR = 5;
constexpr int PATTERN_REG = 6;
constexpr int LOOP_LIMIT = 7;
constexpr int COLUMN_COUNTER = 8;

struct WorkloadSpec {
  std::string_view name;
  size_t cachelines;
};

constexpr std::array<WorkloadSpec, 5> k_workload_specs{{
    {"completion", 0},
    {"64B", 1},
    {"8KiB", 128},
    {"64KiB", 1024},
    {"512KiB", 8192},
}};

struct Options {
  std::string pci_bdf;
  int xdma_channel = 0;
  int bank = 0;
  int start_row = 4096;
  uint32_t seed = k_default_seed;
  int warmups = 5;
  int iterations = 100;
  std::vector<std::string> workloads{
      "completion", "64B", "8KiB", "64KiB", "512KiB"};
  std::string stack_label;
  std::string driver_label;
  std::string bitstream_label;
  std::optional<std::filesystem::path> bitstream_file;
  std::optional<std::filesystem::path> output;
  std::optional<std::filesystem::path> program_manifest;
  bool dry_run_only = false;
  std::vector<std::string> argv;
};

// Small self-contained SHA-256 implementation.  Keeping this in the harness
// avoids adding a benchmark-only crypto dependency and makes payload/program
// hashes directly comparable with the Python harness.
class Sha256 {
 public:
  void update(const void* data, size_t size) {
    const auto* bytes = static_cast<const uint8_t*>(data);
    total_bytes_ += size;
    while (size != 0) {
      const size_t take = std::min(size, block_.size() - block_size_);
      std::memcpy(block_.data() + block_size_, bytes, take);
      block_size_ += take;
      bytes += take;
      size -= take;
      if (block_size_ == block_.size()) {
        transform(block_.data());
        block_size_ = 0;
      }
    }
  }

  std::array<uint8_t, 32> finish() {
    const uint64_t message_bits = static_cast<uint64_t>(total_bytes_) * 8;
    const uint8_t marker = 0x80;
    update(&marker, 1);
    const uint8_t zero = 0;
    while (block_size_ != 56) {
      update(&zero, 1);
    }
    std::array<uint8_t, 8> length{};
    for (size_t i = 0; i < length.size(); ++i) {
      length[length.size() - 1 - i] =
          static_cast<uint8_t>(message_bits >> (i * 8));
    }
    update(length.data(), length.size());

    std::array<uint8_t, 32> digest{};
    for (size_t word = 0; word < state_.size(); ++word) {
      for (size_t byte = 0; byte < 4; ++byte) {
        digest[word * 4 + byte] =
            static_cast<uint8_t>(state_[word] >> (24 - byte * 8));
      }
    }
    return digest;
  }

 private:
  static constexpr std::array<uint32_t, 64> k_round_constants{{
      0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u,
      0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u,
      0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u,
      0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u,
      0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu,
      0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
      0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
      0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u,
      0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u,
      0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,
      0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u,
      0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u,
      0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
      0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
      0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u,
      0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u,
  }};

  static uint32_t rotr(uint32_t value, int count) {
    return (value >> count) | (value << (32 - count));
  }

  void transform(const uint8_t* block) {
    std::array<uint32_t, 64> words{};
    for (size_t i = 0; i < 16; ++i) {
      words[i] = (static_cast<uint32_t>(block[i * 4]) << 24) |
                 (static_cast<uint32_t>(block[i * 4 + 1]) << 16) |
                 (static_cast<uint32_t>(block[i * 4 + 2]) << 8) |
                 static_cast<uint32_t>(block[i * 4 + 3]);
    }
    for (size_t i = 16; i < words.size(); ++i) {
      const uint32_t s0 =
          rotr(words[i - 15], 7) ^ rotr(words[i - 15], 18) ^
          (words[i - 15] >> 3);
      const uint32_t s1 =
          rotr(words[i - 2], 17) ^ rotr(words[i - 2], 19) ^
          (words[i - 2] >> 10);
      words[i] = words[i - 16] + s0 + words[i - 7] + s1;
    }

    uint32_t a = state_[0];
    uint32_t b = state_[1];
    uint32_t c = state_[2];
    uint32_t d = state_[3];
    uint32_t e = state_[4];
    uint32_t f = state_[5];
    uint32_t g = state_[6];
    uint32_t h = state_[7];
    for (size_t i = 0; i < words.size(); ++i) {
      const uint32_t big_s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
      const uint32_t choose = (e & f) ^ (~e & g);
      const uint32_t temp1 =
          h + big_s1 + choose + k_round_constants[i] + words[i];
      const uint32_t big_s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
      const uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
      const uint32_t temp2 = big_s0 + majority;
      h = g;
      g = f;
      f = e;
      e = d + temp1;
      d = c;
      c = b;
      b = a;
      a = temp1 + temp2;
    }
    state_[0] += a;
    state_[1] += b;
    state_[2] += c;
    state_[3] += d;
    state_[4] += e;
    state_[5] += f;
    state_[6] += g;
    state_[7] += h;
  }

  std::array<uint32_t, 8> state_{{
      0x6a09e667u, 0xbb67ae85u, 0x3c6ef372u, 0xa54ff53au,
      0x510e527fu, 0x9b05688cu, 0x1f83d9abu, 0x5be0cd19u,
  }};
  std::array<uint8_t, 64> block_{};
  size_t block_size_ = 0;
  size_t total_bytes_ = 0;
};

std::string hex_digest(const std::array<uint8_t, 32>& digest) {
  std::ostringstream output;
  output << std::hex << std::setfill('0');
  for (const uint8_t byte : digest) {
    output << std::setw(2) << static_cast<unsigned>(byte);
  }
  return output.str();
}

std::string sha256_bytes(const void* data, size_t size) {
  Sha256 hash;
  hash.update(data, size);
  return hex_digest(hash.finish());
}

std::string sha256_file(const std::filesystem::path& path) {
  std::ifstream input(path, std::ios::binary);
  if (!input) {
    throw std::runtime_error("cannot open file for SHA-256: " + path.string());
  }
  Sha256 hash;
  std::array<char, 1024 * 1024> buffer{};
  while (input) {
    input.read(buffer.data(), static_cast<std::streamsize>(buffer.size()));
    const auto count = input.gcount();
    if (count > 0) {
      hash.update(buffer.data(), static_cast<size_t>(count));
    }
  }
  if (!input.eof()) {
    throw std::runtime_error("failed while hashing file: " + path.string());
  }
  return hex_digest(hash.finish());
}

std::string sha256_program(const FinalProgram& program) {
  const auto instructions = program.instructions();
  return sha256_bytes(instructions.data(), instructions.size_bytes());
}

std::string trim(std::string value) {
  const auto not_space = [](unsigned char c) { return !std::isspace(c); };
  const auto begin = std::find_if(value.begin(), value.end(), not_space);
  const auto end = std::find_if(value.rbegin(), value.rend(), not_space).base();
  if (begin >= end) return {};
  return std::string(begin, end);
}

std::optional<std::string> read_text(const std::filesystem::path& path) {
  std::ifstream input(path);
  if (!input) return std::nullopt;
  std::ostringstream output;
  output << input.rdbuf();
  if (!input.good() && !input.eof()) return std::nullopt;
  return trim(output.str());
}

std::string json_quote(std::string_view value) {
  std::ostringstream output;
  output << '"';
  for (const unsigned char c : value) {
    switch (c) {
      case '"': output << "\\\""; break;
      case '\\': output << "\\\\"; break;
      case '\b': output << "\\b"; break;
      case '\f': output << "\\f"; break;
      case '\n': output << "\\n"; break;
      case '\r': output << "\\r"; break;
      case '\t': output << "\\t"; break;
      default:
        if (c < 0x20) {
          output << "\\u00" << std::hex << std::setfill('0') << std::setw(2)
                 << static_cast<unsigned>(c) << std::dec;
        } else {
          output << static_cast<char>(c);
        }
    }
  }
  output << '"';
  return output.str();
}

std::string json_double(double value) {
  if (!std::isfinite(value)) return "null";
  std::ostringstream output;
  output << std::setprecision(17) << value;
  return output.str();
}

std::string json_string_array(const std::vector<std::string>& values) {
  std::ostringstream output;
  output << '[';
  for (size_t i = 0; i < values.size(); ++i) {
    if (i != 0) output << ',';
    output << json_quote(values[i]);
  }
  output << ']';
  return output.str();
}

std::string utc_now() {
  const std::time_t now = std::time(nullptr);
  std::tm utc{};
  gmtime_r(&now, &utc);
  std::array<char, 32> text{};
  std::strftime(text.data(), text.size(), "%Y-%m-%dT%H:%M:%SZ", &utc);
  return text.data();
}

std::string utc_stamp() {
  const std::time_t now = std::time(nullptr);
  std::tm utc{};
  gmtime_r(&now, &utc);
  std::array<char, 32> text{};
  std::strftime(text.data(), text.size(), "%Y%m%dT%H%M%SZ", &utc);
  return text.data();
}

std::string make_run_id() {
  std::array<uint8_t, 16> bytes{};
  std::random_device random;
  for (uint8_t& byte : bytes) byte = static_cast<uint8_t>(random());
  bytes[6] = static_cast<uint8_t>((bytes[6] & 0x0f) | 0x40);
  bytes[8] = static_cast<uint8_t>((bytes[8] & 0x3f) | 0x80);
  std::ostringstream output;
  output << std::hex << std::setfill('0');
  for (size_t i = 0; i < bytes.size(); ++i) {
    if (i == 4 || i == 6 || i == 8 || i == 10) output << '-';
    output << std::setw(2) << static_cast<unsigned>(bytes[i]);
  }
  return output.str();
}

class JsonlWriter {
 public:
  JsonlWriter(const std::filesystem::path& path, std::string run_id)
      : run_id_(std::move(run_id)) {
    if (std::filesystem::exists(path)) {
      throw std::runtime_error("refusing to overwrite existing output: " + path.string());
    }
    stream_.open(path, std::ios::out | std::ios::binary);
    if (!stream_) {
      throw std::runtime_error("cannot create output: " + path.string());
    }
  }

  void write(std::string_view record_type, std::string_view fields = {}) {
    stream_ << "{\"schema\":" << json_quote(k_schema)
            << ",\"record_type\":" << json_quote(record_type)
            << ",\"run_id\":" << json_quote(run_id_)
            << ",\"timestamp_utc\":" << json_quote(utc_now());
    if (!fields.empty()) stream_ << ',' << fields;
    stream_ << "}\n";
    stream_.flush();
    if (!stream_) throw std::runtime_error("failed writing JSONL output");
  }

  void close() {
    stream_.close();
    if (!stream_) throw std::runtime_error("failed closing JSONL output");
  }

 private:
  std::ofstream stream_;
  std::string run_id_;
};

std::optional<size_t> cachelines_for(std::string_view name) {
  for (const auto& spec : k_workload_specs) {
    if (spec.name == name) return spec.cachelines;
  }
  return std::nullopt;
}

bool parse_int(std::string_view text, int* value) {
  if (text.empty()) return false;
  int parsed = 0;
  const auto result =
      std::from_chars(text.data(), text.data() + text.size(), parsed, 10);
  if (result.ec != std::errc() || result.ptr != text.data() + text.size()) return false;
  *value = parsed;
  return true;
}

bool parse_uint32(std::string_view text, uint32_t* value) {
  if (text.empty()) return false;
  int base = 10;
  if (text.size() >= 2 && text[0] == '0' && (text[1] == 'x' || text[1] == 'X')) {
    text.remove_prefix(2);
    base = 16;
  }
  if (text.empty()) return false;
  uint32_t parsed = 0;
  const auto result =
      std::from_chars(text.data(), text.data() + text.size(), parsed, base);
  if (result.ec != std::errc() || result.ptr != text.data() + text.size()) return false;
  *value = parsed;
  return true;
}

bool normalize_bdf(std::string value, std::string* normalized) {
  if (value.size() != 12 || value[4] != ':' || value[7] != ':' || value[10] != '.') {
    return false;
  }
  for (const size_t index :
       std::array<size_t, 9>{0, 1, 2, 3, 5, 6, 8, 9, 11}) {
    if (!std::isxdigit(static_cast<unsigned char>(value[index]))) return false;
  }
  unsigned slot = 0;
  unsigned function = 0;
  const auto slot_result = std::from_chars(value.data() + 8, value.data() + 10, slot, 16);
  const auto function_result =
      std::from_chars(value.data() + 11, value.data() + 12, function, 16);
  if (slot_result.ec != std::errc() || function_result.ec != std::errc() ||
      slot > 0x1f || function > 7) {
    return false;
  }
  std::transform(value.begin(), value.end(), value.begin(), [](unsigned char c) {
    return static_cast<char>(std::tolower(c));
  });
  *normalized = std::move(value);
  return true;
}

bool parse_workloads(std::string_view text, std::vector<std::string>* workloads) {
  workloads->clear();
  size_t start = 0;
  while (start <= text.size()) {
    const size_t comma = text.find(',', start);
    const size_t end = comma == std::string_view::npos ? text.size() : comma;
    const std::string name = trim(std::string(text.substr(start, end - start)));
    if (!name.empty()) {
      if (!cachelines_for(name).has_value() ||
          std::find(workloads->begin(), workloads->end(), name) != workloads->end()) {
        return false;
      }
      workloads->push_back(name);
    }
    if (comma == std::string_view::npos) break;
    start = comma + 1;
  }
  return !workloads->empty();
}

void print_usage(const char* argv0) {
  std::fprintf(
      stderr,
      "Usage: %s --pci-bdf dddd:bb:ss.f --stack-label TEXT --driver-label TEXT "
      "--bitstream-label TEXT [--xdma-channel 0] [--bank N] [--start-row N] "
      "[--seed HEX_OR_DEC] [--warmups N] [--iterations N] "
      "[--workloads completion,64B,8KiB,64KiB,512KiB] "
      "[--bitstream-file PATH] [--output PATH] [--program-manifest PATH] "
      "[--dry-run-only]\n",
      argv0);
}

bool parse_args(int argc, char** argv, Options* options) {
  options->argv.assign(argv, argv + argc);
  for (int i = 1; i < argc; ++i) {
    const std::string_view argument(argv[i]);
    if (argument == "--help" || argument == "-h") {
      print_usage(argv[0]);
      std::exit(0);
    }
    if (argument == "--dry-run-only") {
      options->dry_run_only = true;
      continue;
    }
    if (i + 1 >= argc) {
      std::fprintf(stderr, "Missing value for %.*s\n", static_cast<int>(argument.size()),
                   argument.data());
      return false;
    }
    const std::string value(argv[++i]);
    bool ok = true;
    if (argument == "--pci-bdf") {
      ok = normalize_bdf(value, &options->pci_bdf);
    } else if (argument == "--xdma-channel") {
      ok = parse_int(value, &options->xdma_channel);
    } else if (argument == "--bank") {
      ok = parse_int(value, &options->bank);
    } else if (argument == "--start-row") {
      ok = parse_int(value, &options->start_row);
    } else if (argument == "--seed") {
      ok = parse_uint32(value, &options->seed);
    } else if (argument == "--warmups") {
      ok = parse_int(value, &options->warmups);
    } else if (argument == "--iterations") {
      ok = parse_int(value, &options->iterations);
    } else if (argument == "--workloads") {
      ok = parse_workloads(value, &options->workloads);
    } else if (argument == "--stack-label") {
      options->stack_label = value;
    } else if (argument == "--driver-label") {
      options->driver_label = value;
    } else if (argument == "--bitstream-label") {
      options->bitstream_label = value;
    } else if (argument == "--bitstream-file") {
      options->bitstream_file = value;
    } else if (argument == "--output") {
      options->output = value;
    } else if (argument == "--program-manifest") {
      options->program_manifest = value;
    } else {
      std::fprintf(stderr, "Unknown argument: %.*s\n", static_cast<int>(argument.size()),
                   argument.data());
      return false;
    }
    if (!ok) {
      std::fprintf(stderr, "Invalid value for %.*s: %s\n",
                   static_cast<int>(argument.size()), argument.data(), value.c_str());
      return false;
    }
  }

  if (options->pci_bdf.empty() || options->stack_label.empty() ||
      options->driver_label.empty() || options->bitstream_label.empty()) {
    std::fprintf(stderr, "--pci-bdf and all three provenance labels are required\n");
    return false;
  }
  if (options->xdma_channel != 0) {
    std::fprintf(stderr, "This U200 benchmark is restricted to XDMA channel 0\n");
    return false;
  }
  if (options->bank < 0 || options->bank > k_max_bank || options->warmups < 0 ||
      options->iterations < 1) {
    std::fprintf(stderr, "bank, warmups, or iterations is out of range\n");
    return false;
  }
  size_t max_rows = 0;
  for (const std::string& name : options->workloads) {
    const size_t cachelines = *cachelines_for(name);
    max_rows = std::max(max_rows,
                        (cachelines + k_cachelines_per_row - 1) / k_cachelines_per_row);
  }
  if (options->start_row < 0 || options->start_row > k_max_row ||
      (max_rows != 0 &&
       static_cast<size_t>(options->start_row) + max_rows - 1 > k_max_row)) {
    std::fprintf(stderr, "--start-row does not leave room for the selected workloads\n");
    return false;
  }
  if (options->bitstream_file.has_value() &&
      !std::filesystem::is_regular_file(*options->bitstream_file)) {
    std::fprintf(stderr, "--bitstream-file is not a readable regular file\n");
    return false;
  }
  return true;
}

std::array<uint32_t, k_words_per_cacheline> lane_pattern(uint32_t seed,
                                                         int bank,
                                                         int row) {
  uint32_t state = seed ^ (static_cast<uint32_t>(bank) << 27) ^
                   static_cast<uint32_t>(row) ^ UINT32_C(0x9e3779b9);
  if (state == 0) state = UINT32_C(0xa341316c);
  std::array<uint32_t, k_words_per_cacheline> words{};
  for (size_t lane = 0; lane < words.size(); ++lane) {
    state ^= state << 13;
    state ^= state >> 17;
    state ^= state << 5;
    words[lane] = state ^
                  (static_cast<uint32_t>(lane + 1) * UINT32_C(0x045d9f3b));
  }
  return words;
}

void sleep_cycles(Program& program, uint32_t cycles) {
  if (cycles < 1) throw std::invalid_argument("sleep cycles must be positive");
  if (cycles <= 2) {
    for (uint32_t i = 0; i < cycles; ++i) program.add_inst(all_nops());
  } else {
    program.add_inst(SMC_SLEEP(cycles));
  }
}

void stage_wide_pattern(
    Program& program,
    const std::array<uint32_t, k_words_per_cacheline>& words) {
  for (size_t lane = 0; lane < words.size(); ++lane) {
    program.add_inst(SMC_LI(words[lane], PATTERN_REG));
    program.add_inst(SMC_LDWD(PATTERN_REG, static_cast<int>(lane)));
  }
}

void begin_row(Program& program) {
  program.add_inst(SMC_PRE(BAR, 0, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_LI(0, CAR));
  sleep_cycles(program, 2);
  program.add_inst(SMC_ACT(BAR, 0, RAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  sleep_cycles(program, 2);
}

void end_row(Program& program, bool write) {
  sleep_cycles(program, write ? 8 : 4);
  program.add_inst(SMC_PRE(BAR, 0, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  sleep_cycles(program, 3);
}

FinalProgram build_completion_program() {
  Program program;
  sleep_cycles(program, 1);
  return program.conclude();
}

FinalProgram build_write_row_program(
    int bank,
    int row,
    size_t cachelines,
    const std::array<uint32_t, k_words_per_cacheline>& words) {
  Program program;
  stage_wide_pattern(program, words);
  program.add_inst(SMC_LI(static_cast<uint32_t>(bank), BAR));
  program.add_inst(SMC_LI(static_cast<uint32_t>(row), RAR));
  program.add_inst(SMC_LI(k_column_stride, CASR));
  program.add_inst(SMC_LI(static_cast<uint32_t>(cachelines), LOOP_LIMIT));
  program.add_inst(SMC_LI(0, COLUMN_COUNTER));
  begin_row(program);
  program.add_label("WRITE_CACHELINE");
  program.add_inst(SMC_WRITE(BAR, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  sleep_cycles(program, 1);
  program.add_inst(SMC_ADDI(COLUMN_COUNTER, 1, COLUMN_COUNTER));
  program.add_branch(Program::BR_TYPE::BL, COLUMN_COUNTER, LOOP_LIMIT,
                     "WRITE_CACHELINE");
  end_row(program, true);
  return program.conclude();
}

FinalProgram build_read_rows_program(int bank, int start_row, size_t cachelines) {
  const size_t rows =
      (cachelines + k_cachelines_per_row - 1) / k_cachelines_per_row;
  const size_t final_row_cachelines =
      cachelines - (rows - 1) * k_cachelines_per_row;
  if (rows > 1 && final_row_cachelines != k_cachelines_per_row) {
    throw std::invalid_argument("multirow workloads must contain whole rows");
  }

  Program program;
  program.add_inst(SMC_LI(static_cast<uint32_t>(bank), BAR));
  program.add_inst(SMC_LI(static_cast<uint32_t>(start_row), RAR));
  program.add_inst(SMC_LI(static_cast<uint32_t>(start_row + rows), LOOP_LIMIT));
  program.add_inst(SMC_LI(k_column_stride, CASR));
  program.add_label("READ_ROW");
  begin_row(program);
  for (size_t cacheline = 0; cacheline < final_row_cachelines; ++cacheline) {
    program.add_inst(SMC_READ(BAR, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    sleep_cycles(program, 1);
  }
  end_row(program, false);
  program.add_inst(SMC_ADDI(RAR, 1, RAR));
  program.add_branch(Program::BR_TYPE::BL, RAR, LOOP_LIMIT, "READ_ROW");
  return program.conclude();
}

uint64_t dram_command_count(const vm::ExecutionResult& result,
                            std::string_view name) {
  for (size_t index = 0; index < vm::k_dram_command_names.size(); ++index) {
    if (vm::k_dram_command_names[index] == name) {
      return result.dram_cmd_counts[index];
    }
  }
  throw std::logic_error("unknown VM command name");
}

struct ProgramValidation {
  size_t static_instructions = 0;
  uint64_t dynamic_instructions = 0;
  uint64_t cycles = 0;
  uint64_t reads = 0;
  uint64_t writes = 0;
  std::string instruction_sha256;
};

ProgramValidation validate_program(const FinalProgram& program,
                                   uint64_t expected_reads) {
  const vm::ExecutionResult result = vm::execute(program, k_vm_max_instructions);
  const uint64_t observed_reads = dram_command_count(result, "RD");
  if (observed_reads != expected_reads) {
    throw std::runtime_error("offline RD validation failed: expected " +
                             std::to_string(expected_reads) + ", got " +
                             std::to_string(observed_reads));
  }
  return ProgramValidation{
      .static_instructions = program.instruction_count(),
      .dynamic_instructions = result.instructions_executed,
      .cycles = result.total_cycles,
      .reads = observed_reads,
      .writes = dram_command_count(result, "WR"),
      .instruction_sha256 = sha256_program(program),
  };
}

struct Workload {
  std::string name;
  size_t payload_bytes;
  size_t cachelines;
  size_t rows;
  FinalProgram program;
  ProgramValidation validation;
  std::vector<FinalProgram> setup_programs;
  std::vector<ProgramValidation> setup_validations;
  std::vector<uint32_t> expected;
  std::optional<std::string> expected_sha256;
};

Workload build_workload(std::string name, int bank, int start_row, uint32_t seed) {
  const size_t cachelines = *cachelines_for(name);
  if (cachelines == 0) {
    FinalProgram program = build_completion_program();
    ProgramValidation validation = validate_program(program, 0);
    return Workload{
        .name = std::move(name),
        .payload_bytes = 0,
        .cachelines = 0,
        .rows = 0,
        .program = std::move(program),
        .validation = std::move(validation),
        .setup_programs = {},
        .setup_validations = {},
        .expected = {},
        .expected_sha256 = std::nullopt,
    };
  }

  const size_t rows =
      (cachelines + k_cachelines_per_row - 1) / k_cachelines_per_row;
  std::vector<FinalProgram> setup_programs;
  std::vector<ProgramValidation> setup_validations;
  std::vector<uint32_t> expected;
  expected.reserve(cachelines * k_words_per_cacheline);
  size_t remaining = cachelines;
  for (size_t row_offset = 0; row_offset < rows; ++row_offset) {
    const int row = start_row + static_cast<int>(row_offset);
    const size_t row_cachelines = std::min(k_cachelines_per_row, remaining);
    const auto words = lane_pattern(seed, bank, row);
    FinalProgram write_program =
        build_write_row_program(bank, row, row_cachelines, words);
    const ProgramValidation write_validation = validate_program(write_program, 0);
    if (write_validation.writes != row_cachelines) {
      throw std::runtime_error("offline WR validation failed");
    }
    setup_validations.push_back(write_validation);
    setup_programs.push_back(std::move(write_program));
    for (size_t cacheline = 0; cacheline < row_cachelines; ++cacheline) {
      expected.insert(expected.end(), words.begin(), words.end());
    }
    remaining -= row_cachelines;
  }

  FinalProgram read_program =
      build_read_rows_program(bank, start_row, cachelines);
  ProgramValidation validation = validate_program(read_program, cachelines);
  const size_t payload_bytes = expected.size() * sizeof(uint32_t);
  if (payload_bytes != cachelines * k_bytes_per_cacheline) {
    throw std::logic_error("internal expected-payload sizing error");
  }
  const std::string expected_hash =
      sha256_bytes(expected.data(), expected.size() * sizeof(uint32_t));
  return Workload{
      .name = std::move(name),
      .payload_bytes = payload_bytes,
      .cachelines = cachelines,
      .rows = rows,
      .program = std::move(read_program),
      .validation = std::move(validation),
      .setup_programs = std::move(setup_programs),
      .setup_validations = std::move(setup_validations),
      .expected = std::move(expected),
      .expected_sha256 = expected_hash,
  };
}

std::string validation_json(const ProgramValidation& validation) {
  std::ostringstream output;
  output << "{\"static_instructions\":" << validation.static_instructions
         << ",\"dynamic_instructions\":" << validation.dynamic_instructions
         << ",\"cycles\":" << validation.cycles
         << ",\"reads\":" << validation.reads
         << ",\"writes\":" << validation.writes
         << ",\"instruction_sha256\":"
         << json_quote(validation.instruction_sha256) << '}';
  return output.str();
}

void print_program_table(const std::vector<Workload>& workloads) {
  std::printf("workload    bytes       rows  static-inst  dynamic-inst  VM RD  instruction-sha256\n");
  for (const Workload& workload : workloads) {
    std::printf("%-11s %8zu %6zu %12zu %13llu %6llu  %s\n",
                workload.name.c_str(), workload.payload_bytes, workload.rows,
                workload.validation.static_instructions,
                static_cast<unsigned long long>(workload.validation.dynamic_instructions),
                static_cast<unsigned long long>(workload.validation.reads),
                workload.validation.instruction_sha256.c_str());
  }
}

std::string instruction_hex_json(const FinalProgram& program) {
  std::ostringstream output;
  output << '[' << std::hex << std::setfill('0');
  const auto instructions = program.instructions();
  for (size_t index = 0; index < instructions.size(); ++index) {
    if (index != 0) output << ',';
    output << '"' << "0x" << std::setw(16) << instructions[index] << '"';
  }
  output << ']';
  return output.str();
}

void write_program_manifest(const std::filesystem::path& path,
                            const Options& options,
                            const std::vector<Workload>& workloads) {
  if (!path.parent_path().empty()) {
    std::filesystem::create_directories(path.parent_path());
  }
  if (std::filesystem::exists(path)) {
    throw std::runtime_error("refusing to overwrite existing manifest: " +
                             path.string());
  }
  std::ofstream output(path, std::ios::out | std::ios::binary);
  if (!output) {
    throw std::runtime_error("cannot create program manifest: " + path.string());
  }
  auto write_program = [&](const Workload& workload,
                           std::string_view role,
                           std::optional<size_t> setup_index,
                           const FinalProgram& program,
                           const ProgramValidation& validation) {
    output << "{\"schema\":\"drambender.u200-program-manifest.v1\""
           << ",\"adapter\":\"new_repo_native_cpp\""
           << ",\"stack_label\":" << json_quote(options.stack_label)
           << ",\"workload\":" << json_quote(workload.name)
           << ",\"role\":" << json_quote(role)
           << ",\"setup_index\":";
    if (setup_index) output << *setup_index;
    else output << "null";
    output << ",\"instruction_count\":" << program.instruction_count()
           << ",\"instruction_sha256\":"
           << json_quote(validation.instruction_sha256)
           << ",\"instructions_hex\":" << instruction_hex_json(program)
           << "}\n";
  };

  for (const Workload& workload : workloads) {
    write_program(workload, "read", std::nullopt, workload.program,
                  workload.validation);
    if (workload.setup_programs.size() != workload.setup_validations.size()) {
      throw std::logic_error("setup program/validation count mismatch");
    }
    for (size_t index = 0; index < workload.setup_programs.size(); ++index) {
      write_program(workload, "setup_write", index,
                    workload.setup_programs[index],
                    workload.setup_validations[index]);
    }
  }
  output.close();
  if (!output) {
    throw std::runtime_error("failed closing program manifest: " + path.string());
  }
}

struct Sample {
  uint64_t execute_ns = 0;
  uint64_t receive_ns = 0;
  uint64_t synchronize_ns = 0;
  uint64_t elapsed_ns = 0;
  size_t mismatched_words = 0;
  std::optional<size_t> first_mismatch_word;
  std::optional<uint32_t> first_expected;
  std::optional<uint32_t> first_observed;
  std::optional<std::string> sha256;
};

uint64_t elapsed_ns(std::chrono::steady_clock::time_point begin,
                    std::chrono::steady_clock::time_point end) {
  return static_cast<uint64_t>(
      std::chrono::duration_cast<std::chrono::nanoseconds>(end - begin).count());
}

Sample run_iteration(IBoard& board, const Workload& workload) {
  std::vector<uint32_t> observed;
  if (!workload.expected.empty()) {
    observed.assign(workload.expected.size(), UINT32_C(0x0d15ea5e));
  }

  const auto started = std::chrono::steady_clock::now();
  board.execute(workload.program);
  const auto after_execute = std::chrono::steady_clock::now();
  auto after_receive = after_execute;
  if (!observed.empty()) {
    const size_t received = board.receive(std::span<std::byte>(
        reinterpret_cast<std::byte*>(observed.data()),
        observed.size() * sizeof(uint32_t)));
    if (received != observed.size() * sizeof(uint32_t)) {
      throw std::runtime_error("short receive: expected " +
                               std::to_string(observed.size() * sizeof(uint32_t)) +
                               ", got " + std::to_string(received));
    }
    after_receive = std::chrono::steady_clock::now();
  }
  board.synchronize();
  const auto finished = std::chrono::steady_clock::now();

  Sample sample{
      .execute_ns = elapsed_ns(started, after_execute),
      .receive_ns = elapsed_ns(after_execute, after_receive),
      .synchronize_ns = elapsed_ns(after_receive, finished),
      .elapsed_ns = elapsed_ns(started, finished),
      .mismatched_words = 0,
      .first_mismatch_word = std::nullopt,
      .first_expected = std::nullopt,
      .first_observed = std::nullopt,
      .sha256 = std::nullopt,
  };
  if (!observed.empty()) {
    for (size_t index = 0; index < observed.size(); ++index) {
      if (observed[index] != workload.expected[index]) {
        ++sample.mismatched_words;
        if (!sample.first_mismatch_word.has_value()) {
          sample.first_mismatch_word = index;
          sample.first_expected = workload.expected[index];
          sample.first_observed = observed[index];
        }
      }
    }
    sample.sha256 =
        sha256_bytes(observed.data(), observed.size() * sizeof(uint32_t));
  }
  return sample;
}

std::string hex_word(uint32_t word) {
  std::ostringstream output;
  output << "0x" << std::hex << std::setfill('0') << std::setw(8) << word;
  return output.str();
}

std::string sample_fields(const Workload& workload,
                          std::string_view phase,
                          int iteration,
                          const Sample& sample) {
  std::ostringstream output;
  output << "\"workload\":" << json_quote(workload.name)
         << ",\"phase\":" << json_quote(phase)
         << ",\"iteration\":" << iteration
         << ",\"payload_bytes\":" << workload.payload_bytes
         << ",\"execute_ns\":" << sample.execute_ns
         << ",\"receive_ns\":" << sample.receive_ns
         << ",\"synchronize_ns\":" << sample.synchronize_ns
         << ",\"elapsed_ns\":" << sample.elapsed_ns
         << ",\"mismatched_words\":" << sample.mismatched_words
         << ",\"sha256\":"
         << (sample.sha256.has_value() ? json_quote(*sample.sha256) : "null");
  if (sample.first_mismatch_word.has_value()) {
    output << ",\"first_mismatch_word\":" << *sample.first_mismatch_word
           << ",\"expected\":" << json_quote(hex_word(*sample.first_expected))
           << ",\"observed\":" << json_quote(hex_word(*sample.first_observed));
  }
  return output.str();
}

Sample execute_checked_sample(IBoard& board,
                              const Workload& workload,
                              JsonlWriter& writer,
                              std::string_view phase,
                              int iteration) {
  Sample sample = run_iteration(board, workload);
  writer.write("sample", sample_fields(workload, phase, iteration, sample));
  if (sample.mismatched_words != 0) {
    throw std::runtime_error(workload.name + " " + std::string(phase) +
                             " iteration " + std::to_string(iteration) +
                             " failed correctness");
  }
  return sample;
}

double percentile_linear(std::vector<uint64_t> values, double percentile) {
  if (values.empty()) throw std::invalid_argument("empty percentile input");
  std::sort(values.begin(), values.end());
  const double rank =
      static_cast<double>(values.size() - 1) * percentile / 100.0;
  const size_t lower = static_cast<size_t>(std::floor(rank));
  const size_t upper = static_cast<size_t>(std::ceil(rank));
  if (lower == upper) return static_cast<double>(values[lower]);
  const double weight = rank - static_cast<double>(lower);
  return static_cast<double>(values[lower]) * (1.0 - weight) +
         static_cast<double>(values[upper]) * weight;
}

struct Distribution {
  uint64_t min = 0;
  double mean = 0;
  double p50 = 0;
  double p95 = 0;
  double p99 = 0;
  uint64_t max = 0;
  double population_stddev = 0;
};

Distribution distribution(const std::vector<uint64_t>& values) {
  if (values.empty()) throw std::invalid_argument("empty distribution input");
  long double sum = 0;
  for (const uint64_t value : values) sum += value;
  const long double mean = sum / values.size();
  long double squared_error = 0;
  for (const uint64_t value : values) {
    const long double delta = static_cast<long double>(value) - mean;
    squared_error += delta * delta;
  }
  return Distribution{
      .min = *std::min_element(values.begin(), values.end()),
      .mean = static_cast<double>(mean),
      .p50 = percentile_linear(values, 50),
      .p95 = percentile_linear(values, 95),
      .p99 = percentile_linear(values, 99),
      .max = *std::max_element(values.begin(), values.end()),
      .population_stddev =
          std::sqrt(static_cast<double>(squared_error / values.size())),
  };
}

std::string distribution_json(const Distribution& value) {
  std::ostringstream output;
  output << "{\"min\":" << value.min
         << ",\"mean\":" << json_double(value.mean)
         << ",\"p50\":" << json_double(value.p50)
         << ",\"p95\":" << json_double(value.p95)
         << ",\"p99\":" << json_double(value.p99)
         << ",\"max\":" << value.max
         << ",\"population_stddev\":" << json_double(value.population_stddev)
         << '}';
  return output.str();
}

struct Summary {
  std::string workload;
  size_t payload_bytes = 0;
  size_t samples = 0;
  Distribution latency;
  Distribution execute;
  Distribution receive;
  Distribution synchronize;
  uint64_t total_elapsed_ns = 0;
  double runs_per_second = 0;
  double payload_gib_per_second = 0;
};

Summary summarize(const Workload& workload, const std::vector<Sample>& samples) {
  std::vector<uint64_t> total;
  std::vector<uint64_t> execute;
  std::vector<uint64_t> receive;
  std::vector<uint64_t> synchronize;
  total.reserve(samples.size());
  execute.reserve(samples.size());
  receive.reserve(samples.size());
  synchronize.reserve(samples.size());
  uint64_t total_ns = 0;
  for (const Sample& sample : samples) {
    total.push_back(sample.elapsed_ns);
    execute.push_back(sample.execute_ns);
    receive.push_back(sample.receive_ns);
    synchronize.push_back(sample.synchronize_ns);
    total_ns += sample.elapsed_ns;
  }
  const double seconds = static_cast<double>(total_ns) / 1e9;
  return Summary{
      .workload = workload.name,
      .payload_bytes = workload.payload_bytes,
      .samples = samples.size(),
      .latency = distribution(total),
      .execute = distribution(execute),
      .receive = distribution(receive),
      .synchronize = distribution(synchronize),
      .total_elapsed_ns = total_ns,
      .runs_per_second = static_cast<double>(samples.size()) / seconds,
      .payload_gib_per_second =
          workload.payload_bytes == 0
              ? 0.0
              : static_cast<double>(samples.size() * workload.payload_bytes) /
                    seconds / static_cast<double>(uint64_t{1} << 30),
  };
}

std::string summary_fields(const Summary& summary) {
  std::ostringstream output;
  output << "\"workload\":" << json_quote(summary.workload)
         << ",\"payload_bytes\":" << summary.payload_bytes
         << ",\"samples\":" << summary.samples
         << ",\"percentile_method\":\"linear_r7\""
         << ",\"latency_ns\":" << distribution_json(summary.latency)
         << ",\"phase_latency_ns\":{"
         << "\"execute\":" << distribution_json(summary.execute)
         << ",\"receive\":" << distribution_json(summary.receive)
         << ",\"synchronize\":" << distribution_json(summary.synchronize)
         << "}"
         << ",\"total_elapsed_ns\":" << summary.total_elapsed_ns
         << ",\"runs_per_second\":" << json_double(summary.runs_per_second)
         << ",\"payload_gib_per_second\":"
         << json_double(summary.payload_gib_per_second);
  return output.str();
}

std::string summary_object(const Summary& summary) {
  return '{' + summary_fields(summary) + '}';
}

std::string hostname() {
  std::array<char, 256> buffer{};
  if (::gethostname(buffer.data(), buffer.size()) != 0) return "unknown";
  buffer.back() = '\0';
  return buffer.data();
}

std::string platform_text() {
  struct utsname info {};
  if (::uname(&info) != 0) return "unknown";
  return std::string(info.sysname) + "-" + info.release + "-" + info.machine;
}

std::string kernel_release() {
  struct utsname info {};
  return ::uname(&info) == 0 ? std::string(info.release) : "unknown";
}

std::string cpu_affinity_json() {
  cpu_set_t affinity;
  CPU_ZERO(&affinity);
  if (::sched_getaffinity(0, sizeof(affinity), &affinity) != 0) {
    return "{\"available\":false,\"cpus\":[],\"list\":null}";
  }

  std::ostringstream list;
  std::ostringstream array;
  array << '[';
  bool first = true;
  for (int cpu = 0; cpu < CPU_SETSIZE; ++cpu) {
    if (!CPU_ISSET(cpu, &affinity)) continue;
    if (!first) {
      list << ',';
      array << ',';
    }
    list << cpu;
    array << cpu;
    first = false;
  }
  array << ']';
  return "{\"available\":true,\"cpus\":" + array.str() +
         ",\"list\":" + json_quote(list.str()) + '}';
}

std::string executable_path() {
  std::error_code error;
  const auto path = std::filesystem::read_symlink("/proc/self/exe", error);
  return error ? "unknown" : path.string();
}

std::string sysfs_device_json(const std::string& bdf) {
  const std::filesystem::path root =
      std::filesystem::path("/sys/bus/pci/devices") / bdf;
  std::ostringstream output;
  output << "{\"sysfs_path\":" << json_quote(root.string())
         << ",\"present\":" << (std::filesystem::exists(root) ? "true" : "false");
  for (const std::string_view field : {
           "vendor", "device", "subsystem_vendor", "subsystem_device",
           "current_link_speed", "current_link_width", "numa_node"}) {
    if (const auto value = read_text(root / field); value.has_value()) {
      output << ',' << json_quote(field) << ':' << json_quote(*value);
    }
  }
  std::error_code error;
  const auto driver = std::filesystem::read_symlink(root / "driver", error);
  output << ",\"driver\":"
         << (error ? "null" : json_quote(driver.filename().string())) << '}';
  return output.str();
}

std::string module_json(std::string_view name) {
  const std::filesystem::path root =
      std::filesystem::path("/sys/module") / name;
  const auto srcversion = read_text(root / "srcversion");
  const auto version = read_text(root / "version");
  std::ostringstream output;
  output << "{\"name\":" << json_quote(name)
         << ",\"loaded\":" << (std::filesystem::exists(root) ? "true" : "false")
         << ",\"srcversion\":"
         << (srcversion ? json_quote(*srcversion) : "null")
         << ",\"version\":" << (version ? json_quote(*version) : "null") << '}';
  return output.str();
}

std::string provenance_json(const Options& options) {
  const std::string executable = executable_path();
  const bool have_executable =
      executable != "unknown" && std::filesystem::is_regular_file(executable);
  std::ostringstream output;
  output << "{\"argv\":" << json_string_array(options.argv)
         << ",\"hostname\":" << json_quote(hostname())
         << ",\"platform\":" << json_quote(platform_text())
         << ",\"kernel\":" << json_quote(kernel_release())
         << ",\"pid\":" << static_cast<long long>(::getpid())
         << ",\"sched_getaffinity\":" << cpu_affinity_json()
         << ",\"sched_getcpu_at_start\":" << ::sched_getcpu()
         << ",\"adapter\":\"new_repo_native_cpp\""
         << ",\"cpp_standard\":" << __cplusplus
         << ",\"compiler\":" << json_quote(__VERSION__)
         << ",\"source_file\":" << json_quote(__FILE__)
         << ",\"executable_path\":" << json_quote(executable)
         << ",\"executable_sha256\":"
         << (have_executable ? json_quote(sha256_file(executable)) : "null")
         << ",\"pci_device\":" << sysfs_device_json(options.pci_bdf)
         << ",\"xdma_module\":" << module_json("xdma")
         << ",\"stack_label\":" << json_quote(options.stack_label)
         << ",\"driver_label\":" << json_quote(options.driver_label)
         << ",\"bitstream\":{"
         << "\"label\":" << json_quote(options.bitstream_label)
         << ",\"declared_file\":";
  if (options.bitstream_file.has_value()) {
    const auto absolute = std::filesystem::absolute(*options.bitstream_file);
    output << json_quote(absolute.string())
           << ",\"declared_file_sha256\":" << json_quote(sha256_file(absolute));
  } else {
    output << "null,\"declared_file_sha256\":null";
  }
  output << ",\"qualification\":\"user-declared; the host cannot attest the programmed image\"}"
         << ",\"pci_bdf\":" << json_quote(options.pci_bdf)
         << ",\"xdma_channel\":" << options.xdma_channel
         << ",\"bank\":" << options.bank
         << ",\"start_row\":" << options.start_row
         << ",\"seed\":" << options.seed
         << ",\"warmups\":" << options.warmups
         << ",\"iterations\":" << options.iterations
         << ",\"workloads\":" << json_string_array(options.workloads)
         << ",\"timed_region\":\"immediately before execute through return from synchronize\""
         << ",\"correctness_region\":\"outside timed region, after every payload sample\""
         << ",\"binding_overhead\":\"none; direct native C++ API calls\""
         << ",\"payload_definition\":\"one execute of a looped read program; 64 B is one cacheline and larger workloads use contiguous complete 8 KiB rows\""
         << ",\"pattern_definition\":\"32-bit xorshift row/lane pattern from seed, bank, and logical row; each row repeats its 16 lane words across its cachelines\""
         << '}';
  return output.str();
}

std::filesystem::path output_path(const Options& options) {
  if (options.output.has_value()) return *options.output;
  return "u200-readback-benchmark-cpp-" + utc_stamp() + ".jsonl";
}

void run_hardware(const Options& options,
                  const std::vector<Workload>& workloads,
                  const std::filesystem::path& path) {
  if (!path.parent_path().empty()) {
    std::filesystem::create_directories(path.parent_path());
  }
  JsonlWriter writer(path, make_run_id());
  writer.write("run_start", "\"provenance\":" + provenance_json(options));

  std::unique_ptr<IBoard> board;
  std::exception_ptr failure;
  std::string status = "fail";
  std::string final_reset = "not-opened";
  std::vector<Summary> summaries;
  try {
    board = create_board(BoardType::DDR4, options.pci_bdf, options.xdma_channel,
                         HostInterface::XDMA);
    board->full_reset();
    for (const Workload& workload : workloads) {
      std::ostringstream start;
      start << "\"workload\":" << json_quote(workload.name)
            << ",\"payload_bytes\":" << workload.payload_bytes
            << ",\"cachelines\":" << workload.cachelines
            << ",\"rows\":" << workload.rows
            << ",\"program_validation\":" << validation_json(workload.validation)
            << ",\"setup_programs\":" << workload.setup_programs.size()
            << ",\"expected_sha256\":"
            << (workload.expected_sha256 ? json_quote(*workload.expected_sha256) : "null");
      writer.write("workload_start", start.str());

      board->full_reset();
      for (const FinalProgram& setup_program : workload.setup_programs) {
        board->execute(setup_program);
      }
      board->synchronize();

      (void)execute_checked_sample(*board, workload, writer, "preflight", 0);
      for (int iteration = 0; iteration < options.warmups; ++iteration) {
        (void)execute_checked_sample(*board, workload, writer, "warmup", iteration);
      }
      std::vector<Sample> measured;
      measured.reserve(static_cast<size_t>(options.iterations));
      for (int iteration = 0; iteration < options.iterations; ++iteration) {
        measured.push_back(execute_checked_sample(
            *board, workload, writer, "measurement", iteration));
      }
      summaries.push_back(summarize(workload, measured));
      const Summary& summary = summaries.back();
      writer.write("summary", summary_fields(summary));
      std::printf("%s: p50=%.3f ms p95=%.3f ms p99=%.3f ms max=%.3f ms "
                  "runs/s=%.2f GiB/s=%.4f\n",
                  workload.name.c_str(), summary.latency.p50 / 1e6,
                  summary.latency.p95 / 1e6, summary.latency.p99 / 1e6,
                  static_cast<double>(summary.latency.max) / 1e6,
                  summary.runs_per_second, summary.payload_gib_per_second);
    }
    status = "pass";
  } catch (const std::exception& error) {
    writer.write("error", "\"error\":" +
                              json_quote(std::string("exception: ") + error.what()));
    failure = std::current_exception();
  } catch (...) {
    writer.write("error", "\"error\":\"unknown exception\"");
    failure = std::current_exception();
  }

  if (board) {
    try {
      board->full_reset();
      final_reset = "pass";
    } catch (const std::exception& error) {
      final_reset = std::string("fail: ") + error.what();
      status = "fail";
      if (!failure) failure = std::current_exception();
    } catch (...) {
      final_reset = "fail: unknown exception";
      status = "fail";
      if (!failure) failure = std::current_exception();
    }
    try {
      board->close();
    } catch (const std::exception& error) {
      writer.write("close_error", "\"error\":" + json_quote(error.what()));
      status = "fail";
      if (!failure) failure = std::current_exception();
    } catch (...) {
      writer.write("close_error", "\"error\":\"unknown exception\"");
      status = "fail";
      if (!failure) failure = std::current_exception();
    }
  }

  std::ostringstream end;
  end << "\"status\":" << json_quote(status)
      << ",\"final_full_reset\":" << json_quote(final_reset)
      << ",\"summaries\":[";
  for (size_t index = 0; index < summaries.size(); ++index) {
    if (index != 0) end << ',';
    end << summary_object(summaries[index]);
  }
  end << ']';
  writer.write("run_end", end.str());
  writer.close();
  if (failure) std::rethrow_exception(failure);
}

}  // namespace

int main(int argc, char** argv) {
  Options options;
  if (!parse_args(argc, argv, &options)) {
    print_usage(argv[0]);
    return 2;
  }

  try {
    std::vector<Workload> workloads;
    workloads.reserve(options.workloads.size());
    for (const std::string& name : options.workloads) {
      workloads.push_back(
          build_workload(name, options.bank, options.start_row, options.seed));
    }
    print_program_table(workloads);
    if (options.program_manifest.has_value()) {
      write_program_manifest(*options.program_manifest, options, workloads);
      std::printf("Program manifest: %s\n",
                  std::filesystem::absolute(*options.program_manifest).c_str());
      std::printf("Program manifest SHA-256: %s\n",
                  sha256_file(*options.program_manifest).c_str());
    }
    if (options.dry_run_only) {
      std::puts("PASS: all generated programs passed VM command-count validation");
      return 0;
    }

    const std::filesystem::path path = output_path(options);
    run_hardware(options, workloads, path);
    std::printf("JSONL: %s\n", std::filesystem::absolute(path).c_str());
    std::printf("SHA-256: %s\n", sha256_file(path).c_str());
    return 0;
  } catch (const std::exception& error) {
    std::fprintf(stderr, "u200_readback_benchmark runtime failure: %s\n", error.what());
    return 1;
  } catch (...) {
    std::fputs("u200_readback_benchmark runtime failure: unknown exception\n", stderr);
    return 1;
  }
}
