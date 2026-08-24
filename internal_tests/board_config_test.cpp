#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <memory>
#include <span>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#include "api/board/cms_monitor.h"
#include "drambender/api/board/HBM2.h"
#include "drambender/api/board/board_config.h"
#include "drambender/api/host_interface/host_interface.h"

namespace {

void require(bool condition, const char* message) {
  if (!condition) {
    throw std::runtime_error(message);
  }
}

bool close_enough(double lhs, double rhs) {
  return std::abs(lhs - rhs) < 1e-12;
}

class RecordingHostInterface : public DRAMBender::IHostInterface {
 public:
  void init() override {}

  size_t send(std::span<const std::byte> data) override {
    last_send.assign(data.begin(), data.end());
    return data.size();
  }

  size_t recv(std::span<std::byte>) override { return 0; }
  void drain() override {}

  std::vector<std::byte> last_send;
};

class ConfiguredHBM2 : public DRAMBender::HBM2 {
 public:
  ConfiguredHBM2(std::unique_ptr<DRAMBender::IHostInterface> host_interface,
                 const DRAMBender::BoardConfig& board_config)
      : HBM2(std::move(host_interface), board_config) {}
};

void test_broadcast_channel_bound_comes_from_config() {
  static constexpr DRAMBender::BoardConfig four_channel_config{
      .name = "four-channel-test",
      .board_type = DRAMBender::BoardType::U55C,
      .memory_type = DRAMBender::MemoryType::HBM2,
      .instruction_capacity = 16,
      .dram_command_slot_ns = 5.0 / 3.0,
      .dram_slots_per_fabric_cycle = 4,
      .readback_buffer_capacity = 16,
      .hbm_channel_count = 4,
      .hbm_pseudo_channel_count = 2,
      .hbm_sid_count = 1,
      .broadcast_supported = true,
      .power_telemetry_supported = false,
  };

  auto host = std::make_unique<RecordingHostInterface>();
  RecordingHostInterface* const host_view = host.get();
  ConfiguredHBM2 board(std::move(host), four_channel_config);
  require(&board.board_config() == &four_channel_config,
          "board did not retain its selected configuration");

  bool oversized_rejected = false;
  try {
    board.execute(DRAMBender::FinalProgram(
        std::vector<DRAMBender::Inst>(
            four_channel_config.instruction_capacity + 1)));
  } catch (const std::invalid_argument& error) {
    const std::string message = error.what();
    oversized_rejected =
        message.find(four_channel_config.name) != std::string::npos &&
        message.find(std::to_string(four_channel_config.instruction_capacity)) !=
            std::string::npos;
  }
  require(oversized_rejected,
          "program capacity validation did not use the board configuration");

  board.set_broadcast_channels(std::vector<int>{0, 3});
  require(host_view->last_send.size() >= sizeof(uint32_t),
          "broadcast command packet was not sent");
  uint32_t channel_mask = 0;
  std::memcpy(&channel_mask, host_view->last_send.data(), sizeof(channel_mask));
  require(channel_mask == 0b1001,
          "broadcast command did not encode configured channels");

  bool rejected = false;
  try {
    board.set_broadcast_channels(std::vector<int>{4});
  } catch (const std::invalid_argument& error) {
    rejected = std::string(error.what()).find("0..3") != std::string::npos;
  }
  require(rejected,
          "broadcast channel validation did not use the configured channel count");
}

}  // namespace

int main() {
  using namespace DRAMBender;

  const BoardConfig& u200 = get_board_config(BoardType::U200);
  require(u200.name == "U200", "unexpected U200 name");
  require(u200.memory_type == MemoryType::DDR4, "U200 must use DDR4");
  require(u200.instruction_capacity == 32768, "unexpected U200 instruction capacity");
  require(close_enough(u200.dram_command_slot_ns, 1.5), "unexpected U200 command slot");
  require(u200.summary().find("6.000000 ns") != std::string::npos,
          "U200 summary should show its derived fabric cycle");
  require(u200.summary().find("HBM channels") == std::string::npos,
          "DDR4 summary should not print HBM-only fields");

  const BoardConfig& u50 = get_board_config(BoardType::U50);
  require(u50.memory_type == MemoryType::HBM2, "U50 must use HBM2");
  require(u50.instruction_capacity == 32768,
          "unexpected U50 instruction capacity");
  require(close_enough(u50.dram_command_slot_ns, 5.0 / 3.0),
          "unexpected U50 command slot");
  require(u50.hbm_channel_count == 16, "unexpected U50 HBM channel count");
  require(u50.hbm_sid_count == 1, "unexpected U50 SID count");
  require(!u50.broadcast_supported, "U50 must not advertise broadcast");

  const BoardConfig& u55c = get_board_config(BoardType::U55C);
  require(u55c.instruction_capacity == 131072,
          "unexpected U55C instruction capacity");
  require(u55c.hbm_sid_count == 2, "unexpected U55C SID count");
  require(u55c.broadcast_supported, "U55C must advertise broadcast");
  require(u55c.power_telemetry_supported,
          "U55C must advertise power telemetry");

  for (const BoardConfig* config : {&u200, &u50, &u55c}) {
    require(config->dram_slots_per_fabric_cycle == 4,
            "unexpected DRAM slots per fabric cycle");
    require(config->readback_buffer_capacity == 1024,
            "unexpected readback buffer capacity");
    require(&get_board_config(config->board_type) == config,
            "board registry must return stable built-in objects");
  }

  bool rejected = false;
  try {
    static_cast<void>(get_board_config(static_cast<BoardType>(99)));
  } catch (const std::invalid_argument&) {
    rejected = true;
  }
  require(rejected, "invalid board type should be rejected");

  test_broadcast_channel_bound_comes_from_config();

  std::cout << "board_config_test: PASS\n";
  return 0;
}
