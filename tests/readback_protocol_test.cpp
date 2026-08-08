#include "drambender/api/board/board.h"
#include "drambender/api/host_interface/host_interface.h"

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <exception>
#include <iostream>
#include <memory>
#include <span>
#include <stdexcept>
#include <string>
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
  void cancel_receive() override {
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
                           2048,
                           1024,
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

bool test_byte_stream_buffer_preserves_unused_bytes() {
  DRAMBender::host_interface_internal::ByteStreamBuffer buffer;
  std::vector<std::byte> chunk(4096);
  for (size_t index = 0; index < chunk.size(); ++index) {
    chunk[index] = b(static_cast<uint8_t>(index & 0xffU));
  }

  buffer.append(chunk);
  std::array<std::byte, 32> first{};
  std::array<std::byte, 16> second{};
  if (buffer.read(first) != first.size()) {
    std::cerr << "failed to read first logical chunk\n";
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
      "Platform readback metadata declares an empty non-final packet.");
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
      "Platform readback metadata contains nonzero reserved bits.");
}

}  // namespace

int main() {
  bool ok = true;
  ok &= test_byte_stream_buffer_preserves_unused_bytes();
  ok &= test_metadata_split_across_recv_calls();
  ok &= test_board_consumes_metadata_packets_by_default();
  ok &= test_driver_sized_chunk_parses_as_metadata_packet();
  ok &= test_empty_nonlast_metadata_is_malformed();
  ok &= test_empty_last_metadata_remains_valid_packet();
  ok &= test_reserved_metadata_bits_are_malformed();
  return ok ? 0 : 1;
}
