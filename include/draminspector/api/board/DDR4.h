#ifndef DRAMINSPECTOR_API_BOARD_DDR4_H
#define DRAMINSPECTOR_API_BOARD_DDR4_H

#include <memory>

#include "draminspector/api/board/board.h"

namespace DRAMBender {

class DDR4 : public IBoard {
 public:
  explicit DDR4(int instance_id = 0, HostInterface host_interface = HostInterface::XDMA);

 protected:
  DDR4(int instance_id, std::unique_ptr<IHostInterface> host_interface);

 private:
  const int m_instance_id_;
};

}  // namespace DRAMBender

#endif  // DRAMINSPECTOR_API_BOARD_DDR4_H
