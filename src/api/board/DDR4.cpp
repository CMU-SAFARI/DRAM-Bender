#include "drambender/api/board/DDR4.h"

#include <utility>

namespace DRAMBender {

DDR4::DDR4(std::string pci_bdf, int xdma_channel, HostInterface host_interface)
    : DDR4(create_host_interface(host_interface, std::move(pci_bdf), xdma_channel)) {}

DDR4::DDR4(std::unique_ptr<IHostInterface> host_interface)
    // U200 DDR4 design: 32 K instruction buffer.
    : IBoard(std::move(host_interface), 32768) {}

}  // namespace DRAMBender
