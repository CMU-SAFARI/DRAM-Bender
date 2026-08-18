#include "cms_monitor.h"

#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

#include <cerrno>
#include <chrono>
#include <cstring>
#include <filesystem>
#include <stdexcept>
#include <string>
#include <system_error>
#include <thread>

#include "../host_interface/xdma_device_resolver.h"
#include "cms_registers.h"

namespace DRAMBender {

namespace cms {

PowerTelemetry decode_telemetry(const std::function<uint32_t(uint32_t)>& read32) {
  const auto rail = [&](const RailRegs& r) {
    return RailTelemetry{
        SensorStat{read32(r.voltage_instant), read32(r.voltage_max),
                   read32(r.voltage_average)},
        SensorStat{read32(r.current_instant), read32(r.current_max),
                   read32(r.current_average)},
    };
  };
  const auto temp = [&](const TempRegs& t) {
    return SensorStat{read32(t.instant), read32(t.max), read32(t.average)};
  };

  PowerTelemetry telemetry;
  telemetry.pex_12v = rail(k_pex_12v);
  telemetry.pex_3v3 = rail(k_pex_3v3);
  telemetry.vccint = rail(k_vccint);
  telemetry.vccint_io = rail(k_vccint_io);
  telemetry.hbm = rail(k_hbm_1v2);
  telemetry.hbm_temp0_celsius = temp(k_hbm_temp0);
  telemetry.hbm_temp1_celsius = temp(k_hbm_temp1);
  return telemetry;
}

}  // namespace cms

namespace {

std::filesystem::path resolve_user_node(const std::string& pci_bdf, int xdma_channel) {
  // The user BAR node (xdmaN_user) shares the instance number N with the
  // card's H2C/C2H nodes. Resolve those by PCI BDF, then swap the suffix.
  const xdma_internal::DevicePaths paths =
      xdma_internal::resolve_device_paths(pci_bdf, xdma_channel);
  const std::string h2c_name = paths.h2c.path.filename().string();
  const auto pos = h2c_name.find("_h2c_");
  if (pos == std::string::npos) {
    throw std::runtime_error("Unexpected XDMA H2C node name: " + h2c_name);
  }
  const std::string user_name = h2c_name.substr(0, pos) + "_user";
  return paths.h2c.path.parent_path() / user_name;
}

}  // namespace

CmsMonitor::CmsMonitor(std::string pci_bdf, int xdma_channel)
    : pci_bdf_(std::move(pci_bdf)), xdma_channel_(xdma_channel) {}

CmsMonitor::~CmsMonitor() {
  if (map_ != nullptr && map_ != MAP_FAILED) {
    munmap(map_, map_size_);
  }
  if (fd_ >= 0) {
    close(fd_);
  }
}

uint32_t CmsMonitor::readRegister_(uint32_t offset) const {
  const auto* reg = reinterpret_cast<volatile const uint32_t*>(
      static_cast<const uint8_t*>(map_) + (offset - map_base_offset_));
  return *reg;
}

void CmsMonitor::writeRegister_(uint32_t offset, uint32_t value) {
  auto* reg = reinterpret_cast<volatile uint32_t*>(
      static_cast<uint8_t*>(map_) + (offset - map_base_offset_));
  *reg = value;
}

void CmsMonitor::ensureInitialized_() {
  if (initialized_) {
    return;
  }

  const std::filesystem::path user_node = resolve_user_node(pci_bdf_, xdma_channel_);

  const long page_size = sysconf(_SC_PAGESIZE);
  const uint32_t page_mask = static_cast<uint32_t>(page_size) - 1;
  map_base_offset_ = cms::k_mb_resetn_reg & ~page_mask;
  const size_t span = (cms::k_highest_offset - map_base_offset_) + sizeof(uint32_t);
  map_size_ = (span + page_mask) & ~static_cast<size_t>(page_mask);

  fd_ = ::open(user_node.c_str(), O_RDWR | O_SYNC);
  if (fd_ < 0) {
    throw std::system_error(errno, std::generic_category(),
                            "Failed to open CMS user node " + user_node.string());
  }

  map_ = mmap(nullptr, map_size_, PROT_READ | PROT_WRITE, MAP_SHARED, fd_,
              static_cast<off_t>(map_base_offset_));
  if (map_ == MAP_FAILED) {
    const int err = errno;
    ::close(fd_);
    fd_ = -1;
    throw std::system_error(err, std::generic_category(),
                            "Failed to mmap CMS registers on " + user_node.string());
  }

  // Reset the CMS microcontroller, wait for it to report ready, then enable HBM
  // monitoring. This sequence is unchanged from the bscdrambender reference.
  writeRegister_(cms::k_mb_resetn_reg, 0x0);
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
  writeRegister_(cms::k_mb_resetn_reg, 0x1);
  std::this_thread::sleep_for(std::chrono::milliseconds(1000));

  bool ready = false;
  for (int attempt = 0; attempt < 100; ++attempt) {
    if (readRegister_(cms::k_host_status2_reg) & cms::k_host_status2_ready_bit) {
      ready = true;
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  if (!ready) {
    throw std::runtime_error("Timed out waiting for the CMS to become ready.");
  }

  writeRegister_(cms::k_control_reg,
                 readRegister_(cms::k_control_reg) | cms::k_control_hbm_monitor_enable_bit);

  initialized_ = true;
}

PowerTelemetry CmsMonitor::read() {
  ensureInitialized_();
  return cms::decode_telemetry(
      [this](uint32_t offset) { return readRegister_(offset); });
}

}  // namespace DRAMBender
