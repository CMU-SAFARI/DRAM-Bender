#include <chrono>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iostream>
#include <stdexcept>
#include <string>
#include <string_view>

#include "api/host_interface/xdma_device_resolver.h"

namespace {

using DRAMBender::xdma_internal::DevicePaths;
using DRAMBender::xdma_internal::normalize_pci_bdf;
using DRAMBender::xdma_internal::resolve_device_paths;

class TemporaryDirectory {
 public:
  TemporaryDirectory() {
    const auto nonce = std::chrono::steady_clock::now().time_since_epoch().count();
    path_ = std::filesystem::temp_directory_path() /
            ("drambender-xdma-resolver-" + std::to_string(nonce));
    std::filesystem::create_directories(path_);
  }

  ~TemporaryDirectory() {
    std::error_code error;
    std::filesystem::remove_all(path_, error);
  }

  const std::filesystem::path& path() const { return path_; }

 private:
  std::filesystem::path path_;
};

void require(bool condition, std::string_view message) {
  if (!condition) {
    throw std::runtime_error(std::string(message));
  }
}

template <typename Exception = std::exception>
void requireThrows(const std::function<void()>& operation, std::string_view expected_text) {
  try {
    operation();
  } catch (const Exception& error) {
    require(std::string_view(error.what()).find(expected_text) != std::string_view::npos,
            "exception did not contain expected diagnostic");
    return;
  }
  throw std::runtime_error("operation did not throw");
}

struct FakeSysfs {
  TemporaryDirectory temporary;
  std::filesystem::path sysfs = temporary.path() / "sys";
  std::filesystem::path dev = temporary.path() / "dev";

  FakeSysfs() {
    std::filesystem::create_directories(sysfs / "class" / "xdma");
    std::filesystem::create_directories(sysfs / "bus" / "pci" / "devices");
    std::filesystem::create_directories(sysfs / "devices");
    std::filesystem::create_directories(dev);
  }

  std::filesystem::path addPciDevice(std::string_view bdf) {
    const auto target = sysfs / "devices" / std::string(bdf);
    std::filesystem::create_directories(target / "xdma");
    std::filesystem::create_directory_symlink(
        target, sysfs / "bus" / "pci" / "devices" / std::string(bdf));
    return target;
  }

  void addEndpoint(const std::filesystem::path& pci_target,
                   std::string_view name,
                   std::string_view device_number = "240:0",
                   bool add_dev_node = true) {
    const auto endpoint = pci_target / "xdma" / std::string(name);
    std::filesystem::create_directories(endpoint);
    std::ofstream(endpoint / "dev") << device_number << '\n';
    std::filesystem::create_directory_symlink(
        endpoint, sysfs / "class" / "xdma" / std::string(name));
    if (add_dev_node) {
      std::ofstream(dev / std::string(name)) << "fake";
    }
  }
};

void testNormalization() {
  require(normalize_pci_bdf("0000:AB:1F.7") == "0000:ab:1f.7",
          "uppercase BDF did not normalize");
  requireThrows<std::invalid_argument>([] { normalize_pci_bdf("01:00.0"); }, "dddd:bb:ss.f");
  requireThrows<std::invalid_argument>([] { normalize_pci_bdf("0000:01:20.0"); },
                                       "slot or function");
  requireThrows<std::invalid_argument>([] { normalize_pci_bdf("0000:01:00.8"); },
                                       "slot or function");
}

void testResolveByBdfNotProbeOrder() {
  FakeSysfs fake;
  const auto pci_a = fake.addPciDevice("0000:01:00.0");
  const auto pci_b = fake.addPciDevice("0000:81:00.0");

  fake.addEndpoint(pci_a, "xdma7_h2c_1", "241:17");
  fake.addEndpoint(pci_a, "xdma7_c2h_1", "241:18");
  fake.addEndpoint(pci_b, "xdma0_h2c_1", "240:1");
  fake.addEndpoint(pci_b, "xdma0_c2h_1", "240:2");

  const DevicePaths paths = resolve_device_paths("0000:01:00.0", 1, fake.sysfs, fake.dev);
  require(paths.h2c.path == fake.dev / "xdma7_h2c_1", "selected wrong H2C endpoint");
  require(paths.c2h.path == fake.dev / "xdma7_c2h_1", "selected wrong C2H endpoint");
  require(paths.h2c.major_number == 241 && paths.h2c.minor_number == 17,
          "parsed wrong H2C device number");
  require(paths.c2h.major_number == 241 && paths.c2h.minor_number == 18,
          "parsed wrong C2H device number");
}

void testRejectsMissingOrInconsistentEndpoints() {
  {
    FakeSysfs fake;
    const auto pci = fake.addPciDevice("0000:01:00.0");
    fake.addEndpoint(pci, "xdma3_h2c_0");
    requireThrows([&] { resolve_device_paths("0000:01:00.0", 0, fake.sysfs, fake.dev); },
                  "both XDMA H2C and C2H");
  }
  {
    FakeSysfs fake;
    const auto pci = fake.addPciDevice("0000:01:00.0");
    fake.addEndpoint(pci, "xdma3_h2c_0");
    fake.addEndpoint(pci, "xdma4_c2h_0");
    requireThrows([&] { resolve_device_paths("0000:01:00.0", 0, fake.sysfs, fake.dev); },
                  "inconsistent driver instance");
  }
  {
    FakeSysfs fake;
    const auto pci = fake.addPciDevice("0000:01:00.0");
    fake.addEndpoint(pci, "xdma3_h2c_0", "240:0", false);
    fake.addEndpoint(pci, "xdma3_c2h_0");
    requireThrows([&] { resolve_device_paths("0000:01:00.0", 0, fake.sysfs, fake.dev); },
                  "device node is missing");
  }
  {
    FakeSysfs fake;
    const auto pci = fake.addPciDevice("0000:01:00.0");
    fake.addEndpoint(pci, "xdma3_h2c_0", "not-a-device-number");
    fake.addEndpoint(pci, "xdma3_c2h_0");
    requireThrows([&] { resolve_device_paths("0000:01:00.0", 0, fake.sysfs, fake.dev); },
                  "Malformed XDMA device number");
  }
}

void testRejectsAbsentDeviceAndNegativeChannel() {
  FakeSysfs fake;
  requireThrows([&] { resolve_device_paths("0000:01:00.0", 0, fake.sysfs, fake.dev); },
                "is not present in sysfs");
  requireThrows<std::invalid_argument>(
      [&] { resolve_device_paths("0000:01:00.0", -1, fake.sysfs, fake.dev); },
      "non-negative");
}

}  // namespace

int main() {
  try {
    testNormalization();
    testResolveByBdfNotProbeOrder();
    testRejectsMissingOrInconsistentEndpoints();
    testRejectsAbsentDeviceAndNegativeChannel();
  } catch (const std::exception& error) {
    std::cerr << "xdma_device_resolver_test failed: " << error.what() << '\n';
    return 1;
  }

  std::cout << "xdma_device_resolver_test passed\n";
  return 0;
}
