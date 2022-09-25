#include "instruction.h"
#include "prog.h"
#include "platform.h"
#include <fstream>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <cstring>
#include <list>
#include <algorithm>
#include <iterator>
#include <iomanip>

#define NEWFILTER

using namespace std;

#define NO_BANKS 2
#define NO_ROWS 32*1024

// Stride register ids are fixed and should not be changed
// CASR should always be reg 0
#define CASR 0
// BASR should always be reg 1
#define BASR 1
// RASR should always be reg 2
#define RASR 2

#define PATTERN_REG 12
#define INV_PATTERN_REG 13
#define TEMP_PATTERN_REG 14

#define BAR 3
#define CAR 4
#define RARBASE 5
#define RAR1 6
#define RAR2 9

#define ONE_REG 10 
#define ZERO_REG 11

#define ITER_REG 7
#define CTR_REG  8

#define INIT_LOOP 15

Program genRowCopy(int t1, int t2, int row1_reg, int row2_reg, int bank_reg)
{
  Program ret;
  // t1 -> ACT to PRE, t2 -> PRE to 2nd ACT
  int sz = 3 + t1 + t2;
  sz = (4-(sz%4)) + sz;
  Mininst buff[sz];
  for(int i = 0 ; i < sz ; i++)
    buff[i] = SMC_NOP();

  // Overwrite with the actual sequence 
  buff[0] = SMC_ACT(bank_reg, 0, row1_reg, 0);
  buff[1+t1] = SMC_PRE(bank_reg, 0, 0);
  buff[2+t1+t2] = SMC_ACT(bank_reg, 0, row2_reg, 0);

  for(int i = 0 ; i < sz ; i+=4)
    ret.add_inst(buff[i], buff[i+1], buff[i+2], buff[i+3]);

  return ret;
}

/**
 * To send an ACT -> SLEEP t1 -> PRE -> SLEEP t2 -> ACT sequence
 * This seq. will use BAR RAR1 and RAR2 registers
 */ 
Program genActPreActSequence(int t1, int t2, int row1_reg, int row2_reg, int bank_reg)
{
  Program ret;
  // t1 -> ACT to PRE, t2 -> PRE to 2nd ACT
  int sz = 3 + t1 + t2;
  sz = (4-(sz%4)) + sz;
  Mininst buff[sz];
  for(int i = 0 ; i < sz ; i++)
    buff[i] = SMC_NOP();

  // Overwrite with the actual sequence 
  buff[0] = SMC_ACT(bank_reg, 0, row1_reg, 0);
  buff[1+t1] = SMC_PRE(bank_reg, 0, 0);
  buff[2+t1+t2] = SMC_ACT(bank_reg, 0, row2_reg, 0);

  for(int i = 0 ; i < sz ; i+=4)
    ret.add_inst(buff[i], buff[i+1], buff[i+2], buff[i+3]);

  return ret;
}


/**
 * This function will generate a block of instructions that will
 * write to a range of rows. It assumes the bank will be precharged.
 */

Program genCopyRange(int row_reg, int no_rows, int bank_reg, bool stripes)
{
  Program ret;
  ret.add_inst(SMC_LI(no_rows, INIT_LOOP));
  ret.add_inst(SMC_ADD(INIT_LOOP, row_reg, INIT_LOOP)); // write until this row

  ret.add_inst(SMC_LI(0, ONE_REG));
  ret.add_inst(SMC_LI(1, ZERO_REG));
  
  ret.add_label("genWriteRange:LOOP_BEGIN");
  ret.add_inst(SMC_SLEEP(4));
  
  ret.add_below(genRowCopy(4,4,ONE_REG,row_reg,bank_reg));
  ret.add_inst(SMC_SLEEP(6));
  ret.add_inst(SMC_PRE(bank_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_ADDI(row_reg, 1, row_reg));

  ret.add_inst(SMC_SLEEP(6));
  ret.add_below(genRowCopy(4,4,ZERO_REG,row_reg,bank_reg));
  ret.add_inst(SMC_SLEEP(6));
  ret.add_inst(SMC_PRE(bank_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_ADDI(row_reg, 1, row_reg));

  ret.add_inst(SMC_SLEEP(6));

  ret.add_below(genRowCopy(4,4,ONE_REG,row_reg,bank_reg));
  ret.add_inst(SMC_SLEEP(6));
  ret.add_inst(SMC_PRE(bank_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_ADDI(row_reg, 1, row_reg));
  ret.add_inst(SMC_SLEEP(6));

  ret.add_below(genRowCopy(4,4,ZERO_REG,row_reg,bank_reg));
  ret.add_inst(SMC_SLEEP(6));
  ret.add_inst(SMC_PRE(bank_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_ADDI(row_reg, 1, row_reg));
  ret.add_inst(SMC_SLEEP(6));

  ret.add_inst(SMC_SUBI(row_reg, no_rows, row_reg));
  return ret;
}

/**
 * This function will generate a block of instructions that will
 * write to a range of rows. It assumes the bank will be precharged.
 */
Program genWriteRange1000(int row_reg, int no_rows, int bank_reg)
{
  Program ret;
  ret.add_inst(SMC_LI(no_rows, INIT_LOOP));
  ret.add_inst(SMC_ADD(INIT_LOOP, row_reg, INIT_LOOP)); // write until this row
  
  ret.add_label("genWriteRange:LOOP_BEGIN");
  ret.add_inst(SMC_LI(0, CAR));

  ret.add_inst(SMC_ACT(bank_reg, 0, row_reg, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));
  
  for(int i = 0 ; i < 32 ; i++)
  {
    ret.add_inst(SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0));
    ret.add_inst(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP());
  }
  ret.add_inst(SMC_SLEEP(4));
  ret.add_inst(SMC_PRE(bank_reg, 0, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());

  ret.add_inst(SMC_MV(PATTERN_REG, TEMP_PATTERN_REG));
  ret.add_inst(SMC_MV(INV_PATTERN_REG, PATTERN_REG));
  ret.add_inst(SMC_MV(TEMP_PATTERN_REG, INV_PATTERN_REG));
  for(int i = 0 ; i < 16 ; i++)
    ret.add_inst(SMC_LDWD(PATTERN_REG,i));

  ret.add_inst(SMC_ACT(bank_reg, 0, row_reg, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));
  
  for(int i = 0 ; i < 32 ; i++)
  {
    ret.add_inst(SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0));
    ret.add_inst(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP());
  }
  ret.add_inst(SMC_SLEEP(4));
  ret.add_inst(SMC_PRE(bank_reg, 0, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));

  ret.add_inst(SMC_ACT(bank_reg, 0, row_reg, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));
  
  for(int i = 0 ; i < 32 ; i++)
  {
    ret.add_inst(SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0));
    ret.add_inst(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP());
  }
  ret.add_inst(SMC_SLEEP(4));
  ret.add_inst(SMC_PRE(bank_reg, 0, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));

  ret.add_inst(SMC_ACT(bank_reg, 0, row_reg, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));
  
  for(int i = 0 ; i < 32 ; i++)
  {
    ret.add_inst(SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0));
    ret.add_inst(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP());
  }
  ret.add_inst(SMC_SLEEP(4));
  ret.add_inst(SMC_PRE(bank_reg, 0, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));

  ret.add_inst(SMC_MV(PATTERN_REG, TEMP_PATTERN_REG));
  ret.add_inst(SMC_MV(INV_PATTERN_REG, PATTERN_REG));
  ret.add_inst(SMC_MV(TEMP_PATTERN_REG, INV_PATTERN_REG));
  for(int i = 0 ; i < 16 ; i++)
    ret.add_inst(SMC_LDWD(PATTERN_REG,i));

  ret.add_inst(SMC_SUBI(row_reg, no_rows, row_reg));
  return ret;
}

/**
 * This function will generate a block of instructions that will
 * write to a range of rows. It assumes the bank will be precharged.
 */

Program genWriteRange(int row_reg, int no_rows, int bank_reg, bool stripes)
{
  Program ret;
  ret.add_inst(SMC_LI(no_rows, INIT_LOOP));
  ret.add_inst(SMC_ADD(INIT_LOOP, row_reg, INIT_LOOP)); // write until this row
  
  ret.add_label("genWriteRange:LOOP_BEGIN");
  ret.add_inst(SMC_LI(0, CAR));
  ret.add_inst(SMC_ACT(bank_reg, 0, row_reg, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));
  for(int i = 0 ; i < 64 ; i++)
  {
    ret.add_inst(SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_WRITE(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  }
  ret.add_inst(SMC_SLEEP(4));
  ret.add_inst(SMC_PRE(bank_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  if(stripes)
  {
    ret.add_inst(SMC_MV(PATTERN_REG, TEMP_PATTERN_REG));
    ret.add_inst(SMC_MV(INV_PATTERN_REG, PATTERN_REG));
    ret.add_inst(SMC_MV(TEMP_PATTERN_REG, INV_PATTERN_REG));
    for(int i = 0 ; i < 16 ; i++)
      ret.add_inst(SMC_LDWD(PATTERN_REG,i));
  }
  ret.add_branch(ret.BR_TYPE::BL, row_reg, INIT_LOOP, "genWriteRange:LOOP_BEGIN");
  ret.add_inst(SMC_SUBI(row_reg, no_rows, row_reg));
  return ret;
}

Program genReadRange(int row_reg, int no_rows, int bank_reg)
{
  Program ret;
  ret.add_inst(SMC_LI(no_rows, INIT_LOOP));
  ret.add_inst(SMC_ADD(INIT_LOOP, row_reg, INIT_LOOP)); // read until this row
  ret.add_label("genReadRange:LOOP_BEGIN");
  ret.add_inst(SMC_LI(0, CAR)); // TODO: fix this
  ret.add_inst(SMC_ACT(bank_reg, 0, row_reg, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));
  for(int i = 0 ; i < 64 ; i++)
  {
    ret.add_inst(SMC_READ(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_READ(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  }
  ret.add_inst(SMC_SLEEP(4));
  ret.add_inst(SMC_PRE(bank_reg, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_branch(ret.BR_TYPE::BL, row_reg, INIT_LOOP, "genReadRange:LOOP_BEGIN");
  /*  
  ret.add_inst(SMC_SLEEP(5));
  ret.dump_registers();
  ret.add_inst(SMC_END());
  */
  ret.add_inst(SMC_SUBI(row_reg, no_rows, row_reg));
  return ret;
}
/**
 * @return an instruction formed by NOPs
 */
Inst all_nops()
{
  return  __pack_mininsts(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
}

Program gen_test_prog(int bank, int r1, int r2,int iters)
{
  Program program;

  program.add_inst(SMC_LI(8, CASR)); // Load 8 into CASR since each READ reads 8 columns
  program.add_inst(SMC_LI(1, BASR)); // Load 1 into BASR
  program.add_inst(SMC_LI(1, RASR)); // Load 1 into RASR

  program.add_inst(SMC_LI(0xffffffff, PATTERN_REG));
  program.add_inst(SMC_LI(0x00000000, INV_PATTERN_REG));
  for(int i = 0 ; i < 16 ; i++)
    program.add_inst(SMC_LDWD(PATTERN_REG,i));

  program.add_inst(SMC_LI(bank, BAR));
  program.add_inst(SMC_LI(r1-(r1%4), RARBASE));

  program.add_inst(SMC_LI(iters, ITER_REG));
  program.add_inst(SMC_LI(0, CTR_REG));

  program.add_label("WRITE_BEGIN");
  program.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  program.add_inst(SMC_SLEEP(3));
  program.add_below(genWriteRange(RARBASE, 4, BAR, true));
  //program.add_below(genWriteRange1000(RARBASE, 4, BAR));
  //program.add_below(genCopyRange(RARBASE, 4, BAR, true));
  program.add_inst(SMC_LI(r1, RAR1));
  program.add_inst(SMC_LI(r2, RAR2));
  
  program.add_below(genActPreActSequence(1, 1, RAR1, RAR2, BAR));

  program.add_inst(SMC_SLEEP(6));
  program.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());

  program.add_below(genReadRange(RARBASE, 1, BAR));
  program.add_inst(SMC_ADDI(CTR_REG, 1, CTR_REG));
  
  program.add_branch(program.BR_TYPE::BL, CTR_REG, ITER_REG, "WRITE_BEGIN");
  program.add_inst(SMC_END());

  return program;
}

bool nonoverlapping_pattern(std::vector<uint8_t> bv)
{
  unsigned wsize = bv.size()/8;
  uint8_t buf[wsize];
  for(int j = 0 ; j < wsize ; j++)
  {
    uint8_t intermediate = 0;
    for(int k = 0 ; k < 8 ; k++)
      intermediate = (intermediate << 1) | bv[j*8 + k];
    buf[j] = intermediate;
  }

  int bin[8] = {0};
  for (int i = 0 ; i < (1024*128*8 - 3) ; i += 3)
  {
    if (i % 8 < 6)
      bin[(buf[i/8] >> (i%8)) & 0x7]++;
    else
    {
      int next_bits = 3 - (8-(i%8));
      int next_mask = next_bits == 2 ? 0x3 : 0x1;
      int this_mask = next_bits == 2 ? 0x1 : 0x3;
      uint8_t next_pattern = (buf[(i/8)+1]) & next_mask;
      uint8_t this_pattern = (buf[i/8] >> (i%8)) & this_mask;
      bin[(next_pattern << (3-next_bits)) | this_pattern]++;
    }
  }
  
  bool pass = true;
  for (int i = 0 ; i < 8 ; i++)
  {
    cout << i << ": " << bin[i] << endl;
    if (bin[i] < 30000 || bin[i] > 55000)
      pass = false;
  }
  return pass;
}

vector<int> pre_filter(SoftMCPlatform& platform, int bank, int row)
{
  vector<int> cells_to_track;

  const int NO_CELLS = 64 * 1024;
  const int pre_pre_filter_iterations = 128*1024;
  const int threshold_size = 4096;

  Program prog = gen_test_prog(bank, row, row+3, pre_pre_filter_iterations);
  platform.execute(prog);
  uint8_t buf1[8*1024];
  uint8_t buf2[8*1024];

  vector<vector<uint8_t>> vnc_bitstreams;

  for (int i = 0 ; i < NO_CELLS ; i++)
    vnc_bitstreams.push_back(vector<uint8_t>());

  // Von neumann corrector first
  for (int i = 0 ; i < pre_pre_filter_iterations/2 ; i++)
  {
    platform.receiveData((char*)buf1, 8*1024);
    platform.receiveData((char*)buf2, 8*1024);

    for (int b = 0 ; b < NO_CELLS ; b++)
    {
      if(vnc_bitstreams[b].size() == threshold_size)
        continue;

      int b1 = (buf1[b/8] >> b%8) & 0x1;
      int b2 = (buf2[b/8] >> b%8) & 0x1;

      if (~b1 & b2)
        vnc_bitstreams[b].push_back(1);
      else if (b1 & ~b2)
        vnc_bitstreams[b].push_back(0);
    }
  }
  
  int cnt = 0;
  for (int b = 0 ; b < NO_CELLS ; b++)
  {
    if (vnc_bitstreams[b].size() == threshold_size)
      cnt++;
  }

  cout << cnt << " cells have passed initial filtering." << endl;

  // counter bins for each bitline
  int bin[NO_CELLS][8];
  for (int i = 0 ; i < NO_CELLS ; i++)
  {
    for (int j = 0 ; j < 8 ; j++)
      bin[i][j] = 0;
  }

  int freq[NO_CELLS] = {0};

  for (int b = 0 ; b < NO_CELLS ; b++)
  {
    if (vnc_bitstreams[b].size() < threshold_size - 1)
      continue;
    for (int i = 0 ; i < (threshold_size - 1)/3 ; i++)
    {
      int b1 = vnc_bitstreams[b][i] & 0x1;
      int b2 = vnc_bitstreams[b][i+1] & 0x1;
      int b3 = vnc_bitstreams[b][i+2] & 0x1;

      if (b1)
        freq[b]++;
      if (b2)
        freq[b]++;
      if (b3)
        freq[b]++;

      bin[b][(b3 << 2) | (b2 << 1) | b1]++;
    }
  }

  bool passed_frequency[NO_CELLS] = {false};

  int upper_freq = threshold_size/2 + threshold_size/2/100;
  int lower_freq = threshold_size/2 - threshold_size/2/100;
  for (int i = 0 ; i < NO_CELLS ; i++)
  {
    if (vnc_bitstreams[i].size() < threshold_size - 1)
      continue;
    if (freq[i] < upper_freq && freq[i] > lower_freq)
      passed_frequency[i] = true;
  }

  cnt = 0;
  for (int b = 0 ; b < NO_CELLS ; b++)
  {
    if (passed_frequency[b])
      cnt++;
  }

  cout << cnt << " cells have passed frequency filtering." << endl;

  //cout << "Cell: " << i << endl;
  int lower_limit = ((threshold_size - 1) / 3 / 8)  - (((threshold_size - 1) / 3 / 8) / 10); 
  int upper_limit = ((threshold_size - 1) / 3 / 8)  + (((threshold_size - 1) / 3 / 8) / 10); 
  cout << "UL: " << upper_limit << " LL: " << lower_limit << endl;
  bool passed[NO_CELLS];

  for (int b = 0 ; b < NO_CELLS ; b++)
    passed[b] = true;

  for (int i = 0 ; i < NO_CELLS ; i++)
  {
    if (!passed_frequency[i])
    {
      passed[i] = false;
      continue;
    }
    for (int j = 0 ; j < 8 ; j++)
    {
      //cout << "Bin" << j << ": " << bin[i][j] << endl;
      if (bin[i][j] < lower_limit || bin[i][j] > upper_limit)
      {
        //cout << "Cell " << i <<  " Bin" << j << ": " << bin[i][j] << endl;
        passed[i] = false;
        break;
      }
    }
    if (passed[i])
      cout << i << " " << "PASSed" << endl;
  }

  for (int i = 0 ; i < NO_CELLS ; i++)
  {
    if (passed[i])
      cells_to_track.push_back(i);
  }

  return cells_to_track;
}

int main(int argc, char *argv[])
{
  SoftMCPlatform platform;
  int err;
  
  // buffer allocated for reading data from the board
  uint8_t buf[8*1024];
  uint8_t prev_read[8*1024];
  
  // Initialize the platform, opens file descriptors for the board PCI-E interface.
  if((err = platform.init()) != SOFTMC_SUCCESS){
      cerr << "Could not initialize SoftMC Platform: " << err << endl;
  }
  // reset the board to hopefully restore the board's state
  platform.reset_fpga();
  platform.set_aref(true);

  ifstream lfFile;
  string trackFn = string(argv[1]) + "/" + "lastrow.txt";
  lfFile.open(trackFn);

  int x=0;
  lfFile >> x;

  lfFile.close();

  for(int bank = 1 ; bank < NO_BANKS ; bank++)
  {
    for(int r1 = x ; r1 < NO_ROWS ; r1 += 4)
    {
      bool satisfied = false;
      #ifdef NEWFILTER
      vector<int> cell_pos = pre_filter(platform, bank, r1);
      #else
      // Enrollment phase: 
      // Look at switching activity of each cell in a row
      Program prog = gen_test_prog(bank, r1, r1+3, 32*1024);
      platform.execute(prog);
      int n_switches[64*1024]; // how many times each cell have switched
      fill(n_switches, n_switches + 64*1024, 0);
      platform.receiveData((char*)prev_read, 8*1024);
      for(int k = 0; k < 32*1024-1 ; k++)
      {
        platform.receiveData((char*)buf, 8*1024); // read one segment each iteration
        for(int i = 0 ; i < 8 * 1024 ; i++)
        {
          uint8_t diff = prev_read[i] ^ buf[i];
          for(int j = 0 ; j < 8 ; j++)
            n_switches[i*8 + j] += (diff >> j) & 0x1;
        }
        copy(begin(buf), end(buf), begin(prev_read));
      }
      vector<int> cell_pos; // Switching cell positions
      float total_bps = 0;
      for(int i = 0 ; i < 8*8*1024 ; i++)
      {
        // In total it takes 132ms to execute all the DRAM commands
        // We compute bps based on switching
        total_bps += (1000/132.f) * n_switches[i];
        if(n_switches[i] > 1000)
          cell_pos.push_back(i);
      }

      cout << "Finished enrollment for bank " << bank << 
          " row " << r1 << "... " << cell_pos.size() << " cells passed... Predicted bps " 
          << fixed << setw(11) << setprecision(6) << total_bps << endl;
      #endif

      cout << "Finished enrollment for bank " << bank << 
          " row " << r1 << "... " << cell_pos.size() << " cells passed..." << endl;
  
      if(cell_pos.size() == 0)
        continue;

      for (int i = 0 ; i < cell_pos.size() ; i++)
        cout << cell_pos[i] << " ";
      cout << endl;

      // Begin filtered acquisition phase
      vector<vector<uint8_t>> stream_per_cell;
      for(int i = 0 ; i < cell_pos.size() ; i++)
      {
        stream_per_cell.push_back(vector<uint8_t>());
      }

      int prev_bpc_i     = 0;
      int prev_cell_flips[cell_pos.size()]{0};

      int loop_count = 0;
      int loop_limit = 15;
      bool bcf = false; // has the best cell exceeded the threshold

      while(!satisfied)
      {
        if(loop_count == loop_limit)
        {
          cout << "Exiting because we have iterated enough times" << endl;
          break;
        }
        int iterations = 1024*1024;
        Program prog = gen_test_prog(bank, r1, r1+3, iterations);
        platform.execute(prog);
        
        for(int k = 0; k < iterations/2 ; k++)
        {
          platform.receiveData((char*)prev_read, 8*1024); // read one segment each iteration
          platform.receiveData((char*)buf, 8*1024); // read one segment each iteration
          //VON NEUMANN CORRECTOR BELOW
          for(int i = 0 ; i < cell_pos.size() ; i++)
          {
            uint8_t b1 = (prev_read[cell_pos[i]/8] >> (cell_pos[i]%8)) & 0x1;
            uint8_t b2 = (buf[cell_pos[i]/8] >> (cell_pos[i]%8)) & 0x1;
            uint8_t b3 = b1 ^ b2;
            if(!b3) continue;
            if(b2) stream_per_cell[i].push_back(1);
            else stream_per_cell[i].push_back(0);
          }
        }
    
        int bpc_flips = 0; // best performing cell flip count
        int bpc_i = 0; // best performing cell index
        for(int i = 0 ; i < cell_pos.size() ; i++)
        {
          if(stream_per_cell[i].size() > bpc_flips)
          {
            bpc_flips = stream_per_cell[i].size();
            bpc_i = i;
          }
        }

        /*
        cout << "Dumping # of switches per cell..." << endl;
        for(int i = 0 ; i < cell_pos.size() ; i++)
        {
          cout << "Cell#" << cell_pos[i] << " Got:" << stream_per_cell[i].size() - prev_cell_flips[i]
            << "Exp:" << 32*n_switches[cell_pos[i]] << endl;
        }
        */
        
        if(!bcf)
        {
          if(prev_bpc_i == bpc_i)
          {
            int remaining_bits = 1024*1024 - bpc_flips;
            int count_diff = bpc_flips - prev_cell_flips[bpc_i];
            if(remaining_bits/count_diff + 1 > 16)
            {
              cout << "Exiting because it will take too long" << endl;
              break;
            }
            if(remaining_bits < 0){
              cout << "Finished one cell, will keep iterating for 5 iterations" << endl;
              bcf = true;
              loop_limit = loop_count + 5;
            }
            else{
            cout << "It will take " << remaining_bits/count_diff + 1 << " more iterations to finish" << endl;
            cout << "Based on the best cell's performance which has flipped " << bpc_flips << " times so far" << endl;
            }   
          }else
          {
            cout << "Cannot approximate test time because the best performing cell changed" << endl;
            cout << "Was " << cell_pos[prev_bpc_i] << " Now " << cell_pos[bpc_i] << endl;
          }
        }
        cout << "Cells about to finish: " << endl;
        for(int i = 0 ; i < cell_pos.size() ; i++){
          if(stream_per_cell[i].size() > 768*1024)
            cout << cell_pos[i] << ":" << stream_per_cell[i].size() << " ";
          
          prev_cell_flips[i] = stream_per_cell[i].size();
        }
        cout << endl;
        prev_bpc_i = bpc_i;
        loop_count ++;
      }
      
      cout << "Writing bitstreams..." << endl;
      int filtered_streams = 0;
      for(int i = 0 ; i < cell_pos.size() ; i++){
        if(stream_per_cell[i].size() >= 1024*1024){ //&& nonoverlapping_pattern(stream_per_cell[i])){
          ofstream dump_file;
          filtered_streams++;
          string fn = string(argv[1]) + "/" + to_string(bank) + "_" + to_string(r1) +
                      "_" + to_string(r1+3) + "_" + to_string(cell_pos[i]);
          dump_file.open(fn, ofstream::binary);
          unsigned wsize = stream_per_cell[i].size()/8;
          uint8_t wbuf[wsize];
          for(int j = 0 ; j < wsize ; j++)
          {
            uint8_t intermediate = 0;
            for(int k = 0 ; k < 8 ; k++)
              intermediate = (intermediate << 1) | stream_per_cell[i][j*8 + k];
            wbuf[j] = intermediate;
          }
          dump_file.write((char*)wbuf, wsize);
          dump_file.close();
        }
      }
      //cout << "Filtered streams: " << filtered_streams << endl;
      cout << "Finished processing b:" << bank << " r1:" << r1 << " r2:" << r1+3 << endl;
      ofstream lfFile;
      string trackFn = string(argv[1]) + "/" + "lastrow.txt";
      lfFile.open(trackFn);
      lfFile << r1;
      lfFile.close();
    }
  }
}
