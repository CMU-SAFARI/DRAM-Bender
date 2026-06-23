#ifndef DRAMBENDER_API_HOST_INTERFACE_HOST_INTERFACE_H
#define DRAMBENDER_API_HOST_INTERFACE_HOST_INTERFACE_H

#include <cstddef>
#include <memory>
#include <span>
#include <string_view>

namespace DRAMBender {

enum class HostInterface {
  XDMA,
  QDMA,
  Ethernet,
};

constexpr std::string_view to_string(HostInterface host_interface) noexcept {
  switch (host_interface) {
    case HostInterface::XDMA:
      return "XDMA";
    case HostInterface::QDMA:
      return "QDMA";
    case HostInterface::Ethernet:
      return "Ethernet";
  }

  return "Unknown";
}

/**
 * @brief Interface class for low-level communication with the FPGA host interface.
 */
class IHostInterface {
 public:
  virtual ~IHostInterface() = default;

  /**
   * @brief Initializes the board interface.
   *
   * Implementations should throw on failure.
   */
  virtual void init() = 0;

  /**
   * @brief Send bytes to the FPGA.
   *
   * Implementations must either send the full payload or throw.
   *
   * @return size_t The number of bytes sent.
   */
  virtual size_t send(std::span<const std::byte> data) = 0;

  /**
   * @brief Prepare the backend for a new receive session.
   *
   * Backends that support receive cancellation should clear any prior
   * cancellation request here. Other backends may keep the default no-op.
   */
  virtual void begin_receive() {}

  /**
   * @brief Receive bytes from the FPGA into a caller-owned buffer.
   *
   * @return size_t The number of bytes received.
   */
  virtual size_t recv(std::span<std::byte> dst) = 0;

  /**
   * @brief Interrupt a blocked recv() call, if the backend supports it.
   *
   * This is used by recovery paths such as full_reset() and close(). The
   * default implementation is a no-op for host interfaces without a blocking
   * receive primitive.
   */
  virtual void cancel_receive() {}

  /**
   * @brief Drain any stale data from the host-side buffer.
   *
   * Implementations should read and discard currently available data without
   * blocking indefinitely.
   */
  virtual void drain() = 0;
};

std::unique_ptr<IHostInterface> create_host_interface(HostInterface host_interface,
                                                      int board_id,
                                                      int instance_id);

}  // namespace DRAMBender

#endif  // DRAMBENDER_API_HOST_INTERFACE_HOST_INTERFACE_H
