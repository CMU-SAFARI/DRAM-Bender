#ifndef DRAMBENDER_API_BOARD_DDR4_H
#define DRAMBENDER_API_BOARD_DDR4_H

#include <memory>
#include <string>

#include "drambender/api/board/board.h"

namespace DRAMBender {

class DDR4 : public IBoard {
 public:
  DDR4(std::string pci_bdf,
       int xdma_channel = 0,
       HostInterface host_interface = HostInterface::XDMA);

 protected:
  explicit DDR4(std::unique_ptr<IHostInterface> host_interface);
};

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_BOARD_DDR4_H
