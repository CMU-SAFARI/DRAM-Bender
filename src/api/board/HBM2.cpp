#include "drambender/api/board/HBM2.h"

#include <array>
#include <stdexcept>
#include <vector>

namespace DRAMBender {

HBM2::HBM2(int board_id, int instance_id, HostInterface host_interface)
    : HBM2(board_id,
           instance_id,
           create_host_interface(host_interface, board_id, instance_id)) {}

HBM2::HBM2(int board_id, int instance_id, std::unique_ptr<IHostInterface> host_interface)
    : IBoard(std::move(host_interface)), m_board_id_(board_id), m_instance_id_(instance_id) {}

HBMTemperature HBM2::read_temperature() {
  synchronize();

  std::array<std::byte, axi_datapath_byte_width> command_packet{};
  command_packet[8] = static_cast<std::byte>(0x10);
  sendControlPacket_(command_packet);

  std::array<std::byte, 512> follow_up_packet{};
  sendControlPacket_(follow_up_packet);

  std::vector<std::byte> recv_buffer(
      static_cast<size_t>(readback_buffer_size()) * axi_datapath_byte_width);
  const size_t recv_count = hostInterface().recv(recv_buffer);
  if (recv_count <= 33) {
    throw std::runtime_error("HBM temperature readback packet is too short.");
  }

  return HBMTemperature{
      .stack0_celsius = std::to_integer<unsigned char>(recv_buffer[32]),
      .stack1_celsius = std::to_integer<unsigned char>(recv_buffer[33]),
  };
}

}  // namespace DRAMBender
