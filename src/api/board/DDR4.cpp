#include "drambender/api/board/DDR4.h"

namespace DRAMBender {

DDR4::DDR4(int board_id, int instance_id, HostInterface host_interface)
    : DDR4(board_id,
           instance_id,
           create_host_interface(host_interface, board_id, instance_id)) {}

DDR4::DDR4(int board_id, int instance_id, std::unique_ptr<IHostInterface> host_interface)
    : IBoard(std::move(host_interface)), m_board_id_(board_id), m_instance_id_(instance_id) {}

}  // namespace DRAMBender
