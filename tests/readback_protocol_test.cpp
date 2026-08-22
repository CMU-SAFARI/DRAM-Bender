#include "drambender/api/board/board.h"
#include "drambender/api/host_interface/host_interface.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <exception>
#include <iostream>
#include <memory>
#include <mutex>
#include <random>
#include <span>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "api/host_interface/byte_stream_buffer.h"
#include "drambender/api/program/instruction.h"
#include "drambender/api/program/program.h"

namespace {

using DRAMBender::axi_datapath_byte_width;

std::byte b(uint8_t value) {
  return static_cast<std::byte>(value);
}

std::vector<std::byte> bytes(std::initializer_list<uint8_t> values) {
  std::vector<std::byte> out;
  out.reserve(values.size());
  for (uint8_t value : values) {
    out.push_back(b(value));
  }
  return out;
}

std::vector<std::byte> metadata(size_t payload_bytes, bool is_last) {
  std::array<std::byte, axi_datapath_byte_width> packet{};
  uint64_t beats = payload_bytes / axi_datapath_byte_width;
  if (payload_bytes % axi_datapath_byte_width != 0) {
    throw std::invalid_argument("test metadata payload must be AXI-beat aligned");
  }
  uint64_t flags = is_last ? (uint64_t{1} << 63) : 0;
  std::memcpy(packet.data(), &beats, sizeof(beats));
  std::memcpy(packet.data() + 3 * sizeof(uint64_t), &flags, sizeof(flags));
  return std::vector<std::byte>(packet.begin(), packet.end());
}

std::vector<std::byte> concat(std::initializer_list<std::vector<std::byte>> chunks) {
  std::vector<std::byte> out;
  for (const auto& chunk : chunks) {
    out.insert(out.end(), chunk.begin(), chunk.end());
  }
  return out;
}

class FakeHostInterface : public DRAMBender::IHostInterface {
 public:
  explicit FakeHostInterface(std::vector<std::vector<std::byte>> chunks)
      : chunks_(std::move(chunks)) {}

  void init() override {}
  size_t send(std::span<const std::byte> data) override {
    return data.size();
  }
  void begin_receive() override {
    begin_receive_count_++;
  }
  size_t recv(std::span<std::byte> dst) override {
    if (dst.empty()) {
      return 0;
    }
    while (chunk_index_ < chunks_.size() && byte_index_ == chunks_[chunk_index_].size()) {
      ++chunk_index_;
      byte_index_ = 0;
    }
    if (chunk_index_ >= chunks_.size()) {
      return 0;
    }

    const auto& chunk = chunks_[chunk_index_];
    const size_t count = std::min(dst.size(), chunk.size() - byte_index_);
    std::memcpy(dst.data(), chunk.data() + static_cast<std::ptrdiff_t>(byte_index_), count);
    byte_index_ += count;
    return count;
  }
  void cancel_receive() noexcept override {
    cancel_receive_count_++;
  }
  void drain() override {
    ++drain_count_;
  }

  int begin_receive_count() const noexcept {
    return begin_receive_count_;
  }
  int cancel_receive_count() const noexcept {
    return cancel_receive_count_;
  }
  int drain_count() const noexcept {
    return drain_count_;
  }

 private:
  std::vector<std::vector<std::byte>> chunks_;
  size_t chunk_index_ = 0;
  size_t byte_index_ = 0;
  int begin_receive_count_ = 0;
  int cancel_receive_count_ = 0;
  int drain_count_ = 0;
};

class PacketTestBoard : public DRAMBender::IBoard {
 public:
  explicit PacketTestBoard(std::unique_ptr<DRAMBender::IHostInterface> host)
      : DRAMBender::IBoard(std::move(host),
                           DRAMBender::get_board_config(DRAMBender::BoardType::U200),
                           std::chrono::seconds(5)) {}

  bool expect_packet(const std::vector<std::byte>& payload, bool is_last) {
    const auto packet = receiveReadbackPacket_();
    if (!packet.has_value()) {
      std::cerr << "expected a packet, got end-of-stream\n";
      return false;
    }
    if (packet->is_last != is_last) {
      std::cerr << "packet last flag mismatch\n";
      return false;
    }
    if (packet->payload != payload) {
      std::cerr << "packet payload mismatch: expected " << payload.size()
                << " byte(s), got " << packet->payload.size() << '\n';
      return false;
    }
    return true;
  }

  bool expect_protocol_error(const std::string& expected_message) {
    try {
      (void)receiveReadbackPacket_();
      std::cerr << "expected protocol error, but packet parsing succeeded\n";
      return false;
    } catch (const std::runtime_error& error) {
      if (error.what() != expected_message) {
        std::cerr << "protocol error mismatch: expected '" << expected_message
                  << "', got '" << error.what() << "'\n";
        return false;
      }
    }
    return true;
  }
};

struct BlockingHostState {
  std::mutex mutex;
  std::condition_variable cv;
  std::vector<std::byte> stream;
  size_t read_offset = 0;
  int send_count = 0;
  int begin_receive_count = 0;
  int cancel_receive_count = 0;
  int drain_count = 0;
  bool cancelled = false;
  bool fail_drain = false;
  bool fail_first_send = false;
};

class BlockingHostInterface : public DRAMBender::IHostInterface {
 public:
  explicit BlockingHostInterface(std::shared_ptr<BlockingHostState> state)
      : state_(std::move(state)) {}

  void init() override {}

  size_t send(std::span<const std::byte> data) override {
    std::lock_guard<std::mutex> lock(state_->mutex);
    ++state_->send_count;
    if (state_->fail_first_send && state_->send_count == 1) {
      throw std::runtime_error("injected send failure");
    }
    return data.size();
  }

  void begin_receive() override {
    std::lock_guard<std::mutex> lock(state_->mutex);
    ++state_->begin_receive_count;
    state_->cancelled = false;
  }

  size_t recv(std::span<std::byte> dst) override {
    std::unique_lock<std::mutex> lock(state_->mutex);
    state_->cv.wait(lock, [&] {
      return state_->cancelled || state_->read_offset < state_->stream.size();
    });
    if (state_->cancelled) {
      return 0;
    }

    const size_t count =
        std::min(dst.size_bytes(), state_->stream.size() - state_->read_offset);
    std::memcpy(dst.data(),
                state_->stream.data() +
                    static_cast<std::ptrdiff_t>(state_->read_offset),
                count);
    state_->read_offset += count;
    return count;
  }

  void cancel_receive() noexcept override {
    {
      std::lock_guard<std::mutex> lock(state_->mutex);
      ++state_->cancel_receive_count;
      state_->cancelled = true;
    }
    state_->cv.notify_all();
  }

  void drain() override {
    std::lock_guard<std::mutex> lock(state_->mutex);
    ++state_->drain_count;
    state_->stream.clear();
    state_->read_offset = 0;
    if (state_->fail_drain) {
      throw std::runtime_error("injected drain failure");
    }
  }

 private:
  std::shared_ptr<BlockingHostState> state_;
};

class RecoveryTestBoard : public DRAMBender::IBoard {
 public:
  RecoveryTestBoard(std::shared_ptr<BlockingHostState> state,
                    std::chrono::milliseconds receive_timeout)
      : DRAMBender::IBoard(
            std::make_unique<BlockingHostInterface>(std::move(state)),
            DRAMBender::get_board_config(DRAMBender::BoardType::U200),
            receive_timeout) {}
};

class TestInterruption final {};

DRAMBender::FinalProgram one_nop_program() {
  DRAMBender::Program program;
  program.add_inst(DRAMBender::all_nops());
  return program.conclude();
}

void queue_stream(const std::shared_ptr<BlockingHostState>& state,
                  std::vector<std::byte> stream) {
  {
    std::lock_guard<std::mutex> lock(state->mutex);
    state->stream = std::move(stream);
    state->read_offset = 0;
  }
  state->cv.notify_all();
}

bool verify_board_reuse(RecoveryTestBoard& board,
                        const std::shared_ptr<BlockingHostState>& state) {
  std::vector<std::byte> payload(axi_datapath_byte_width);
  payload[0] = b(0x78);
  payload[1] = b(0x56);
  payload[2] = b(0x34);
  payload[3] = b(0x12);
  queue_stream(state, concat({metadata(payload.size(), true), payload}));

  board.execute(one_nop_program());
  std::array<std::byte, sizeof(uint32_t)> observed{};
  if (board.receive(observed) != observed.size()) {
    std::cerr << "reused board returned a short read\n";
    return false;
  }
  board.synchronize();
  if (observed[0] != b(0x78) || observed[1] != b(0x56) ||
      observed[2] != b(0x34) || observed[3] != b(0x12)) {
    std::cerr << "reused board returned incorrect data\n";
    return false;
  }
  return true;
}

bool test_byte_stream_buffer_preserves_unused_bytes() {
  DRAMBender::host_interface_internal::ByteStreamBuffer buffer;
  std::vector<std::byte> chunk(4096);
  for (size_t index = 0; index < chunk.size(); ++index) {
    chunk[index] = b(static_cast<uint8_t>(index & 0xffU));
  }

  std::array<std::byte, 32> first{};
  std::array<std::byte, 16> second{};
  if (buffer.copyPrefixAndBufferSurplus(chunk, first) != first.size()) {
    std::cerr << "failed to deliver the direct prefix\n";
    return false;
  }
  if (buffer.pending() != chunk.size() - first.size()) {
    std::cerr << "pending count mismatch after first logical read\n";
    return false;
  }
  if (buffer.read(second) != second.size()) {
    std::cerr << "failed to read second logical chunk\n";
    return false;
  }

  for (size_t index = 0; index < first.size(); ++index) {
    if (first[index] != chunk[index]) {
      std::cerr << "first logical read data mismatch\n";
      return false;
    }
  }
  for (size_t index = 0; index < second.size(); ++index) {
    if (second[index] != chunk[first.size() + index]) {
      std::cerr << "second logical read data mismatch\n";
      return false;
    }
  }

  buffer.clear();
  std::array<std::byte, 64> larger_dst{};
  larger_dst.fill(b(0xa5));
  constexpr size_t short_count = 17;
  if (buffer.copyPrefixAndBufferSurplus(
          std::span<const std::byte>(chunk).first(short_count),
          larger_dst) != short_count ||
      buffer.pending() != 0) {
    std::cerr << "short direct prefix left unexpected surplus\n";
    return false;
  }
  for (size_t index = 0; index < short_count; ++index) {
    if (larger_dst[index] != chunk[index]) {
      std::cerr << "short direct prefix data mismatch\n";
      return false;
    }
  }
  for (size_t index = short_count; index < larger_dst.size(); ++index) {
    if (larger_dst[index] != b(0xa5)) {
      std::cerr << "short direct prefix overwrote the destination tail\n";
      return false;
    }
  }
  return true;
}

bool test_metadata_split_across_recv_calls() {
  const auto payload = bytes({
      0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
      0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
      0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
      0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
  });
  const auto meta = metadata(payload.size(), true);
  std::vector<std::vector<std::byte>> chunks = {
      std::vector<std::byte>(meta.begin(), meta.begin() + 7),
      std::vector<std::byte>(meta.begin() + 7, meta.end()),
      std::vector<std::byte>(payload.begin(), payload.begin() + 5),
      std::vector<std::byte>(payload.begin() + 5, payload.end()),
  };

  PacketTestBoard board(std::make_unique<FakeHostInterface>(std::move(chunks)));
  return board.expect_packet(payload, true);
}

bool test_metadata_randomized_fragmentation() {
  std::mt19937 generator(0x44525631U);
  std::uniform_int_distribution<size_t> beat_count_distribution(1, 16);
  std::uniform_int_distribution<size_t> chunk_size_distribution(1, 97);
  std::uniform_int_distribution<unsigned int> byte_distribution(0, 255);

  for (size_t iteration = 0; iteration < 2'000; ++iteration) {
    std::vector<std::byte> payload(
        beat_count_distribution(generator) * axi_datapath_byte_width);
    for (std::byte& value : payload) {
      value = b(static_cast<uint8_t>(byte_distribution(generator)));
    }

    const auto stream = concat({metadata(payload.size(), true), payload});
    std::vector<std::vector<std::byte>> chunks;
    for (size_t offset = 0; offset < stream.size();) {
      const size_t chunk_size =
          std::min(chunk_size_distribution(generator), stream.size() - offset);
      chunks.emplace_back(stream.begin() + static_cast<std::ptrdiff_t>(offset),
                          stream.begin() +
                              static_cast<std::ptrdiff_t>(offset + chunk_size));
      offset += chunk_size;
    }

    PacketTestBoard board(
        std::make_unique<FakeHostInterface>(std::move(chunks)));
    if (!board.expect_packet(payload, true)) {
      std::cerr << "randomized fragmentation failed at iteration " << iteration
                << '\n';
      return false;
    }
  }
  return true;
}

bool test_board_consumes_metadata_packets_by_default() {
  const auto payload = bytes({
      0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
      0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
      0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
      0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
  });
  auto stream = concat({metadata(payload.size(), false),
                        payload,
                        metadata(0, true)});
  PacketTestBoard board(std::make_unique<FakeHostInterface>(
      std::vector<std::vector<std::byte>>{std::move(stream)}));

  DRAMBender::Program program;
  program.add_inst(DRAMBender::all_nops());
  board.execute(program.conclude());

  std::vector<std::byte> observed(payload.size());
  if (board.receive(observed) != observed.size()) {
    std::cerr << "metadata receive returned an unexpected byte count\n";
    return false;
  }
  board.synchronize();

  if (observed != payload) {
    std::cerr << "metadata payload mismatch\n";
    return false;
  }
  return true;
}

bool test_receive_queue_preserves_partial_data_across_sessions() {
  std::vector<std::byte> first_payload(4 * axi_datapath_byte_width);
  std::vector<std::byte> second_payload(3 * axi_datapath_byte_width);
  for (size_t index = 0; index < first_payload.size(); ++index) {
    first_payload[index] = b(static_cast<uint8_t>((index * 17U + 3U) & 0xffU));
  }
  for (size_t index = 0; index < second_payload.size(); ++index) {
    second_payload[index] =
        b(static_cast<uint8_t>((index * 29U + 0x51U) & 0xffU));
  }

  auto first_stream =
      concat({metadata(first_payload.size(), true), first_payload});
  auto second_stream = concat({
      metadata(axi_datapath_byte_width, false),
      std::vector<std::byte>(
          second_payload.begin(),
          second_payload.begin() +
              static_cast<std::ptrdiff_t>(axi_datapath_byte_width)),
      metadata(axi_datapath_byte_width, false),
      std::vector<std::byte>(
          second_payload.begin() +
              static_cast<std::ptrdiff_t>(axi_datapath_byte_width),
          second_payload.begin() +
              static_cast<std::ptrdiff_t>(2 * axi_datapath_byte_width)),
      metadata(axi_datapath_byte_width, true),
      std::vector<std::byte>(
          second_payload.begin() +
              static_cast<std::ptrdiff_t>(2 * axi_datapath_byte_width),
          second_payload.end()),
  });

  PacketTestBoard board(std::make_unique<FakeHostInterface>(
      std::vector<std::vector<std::byte>>{
          std::move(first_stream),
          std::move(second_stream),
      }));

  board.execute(one_nop_program());
  board.synchronize();

  std::array<std::byte, 3 * axi_datapath_byte_width> first_observed{};
  if (board.receive(first_observed) != first_observed.size() ||
      !std::equal(first_observed.begin(),
                  first_observed.end(),
                  first_payload.begin())) {
    std::cerr << "partial receive from first session returned incorrect data\n";
    return false;
  }

  // The unread final beat from the first session must remain at the front of
  // the queue while three packets from the second session are appended.
  board.execute(one_nop_program());
  board.synchronize();

  std::vector<std::byte> expected(
      first_payload.begin() +
          static_cast<std::ptrdiff_t>(3 * axi_datapath_byte_width),
      first_payload.end());
  expected.insert(expected.end(), second_payload.begin(), second_payload.end());

  std::array<std::byte, 52> observed_prefix{};
  std::array<std::byte, 76> observed_suffix{};
  if (board.receive(observed_prefix) != observed_prefix.size() ||
      board.receive(observed_suffix) != observed_suffix.size()) {
    std::cerr << "cross-session receive returned an unexpected byte count\n";
    return false;
  }

  std::vector<std::byte> observed(observed_prefix.begin(), observed_prefix.end());
  observed.insert(observed.end(), observed_suffix.begin(), observed_suffix.end());
  if (observed != expected) {
    std::cerr << "partial cross-packet receive reordered or lost queued data\n";
    return false;
  }
  return true;
}

bool test_receive_queue_bulk_copies_large_multi_packet_payload() {
  constexpr size_t packet_bytes = 64 * 1024;
  constexpr size_t packet_count = 8;
  constexpr size_t total_bytes = packet_bytes * packet_count;

  std::vector<std::byte> expected(total_bytes);
  for (size_t index = 0; index < expected.size(); ++index) {
    expected[index] =
        b(static_cast<uint8_t>((index * 37U + (index >> 8U) + 0x29U) & 0xffU));
  }

  std::vector<std::byte> stream;
  stream.reserve(total_bytes + packet_count * axi_datapath_byte_width);
  for (size_t packet_index = 0; packet_index < packet_count; ++packet_index) {
    const auto meta = metadata(packet_bytes, packet_index + 1 == packet_count);
    stream.insert(stream.end(), meta.begin(), meta.end());
    const auto payload_begin =
        expected.begin() + static_cast<std::ptrdiff_t>(packet_index * packet_bytes);
    stream.insert(stream.end(),
                  payload_begin,
                  payload_begin + static_cast<std::ptrdiff_t>(packet_bytes));
  }

  PacketTestBoard board(std::make_unique<FakeHostInterface>(
      std::vector<std::vector<std::byte>>{std::move(stream)}));
  board.execute(one_nop_program());

  std::vector<std::byte> observed(total_bytes);
  if (board.receive(observed) != observed.size()) {
    std::cerr << "large receive returned an unexpected byte count\n";
    return false;
  }
  board.synchronize();
  if (observed != expected) {
    std::cerr << "large multi-packet receive reordered or lost data\n";
    return false;
  }
  return true;
}

bool test_driver_sized_chunk_parses_as_metadata_packet() {
  const auto payload = bytes({
      0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
      0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
      0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
      0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
  });
  auto page = concat({metadata(payload.size(), true), payload});
  page.resize(4096, std::byte{0});

  PacketTestBoard board(std::make_unique<FakeHostInterface>(
      std::vector<std::vector<std::byte>>{std::move(page)}));
  return board.expect_packet(payload, true);
}

bool test_empty_nonlast_metadata_is_malformed() {
  PacketTestBoard board(std::make_unique<FakeHostInterface>(
      std::vector<std::vector<std::byte>>{metadata(0, false)}));
  return board.expect_protocol_error(
      "Board readback metadata declares an empty non-final packet.");
}

bool test_empty_last_metadata_remains_valid_packet() {
  PacketTestBoard board(std::make_unique<FakeHostInterface>(
      std::vector<std::vector<std::byte>>{metadata(0, true)}));
  return board.expect_packet({}, true);
}

bool test_reserved_metadata_bits_are_malformed() {
  auto packet = metadata(axi_datapath_byte_width, true);
  packet[2] = b(0x80);

  PacketTestBoard board(std::make_unique<FakeHostInterface>(
      std::vector<std::vector<std::byte>>{std::move(packet)}));
  return board.expect_protocol_error(
      "Board readback metadata contains nonzero reserved bits.");
}

bool test_receive_timeout_full_resets_and_board_is_reusable() {
  auto state = std::make_shared<BlockingHostState>();
  RecoveryTestBoard board(state, std::chrono::milliseconds(30));
  board.execute(one_nop_program());

  std::array<std::byte, sizeof(uint32_t)> observed{};
  try {
    (void)board.receive(observed, std::chrono::milliseconds(30));
    std::cerr << "expected receive timeout\n";
    return false;
  } catch (const std::runtime_error& error) {
    if (std::string(error.what()) !=
        "Timed out while waiting for readback data from the board.") {
      std::cerr << "unexpected receive timeout error: " << error.what() << '\n';
      return false;
    }
  }

  {
    std::lock_guard<std::mutex> lock(state->mutex);
    if (state->cancel_receive_count != 1 || state->drain_count != 1 ||
        state->send_count != 2) {
      std::cerr << "receive timeout did not perform exactly one full reset\n";
      return false;
    }
  }
  return verify_board_reuse(board, state);
}

bool test_unbounded_receive_waits_past_configured_control_timeout() {
  auto state = std::make_shared<BlockingHostState>();
  RecoveryTestBoard board(state, std::chrono::milliseconds(30));
  board.execute(one_nop_program());

  std::thread producer([state] {
    std::this_thread::sleep_for(std::chrono::milliseconds(75));
    std::vector<std::byte> payload(axi_datapath_byte_width);
    payload[0] = b(0xef);
    payload[1] = b(0xbe);
    payload[2] = b(0xad);
    payload[3] = b(0xde);
    queue_stream(state, concat({metadata(payload.size(), true), payload}));
  });

  bool ok = true;
  try {
    std::array<std::byte, sizeof(uint32_t)> observed{};
    (void)board.receive(observed);
    board.synchronize();
    if (observed[0] != b(0xef) || observed[1] != b(0xbe) ||
        observed[2] != b(0xad) || observed[3] != b(0xde)) {
      std::cerr << "unbounded receive returned incorrect delayed data\n";
      ok = false;
    }
  } catch (const std::exception& error) {
    std::cerr << "unbounded receive unexpectedly failed: " << error.what() << '\n';
    ok = false;
  }
  producer.join();

  {
    std::lock_guard<std::mutex> lock(state->mutex);
    if (state->cancel_receive_count != 0 || state->drain_count != 0) {
      std::cerr << "unbounded delayed receive unexpectedly reset the board\n";
      ok = false;
    }
  }
  return ok;
}

bool test_huge_receive_timeout_saturates_instead_of_wrapping() {
  auto state = std::make_shared<BlockingHostState>();
  RecoveryTestBoard board(state, std::chrono::milliseconds(30));
  board.execute(one_nop_program());

  std::thread producer([state] {
    std::this_thread::sleep_for(std::chrono::milliseconds(75));
    std::vector<std::byte> payload(axi_datapath_byte_width);
    payload[0] = b(0x04);
    payload[1] = b(0x03);
    payload[2] = b(0x02);
    payload[3] = b(0x01);
    queue_stream(state, concat({metadata(payload.size(), true), payload}));
  });

  bool ok = true;
  try {
    std::array<std::byte, sizeof(uint32_t)> observed{};
    (void)board.receive(observed, std::chrono::milliseconds::max());
    board.synchronize();
    if (observed[0] != b(0x04) || observed[1] != b(0x03) ||
        observed[2] != b(0x02) || observed[3] != b(0x01)) {
      std::cerr << "huge-timeout receive returned incorrect delayed data\n";
      ok = false;
    }
  } catch (const std::exception& error) {
    std::cerr << "huge-timeout receive unexpectedly failed: " << error.what()
              << '\n';
    ok = false;
  }
  producer.join();

  {
    std::lock_guard<std::mutex> lock(state->mutex);
    if (state->cancel_receive_count != 0 || state->drain_count != 0) {
      std::cerr << "huge-timeout receive unexpectedly reset the board\n";
      ok = false;
    }
  }
  return ok;
}

bool test_interrupted_synchronize_full_resets_and_board_is_reusable() {
  auto state = std::make_shared<BlockingHostState>();
  RecoveryTestBoard board(state, std::chrono::seconds(5));
  board.execute(one_nop_program());

  int interruption_checks = 0;
  try {
    board.synchronize_interruptibly([&] {
      ++interruption_checks;
      throw TestInterruption{};
    });
    std::cerr << "expected synchronization interruption\n";
    return false;
  } catch (const TestInterruption&) {
  }

  if (interruption_checks != 1) {
    std::cerr << "unexpected number of synchronization interruption checks\n";
    return false;
  }
  {
    std::lock_guard<std::mutex> lock(state->mutex);
    if (state->cancel_receive_count != 1 || state->drain_count != 1 ||
        state->send_count != 2) {
      std::cerr << "interrupted synchronization did not perform one full reset\n";
      return false;
    }
  }
  return verify_board_reuse(board, state);
}

bool test_protocol_error_full_resets_and_board_is_reusable() {
  auto state = std::make_shared<BlockingHostState>();
  RecoveryTestBoard board(state, std::chrono::seconds(5));
  queue_stream(state, metadata(0, false));
  board.execute(one_nop_program());

  try {
    board.synchronize();
    std::cerr << "expected malformed-metadata error\n";
    return false;
  } catch (const std::runtime_error& error) {
    if (std::string(error.what()) !=
        "Board readback metadata declares an empty non-final packet.") {
      std::cerr << "unexpected malformed-metadata error: " << error.what()
                << '\n';
      return false;
    }
  }

  {
    std::lock_guard<std::mutex> lock(state->mutex);
    if (state->cancel_receive_count != 1 || state->drain_count != 1 ||
        state->send_count != 2) {
      std::cerr << "protocol error did not perform exactly one full reset\n";
      return false;
    }
  }
  return verify_board_reuse(board, state);
}

bool test_send_error_full_resets_and_board_is_reusable() {
  auto state = std::make_shared<BlockingHostState>();
  state->fail_first_send = true;
  RecoveryTestBoard board(state, std::chrono::seconds(5));

  try {
    board.execute(one_nop_program());
    std::cerr << "expected injected send failure\n";
    return false;
  } catch (const std::runtime_error& error) {
    if (std::string(error.what()) != "injected send failure") {
      std::cerr << "send recovery masked the original error: " << error.what()
                << '\n';
      return false;
    }
  }

  {
    std::lock_guard<std::mutex> lock(state->mutex);
    if (state->cancel_receive_count != 1 || state->drain_count != 1 ||
        state->send_count != 2) {
      std::cerr << "send failure did not perform exactly one full reset\n";
      return false;
    }
  }
  return verify_board_reuse(board, state);
}

bool test_failed_automatic_reset_closes_board_and_preserves_timeout() {
  auto state = std::make_shared<BlockingHostState>();
  state->fail_drain = true;
  RecoveryTestBoard board(state, std::chrono::milliseconds(30));
  board.execute(one_nop_program());

  std::array<std::byte, sizeof(uint32_t)> observed{};
  try {
    (void)board.receive(observed, std::chrono::milliseconds(30));
    std::cerr << "expected receive timeout with injected recovery failure\n";
    return false;
  } catch (const std::runtime_error& error) {
    if (std::string(error.what()) !=
        "Timed out while waiting for readback data from the board.") {
      std::cerr << "recovery failure masked the original timeout: "
                << error.what() << '\n';
      return false;
    }
  }

  if (!board.is_closed()) {
    std::cerr << "board remained open after automatic full_reset failed\n";
    return false;
  }
  return true;
}

}  // namespace

int main() {
  bool ok = true;
  ok &= test_byte_stream_buffer_preserves_unused_bytes();
  ok &= test_metadata_split_across_recv_calls();
  ok &= test_metadata_randomized_fragmentation();
  ok &= test_board_consumes_metadata_packets_by_default();
  ok &= test_receive_queue_preserves_partial_data_across_sessions();
  ok &= test_receive_queue_bulk_copies_large_multi_packet_payload();
  ok &= test_driver_sized_chunk_parses_as_metadata_packet();
  ok &= test_empty_nonlast_metadata_is_malformed();
  ok &= test_empty_last_metadata_remains_valid_packet();
  ok &= test_reserved_metadata_bits_are_malformed();
  ok &= test_receive_timeout_full_resets_and_board_is_reusable();
  ok &= test_unbounded_receive_waits_past_configured_control_timeout();
  ok &= test_huge_receive_timeout_saturates_instead_of_wrapping();
  ok &= test_interrupted_synchronize_full_resets_and_board_is_reusable();
  ok &= test_protocol_error_full_resets_and_board_is_reusable();
  ok &= test_send_error_full_resets_and_board_is_reusable();
  ok &= test_failed_automatic_reset_closes_board_and_preserves_timeout();
  return ok ? 0 : 1;
}
