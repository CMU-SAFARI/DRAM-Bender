#include "api/host_interface/xdma_device_resolver.h"

#include <algorithm>
#include <charconv>
#include <cctype>
#include <fstream>
#include <optional>
#include <stdexcept>
#include <string>
#include <system_error>
#include <utility>

namespace DRAMBender::xdma_internal {
namespace {

enum class Direction { H2C, C2H };

struct NodeName {
  unsigned int device_index;
  Direction direction;
  unsigned int channel;
};

bool isHexDigit(char value) {
  return std::isxdigit(static_cast<unsigned char>(value)) != 0;
}

std::optional<unsigned int> parseUnsigned(std::string_view value, int base = 10) {
  if (value.empty()) {
    return std::nullopt;
  }

  unsigned int parsed = 0;
  const auto [end, error] =
      std::from_chars(value.data(), value.data() + value.size(), parsed, base);
  if (error != std::errc{} || end != value.data() + value.size()) {
    return std::nullopt;
  }
  return parsed;
}

std::optional<NodeName> parseNodeName(std::string_view name) {
  constexpr std::string_view prefix = "xdma";
  if (!name.starts_with(prefix)) {
    return std::nullopt;
  }

  const size_t first_separator = name.find('_', prefix.size());
  if (first_separator == std::string_view::npos) {
    return std::nullopt;
  }
  const size_t second_separator = name.find('_', first_separator + 1);
  if (second_separator == std::string_view::npos ||
      name.find('_', second_separator + 1) != std::string_view::npos) {
    return std::nullopt;
  }

  const auto device_index =
      parseUnsigned(name.substr(prefix.size(), first_separator - prefix.size()));
  const auto channel = parseUnsigned(name.substr(second_separator + 1));
  if (!device_index || !channel) {
    return std::nullopt;
  }

  const std::string_view direction_text =
      name.substr(first_separator + 1, second_separator - first_separator - 1);
  Direction direction;
  if (direction_text == "h2c") {
    direction = Direction::H2C;
  } else if (direction_text == "c2h") {
    direction = Direction::C2H;
  } else {
    return std::nullopt;
  }

  return NodeName{*device_index, direction, *channel};
}

bool isPathWithin(const std::filesystem::path& child,
                  const std::filesystem::path& parent) {
  auto child_it = child.begin();
  for (auto parent_it = parent.begin(); parent_it != parent.end(); ++parent_it, ++child_it) {
    if (child_it == child.end() || *child_it != *parent_it) {
      return false;
    }
  }
  return true;
}

std::pair<unsigned int, unsigned int> readDeviceNumber(
    const std::filesystem::path& sysfs_node) {
  std::ifstream stream(sysfs_node / "dev");
  std::string value;
  if (!(stream >> value)) {
    throw std::runtime_error("Cannot read XDMA device number from " +
                             (sysfs_node / "dev").string() + ".");
  }

  std::string extra;
  if (stream >> extra) {
    throw std::runtime_error("Malformed XDMA device number in " +
                             (sysfs_node / "dev").string() + ".");
  }

  const size_t separator = value.find(':');
  if (separator == std::string::npos || value.find(':', separator + 1) != std::string::npos) {
    throw std::runtime_error("Malformed XDMA device number in " +
                             (sysfs_node / "dev").string() + ".");
  }

  const auto major_number = parseUnsigned(std::string_view(value).substr(0, separator));
  const auto minor_number = parseUnsigned(std::string_view(value).substr(separator + 1));
  if (!major_number || !minor_number) {
    throw std::runtime_error("Malformed XDMA device number in " +
                             (sysfs_node / "dev").string() + ".");
  }
  return {*major_number, *minor_number};
}

}  // namespace

std::string normalize_pci_bdf(std::string_view pci_bdf) {
  // Require the complete Linux PCI address. In particular, do not accept an
  // omitted domain: the same bus/device/function can exist in multiple PCI
  // domains on a large test rig.
  if (pci_bdf.size() != 12 || pci_bdf[4] != ':' || pci_bdf[7] != ':' ||
      pci_bdf[10] != '.') {
    throw std::invalid_argument(
        "PCI BDF must use the complete dddd:bb:ss.f form (for example 0000:01:00.0).");
  }

  for (size_t index = 0; index < pci_bdf.size(); ++index) {
    if (index == 4 || index == 7 || index == 10) {
      continue;
    }
    if (!isHexDigit(pci_bdf[index])) {
      throw std::invalid_argument(
          "PCI BDF must use the complete dddd:bb:ss.f form (for example 0000:01:00.0).");
    }
  }

  const auto slot = parseUnsigned(pci_bdf.substr(8, 2), 16);
  const auto function = parseUnsigned(pci_bdf.substr(11, 1), 16);
  if (!slot || *slot > 0x1f || !function || *function > 7) {
    throw std::invalid_argument("PCI BDF contains an invalid slot or function number.");
  }

  std::string normalized(pci_bdf);
  std::transform(normalized.begin(), normalized.end(), normalized.begin(), [](char value) {
    return static_cast<char>(std::tolower(static_cast<unsigned char>(value)));
  });
  return normalized;
}

DevicePaths resolve_device_paths(std::string_view pci_bdf,
                                 int xdma_channel,
                                 const std::filesystem::path& sysfs_root,
                                 const std::filesystem::path& dev_root) {
  const std::string normalized_bdf = normalize_pci_bdf(pci_bdf);
  if (xdma_channel < 0) {
    throw std::invalid_argument("XDMA channel must be non-negative.");
  }

  const std::filesystem::path pci_path =
      sysfs_root / "bus" / "pci" / "devices" / normalized_bdf;
  std::error_code error;
  const std::filesystem::path canonical_pci_path = std::filesystem::canonical(pci_path, error);
  if (error || !std::filesystem::is_directory(canonical_pci_path)) {
    throw std::runtime_error("PCI device " + normalized_bdf +
                             " is not present in sysfs at " + pci_path.string() + ".");
  }

  const std::filesystem::path class_path = sysfs_root / "class" / "xdma";
  if (!std::filesystem::is_directory(class_path)) {
    throw std::runtime_error("XDMA sysfs class is not available at " + class_path.string() +
                             "; is the XDMA driver loaded?");
  }

  struct Match {
    DeviceNode node;
    unsigned int device_index;
  };
  std::optional<Match> h2c;
  std::optional<Match> c2h;

  for (const auto& entry : std::filesystem::directory_iterator(class_path)) {
    const auto parsed = parseNodeName(entry.path().filename().string());
    if (!parsed || parsed->channel != static_cast<unsigned int>(xdma_channel)) {
      continue;
    }

    const std::filesystem::path canonical_entry = std::filesystem::canonical(entry.path(), error);
    if (error) {
      error.clear();
      continue;  // Ignore a stale class symlink while a device is being removed.
    }
    if (!isPathWithin(canonical_entry, canonical_pci_path)) {
      continue;
    }

    const auto [major_number, minor_number] = readDeviceNumber(canonical_entry);
    const std::filesystem::path device_path = dev_root / entry.path().filename();
    if (!std::filesystem::exists(device_path)) {
      throw std::runtime_error("XDMA endpoint " + entry.path().filename().string() +
                               " belongs to PCI device " + normalized_bdf +
                               " but its device node is missing at " + device_path.string() + ".");
    }

    Match match{
        DeviceNode{device_path, canonical_entry, major_number, minor_number},
        parsed->device_index,
    };
    auto& destination = parsed->direction == Direction::H2C ? h2c : c2h;
    if (destination) {
      throw std::runtime_error("Multiple XDMA endpoints match PCI device " + normalized_bdf +
                               " channel " + std::to_string(xdma_channel) + ".");
    }
    destination = std::move(match);
  }

  if (!h2c || !c2h) {
    throw std::runtime_error("PCI device " + normalized_bdf + " does not expose both XDMA H2C "
                             "and C2H endpoints for channel " +
                             std::to_string(xdma_channel) + ".");
  }
  if (h2c->device_index != c2h->device_index) {
    throw std::runtime_error("XDMA H2C and C2H endpoints for PCI device " + normalized_bdf +
                             " channel " + std::to_string(xdma_channel) +
                             " have inconsistent driver instance numbers.");
  }

  return DevicePaths{std::move(h2c->node), std::move(c2h->node)};
}

}  // namespace DRAMBender::xdma_internal
