#include <array>
#include <chrono>
#include <cmath>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <dlfcn.h>
#include <limits>
#include <memory>
#include <mutex>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include "drambender/api/board/DDR4.h"
#include "drambender/api/board/HBM2.h"
#include "drambender/api/board/board.h"
#include "drambender/api/board/board_config.h"
#include "drambender/api/host_interface/host_interface.h"
#include "drambender/api/program/instruction.h"
#include "drambender/api/program/program.h"
#include "drambender/utils/debug.h"
#include "drambender/utils/vm.h"
#include "program_template_plugin.h"

#include <nanobind/nanobind.h>
#include <nanobind/ndarray.h>
#include <nanobind/stl/array.h>
#include <nanobind/stl/optional.h>
#include <nanobind/stl/string.h>
#include <nanobind/stl/unique_ptr.h>
#include <nanobind/stl/vector.h>

namespace nb = nanobind;

namespace DRAMBender {
namespace {

class PythonSignalPending final {};

void python_interruption_point() {
  nb::gil_scoped_acquire acquire;
  if (PyErr_CheckSignals() != 0) {
    throw PythonSignalPending{};
  }
}

[[noreturn]] void recover_board_and_raise_python_signal(IBoard& board) {
  {
    nb::gil_scoped_release release;
    try {
      board.full_reset();
    } catch (...) {
      // full_reset() marks the handle faulted on failure. Close it when
      // possible; either way, preserve the user's KeyboardInterrupt.
      try {
        board.close();
      } catch (...) {
      }
    }
  }
  throw nb::python_error();
}

void recover_if_python_signal_pending(IBoard& board) {
  if (PyErr_CheckSignals() != 0) {
    recover_board_and_raise_python_signal(board);
  }
}

void synchronize_interruptibly(IBoard& board) {
  try {
    nb::gil_scoped_release release;
    board.synchronize_interruptibly(python_interruption_point);
  } catch (const PythonSignalPending&) {
    // IBoard has already completed full_reset() before rethrowing the
    // interruption marker.
    throw nb::python_error();
  }
  recover_if_python_signal_pending(board);
}

class WritableBufferView {
 public:
  explicit WritableBufferView(nb::handle object) {
    if (PyObject_GetBuffer(object.ptr(), &view_, PyBUF_STRIDES | PyBUF_WRITABLE) != 0) {
      throw nb::python_error();
    }
    has_view_ = true;
    if (PyBuffer_IsContiguous(&view_, 'C') == 0) {
      throw std::invalid_argument("receive_into expects a writable C-contiguous buffer.");
    }
  }

  WritableBufferView(const WritableBufferView&) = delete;
  WritableBufferView& operator=(const WritableBufferView&) = delete;

  WritableBufferView(WritableBufferView&& other) noexcept : view_(other.view_), has_view_(other.has_view_) {
    other.view_.obj = nullptr;
    other.has_view_ = false;
  }

  WritableBufferView& operator=(WritableBufferView&&) = delete;

  ~WritableBufferView() {
    if (has_view_) {
      PyBuffer_Release(&view_);
    }
  }

  void* data() const noexcept {
    return view_.buf;
  }

  size_t size_bytes() const {
    if (view_.len < 0) {
      throw std::runtime_error("Received a Python buffer with a negative size.");
    }

    return static_cast<size_t>(view_.len);
  }

 private:
  Py_buffer view_{};
  bool has_view_ = false;
};

struct MockHostState {
  std::mutex mutex;
  std::condition_variable cv;
  bool block_receive = false;
  bool cancelled = false;
  int drain_count = 0;
};

class NullHostInterface : public IHostInterface {
 public:
  explicit NullHostInterface(std::shared_ptr<MockHostState> state)
      : state_(std::move(state)) {}

  void init() override {}

  size_t send(std::span<const std::byte> data) override {
    return data.size();
  }

  void begin_receive() override {
    std::lock_guard<std::mutex> lock(state_->mutex);
    state_->cancelled = false;
  }

  size_t recv(std::span<std::byte>) override {
    std::unique_lock<std::mutex> lock(state_->mutex);
    if (!state_->block_receive) {
      return 0;
    }
    state_->cv.wait(lock, [&] { return state_->cancelled; });
    return 0;
  }

  void cancel_receive() noexcept override {
    {
      std::lock_guard<std::mutex> lock(state_->mutex);
      state_->cancelled = true;
    }
    state_->cv.notify_all();
  }

  void drain() override {
    std::lock_guard<std::mutex> lock(state_->mutex);
    state_->block_receive = false;
    ++state_->drain_count;
  }

 private:
  std::shared_ptr<MockHostState> state_;
};

// Internal test hook. This is intentionally not wrapped by the public
// drambender package API.
class MockBoard : public IBoard {
 public:
  explicit MockBoard(int receive_timeout_ms = 5000)
      : MockBoard(std::make_shared<MockHostState>(), receive_timeout_ms) {}

  void execute(const FinalProgram&) override {
    ensureOpen_();
  }

  size_t receive(
      std::span<std::byte> dst,
      std::optional<std::chrono::milliseconds> /*timeout*/) override {
    ensureOpen_();
    if (dst.data() == nullptr && !dst.empty()) {
      throw std::invalid_argument("receive destination buffer cannot be null.");
    }
    if (dst.size_bytes() % sizeof(Word_t) != 0) {
      throw std::invalid_argument("receive expects a byte count that is a multiple of 4.");
    }
    if (dst.empty()) {
      return 0;
    }
    if (read_offset_ + dst.size_bytes() > queued_readback_.size()) {
      throw std::runtime_error("MockBoard does not have enough queued readback data.");
    }

    std::memcpy(
        dst.data(),
        queued_readback_.data() + static_cast<std::ptrdiff_t>(read_offset_),
        dst.size_bytes());
    read_offset_ += dst.size_bytes();
    return dst.size_bytes();
  }

  size_t receive_interruptibly(
      std::span<std::byte> dst,
      const InterruptionPoint& interruption_point,
      std::optional<std::chrono::milliseconds> timeout) override {
    bool block_receive = false;
    {
      std::lock_guard<std::mutex> lock(host_state_->mutex);
      block_receive = host_state_->block_receive;
    }
    if (block_receive) {
      return IBoard::receive_interruptibly(dst, interruption_point, timeout);
    }

    // The ordinary in-memory queue path never blocks. The binding performs
    // one Python signal check immediately after it returns.
    return receive(dst, timeout);
  }

  void start_blocked_receive() {
    {
      std::lock_guard<std::mutex> lock(host_state_->mutex);
      host_state_->block_receive = true;
    }
    Program program;
    program.add_inst(all_nops());
    IBoard::execute(program.conclude());
  }

  int drain_count() {
    std::lock_guard<std::mutex> lock(host_state_->mutex);
    return host_state_->drain_count;
  }

  void queue_receive_words(const std::vector<uint32_t>& words) {
    append_bytes_(words.data(), words.size() * sizeof(uint32_t));
  }

  void queue_receive_bytes(const std::vector<uint8_t>& bytes) {
    append_bytes_(bytes.data(), bytes.size());
  }

  void clear_receive_queue() {
    queued_readback_.clear();
    read_offset_ = 0;
  }

 private:
  MockBoard(std::shared_ptr<MockHostState> state, int receive_timeout_ms)
      : IBoard(std::make_unique<NullHostInterface>(state),
               2048,
               1024,
               std::chrono::milliseconds(receive_timeout_ms)),
        host_state_(std::move(state)) {}

  void append_bytes_(const void* data, size_t size_bytes) {
    if (size_bytes == 0) {
      return;
    }

    const auto* src = static_cast<const std::byte*>(data);
    queued_readback_.insert(queued_readback_.end(), src, src + static_cast<std::ptrdiff_t>(size_bytes));
  }

  std::vector<std::byte> queued_readback_;
  size_t read_offset_ = 0;
  std::shared_ptr<MockHostState> host_state_;
};

std::optional<std::chrono::milliseconds> parse_receive_timeout(
    nb::handle timeout) {
  if (timeout.is_none()) {
    return std::nullopt;
  }

  const double timeout_seconds = PyFloat_AsDouble(timeout.ptr());
  if (PyErr_Occurred()) {
    throw nb::python_error();
  }
  if (!std::isfinite(timeout_seconds) || timeout_seconds < 0.0) {
    throw std::invalid_argument(
        "receive_into timeout must be a finite nonnegative number of seconds or None.");
  }

  const long double timeout_milliseconds =
      std::ceil(static_cast<long double>(timeout_seconds) * 1000.0L);
  constexpr auto max_timeout =
      std::numeric_limits<std::chrono::milliseconds::rep>::max();
  if (timeout_milliseconds > static_cast<long double>(max_timeout)) {
    throw std::invalid_argument("receive_into timeout is too large.");
  }

  return std::chrono::milliseconds(
      static_cast<std::chrono::milliseconds::rep>(timeout_milliseconds));
}

size_t receive_into(IBoard& board, nb::handle dst, nb::handle timeout) {
  WritableBufferView buffer(dst);
  const auto parsed_timeout = parse_receive_timeout(timeout);

  size_t bytes_received = 0;
  try {
    nb::gil_scoped_release release;
    bytes_received = board.receive_interruptibly(
        std::span(reinterpret_cast<std::byte*>(buffer.data()), buffer.size_bytes()),
        python_interruption_point,
        parsed_timeout);
  } catch (const PythonSignalPending&) {
    // IBoard has already completed full_reset() before rethrowing the
    // interruption marker.
    throw nb::python_error();
  }
  recover_if_python_signal_pending(board);

  return bytes_received;
}

constexpr uint32_t k_template_plugin_abi_version = 1;

long long coerce_python_integer(nb::handle value, const std::string& context) {
  if (!PyLong_Check(value.ptr())) {
    throw std::invalid_argument(context + " must be an integer.");
  }

  const long long result = PyLong_AsLongLong(value.ptr());
  if (PyErr_Occurred()) {
    throw nb::python_error();
  }

  if (result < std::numeric_limits<int32_t>::min() ||
      result > static_cast<long long>(std::numeric_limits<uint32_t>::max())) {
    throw std::invalid_argument(
        context + " must be in the range [-2^31, 2^32 - 1].");
  }

  return result;
}

int coerce_cpp_int(nb::handle value, const std::string& context) {
  const long long result = coerce_python_integer(value, context);
  if (result < std::numeric_limits<int>::min() ||
      result > std::numeric_limits<int>::max()) {
    throw std::invalid_argument(
        context + " must fit in a signed 32-bit integer.");
  }
  return static_cast<int>(result);
}

uint32_t coerce_u32_bits(nb::handle value, const std::string& context) {
  return static_cast<uint32_t>(
      static_cast<int32_t>(coerce_python_integer(value, context)));
}

std::string coerce_string(nb::handle value, const std::string& context) {
  if (!PyUnicode_Check(value.ptr())) {
    throw std::invalid_argument(context + " must be a string.");
  }
  return nb::cast<std::string>(value);
}

nb::tuple require_op_tuple(nb::handle value, size_t index) {
  try {
    return nb::cast<nb::tuple>(value);
  } catch (const nb::cast_error&) {
    throw std::invalid_argument(
        "ops[" + std::to_string(index) + "] must be a tuple.");
  }
}

nb::tuple require_tuple(nb::handle value, const std::string& context) {
  try {
    return nb::cast<nb::tuple>(value);
  } catch (const nb::cast_error&) {
    throw std::invalid_argument(context + " must be a tuple.");
  }
}

void require_arity(const nb::tuple& op, size_t expected, const std::string& opcode) {
  if (op.size() != expected) {
    throw std::invalid_argument(
        "Opcode " + opcode + " expects " + std::to_string(expected - 1) +
        " operand(s), but received " + std::to_string(op.size() - 1) + ".");
  }
}

PC_TYPE coerce_pc_type(nb::handle value, const std::string& context) {
  return static_cast<PC_TYPE>(coerce_cpp_int(value, context));
}

Mininst coerce_mininst(nb::handle value, const std::string& context) {
  const nb::tuple op = require_tuple(value, context);
  if (op.size() == 0) {
    throw std::invalid_argument(context + " cannot be empty.");
  }

  const std::string opcode = coerce_string(op[0], context + "[0]");
  if (opcode == "NOP") {
    require_arity(op, 1, opcode);
    return SMC_NOP();
  }
  if (opcode == "PRE") {
    require_arity(op, 5, opcode);
    return SMC_PRE(
        coerce_cpp_int(op[1], context + " PRE bar"),
        coerce_cpp_int(op[2], context + " PRE ibar"),
        coerce_cpp_int(op[3], context + " PRE pall"),
        coerce_cpp_int(op[4], context + " PRE rank"));
  }
  if (opcode == "ACT") {
    require_arity(op, 6, opcode);
    return SMC_ACT(
        coerce_cpp_int(op[1], context + " ACT bar"),
        coerce_cpp_int(op[2], context + " ACT ibar"),
        coerce_cpp_int(op[3], context + " ACT rar"),
        coerce_cpp_int(op[4], context + " ACT irar"),
        coerce_cpp_int(op[5], context + " ACT rank"));
  }
  if (opcode == "RD") {
    require_arity(op, 7, opcode);
    return SMC_READ(
        coerce_cpp_int(op[1], context + " RD bar"),
        coerce_cpp_int(op[2], context + " RD ibar"),
        coerce_cpp_int(op[3], context + " RD car"),
        coerce_cpp_int(op[4], context + " RD icar"),
        coerce_cpp_int(op[5], context + " RD rank"),
        coerce_cpp_int(op[6], context + " RD ap"));
  }
  if (opcode == "WR") {
    require_arity(op, 7, opcode);
    return SMC_WRITE(
        coerce_cpp_int(op[1], context + " WR bar"),
        coerce_cpp_int(op[2], context + " WR ibar"),
        coerce_cpp_int(op[3], context + " WR car"),
        coerce_cpp_int(op[4], context + " WR icar"),
        coerce_cpp_int(op[5], context + " WR rank"),
        coerce_cpp_int(op[6], context + " WR ap"));
  }
  if (opcode == "REF") {
    require_arity(op, 2, opcode);
    return SMC_REF(coerce_cpp_int(op[1], context + " REF rank"));
  }
  if (opcode == "SEL_CH") {
    require_arity(op, 3, opcode);
    return SMC_SEL_CH(
        coerce_cpp_int(op[1], context + " SEL_CH channel"),
        coerce_cpp_int(op[2], context + " SEL_CH pseudo_channel"));
  }

  throw std::invalid_argument("Unsupported DRAM mini-op: " + opcode);
}

FinalProgram lower(nb::list ops) {
  Program program;

  for (size_t op_index = 0; op_index < ops.size(); ++op_index) {
    const nb::tuple op = require_op_tuple(ops[op_index], op_index);
    if (op.size() == 0) {
      throw std::invalid_argument(
          "ops[" + std::to_string(op_index) + "] cannot be empty.");
    }

    const std::string opcode =
        coerce_string(op[0], "ops[" + std::to_string(op_index) + "][0]");

    if (opcode == "ADD") {
      require_arity(op, 4, opcode);
      program.add_inst(SMC_ADD(
          coerce_cpp_int(op[1], "ADD rs1"),
          coerce_cpp_int(op[2], "ADD rs2"),
          coerce_cpp_int(op[3], "ADD rt")));
      continue;
    }
    if (opcode == "ADDI") {
      require_arity(op, 4, opcode);
      program.add_inst(SMC_ADDI(
          coerce_cpp_int(op[1], "ADDI rs1"),
          coerce_u32_bits(op[2], "ADDI immediate"),
          coerce_cpp_int(op[3], "ADDI rt")));
      continue;
    }
    if (opcode == "SUB") {
      require_arity(op, 4, opcode);
      program.add_inst(SMC_SUB(
          coerce_cpp_int(op[1], "SUB rs1"),
          coerce_cpp_int(op[2], "SUB rs2"),
          coerce_cpp_int(op[3], "SUB rt")));
      continue;
    }
    if (opcode == "SUBI") {
      require_arity(op, 4, opcode);
      program.add_inst(SMC_SUBI(
          coerce_cpp_int(op[1], "SUBI rs1"),
          coerce_u32_bits(op[2], "SUBI immediate"),
          coerce_cpp_int(op[3], "SUBI rt")));
      continue;
    }
    if (opcode == "LI") {
      require_arity(op, 3, opcode);
      program.add_inst(SMC_LI(
          coerce_u32_bits(op[1], "LI immediate"),
          coerce_cpp_int(op[2], "LI rt")));
      continue;
    }
    if (opcode == "MV") {
      require_arity(op, 3, opcode);
      program.add_inst(SMC_MV(
          coerce_cpp_int(op[1], "MV rs1"),
          coerce_cpp_int(op[2], "MV rt")));
      continue;
    }
    if (opcode == "SRC") {
      require_arity(op, 3, opcode);
      program.add_inst(SMC_SRC(
          coerce_cpp_int(op[1], "SRC rs1"),
          coerce_cpp_int(op[2], "SRC rt")));
      continue;
    }
    if (opcode == "AND") {
      require_arity(op, 4, opcode);
      program.add_inst(SMC_AND(
          coerce_cpp_int(op[1], "AND rs1"),
          coerce_cpp_int(op[2], "AND rs2"),
          coerce_cpp_int(op[3], "AND rt")));
      continue;
    }
    if (opcode == "OR") {
      require_arity(op, 4, opcode);
      program.add_inst(SMC_OR(
          coerce_cpp_int(op[1], "OR rs1"),
          coerce_cpp_int(op[2], "OR rs2"),
          coerce_cpp_int(op[3], "OR rt")));
      continue;
    }
    if (opcode == "XOR") {
      require_arity(op, 4, opcode);
      program.add_inst(SMC_XOR(
          coerce_cpp_int(op[1], "XOR rs1"),
          coerce_cpp_int(op[2], "XOR rs2"),
          coerce_cpp_int(op[3], "XOR rt")));
      continue;
    }
    if (opcode == "LD") {
      require_arity(op, 4, opcode);
      program.add_inst(SMC_LD(
          coerce_cpp_int(op[1], "LD rb"),
          coerce_cpp_int(op[2], "LD offset"),
          coerce_cpp_int(op[3], "LD rt")));
      continue;
    }
    if (opcode == "ST") {
      require_arity(op, 4, opcode);
      program.add_inst(SMC_ST(
          coerce_cpp_int(op[1], "ST rb"),
          coerce_cpp_int(op[2], "ST offset"),
          coerce_cpp_int(op[3], "ST rv")));
      continue;
    }
    if (opcode == "LDWD") {
      require_arity(op, 3, opcode);
      program.add_inst(SMC_LDWD(
          coerce_cpp_int(op[1], "LDWD rs1"),
          coerce_cpp_int(op[2], "LDWD offset")));
      continue;
    }
    if (opcode == "LDPC") {
      require_arity(op, 3, opcode);
      program.add_inst(SMC_LDPC(
          coerce_pc_type(op[1], "LDPC pc_type"),
          coerce_cpp_int(op[2], "LDPC rt")));
      continue;
    }
    if (opcode == "SRE") {
      require_arity(op, 1, opcode);
      program.add_inst(SMC_SRE());
      continue;
    }
    if (opcode == "SRX") {
      require_arity(op, 1, opcode);
      program.add_inst(SMC_SRX());
      continue;
    }
    if (opcode == "SLEEP") {
      require_arity(op, 2, opcode);
      const int cycles = coerce_cpp_int(op[1], "SLEEP cycles");
      if (cycles < 1) {
        throw std::invalid_argument("SLEEP cycles must be at least 1.");
      }
      if (cycles <= 2) {
        for (int i = 0; i < cycles; ++i) {
          program.add_inst(all_nops());
        }
      } else {
        program.add_inst(SMC_SLEEP(static_cast<uint32_t>(cycles)));
      }
      continue;
    }
    if (opcode == "PRE") {
      require_arity(op, 6, opcode);
          program.add_mininst(
              SMC_PRE(
                  coerce_cpp_int(op[1], "PRE bar"),
                  coerce_cpp_int(op[2], "PRE ibar"),
                  coerce_cpp_int(op[3], "PRE pall"),
                  coerce_cpp_int(op[4], "PRE rank")),
              coerce_cpp_int(op[5], "PRE delay"));
      continue;
    }
    if (opcode == "ACT") {
      require_arity(op, 7, opcode);
          program.add_mininst(
              SMC_ACT(
                  coerce_cpp_int(op[1], "ACT bar"),
                  coerce_cpp_int(op[2], "ACT ibar"),
                  coerce_cpp_int(op[3], "ACT rar"),
                  coerce_cpp_int(op[4], "ACT irar"),
                  coerce_cpp_int(op[5], "ACT rank")),
              coerce_cpp_int(op[6], "ACT delay"));
      continue;
    }
    if (opcode == "RD") {
      require_arity(op, 8, opcode);
          program.add_mininst(
              SMC_READ(
                  coerce_cpp_int(op[1], "RD bar"),
                  coerce_cpp_int(op[2], "RD ibar"),
                  coerce_cpp_int(op[3], "RD car"),
                  coerce_cpp_int(op[4], "RD icar"),
                  coerce_cpp_int(op[5], "RD rank"),
                  coerce_cpp_int(op[6], "RD ap")),
              coerce_cpp_int(op[7], "RD delay"));
      continue;
    }
    if (opcode == "WR") {
      require_arity(op, 8, opcode);
          program.add_mininst(
              SMC_WRITE(
                  coerce_cpp_int(op[1], "WR bar"),
                  coerce_cpp_int(op[2], "WR ibar"),
                  coerce_cpp_int(op[3], "WR car"),
                  coerce_cpp_int(op[4], "WR icar"),
                  coerce_cpp_int(op[5], "WR rank"),
                  coerce_cpp_int(op[6], "WR ap")),
              coerce_cpp_int(op[7], "WR delay"));
      continue;
    }
    if (opcode == "REF") {
      require_arity(op, 3, opcode);
      program.add_mininst(
          SMC_REF(coerce_cpp_int(op[1], "REF rank")),
          coerce_cpp_int(op[2], "REF delay"));
      continue;
    }
    if (opcode == "SEL_CH") {
      require_arity(op, 4, opcode);
      program.add_mininst(
          SMC_SEL_CH(
              coerce_cpp_int(op[1], "SEL_CH channel"),
              coerce_cpp_int(op[2], "SEL_CH pseudo_channel")),
          coerce_cpp_int(op[3], "SEL_CH delay"));
      continue;
    }
    if (opcode == "DRAM") {
      require_arity(op, 5, opcode);
      program.add_inst(
          coerce_mininst(op[1], "DRAM slot 0"),
          coerce_mininst(op[2], "DRAM slot 1"),
          coerce_mininst(op[3], "DRAM slot 2"),
          coerce_mininst(op[4], "DRAM slot 3"));
      continue;
    }
    if (opcode == "DRAM_DELAY") {
      require_arity(op, 3, opcode);
      program.add_mininst(
          coerce_mininst(op[1], "DRAM_DELAY op"),
          coerce_cpp_int(op[2], "DRAM_DELAY delay"));
      continue;
    }
    if (opcode == "DRAM_ALIGN_PAD") {
      require_arity(op, 2, opcode);
      program.add_DRAM_wait(coerce_cpp_int(op[1], "DRAM_ALIGN_PAD slots"));
      continue;
    }
    if (opcode == "LABEL") {
      require_arity(op, 2, opcode);
      program.add_label(coerce_string(op[1], "LABEL name"));
      continue;
    }
    if (opcode == "BL") {
      require_arity(op, 4, opcode);
      program.add_branch(
          Program::BR_TYPE::BL,
          coerce_cpp_int(op[1], "BL rs1"),
          coerce_cpp_int(op[2], "BL rs2"),
          coerce_string(op[3], "BL target"));
      continue;
    }
    if (opcode == "BEQ") {
      require_arity(op, 4, opcode);
      program.add_branch(
          Program::BR_TYPE::BEQ,
          coerce_cpp_int(op[1], "BEQ rs1"),
          coerce_cpp_int(op[2], "BEQ rs2"),
          coerce_string(op[3], "BEQ target"));
      continue;
    }
    if (opcode == "JMP") {
      require_arity(op, 2, opcode);
      program.add_branch(
          Program::BR_TYPE::JUMP,
          0,
          0,
          coerce_string(op[1], "JMP target"));
      continue;
    }

    throw std::invalid_argument("Unsupported opcode: " + opcode);
  }

  return program.conclude();
}

class ProgramPlugin {
 public:
  ProgramPlugin(
      std::string plugin_path,
      std::vector<std::string> scalar_names,
      std::vector<std::string> array_names,
      std::vector<size_t> array_lengths)
      : plugin_path_(std::move(plugin_path)),
        scalar_names_(std::move(scalar_names)),
        array_names_(std::move(array_names)),
        array_lengths_(std::move(array_lengths)) {
    if (array_names_.size() != array_lengths_.size()) {
      throw std::invalid_argument(
          "Program plugin schema is inconsistent: array names and lengths differ.");
    }

    promote_current_module_symbols_();

    handle_ = dlopen(plugin_path_.c_str(), RTLD_NOW | RTLD_LOCAL);
    if (handle_ == nullptr) {
      throw std::runtime_error(
          "Failed to load program plugin " + plugin_path_ + ": " +
          dlerror_string_());
    }

    auto* abi_version_fn =
        reinterpret_cast<DRAMBenderPluginAbiVersionFn>(
            dlsym(handle_, "drambender_template_plugin_abi_version"));
    if (abi_version_fn == nullptr) {
      throw std::runtime_error(
          "Program plugin is missing ABI version symbol: " + plugin_path_);
    }
    if (abi_version_fn() != k_template_plugin_abi_version) {
      throw std::runtime_error(
          "Program plugin ABI version mismatch for " + plugin_path_ + ".");
    }

    instantiate_ = reinterpret_cast<DRAMBenderInstantiateFn>(
        dlsym(handle_, "instantiate"));
    if (instantiate_ == nullptr) {
      throw std::runtime_error(
          "Program plugin is missing instantiate() symbol: " + plugin_path_);
    }
  }

  ProgramPlugin(const ProgramPlugin&) = delete;
  ProgramPlugin& operator=(const ProgramPlugin&) = delete;

  ProgramPlugin(ProgramPlugin&& other) noexcept
      : plugin_path_(std::move(other.plugin_path_)),
        scalar_names_(std::move(other.scalar_names_)),
        array_names_(std::move(other.array_names_)),
        array_lengths_(std::move(other.array_lengths_)),
        handle_(other.handle_),
        instantiate_(other.instantiate_) {
    other.handle_ = nullptr;
    other.instantiate_ = nullptr;
  }

  ProgramPlugin& operator=(ProgramPlugin&&) = delete;

  ~ProgramPlugin() {
    if (handle_ != nullptr) {
      if (dlclose(handle_) != 0) {
        std::fprintf(stderr,
                     "[drambender] ~ProgramPlugin: dlclose(%s) failed: %s\n",
                     plugin_path_.c_str(),
                     dlerror_string_().c_str());
      }
    }
  }

  FinalProgram instantiate(nb::dict args) const {
    const size_t expected_arg_count = scalar_names_.size() + array_names_.size();
    if (args.size() != expected_arg_count) {
      throw std::invalid_argument(
          "Program template invocation expected " +
          std::to_string(expected_arg_count) + " argument(s), but received " +
          std::to_string(args.size()) + ".");
    }

    std::vector<int32_t> scalar_storage;
    scalar_storage.reserve(scalar_names_.size());
    for (const std::string& scalar_name : scalar_names_) {
      const nb::str key(scalar_name.c_str());
      if (!args.contains(key)) {
        throw std::invalid_argument(
            "Missing scalar template argument: " + scalar_name);
      }
      scalar_storage.push_back(marshal_scalar_(args[key], scalar_name));
    }

    std::vector<std::vector<int32_t>> array_storage;
    array_storage.reserve(array_names_.size());
    for (size_t index = 0; index < array_names_.size(); ++index) {
      const nb::str key(array_names_[index].c_str());
      if (!args.contains(key)) {
        throw std::invalid_argument(
            "Missing array template argument: " + array_names_[index]);
      }
      array_storage.push_back(
          marshal_array_(args[key], array_names_[index], array_lengths_[index]));
    }

    std::vector<DRAMBenderIntArrayArg> array_args;
    array_args.reserve(array_storage.size());
    for (const auto& buffer : array_storage) {
      array_args.push_back({buffer.data(), buffer.size()});
    }

    FinalProgram* native_program = nullptr;
    int status = 0;
    {
      nb::gil_scoped_release release;
      status = instantiate_(
          scalar_storage.data(),
          scalar_storage.size(),
          array_args.data(),
          array_args.size(),
          &native_program);
    }

    if (status != 0) {
      // Defensive: a misbehaved plugin may have allocated a program even on
      // failure. Delete before throwing so we don't leak.
      delete native_program;
      throw std::runtime_error(
          "Program plugin instantiation failed with status " +
          std::to_string(status) + ".");
    }
    if (native_program == nullptr) {
      throw std::runtime_error(
          "Program plugin returned success (status=0) but no program instance.");
    }

    FinalProgram result = std::move(*native_program);
    delete native_program;
    return result;
  }

 private:
  static std::string dlerror_string_() {
    const char* error = dlerror();
    return error == nullptr ? std::string("unknown dlopen/dlsym error")
                            : std::string(error);
  }

  static void promote_current_module_symbols_() {
    Dl_info info{};
    if (dladdr(reinterpret_cast<void*>(&promote_current_module_symbols_), &info) == 0 ||
        info.dli_fname == nullptr) {
      throw std::runtime_error(
          "Failed to locate the currently loaded drambender._core module.");
    }

#ifdef RTLD_NOLOAD
    void* promoted =
        dlopen(info.dli_fname, RTLD_NOW | RTLD_GLOBAL | RTLD_NOLOAD);
#else
    void* promoted = nullptr;
#endif
    if (promoted == nullptr) {
      promoted = dlopen(info.dli_fname, RTLD_NOW | RTLD_GLOBAL);
    }

    if (promoted == nullptr) {
      throw std::runtime_error(
          "Failed to promote drambender._core symbols for program plugins: " +
          dlerror_string_());
    }
  }

  static int32_t marshal_scalar_(nb::handle value, const std::string& name) {
    const auto bits =
        static_cast<uint32_t>(coerce_python_integer(value, name));
    return static_cast<int32_t>(bits);
  }

  static std::vector<int32_t> marshal_array_(
      nb::handle value,
      const std::string& name,
      size_t expected_length) {
    PyObject* fast = PySequence_Fast(
        value.ptr(),
        (name + " must be a sequence of integers.").c_str());
    if (fast == nullptr) {
      throw nb::python_error();
    }

    nb::object fast_owner = nb::steal<nb::object>(fast);
    const auto actual_length =
        static_cast<size_t>(PySequence_Fast_GET_SIZE(fast_owner.ptr()));
    if (actual_length != expected_length) {
      throw std::invalid_argument(
          name + " must contain exactly " +
          std::to_string(expected_length) + " element(s).");
    }

    auto* items = PySequence_Fast_ITEMS(fast_owner.ptr());
    std::vector<int32_t> result;
    result.reserve(actual_length);
    for (size_t index = 0; index < actual_length; ++index) {
      result.push_back(marshal_scalar_(
          nb::handle(items[index]),
          name + "[" + std::to_string(index) + "]"));
    }
    return result;
  }

  std::string plugin_path_;
  std::vector<std::string> scalar_names_;
  std::vector<std::string> array_names_;
  std::vector<size_t> array_lengths_;
  void* handle_ = nullptr;
  DRAMBenderInstantiateFn instantiate_ = nullptr;
};

}  // namespace
}  // namespace DRAMBender

NB_MODULE(_core, m) {
  using namespace DRAMBender;

  nb::enum_<HostInterface>(m, "HostInterface")
      .value("XDMA", HostInterface::XDMA)
      .value("QDMA", HostInterface::QDMA)
      .value("Ethernet", HostInterface::Ethernet);

  nb::enum_<BoardType>(m, "BoardType")
      .value("U200", BoardType::U200)
      .value("U50", BoardType::U50)
      .value("U55C", BoardType::U55C);

  nb::enum_<MemoryType>(m, "MemoryType")
      .value("DDR4", MemoryType::DDR4)
      .value("HBM2", MemoryType::HBM2);

  nb::class_<BoardConfig>(m, "BoardConfig")
      .def_ro("name", &BoardConfig::name)
      .def_ro("board_type", &BoardConfig::board_type)
      .def_ro("memory_type", &BoardConfig::memory_type)
      .def_ro("instruction_capacity", &BoardConfig::instruction_capacity)
      .def_ro("dram_command_slot_ns", &BoardConfig::dram_command_slot_ns)
      .def_ro("dram_slots_per_fabric_cycle", &BoardConfig::dram_slots_per_fabric_cycle)
      .def_ro("readback_buffer_capacity", &BoardConfig::readback_buffer_capacity)
      .def_ro("hbm_channel_count", &BoardConfig::hbm_channel_count)
      .def_ro("hbm_pseudo_channel_count", &BoardConfig::hbm_pseudo_channel_count)
      .def_ro("hbm_sid_count", &BoardConfig::hbm_sid_count)
      .def_ro("broadcast_supported", &BoardConfig::broadcast_supported)
      .def_ro("power_telemetry_supported", &BoardConfig::power_telemetry_supported)
      .def("summary", &BoardConfig::summary);

  m.def("get_board_config", &get_board_config, nb::rv_policy::reference);

  nb::enum_<PC_TYPE>(m, "PCType")
      .value("WRITE", PC_TYPE::WRITE)
      .value("READ", PC_TYPE::READ)
      .value("PRE", PC_TYPE::PRE)
      .value("ACT", PC_TYPE::ACT)
      .value("SEL_CH", PC_TYPE::SEL_CH)
      .value("REF", PC_TYPE::REF)
      .value("CYC", PC_TYPE::CYC);

  nb::enum_<Program::BR_TYPE>(m, "BranchType")
      .value("BEQ", Program::BR_TYPE::BEQ)
      .value("BL", Program::BR_TYPE::BL)
      .value("JUMP", Program::BR_TYPE::JUMP);

  nb::class_<HBMTemperature>(
      m,
      "HBMTemperature",
      "Temperatures reported by an HBM2 board, in degrees Celsius.")
      .def_rw("stack0_celsius", &HBMTemperature::stack0_celsius)
      .def_rw("stack1_celsius", &HBMTemperature::stack1_celsius);

  nb::class_<SensorStat>(
      m, "SensorStat", "Instantaneous, maximum, and average value of one sensor.")
      .def_rw("instant", &SensorStat::instant)
      .def_rw("max", &SensorStat::max)
      .def_rw("average", &SensorStat::average);

  nb::class_<RailTelemetry>(
      m, "RailTelemetry", "Voltage (mV), current (mA), and derived power (mW) for one rail.")
      .def_rw("voltage_mv", &RailTelemetry::voltage_mv)
      .def_rw("current_ma", &RailTelemetry::current_ma)
      .def_prop_ro("power_mw", &RailTelemetry::power_mw);

  nb::class_<PowerTelemetry>(
      m, "PowerTelemetry", "Card power and thermal telemetry (U55C only).")
      .def_rw("pex_12v", &PowerTelemetry::pex_12v)
      .def_rw("pex_3v3", &PowerTelemetry::pex_3v3)
      .def_rw("vccint", &PowerTelemetry::vccint)
      .def_rw("vccint_io", &PowerTelemetry::vccint_io)
      .def_rw("hbm", &PowerTelemetry::hbm)
      .def_rw("hbm_temp0_celsius", &PowerTelemetry::hbm_temp0_celsius)
      .def_rw("hbm_temp1_celsius", &PowerTelemetry::hbm_temp1_celsius)
      .def_prop_ro("total_input_power_mw", &PowerTelemetry::total_input_power_mw);

  nb::class_<Program>(m, "Program")
      .def(nb::init<>())
      .def("add_mininst", &Program::add_mininst, nb::rv_policy::reference_internal)
      .def("add_DRAM_wait", &Program::add_DRAM_wait, nb::rv_policy::reference_internal)
      .def("add_inst", nb::overload_cast<Inst>(&Program::add_inst),
           nb::rv_policy::reference_internal)
      .def("add_inst", nb::overload_cast<Mininst, Mininst, Mininst, Mininst>(&Program::add_inst),
           nb::rv_policy::reference_internal)
      .def("add_label", &Program::add_label, nb::rv_policy::reference_internal)
      .def("add_branch", &Program::add_branch, nb::rv_policy::reference_internal)
      .def("add_below", &Program::add_below, nb::rv_policy::reference_internal)
      .def("flush", &Program::flush, nb::rv_policy::reference_internal)
      .def("conclude", &Program::conclude)
      .def("__str__",
           nb::overload_cast<const Program&>(&debug::format_program))
      .def("__repr__",
           [](const Program& p) {
             return "<Program (building), use print() to see instructions>";
           });

  nb::class_<FinalProgram>(m, "FinalProgram")
      .def(nb::init<std::vector<Inst>>())
      .def("instructions",
           [](const FinalProgram& prog) {
             const auto insts = prog.instructions();
             return std::vector<Inst>(insts.begin(), insts.end());
           })
      .def_prop_ro("instruction_count", &FinalProgram::instruction_count)
      .def("__len__", &FinalProgram::instruction_count)
      .def("size", &FinalProgram::size)
      .def_prop_rw("default_dram_inst_latency",
                   &FinalProgram::default_dram_inst_latency,
                   &FinalProgram::set_default_dram_inst_latency)
      .def("dry_run",
           [](const FinalProgram& program, size_t max_instructions,
              std::optional<double> dram_inst_latency,
              int num_dram_insts_per_fabric_cycle) {
             nb::gil_scoped_release release;
             vm::TimingConfig timing{
                 dram_inst_latency.value_or(
                     program.default_dram_inst_latency()),
                 num_dram_insts_per_fabric_cycle};
             return vm::execute(program, max_instructions, timing);
           },
           nb::arg("max_instructions"),
           nb::arg("dram_inst_latency") = nb::none(),
           nb::arg("num_dram_insts_per_fabric_cycle") = 4)
      .def("trace_dram_commands",
           [](const FinalProgram& program, size_t max_instructions,
              std::optional<double> dram_inst_latency,
              int num_dram_insts_per_fabric_cycle) {
             nb::gil_scoped_release release;
             vm::TimingConfig timing{
                 dram_inst_latency.value_or(
                     program.default_dram_inst_latency()),
                 num_dram_insts_per_fabric_cycle};
             return vm::trace_dram_commands(program, max_instructions, timing);
           },
           nb::arg("max_instructions") = vm::k_default_max_instructions,
           nb::arg("dram_inst_latency") = nb::none(),
           nb::arg("num_dram_insts_per_fabric_cycle") = 4)
      .def("__str__",
           nb::overload_cast<const FinalProgram&>(&debug::format_program))
      .def("__repr__",
           [](const FinalProgram& p) {
             return "<FinalProgram, " + std::to_string(p.instruction_count()) +
                    " instructions, " + std::to_string(p.size()) + " bytes>";
           });

  auto maybe_optional_int = [](int value) -> nb::object {
    if (value < 0) {
      return nb::none();
    }
    return nb::int_(value);
  };

  nb::class_<vm::DRAMCommandEvent>(m, "DRAMCommandEvent")
      .def_ro("command", &vm::DRAMCommandEvent::command)
      .def_ro("pc", &vm::DRAMCommandEvent::pc)
      .def_ro("slot", &vm::DRAMCommandEvent::slot)
      .def_ro("time_ns", &vm::DRAMCommandEvent::time_ns)
      .def_ro("delta_ns", &vm::DRAMCommandEvent::delta_ns)
      .def_prop_ro("bank", [maybe_optional_int](const vm::DRAMCommandEvent& event) {
        return maybe_optional_int(event.bank);
      })
      .def_prop_ro("row", [maybe_optional_int](const vm::DRAMCommandEvent& event) {
        return maybe_optional_int(event.row);
      })
      .def_prop_ro("column", [maybe_optional_int](const vm::DRAMCommandEvent& event) {
        return maybe_optional_int(event.column);
      })
      .def_prop_ro("rank", [maybe_optional_int](const vm::DRAMCommandEvent& event) {
        return maybe_optional_int(event.rank);
      })
      .def_prop_ro("channel", [maybe_optional_int](const vm::DRAMCommandEvent& event) {
        return maybe_optional_int(event.channel);
      })
      .def_prop_ro("pseudo_channel", [maybe_optional_int](const vm::DRAMCommandEvent& event) {
        return maybe_optional_int(event.pseudo_channel);
      })
      .def_ro("auto_precharge", &vm::DRAMCommandEvent::auto_precharge)
      .def_ro("precharge_all", &vm::DRAMCommandEvent::precharge_all)
      .def("__repr__",
           [](const vm::DRAMCommandEvent& event) {
             return "<DRAMCommandEvent " + event.command +
                    " pc=" + std::to_string(event.pc) +
                    " slot=" + std::to_string(event.slot) + ">";
           });

  nb::class_<vm::DRAMCommandTrace>(m, "DRAMCommandTrace")
      .def_prop_ro("events",
                   [](const vm::DRAMCommandTrace& trace) {
                     return trace.events;
                   })
      .def_ro("truncated", &vm::DRAMCommandTrace::truncated)
      .def_ro("instructions_executed", &vm::DRAMCommandTrace::instructions_executed)
      .def_ro("total_cycles", &vm::DRAMCommandTrace::total_cycles)
      .def_ro("total_ns", &vm::DRAMCommandTrace::total_ns)
      .def("__len__",
           [](const vm::DRAMCommandTrace& trace) {
             return trace.events.size();
           })
      .def("__str__", &vm::format_dram_command_trace)
      .def("__repr__",
           [](const vm::DRAMCommandTrace& trace) {
             return "<DRAMCommandTrace events=" + std::to_string(trace.events.size()) +
                    " truncated=" + std::string(trace.truncated ? "true" : "false") + ">";
           });

  nb::class_<vm::ExecutionResult>(m, "ExecutionResult")
      .def_ro("total_cycles", &vm::ExecutionResult::total_cycles)
      .def_ro("total_ns", &vm::ExecutionResult::total_ns)
      .def_prop_ro("registers",
                   [](const vm::ExecutionResult& result) {
                     return result.registers;
                   })
      .def_prop_ro("dram_cmd_counts",
                   [](const vm::ExecutionResult& result) {
                     nb::dict counts;
                     for (size_t index = 0; index < vm::k_dram_command_names.size(); ++index) {
                       counts[nb::str(vm::k_dram_command_names[index].data())] =
                           nb::int_(result.dram_cmd_counts[index]);
                     }
                     return counts;
                   })
      .def_ro("instructions_executed", &vm::ExecutionResult::instructions_executed)
      .def_ro("branches_taken", &vm::ExecutionResult::branches_taken)
      .def("__str__", &vm::format_execution_result)
      .def("__repr__",
           [](const vm::ExecutionResult& result) {
             return "<ExecutionResult cycles=" + std::to_string(result.total_cycles) +
                    " instructions=" + std::to_string(result.instructions_executed) + ">";
           });

  nb::class_<IBoard>(
      m,
      "Board",
      "Open FPGA board handle. Use it to execute programs, receive readback "
      "data, reset the board, and release the host connection when finished.")
      .def("execute",
           [](IBoard& board, nb::handle programs) {
             if (nb::isinstance<FinalProgram>(programs)) {
               const auto& program = nb::cast<const FinalProgram&>(programs);
               synchronize_interruptibly(board);
               {
                 nb::gil_scoped_release release;
                 board.execute(program);
               }
               recover_if_python_signal_pending(board);
               return;
             }

             if (nb::isinstance<nb::list>(programs) || nb::isinstance<nb::tuple>(programs)) {
               auto program_vec = nb::cast<std::vector<FinalProgram>>(programs);
               for (const FinalProgram& program : program_vec) {
                 synchronize_interruptibly(board);
                 {
                   nb::gil_scoped_release release;
                   board.execute(program);
                 }
                 recover_if_python_signal_pending(board);
               }
               return;
             }

             throw nb::type_error(
                 "execute expects a FinalProgram or a list/tuple of FinalProgram objects.");
           },
           "Send a FinalProgram, or a list/tuple of FinalProgram objects, to "
           "the board. If the program returns data, call receive_into() for "
           "the bytes you expect and synchronize() as a barrier. Ctrl+C is "
           "handled while waiting for prior readback on Python's main thread; "
           "an in-progress host-to-card write must return before the pending "
           "signal can be handled.")
      .def("synchronize",
           [](IBoard& board) {
             synchronize_interruptibly(board);
           },
           "Wait for the active readback session to finish and rethrow any "
           "asynchronous receive error. Does not consume, discard, or drain "
           "queued readback data. On Python's main thread, Ctrl+C performs a "
           "full reset before KeyboardInterrupt is raised.")
      .def("receive_into",
           &receive_into,
           nb::arg("buffer"),
           nb::arg("timeout") = nb::none(),
           "Copy queued readback data into a writable C-contiguous buffer. "
           "The buffer size must be a multiple of four bytes. timeout is an "
           "optional nonnegative number of seconds; None waits without a "
           "deadline, including across long retention intervals. On Python's "
           "main thread, Ctrl+C performs a full reset before KeyboardInterrupt "
           "is raised. A timeout performs a full reset before raising.")
      .def("set_aref",
           [](IBoard& board, bool enabled) {
             nb::gil_scoped_release release;
             board.set_aref(enabled);
           },
           "Enable or disable FPGA-managed DRAM auto-refresh.")
      .def("reset_fpga",
           [](IBoard& board) {
             nb::gil_scoped_release release;
             board.reset_fpga();
           },
           "Send the FPGA reset control packet after normal synchronization. "
           "Use full_reset() for recovery from stale or stuck readback.")
      .def("full_reset",
           [](IBoard& board) {
             nb::gil_scoped_release release;
             board.full_reset();
           },
           "Cancel active readback, reset FPGA logic, drain stale host "
           "readback, and clear queued software readback.")
      .def("close",
           [](IBoard& board) {
             nb::gil_scoped_release release;
             board.close();
           },
           "Release the host connection. After close(), open a new board to "
           "run more programs.")
      .def_prop_ro("is_closed",
                   &IBoard::is_closed,
                   "True after the host connection has been released.")
      .def("__enter__",
           [](IBoard& board) -> IBoard& { return board; },
           nb::rv_policy::reference_internal)
      .def("__exit__",
           [](IBoard& board, nb::args) {
             nb::gil_scoped_release release;
             board.close();
             return false;  // do not suppress exceptions
           });

  nb::class_<DDR4, IBoard>(
      m,
      "DDR4",
      "DDR4-backed DRAM Bender board.")
      .def(nb::init<std::string, int, HostInterface>(),
           nb::arg("pci_bdf"),
           nb::arg("xdma_channel") = 0,
           nb::arg("host_interface") = HostInterface::XDMA);

  nb::class_<HBM2, IBoard>(
      m,
      "HBM2",
      "Shared base for HBM2 boards. Construct HBM2U50 or HBM2U55C.")
      .def("read_temperature",
           [](HBM2& board) {
             nb::gil_scoped_release release;
             return board.read_temperature();
           },
           "Read the current HBM stack temperatures in degrees Celsius.")
      .def("discard_readback_data",
           [](HBM2& board, bool discard) {
             nb::gil_scoped_release release;
             board.discard_readback_data(discard);
           },
           nb::arg("discard"),
           "Enable or disable discarding HBM readback data.")
      .def("set_broadcast_channels",
           [](HBM2& board, const std::vector<int>& channels) {
             nb::gil_scoped_release release;
             board.set_broadcast_channels(channels);
           },
           nb::arg("channels"),
           "Configure the command broadcast channel mask (U55C only).")
      .def("read_power_telemetry",
           [](HBM2& board) {
             nb::gil_scoped_release release;
             return board.read_power_telemetry();
           },
           "Read card power and thermal telemetry from the CMS (U55C only).")
      .def_prop_ro("num_sids", &HBM2::num_sids)
      .def_prop_ro("broadcast_supported", &HBM2::broadcast_supported)
      .def_prop_ro("power_supported", &HBM2::power_supported);

  nb::class_<HBM2U50, HBM2>(
      m,
      "HBM2U50",
      "Alveo U50 HBM2 board: 1 SID, no broadcast, 32 K instructions.")
      .def(nb::init<std::string, int, HostInterface>(),
           nb::arg("pci_bdf"),
           nb::arg("xdma_channel") = 0,
           nb::arg("host_interface") = HostInterface::XDMA);

  nb::class_<HBM2U55C, HBM2>(
      m,
      "HBM2U55C",
      "Alveo U55C HBM2 board: 2 SIDs, broadcast, 128 K instructions.")
      .def(nb::init<std::string, int, HostInterface>(),
           nb::arg("pci_bdf"),
           nb::arg("xdma_channel") = 0,
           nb::arg("host_interface") = HostInterface::XDMA);

  nb::class_<MockBoard, IBoard>(m, "_MockBoard")
      .def(nb::init<int>(), nb::arg("receive_timeout_ms") = 5000)
      .def("start_blocked_receive", &MockBoard::start_blocked_receive)
      .def_prop_ro("drain_count", &MockBoard::drain_count)
      .def("queue_receive_words", &MockBoard::queue_receive_words)
      .def("queue_receive_bytes", &MockBoard::queue_receive_bytes)
      .def("clear_receive_queue", &MockBoard::clear_receive_queue);

  nb::class_<ProgramPlugin>(m, "_ProgramPlugin")
      .def("instantiate", &ProgramPlugin::instantiate);

  m.def("open_board",
        &create_board,
        nb::arg("board_type"),
        nb::arg("pci_bdf"),
        nb::arg("xdma_channel") = 0,
        nb::arg("host_interface") = HostInterface::XDMA,
        "Open a DRAM Bender endpoint selected by complete PCI BDF and XDMA channel.");

  m.def("lower", &lower, nb::arg("ops"));

  m.def("load_program_plugin",
        [](const std::string& plugin_path,
           const std::vector<std::string>& scalar_names,
           const std::vector<std::string>& array_names,
           const std::vector<size_t>& array_lengths) {
          return std::make_unique<ProgramPlugin>(
              plugin_path, scalar_names, array_names, array_lengths);
        },
        nb::arg("plugin_path"),
        nb::arg("scalar_names"),
        nb::arg("array_names"),
        nb::arg("array_lengths"));

  // Instructions submodule — snake_case names for Python usage
  auto instr = m.def_submodule("instructions", "SoftMC instruction builders.");

  // Arithmetic
  instr.def("add", &SMC_ADD, nb::arg("rs1"), nb::arg("rs2"), nb::arg("rt"),
            "rt = rs1 + rs2");
  instr.def("addi", &SMC_ADDI, nb::arg("rs1"), nb::arg("immediate"), nb::arg("rt"),
            "rt = rs1 + immediate");
  instr.def("sub", &SMC_SUB, nb::arg("rs1"), nb::arg("rs2"), nb::arg("rt"),
            "rt = rs1 - rs2");
  instr.def("subi", &SMC_SUBI, nb::arg("rs1"), nb::arg("immediate"), nb::arg("rt"),
            "rt = rs1 - immediate");
  instr.def("li", &SMC_LI, nb::arg("immediate"), nb::arg("rt"),
            "Load 32-bit immediate into register rt.");
  instr.def("mv", &SMC_MV, nb::arg("rs1"), nb::arg("rt"),
            "rt = rs1 (register move).");
  instr.def("src", &SMC_SRC, nb::arg("rs1"), nb::arg("rt"),
            "Shift right circular by 1 bit.");

  // Bitwise
  instr.def("and_", &SMC_AND, nb::arg("rs1"), nb::arg("rs2"), nb::arg("rt"),
            "rt = rs1 & rs2");
  instr.def("or_", &SMC_OR, nb::arg("rs1"), nb::arg("rs2"), nb::arg("rt"),
            "rt = rs1 | rs2");
  instr.def("xor", &SMC_XOR, nb::arg("rs1"), nb::arg("rs2"), nb::arg("rt"),
            "rt = rs1 ^ rs2");

  // Memory
  instr.def("ld", &SMC_LD, nb::arg("rb"), nb::arg("offset"), nb::arg("rt"),
            "Load word from memory: rt = mem[rb + offset].");
  instr.def("st", &SMC_ST, nb::arg("rb"), nb::arg("offset"), nb::arg("rv"),
            "Store word to memory: mem[rb + offset] = rv.");
  instr.def("ldwd", &SMC_LDWD, nb::arg("rs1"), nb::arg("offset"),
            "Load 32-bit word into wide data register at offset.");
  instr.def("ldpc", &SMC_LDPC, nb::arg("pc_type"), nb::arg("rt"),
            "Load performance counter value into rt.");

  // Control flow
  instr.def("bl", &SMC_BL, nb::arg("rs1"), nb::arg("rs2"), nb::arg("target"),
            "Branch if rs1 < rs2.");
  instr.def("beq", &SMC_BEQ, nb::arg("rs1"), nb::arg("rs2"), nb::arg("target"),
            "Branch if rs1 == rs2.");
  instr.def("jump", &SMC_JUMP, nb::arg("target"),
            "Unconditional jump.");
  instr.def("sleep", &SMC_SLEEP, nb::arg("cycles"),
            "Wait for cycles fabric cycles (6 ns each, minimum 3).");
  instr.def("end", &SMC_END,
            "Program terminator.");
  instr.def("info", &SMC_INFO, nb::arg("read_count"),
            "Auto-generated pipeline hint for upcoming reads.");

  // Self-refresh
  instr.def("sre", &SMC_SRE, "Enter self-refresh mode.");
  instr.def("srx", &SMC_SRX, "Exit self-refresh mode.");

  // DDR commands
  instr.def("write", &SMC_WRITE,
            nb::arg("bar"), nb::arg("ibar"), nb::arg("car"),
            nb::arg("icar"), nb::arg("rank"), nb::arg("ap"),
            "Issue a DDR write command.");
  instr.def("read", &SMC_READ,
            nb::arg("bar"), nb::arg("ibar"), nb::arg("car"),
            nb::arg("icar"), nb::arg("rank"), nb::arg("ap"),
            "Issue a DDR read command.");
  instr.def("pre", &SMC_PRE,
            nb::arg("bar"), nb::arg("ibar"), nb::arg("pall"), nb::arg("rank") = 0,
            "Issue a DDR precharge command.");
  instr.def("act", &SMC_ACT,
            nb::arg("bar"), nb::arg("ibar"), nb::arg("rar"),
            nb::arg("irar"), nb::arg("rank") = 0,
            "Issue a DDR activate (open row) command.");
  instr.def("sel_ch", &SMC_SEL_CH,
            nb::arg("channel"), nb::arg("pseudo_channel") = 0,
            "Select HBM channel.");
  instr.def("ref", &SMC_REF, nb::arg("rank") = 0,
            "Issue a refresh command.");
  instr.def("nop", &SMC_NOP, nb::arg("rank") = 0,
            "No-operation command.");
  instr.def("all_nops", &all_nops,
            "Pack four NOP commands into one instruction.");
}
