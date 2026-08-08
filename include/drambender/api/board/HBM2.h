#ifndef DRAMBENDER_API_BOARD_HBM2_H
#define DRAMBENDER_API_BOARD_HBM2_H

#include <memory>
#include <span>
#include <string>
#include <vector>

#include "drambender/api/board/board.h"

namespace DRAMBender {

struct HBMTemperature {
  int stack0_celsius;
  int stack1_celsius;
};

class HBM2 : public IBoard {
 public:
  HBM2(std::string pci_bdf,
       int xdma_channel = 0,
       HostInterface host_interface = HostInterface::XDMA);

  /**
   * @brief Read the current HBM stack temperatures in degrees Celsius.
   */
  HBMTemperature read_temperature();

  /**
   * @brief Enable or disable discarding HBM readback data.
   *
   * This is useful for workloads that issue reads for DRAM-side activity but
   * do not need the returned data on the host.
   */
  void discard_readback_data(bool discard);

  /**
   * @brief Configure the optional HBM command broadcast channel mask.
   */
  void set_broadcast_channels(std::span<const int> channels);
  void set_broadcast_channels(const std::vector<int>& channels);

 protected:
  explicit HBM2(std::unique_ptr<IHostInterface> host_interface);
};

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_BOARD_HBM2_H
