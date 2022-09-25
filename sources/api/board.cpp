#include "board.h"
#include <unistd.h>
#include <fstream>
#include <iostream>
#include <cassert>
#include <fcntl.h>
#include <string.h>

BoardInterface::BoardInterface(IFACE iface_type)
{
  this -> iface_type = iface_type;
}
BoardInterface::~BoardInterface()
{
  free(send_buf);
  free(recv_buf);
  close(to_card);
  close(from_card);
}

int BoardInterface::init()
{
  switch(iface_type)
  {
    case IFACE::XDMA:
    {
      int fpga_fd = open(TO_FPGA_DEFAULT.c_str(), O_RDWR);
      if(fpga_fd<0)
      {
        std::cerr << "Open to card failed!" << std::endl;
        return 1;
      }
      else
        std::cout << "Opened " << TO_FPGA_DEFAULT <<  " -> " << fpga_fd << std::endl;
      to_card = fpga_fd;
      fpga_fd = open(FROM_FPGA_DEFAULT.c_str(), O_RDWR);
      if(fpga_fd<0)
      {
        std::cerr << "Open to host failed!" << std::endl;
        return 1;
      }
      else
        std::cout << "Opened " << FROM_FPGA_DEFAULT <<  " -> " << fpga_fd << std::endl;
      from_card = fpga_fd;
      // allocate page size aligned X page size regions to our buffers
      if (posix_memalign((void **)&send_buf, 4096 /*alignment */ , SEND_BUF_SIZE + (4096-(SEND_BUF_SIZE % 4096))) != 0)
      {
        std::cerr << "Send buffer allocation failed!" << std::endl;
        return 1;
      }
      if (posix_memalign((void **)&recv_buf, 4096 /*alignment */ , RECV_BUF_SIZE + (4096-(RECV_BUF_SIZE % 4096))))
      {
        std::cerr << "Receive buffer allocation failed!" << std::endl;
        return 1;
      }
      if( (!send_buf) || (!recv_buf) )
      {
        std::cerr << "Buffers cannot be allocated!" << std::endl;
        return 1;
      }
      return 0;
    }
    default:
      std::cerr << "Unknown iface_type!" << std::endl;
      return 1;
  }
}

int BoardInterface::sendData(void* data, const uint size)
{
  switch(iface_type)
  {
    case IFACE::XDMA:
      return xdma_send(data,size);
      break;
    default:
      std::cerr << "Unknown iface_type!" << std::endl;
      return 1;
  }
}

int BoardInterface::recvData(void* buf, const uint size)
{
  switch(iface_type)
  {
    case IFACE::XDMA:
      return xdma_recv(buf,size);
      break;
    default:
      std::cerr << "Unknown iface_type!" << std::endl;
      return 1;
  }
}

int BoardInterface::xdma_send(void* data, const uint size)
{
  memcpy((char*)send_buf, (char*)data, size);

  int fd = to_card;
  ssize_t rc;
  uint64_t count = 0;
  char *buf = (char*) send_buf;
 
  while (count < size) {
    /* write data to file from memory buffer */
    rc = write(fd, buf, size);
    assert(rc == size || rc == 0);
    count += rc;
  }

  // We wrote more than we supposed to
  if (count != size)
    return 1;

  return 0;
}

int BoardInterface::xdma_recv(void* buf, const uint size)
{
  assert(size <= RECV_BUF_SIZE && "given read size is too large");

  int fd = from_card;
  uint64_t count = 0;
  // Try to read from the card.
  count = read(fd, (char*) recv_buf, size);

  // We read more than we were supposed to
  assert(count <= size);// || rc == 0);

  memcpy(buf, (char*) recv_buf, count);
  return count;
}
