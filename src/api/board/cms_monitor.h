#ifndef DRAMBENDER_API_BOARD_CMS_MONITOR_H
#define DRAMBENDER_API_BOARD_CMS_MONITOR_H

#include <cstddef>
#include <cstdint>
#include <functional>
#include <string>

#include "drambender/api/board/HBM2.h"

namespace DRAMBender {

namespace cms {

// Decode a PowerTelemetry snapshot from a register-read function.
//
// read32(offset) must return the 32-bit CMS register at the given absolute
// byte offset. This is pure and hardware-free, so it is unit-testable with a
// fake register map.
PowerTelemetry decode_telemetry(const std::function<uint32_t(uint32_t)>& read32);

}  // namespace cms

// Reads Alveo CMS power/thermal telemetry over the XDMA user BAR.
//
// The user BAR node (/dev/xdmaN_user) is resolved from the board's PCI BDF, so
// this works on multi-card hosts. The register window is mmap'd lazily on the
// first read().
class CmsMonitor {
 public:
  CmsMonitor(std::string pci_bdf, int xdma_channel);
  ~CmsMonitor();

  CmsMonitor(const CmsMonitor&) = delete;
  CmsMonitor& operator=(const CmsMonitor&) = delete;

  PowerTelemetry read();

 private:
  void ensureInitialized_();
  uint32_t readRegister_(uint32_t offset) const;
  void writeRegister_(uint32_t offset, uint32_t value);

  std::string pci_bdf_;
  int xdma_channel_;
  int fd_ = -1;
  void* map_ = nullptr;
  size_t map_size_ = 0;
  uint32_t map_base_offset_ = 0;
  bool initialized_ = false;
};

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_BOARD_CMS_MONITOR_H
