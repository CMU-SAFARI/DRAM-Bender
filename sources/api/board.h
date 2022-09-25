#include <string>

#ifndef BOARD_H
#define BOARD_H
/** This class defines how the host
 * interfaces with the board.
 */
class BoardInterface{
  const uint SEND_BUF_SIZE = 32*2048;
              // send each instruction as a 256-bit packet
  const uint RECV_BUF_SIZE = 1024*32;
  const std::string TO_FPGA_DEFAULT = "/dev/xdma0_h2c_0";
  const std::string FROM_FPGA_DEFAULT = "/dev/xdma0_c2h_0";
public:
  enum class IFACE {
      XDMA = 0
  };
  BoardInterface(IFACE);
  ~BoardInterface();
  int init();
  int sendData(void* data, const uint size);
  int recvData(void* buf , const uint size);
private:
  IFACE iface_type;
  // XDMA related constructs
  int to_card;
  int from_card;
  void* send_buf;
  void* recv_buf;
  int xdma_send(void* data, const uint size);
  int xdma_recv(void* buf,  const uint size);
  // end XDMA related constructs
};

#endif
