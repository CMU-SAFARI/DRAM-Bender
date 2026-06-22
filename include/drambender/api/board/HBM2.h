#ifndef DRAMBENDER_API_BOARD_HBM2_H
#define DRAMBENDER_API_BOARD_HBM2_H

#include <memory>

#include "drambender/api/board/board.h"

namespace DRAMBender {

struct HBMTemperature {
  int stack0_celsius;
  int stack1_celsius;
};

class HBM2 : public IBoard {
 public:
  explicit HBM2(int instance_id = 0, HostInterface host_interface = HostInterface::XDMA);

  HBMTemperature read_temperature();

 protected:
  HBM2(int instance_id, std::unique_ptr<IHostInterface> host_interface);

 private:
  const int m_instance_id_;
};

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_BOARD_HBM2_H
