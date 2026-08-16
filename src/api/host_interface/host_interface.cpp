#include "drambender/api/host_interface/host_interface.h"

#include <memory>
#include <stdexcept>
#include <string>
#include <utility>

namespace DRAMBender {

std::unique_ptr<IHostInterface> make_xdma_host_interface(std::string pci_bdf, int xdma_channel);

std::unique_ptr<IHostInterface> create_host_interface(HostInterface host_interface,
                                                      std::string pci_bdf,
                                                      int xdma_channel) {
  switch (host_interface) {
    case HostInterface::XDMA: {
      std::unique_ptr<IHostInterface> interface =
          make_xdma_host_interface(std::move(pci_bdf), xdma_channel);
      if (!interface) {
        throw std::runtime_error("Failed to create host interface for XDMA.");
      }

      interface->init();
      return interface;
    }
    // QDMA and Ethernet are reserved for planned backends. Only XDMA is
    // implemented today. See the HostInterface enum documentation.
    case HostInterface::QDMA:
      throw std::runtime_error(
          "HostInterface::QDMA is not implemented yet. Use HostInterface::XDMA.");
    case HostInterface::Ethernet:
      throw std::runtime_error(
          "HostInterface::Ethernet is not implemented yet. Use HostInterface::XDMA.");
  }

  throw std::runtime_error("Unsupported host interface: " +
                           std::string(to_string(host_interface)) + ".");
}

}  // namespace DRAMBender
