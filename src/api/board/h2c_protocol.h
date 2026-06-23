#ifndef DRAMBENDER_API_BOARD_H2C_PROTOCOL_H
#define DRAMBENDER_API_BOARD_H2C_PROTOCOL_H

#include <cstddef>
#include <span>

#include "drambender/api/board/board.h"

namespace DRAMBender::h2c_protocol {

inline constexpr size_t control_byte_offset = sizeof(Inst_t);

inline constexpr std::byte reset_control{0x01};
inline constexpr std::byte auto_refresh_control{0x08};
inline constexpr std::byte hbm_temperature_control{0x10};
inline constexpr std::byte execute_program_control{0x20};
inline constexpr std::byte hbm_discard_readback_data_control{0x40};
inline constexpr std::byte hbm_broadcast_channels_control{0x80};

inline void set_control(std::span<std::byte> packet, std::byte control) {
  packet[control_byte_offset] = control;
}

}  // namespace DRAMBender::h2c_protocol

#endif  // DRAMBENDER_API_BOARD_H2C_PROTOCOL_H
