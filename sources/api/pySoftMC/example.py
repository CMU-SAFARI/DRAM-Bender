from pySoftMC import *
import numpy as np

# Initialize SoftMC platform
platform = SoftMCPlatform()
err = platform.init()
if (err != 0):
  print("SoftMC platform initialization failed!")
  exit(-1)
platform.reset_fpga()

# Define registers
CASR = 0
BASR = 1
RASR = 2
BAR  = 3
RAR  = 4
CAR  = 5
PATTERN_REG = 6


def initialize_row(platform: SoftMCPlatform, data32: int, bank: int, row: int):
  p = Program()
  p.add_inst(SMC_LI(bank, BAR))
  p.add_inst(SMC_LI(row, RAR))
  p.add_inst(SMC_LI(8, CASR))

  p.add_inst(SMC_LI(data32, PATTERN_REG))
  for i in range(16):
    p.add_inst(SMC_LDWD(PATTERN_REG, i))
  
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_LI(0, CAR))
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP())

  p.add_inst(SMC_ACT(BAR, 0, RAR, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP())

  for i in range(128):
    p.add_inst(SMC_WRITE(BAR, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
    p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP()) 
  p.add_inst(SMC_SLEEP(3))
  
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP()) 
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP())

  p.add_inst(SMC_END())
  platform.execute(p)

def read_row(platform: SoftMCPlatform, bank: int, row: int):
  p = Program()
  p.add_inst(SMC_LI(bank, BAR))
  p.add_inst(SMC_LI(row, RAR))
  p.add_inst(SMC_LI(8, CASR))
  
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_LI(0, CAR))
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP())

  p.add_inst(SMC_ACT(BAR, 0, RAR, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP())

  for i in range(128):
    p.add_inst(SMC_READ(BAR, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
    p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP()) 
  p.add_inst(SMC_SLEEP(3))
  
  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP()) 
  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP())

  p.add_inst(SMC_END())
  platform.execute(p)

def hammer_row_double(bank, aggressor_row_1, aggressor_row_2, hammer_count, RAS_scale, RP_scale):
  HMR_COUNTER_REG = 7
  NUM_HMR_REG = 8

  p = Program()
  p.add_inst(SMC_LI(bank, BAR))
  p.add_inst(SMC_LI(aggressor_row_1, RAR))

  p.add_inst(SMC_LI(0, HMR_COUNTER_REG))
  p.add_inst(SMC_LI(hammer_count, NUM_HMR_REG))

  p.add_label("HMR_BEGIN")
  if (RAS_scale > 1):
    p.add_inst(SMC_SLEEP(5 * (RAS_scale - 1)))

  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_LI(aggressor_row_1, RAR))
  if (RP_scale > 1):
    p.add_inst(SMC_SLEEP(3 * (RP_scale - 1)))


  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_ACT(BAR, 0, RAR, 0))
  p.add_inst(SMC_LI(aggressor_row_2, RAR))
  p.add_inst(SMC_SLEEP(5))
  if (RAS_scale > 1):
    p.add_inst(SMC_SLEEP(5 * (RAS_scale - 1)))

  p.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP())
  p.add_inst(SMC_ADDI(HMR_COUNTER_REG, 1, HMR_COUNTER_REG))
  if (RP_scale > 1):
    p.add_inst(SMC_SLEEP(3 * (RP_scale - 1)))


  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_ACT(BAR, 0, RAR, 0))
  p.add_branch(Program.BR_TYPE.BL, HMR_COUNTER_REG, NUM_HMR_REG, "HMR_BEGIN")


  p.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP()) 
  p.add_inst(SMC_END())

  platform.execute(p)

def check_flips(buffer, pattern):
  d = []
  out = np.bitwise_xor(buffer, pattern)
  for cl in range(128):
    for w in range(8):
      if (out[cl * 8 + w]) != 0:
        _w = out[cl * 8 + w]
        for byte in range(8):
          for bit in range(8):
            bit_id = np.uint64(byte * 8 + bit)
            if ((np.right_shift(_w, bit_id)) & np.uint64(0x1)):
              d.append((i, cl, w, byte, bit))
              print(f"ITR {i}\tCL {cl}\t Word {w}\t Byte {byte}\t Bit {bit}")


# Get the buffer from the underlying C++ API
buffer = np.frombuffer(platform.get_buffer_memoryview()[:8192], dtype=np.uint64)

ITR_COUNT=10
ACT_COUNT = 100000
pattern = 0xFFFFFFFF

for i in range(ITR_COUNT):
  initialize_row(platform, 0xFFFFFFFF, 0, 233)
  initialize_row(platform, 0x0, 0, 234)
  initialize_row(platform, 0xFFFFFFFF, 0, 235) 

  hammer_row_double(0, 233, 235, ACT_COUNT, 1, 1)

  read_row(platform, 0, 234)
  platform.receiveData(8*1024)

  check_flips(buffer, 0x0)

