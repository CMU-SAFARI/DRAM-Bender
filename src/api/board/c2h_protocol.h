#ifndef DRAMBENDER_API_BOARD_C2H_PROTOCOL_H
#define DRAMBENDER_API_BOARD_C2H_PROTOCOL_H

#include <array>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <stdexcept>

#include "drambender/api/board/board.h"

namespace DRAMBender::c2h_protocol {

inline constexpr uint64_t readback_payload_beats_mask = 0x00000FFFULL;
inline constexpr uint64_t readback_last_mask = uint64_t{1} << 63;

struct ReadbackMetadata {
  size_t payload_bytes;
  bool is_last;
};

inline ReadbackMetadata parse_readback_metadata(
    const std::array<std::byte, axi_datapath_byte_width>& metadata) {
  std::array<uint64_t, axi_datapath_byte_width / sizeof(uint64_t)> words{};
  std::memcpy(words.data(), metadata.data(), metadata.size());

  const bool has_reserved_bits =
      (words[0] & ~readback_payload_beats_mask) != 0 ||
      words[1] != 0 ||
      words[2] != 0 ||
      (words[3] & ~readback_last_mask) != 0;
  if (has_reserved_bits) {
    throw std::runtime_error(
        "Platform readback metadata contains nonzero reserved bits.");
  }

  return ReadbackMetadata{
      .payload_bytes = static_cast<size_t>(words[0] & readback_payload_beats_mask) *
                       axi_datapath_byte_width,
      .is_last = (words[3] & readback_last_mask) != 0,
  };
}

}  // namespace DRAMBender::c2h_protocol

#endif  // DRAMBENDER_API_BOARD_C2H_PROTOCOL_H
