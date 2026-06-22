#include "draminspector/api/board/DDR4.h"

namespace DRAMBender {

DDR4::DDR4(int instance_id, HostInterface host_interface)
    : DDR4(instance_id, create_host_interface(host_interface, instance_id)) {}

DDR4::DDR4(int instance_id, std::unique_ptr<IHostInterface> host_interface)
    : IBoard(std::move(host_interface)), m_instance_id_(instance_id) {}

}  // namespace DRAMBender
