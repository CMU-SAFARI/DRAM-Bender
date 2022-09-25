#include "board.h"
#include "prog.h"
#include <thread>
#include <boost/lockfree/spsc_queue.hpp>

#ifdef PYSMC
#include "ext/pybind11/include/pybind11/pybind11.h"
namespace py = pybind11;
#endif

//ERROR CODES
#define SOFTMC_SUCCESS 0
#define SOFTMC_ERR -1
#define SOFTMC_NO_PLATFORM -2
#define SOFTMC_ERR_OPEN_FPGA -3
#define SOFTMC_NO_SUCH_FPGA -4

class SoftMCPlatform{
  #define INSTR_BUF_SIZE 32*2048
  #define API_BUF_SIZE 1024*1024*2
  public:
    SoftMCPlatform();
    SoftMCPlatform(bool);
    ~SoftMCPlatform();
    /**
     * Initializes the whole platform
     * @return SOFTMC_SUCCESS on sucessful initialization
     */
    int init();
    /**
     * Resets SoftMC logic, won't reset PCI-E endpoint or the PHY interface
     */
    void reset_fpga();
    /**
     * Sends SoftMC program to the FPGA board over PCI-E
     * @param prog reference to the program object to send
     */
    void execute(Program & prog);
    /**
     * Receive data from the FPGA board over PCI-E
     * @param dst_buf pointer to the buffer that will receive the data
     * @param num_words number of bytes to read
     */
    int receiveData(void* dst_buf, int num_words);

    #ifdef PYSMC
    int py_receiveData(int num_words);
    #endif

    /**
     * Compare data with a given data pattern (repeating bytes)
     * and return number of bitflips in 8KB of data
     * @param comp_pattern one byte data pattern to compare the read data
     */ 
    int count_bitflips_in_row(unsigned char comp_pattern);

    /**
     * Turn auto-refresh on-off
     * @param on true to turn aref on false otherwise
     */
    void set_aref(bool on);

    /**
     * Used along with Program::dumpRegisters to read register content
     */
    void readRegisterDump();

  private:
    bool is_dummy;

    BoardInterface *iface;
    void* instr_buf;
    std::thread receiver;
    boost::lockfree::spsc_queue<int, boost::lockfree::capacity<API_BUF_SIZE/4>> api_recv_buf;
    void* xdma_recv_buf;
    void consumeData();

  #ifdef PYSMC
  public:
    uint8_t* py_data_buffer = nullptr;
    py::memoryview get_buffer_memoryview();
  #endif
};
