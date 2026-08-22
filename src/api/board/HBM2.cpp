#include "drambender/api/board/HBM2.h"

#include <array>
#include <condition_variable>
#include <cstdint>
#include <cstring>
#include <exception>
#include <mutex>
#include <optional>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include "cms_monitor.h"
#include "h2c_protocol.h"

namespace DRAMBender {

HBM2::HBM2(std::unique_ptr<IHostInterface> host_interface,
           const BoardConfig& board_config,
           std::unique_ptr<CmsMonitor> monitor)
    : IBoard(std::move(host_interface), board_config),
      monitor_(std::move(monitor)) {}

HBM2::~HBM2() = default;

HBM2U50::HBM2U50(std::string pci_bdf, int xdma_channel, HostInterface host_interface)
    : HBM2U50(create_host_interface(host_interface, pci_bdf, xdma_channel)) {
  reportOpen_(pci_bdf, xdma_channel, host_interface);
}

HBM2U50::HBM2U50(std::unique_ptr<IHostInterface> host_interface)
    : HBM2(std::move(host_interface), get_board_config(BoardType::U50)) {}

HBM2U55C::HBM2U55C(std::string pci_bdf, int xdma_channel, HostInterface host_interface)
    // U55C supports power telemetry, so build a CMS monitor from the PCI BDF.
    // pci_bdf is copied (not moved) so both the host interface and the monitor
    // get it.
    : HBM2(create_host_interface(host_interface, pci_bdf, xdma_channel),
           get_board_config(BoardType::U55C),
           std::make_unique<CmsMonitor>(pci_bdf, xdma_channel)) {
  reportOpen_(pci_bdf, xdma_channel, host_interface);
}

HBM2U55C::HBM2U55C(std::unique_ptr<IHostInterface> host_interface)
    : HBM2(std::move(host_interface), get_board_config(BoardType::U55C)) {}

PowerTelemetry HBM2::read_power_telemetry() {
  if (!board_config().power_telemetry_supported) {
    throw std::runtime_error("This HBM2 board does not support power telemetry.");
  }
  if (!monitor_) {
    throw std::runtime_error(
        "Power telemetry requires a board opened through an XDMA endpoint.");
  }
  return monitor_->read();
}

HBMTemperature HBM2::read_temperature() {
  synchronize();

  std::array<std::byte, axi_datapath_byte_width> command_packet{};
  h2c_protocol::set_control(command_packet, h2c_protocol::hbm_temperature_control);

  std::array<std::byte, 512> follow_up_packet{};

  std::optional<ReadbackPacket> packet;
  std::exception_ptr receiver_exception = nullptr;
  bool receive_done = false;
  std::mutex receive_mutex;
  std::condition_variable receive_cv;

  hostInterface().begin_receive();
  std::thread receiver([&] {
    std::optional<ReadbackPacket> local_packet;
    std::exception_ptr local_exception = nullptr;
    try {
      local_packet = receiveReadbackPacket_();
    } catch (...) {
      local_exception = std::current_exception();
    }

    {
      std::lock_guard<std::mutex> lock(receive_mutex);
      packet = std::move(local_packet);
      receiver_exception = local_exception;
      receive_done = true;
    }
    receive_cv.notify_one();
  });

  try {
    sendControlPacketRaw_(command_packet);
    sendControlPacketRaw_(follow_up_packet);
  } catch (...) {
    hostInterface().cancel_receive();
    receiver.join();
    throw;
  }

  bool timed_out = false;
  {
    std::unique_lock<std::mutex> lock(receive_mutex);
    timed_out = !receive_cv.wait_for(lock, receive_timeout_, [&] { return receive_done; });
  }
  if (timed_out) {
    hostInterface().cancel_receive();
  }
  receiver.join();

  if (timed_out) {
    throw std::runtime_error("Timed out while waiting for HBM temperature readback.");
  }
  if (receiver_exception) {
    std::rethrow_exception(receiver_exception);
  }
  if (!packet.has_value()) {
    throw std::runtime_error("HBM temperature readback did not return a packet.");
  }
  if (packet->payload.size() <= 33) {
    throw std::runtime_error(
        "HBM temperature payload is too short: received " +
        std::to_string(packet->payload.size()) + " byte(s), need at least 34.");
  }

  return HBMTemperature{
      .stack0_celsius = std::to_integer<unsigned char>(packet->payload[32]),
      .stack1_celsius = std::to_integer<unsigned char>(packet->payload[33]),
  };
}

void HBM2::discard_readback_data(bool discard) {
  std::array<std::byte, axi_datapath_byte_width> command_packet{};
  h2c_protocol::set_control(command_packet, h2c_protocol::hbm_discard_readback_data_control);
  command_packet[0] = static_cast<std::byte>(discard ? 1 : 0);
  sendControlPacket_(command_packet);
}

void HBM2::set_broadcast_channels(std::span<const int> channels) {
  if (!board_config().broadcast_supported) {
    throw std::runtime_error(
        "This HBM2 board does not support command broadcast. Select a single "
        "channel with SEL_CH instead.");
  }

  const size_t channel_count = board_config().hbm_channel_count;
  uint32_t channel_mask = 0;
  for (int channel : channels) {
    if (channel < 0 || static_cast<size_t>(channel) >= channel_count) {
      throw std::invalid_argument(
          "HBM2 broadcast channel must be in range 0.." +
          std::to_string(channel_count - 1) + ".");
    }
    channel_mask |= (uint32_t{1} << static_cast<unsigned>(channel));
  }

  std::array<std::byte, axi_datapath_byte_width> command_packet{};
  h2c_protocol::set_control(command_packet, h2c_protocol::hbm_broadcast_channels_control);
  std::memcpy(command_packet.data(), &channel_mask, sizeof(channel_mask));
  sendControlPacket_(command_packet);
}

void HBM2::set_broadcast_channels(const std::vector<int>& channels) {
  set_broadcast_channels(std::span<const int>(channels.data(), channels.size()));
}

}  // namespace DRAMBender
