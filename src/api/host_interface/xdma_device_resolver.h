#ifndef DRAMBENDER_API_HOST_INTERFACE_XDMA_DEVICE_RESOLVER_H
#define DRAMBENDER_API_HOST_INTERFACE_XDMA_DEVICE_RESOLVER_H

#include <filesystem>
#include <string>
#include <string_view>

namespace DRAMBender::xdma_internal {

struct DeviceNode {
  std::filesystem::path path;
  std::filesystem::path sysfs_path;
  unsigned int major_number;
  unsigned int minor_number;
};

struct DevicePaths {
  DeviceNode h2c;
  DeviceNode c2h;
};

std::string normalize_pci_bdf(std::string_view pci_bdf);

DevicePaths resolve_device_paths(
    std::string_view pci_bdf,
    int xdma_channel,
    const std::filesystem::path& sysfs_root = "/sys",
    const std::filesystem::path& dev_root = "/dev");

}  // namespace DRAMBender::xdma_internal

#endif  // DRAMBENDER_API_HOST_INTERFACE_XDMA_DEVICE_RESOLVER_H
