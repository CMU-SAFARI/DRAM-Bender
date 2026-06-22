#include "draminspector/api/host_interface/host_interface.h"

#include <memory>
#include <stdexcept>
#include <string>

namespace DRAMBender {

std::unique_ptr<IHostInterface> make_xdma_host_interface(int instance_id);

std::unique_ptr<IHostInterface> create_host_interface(HostInterface host_interface, int instance_id) {
  switch (host_interface) {
    case HostInterface::XDMA: {
      std::unique_ptr<IHostInterface> interface = make_xdma_host_interface(instance_id);
      if (!interface) {
        throw std::runtime_error("Failed to create host interface for XDMA.");
      }

      interface->init();
      return interface;
    }
    case HostInterface::QDMA:
      throw std::runtime_error("HostInterface::QDMA is declared but not implemented in this pass.");
    case HostInterface::Ethernet:
      throw std::runtime_error(
          "HostInterface::Ethernet is declared but not implemented in this pass.");
  }

  throw std::runtime_error("Unsupported host interface: " +
                           std::string(to_string(host_interface)) + ".");
}

}  // namespace DRAMBender
