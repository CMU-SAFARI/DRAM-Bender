#ifndef DRAMBENDER_API_BOARD_HBM2_H
#define DRAMBENDER_API_BOARD_HBM2_H

#include <cstdint>
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
 * @brief Instantaneous / maximum / average value of one sensor.
 *
 * Stored as 64-bit so derived power (millivolts * milliamps) cannot overflow.
 */
struct SensorStat {
  uint64_t instant;
  uint64_t max;
  uint64_t average;
};

/**
 * @brief Voltage and current for one power rail, plus derived power.
 */
struct RailTelemetry {
  SensorStat voltage_mv;  ///< Rail voltage, millivolts.
  SensorStat current_ma;  ///< Rail current, milliamps.

  /// Derived power in milliwatts (voltage_mv * current_ma / 1000).
  /// Note: the "max" field is voltage_mv.max * current_ma.max, an upper
  /// envelope, not necessarily a simultaneous measurement.
  SensorStat power_mw() const {
    return SensorStat{
        voltage_mv.instant * current_ma.instant / 1000,
        voltage_mv.max * current_ma.max / 1000,
        voltage_mv.average * current_ma.average / 1000,
    };
  }
};

/**
 * @brief Full card power/thermal telemetry read from the CMS (U55C only).
 */
struct PowerTelemetry {
  RailTelemetry pex_12v;    ///< 12V PCIe input rail.
  RailTelemetry pex_3v3;    ///< 3.3V PCIe input rail.
  RailTelemetry vccint;     ///< FPGA core rail.
  RailTelemetry vccint_io;  ///< FPGA I/O rail.
  RailTelemetry hbm;        ///< HBM 1.2V rail.
  SensorStat hbm_temp0_celsius;
  SensorStat hbm_temp1_celsius;

  /// Total card input power in milliwatts: pex_12v + pex_3v3.
  SensorStat total_input_power_mw() const {
    const SensorStat a = pex_12v.power_mw();
    const SensorStat b = pex_3v3.power_mw();
    return SensorStat{a.instant + b.instant, a.max + b.max, a.average + b.average};
  }
};

class CmsMonitor;  // Internal; defined in src/api/board/cms_monitor.h.

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

  /**
   * @brief Read full card power/thermal telemetry from the CMS.
   *
   * Supported on U55C only. Throws on a board without power support, or if the
   * board was not opened through an XDMA endpoint.
   */
  PowerTelemetry read_power_telemetry();

  int num_sids() const noexcept { return capabilities_.num_sids; }
  bool broadcast_supported() const noexcept { return capabilities_.broadcast_supported; }
  bool power_supported() const noexcept { return capabilities_.power_supported; }

  ~HBM2();  // Out-of-line: monitor_ holds an incomplete type.

 protected:
  HBM2(std::unique_ptr<IHostInterface> host_interface,
       HBM2Capabilities capabilities,
       std::unique_ptr<CmsMonitor> monitor = nullptr);

  const HBM2Capabilities capabilities_;
  std::unique_ptr<CmsMonitor> monitor_;
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
