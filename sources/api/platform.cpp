#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <stdlib.h>
#include <cassert>
#include <stdint.h>
#include <stdio.h>
#include <thread>
#include <iostream>
#include <unistd.h>
#include <boost/lockfree/spsc_queue.hpp>

#include "platform.h"
#include "board.h"
#include "prog.h"

[[maybe_unused]] static int consume_total = 0;
[[maybe_unused]] static int receive_total = 0;

SoftMCPlatform::SoftMCPlatform()
{
  // 32 KB large read buffer
  is_dummy = false;
  xdma_recv_buf = malloc(32*1024);

  #ifdef PYSMC
  py_data_buffer = (uint8_t*)malloc(32*1024*sizeof(uint8_t));
  #endif
}

SoftMCPlatform::SoftMCPlatform(bool sandbox)
{
  // 32 KB large read buffer
  is_dummy = sandbox;
  xdma_recv_buf = malloc(32*1024);
}

SoftMCPlatform::~SoftMCPlatform(){
  if (receiver.joinable())
    receiver.join();

  if (xdma_recv_buf)
    free(xdma_recv_buf);

  if (instr_buf)
    free(instr_buf);

  if (iface)
    delete iface;

  #ifdef PYSMC
  if (py_data_buffer)
    free(py_data_buffer);
  #endif
}

int SoftMCPlatform::init(){
  if(is_dummy)
  {
    instr_buf = malloc(INSTR_BUF_SIZE);
    memset(instr_buf, 0, INSTR_BUF_SIZE);
    return SOFTMC_SUCCESS;
  }
  else
  {
    instr_buf = malloc(INSTR_BUF_SIZE);
    memset(instr_buf, 0, INSTR_BUF_SIZE);

    iface = new BoardInterface(BoardInterface::IFACE::XDMA);
    if(!iface -> init())
      return SOFTMC_SUCCESS;
    else
      return SOFTMC_ERR;
  }
}

/**
 * This sends a 256 bit data which has it's
 * 33rd bit set to '1'.
 */
void SoftMCPlatform::reset_fpga()
{
  if(is_dummy)
  {
    return;
  }
  else
  {
    ((uint8_t*) instr_buf)[8] = (uint8_t) 1;
    int sent = iface -> sendData(instr_buf, 32 /*in bytes*/);
    // We do not need to zero out the whole buffer
    memset(instr_buf, 0, 32);
    if(sent)
      std::cerr << "Could not reset the FPGA!" << std::endl;
    else
      std::cout << "Successfully reset the FPGA!" << std::endl;
  }
}

void SoftMCPlatform::execute(Program &prog)
{
  if(is_dummy)
  {
    [[maybe_unused]] uint64_t* iseq     = (uint64_t*) prog.get_inst_array();
    int bytes          = prog.size();
    assert (bytes <= INSTR_BUF_SIZE/4 && " too many instructions in the buffer, the limit is 2048.");
    return;
  }
  else
  {
    uint64_t* iseq     = (uint64_t*) prog.get_inst_array();
    uint64_t* temp_ptr = (uint64_t*) instr_buf;
    int bytes          = prog.size();
    assert (bytes <= INSTR_BUF_SIZE/4 && " too many instructions in the buffer, the limit is 2048.");

    for(int i = 0 ; i < bytes/8 ; i++)
      temp_ptr[i*4] = iseq[i];

    if(receiver.joinable())
      receiver.join();

    receiver = std::thread(&SoftMCPlatform::consumeData, this);
    int sent = iface -> sendData(instr_buf, bytes*4 /*in bytes*/);
    memset(instr_buf, 0, bytes*4);
    free(iseq);
    assert(!sent && "could not send instructions");
  }
}

void SoftMCPlatform::consumeData()
{
  while(true)
  {
    int xdma_read_intent = 32*1024;
    int xdma_read_size = xdma_read_intent;
    int recvd = iface -> recvData((void*)xdma_recv_buf, xdma_read_size);
    if(recvd == 0)
      break;
    // xdma read size in words
    // If we did not read 32KBs then the program probably ended
    // and the last transfer is trash so we discard it
    if(recvd != xdma_read_intent)
      xdma_read_size = recvd-32;
    xdma_read_size /= 4;
    int total_size = xdma_read_size;
    int pushsz = api_recv_buf.push(((int*) xdma_recv_buf), xdma_read_size);
    while(pushsz < total_size)
      pushsz += api_recv_buf.push(((int*) xdma_recv_buf) + pushsz, xdma_read_size = (total_size - pushsz));

//    printf("SoftMCPlatform::consumedata(): spsc filled with %d beats of data\n", pushsz);
//    printf("Consume total: %d\n",++consume_total);

    assert(pushsz == total_size &&
      "Unexpected amount of data pushed into spsc\n");

    if(recvd != xdma_read_intent)
      break;

  }
}

/**
* Try to read param(size) bytes from FPGA, function will block until
* all data is read
* @param recv_buf where to copy read data
* @param size number of bytes to read
* returns the number of bytes read on success
*/
int SoftMCPlatform::receiveData(void* recv_buf, int size){
  if(is_dummy)
  {
    assert(size>0 && size%4 == 0 && "size is expected to be a multiple of four\n");
    size /= 4;
    int * my_buf = (int *) recv_buf;
    for(int i = 0; i < size ; ++i) {
      my_buf[i] = 0x0;
    }
    return size * 4;
  }
  else
  {
    assert(size>0 && size%4 == 0 && "size is expected to be a multiple of four\n");

    size /= 4;
    int total_size = size;
    int rdsz = api_recv_buf.pop((int*) recv_buf, size);
    while (rdsz < total_size)
      rdsz += api_recv_buf.pop(((int*) recv_buf) + rdsz, size = (total_size-rdsz));

    assert(rdsz == total_size && "Unexpected amount of data popped from spsc\n");
    return total_size*4;
  }
}

#ifdef PYSMC
int SoftMCPlatform::py_receiveData(int size){
  if (size > 32 * 1024)
  {
    std::cerr << "Python version only supports read buffer size of up to 32KB!" << std::endl;
    return 0;
  }

  if(is_dummy)
  {
    assert(size>0 && size%4 == 0 && "size is expected to be a multiple of four\n");
    size /= 4;
    int * my_buf = (int *) py_data_buffer;
    for(int i = 0; i < size ; ++i) {
      my_buf[i] = 0x0;
    }
    return size * 4;
  }
  else
  {
    assert(size>0 && size%4 == 0 && "size is expected to be a multiple of four\n");

    size /= 4;
    int total_size = size;
    int rdsz = api_recv_buf.pop((int*) py_data_buffer, size);
    while (rdsz < total_size)
      rdsz += api_recv_buf.pop(((int*) py_data_buffer) + rdsz, size = (total_size-rdsz));

    assert(rdsz == total_size && "Unexpected amount of data popped from spsc\n");
    return total_size*4;
  }
}

py::memoryview SoftMCPlatform::get_buffer_memoryview()
{
  return py::memoryview::from_memory((uint64_t*) py_data_buffer, sizeof(uint8_t) * 32 * 1024, true);
}
#endif

int SoftMCPlatform::count_bitflips_in_row(unsigned char comp_pattern){
  int num_bitflips = 0;
  unsigned char buf[8192];
  receiveData(buf, 8192); // read one row each iteration

  for(int j = 0 ; j < 8192 ; j++){        
    if(comp_pattern != buf[j])
    {
      for(int i = 0 ; i < 8 ; i++)
      {
        if(((comp_pattern >> i) & 1) != ((buf[j] >> i) & 1))
            num_bitflips ++;
      }
    }
  }

  return num_bitflips;
}

void SoftMCPlatform::set_aref(const bool on)
{
  if(is_dummy)
  {
    std::cout << (on ? "Enabled" : "Disabled") << " autorefresh!" << std::endl;
    return;
  }
  else
  {
    ((uint8_t*) instr_buf)[8] = (uint8_t) 0x8;
    ((uint8_t*) instr_buf)[0] = on;
    int sent = iface -> sendData(instr_buf, 32 /*in bytes*/);
    // We do not need to zero out the whole buffer
    memset(instr_buf, 0, 32);
    
    if(sent)
      std::cerr << "Could not set auto refresh!" << std::endl;
    // else
    //   std::cout << (on ? "Enabled" : "Disabled") << " autorefresh!" << std::endl;
  }
}

void SoftMCPlatform::readRegisterDump()
{
  if(is_dummy)
    return;

  /** The author decided to use printfs explicitly within this function
   * because printing unsigned hex bytes is uglier with stdio
   */
  uint8_t readData[64];
  this -> receiveData((void*)readData, 64); // first read wdata content
  printf("WDATA: 0x");
  for(int i = 63 ; i >= 0 ; i--)
    printf("%x", readData[i]);
  printf("\n");
  this -> receiveData((void*)readData, 64); // read register content
  for(int r = 0 ; r < 16 ; r++)
  {
    printf("R%d: 0x", r);
    printf("%x", ((uint32_t*)readData)[r]);
    printf("\n");
  }
}