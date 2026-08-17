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

/**
 * @brief Per-board HBM2 capabilities.
 *
 * These differ between the Alveo U50 and U55C designs. See HBM2U50 and
 * HBM2U55C for the concrete values.
 */
struct HBM2Capabilities {
  int num_sids;              ///< Number of stack IDs (U50: 1, U55C: 2).
  bool broadcast_supported;  ///< Command broadcast to a channel mask (U55C only).
  int instruction_capacity;  ///< Program instruction buffer depth.
  bool power_supported;      ///< On-card power measurement (U55C only, reserved).
};

/**
 * @brief Shared base for the HBM2 boards. Not constructed directly; use
 * HBM2U50 or HBM2U55C.
 */
class HBM2 : public IBoard {
 public:
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
   * @brief Configure the command broadcast channel mask.
   *
   * Only boards whose capabilities report broadcast support accept this. On a
   * board without broadcast support (U50) it throws.
   */
  void set_broadcast_channels(std::span<const int> channels);
  void set_broadcast_channels(const std::vector<int>& channels);

  int num_sids() const noexcept { return capabilities_.num_sids; }
  bool broadcast_supported() const noexcept { return capabilities_.broadcast_supported; }

 protected:
  HBM2(std::unique_ptr<IHostInterface> host_interface, HBM2Capabilities capabilities);

  const HBM2Capabilities capabilities_;
};

/**
 * @brief Alveo U50 HBM2 board: 1 SID, no command broadcast, 32 K instructions.
 */
class HBM2U50 : public HBM2 {
 public:
  HBM2U50(std::string pci_bdf,
          int xdma_channel = 0,
          HostInterface host_interface = HostInterface::XDMA);

 protected:
  explicit HBM2U50(std::unique_ptr<IHostInterface> host_interface);
};

/**
 * @brief Alveo U55C HBM2 board: 2 SIDs, command broadcast, 128 K instructions.
 */
class HBM2U55C : public HBM2 {
 public:
  HBM2U55C(std::string pci_bdf,
           int xdma_channel = 0,
           HostInterface host_interface = HostInterface::XDMA);

 protected:
  explicit HBM2U55C(std::unique_ptr<IHostInterface> host_interface);
};

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_BOARD_HBM2_H
