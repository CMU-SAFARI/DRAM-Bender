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
#include <bitset>

using namespace std;

#define buffer_size 8192*8

#define NUM_BANKS 1 //16
#define NUM_ROWS (1024*32)

// Stride register ids are fixed and should not be changed
// CASR should always be reg 0
#define CASR 0
// BASR should always be reg 1
#define BASR 1
// RASR should always be reg 2
#define RASR 2

#define CONSTANT 8
#define OP1 12
#define OP2 13

#define BAR 3
#define CAR 4
#define RAR 5
#define SRC 6
#define DST 7

#define INIT_LOOP 9

#define TEMP1 10
#define NUM_ROWS_REG 11


/**
 * @return an instruction formed by NOPs
 */
Inst all_nops()
{
  return  __pack_mininsts(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
}

SoftMCPlatform platform;

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

Program genReadRange(int row_reg, int no_rows, int bank_reg)
{
  Program ret;
  ret.add_inst(SMC_LI(no_rows, INIT_LOOP));
  ret.add_inst(SMC_ADD(INIT_LOOP, row_reg, INIT_LOOP)); // read until this row
  ret.add_label("genReadRange:LOOP_BEGIN");
  ret.add_inst(SMC_LI(0, CAR));
  ret.add_inst(SMC_ACT(bank_reg, 0, row_reg, no_rows>1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));
  for(int i = 0 ; i < 128 ; i++)
  {
    ret.add_inst(SMC_READ(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
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

Program writeRowSlow(unsigned int _BAR, unsigned int _RAR, unsigned int _CAR, unsigned int _PATTERN_REG, unsigned int _TEMP1, string label)
{
  Program prog;

  for (int i = 0 ; i < 16 ; i++)
    prog.add_inst(SMC_LDWD(_PATTERN_REG, i));

  prog.add_inst(SMC_LI(1024, TEMP1));

  prog.add_inst(SMC_LI(0, _CAR));
  prog.add_inst(SMC_ACT(_BAR, 0, _RAR, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_label("WRS:BEGIN" + label);
  prog.add_inst(SMC_WRITE(_BAR, 0, _CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_branch(prog.BR_TYPE::BL, _CAR, TEMP1, "WRS:BEGIN" + label);
  prog.add_inst(SMC_PRE(_BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_inst(SMC_SLEEP(3));

  return prog;
}

Program AMBITTest(bool andOp, unsigned int op1, unsigned int op2, unsigned int t1, unsigned int t2, int op1Placement, int op2Placement, int constantPlacement)
{
  Program prog;

  prog.add_inst(SMC_LI(8, CASR));
  prog.add_inst(SMC_LI(0, BASR));
  prog.add_inst(SMC_LI(1, RASR));
  prog.add_inst(SMC_LI(1, BAR));
  prog.add_inst(SMC_LI(0, RAR));
  prog.add_inst(SMC_LI(NUM_ROWS, NUM_ROWS_REG));
  prog.add_label("SEGMENT_BEGIN");
  for(int i = 0 ; i < 4 ; i++)
  {
    if(i == op1Placement)
    {
      prog.add_inst(SMC_LI(op1, OP1));
      prog.add_below(writeRowSlow(BAR, RAR, CAR, OP1, TEMP1, "one"));
    }
    else if (i == op2Placement)
    {
      prog.add_inst(SMC_LI(op2, OP2));
      prog.add_below(writeRowSlow(BAR, RAR, CAR, OP2, TEMP1, "two"));      
    }
    else if (i == constantPlacement)
    {
      prog.add_inst(SMC_LI(andOp ? 0x00000000 : 0xffffffff, CONSTANT));
      prog.add_below(writeRowSlow(BAR, RAR, CAR, CONSTANT, TEMP1, "three"));            
    }
    else
    {
      prog.add_inst(SMC_LI(0x00000000, CONSTANT));
      prog.add_below(writeRowSlow(BAR, RAR, CAR, CONSTANT, TEMP1, "four"));         
    }
    prog.add_inst(SMC_ADDI(RAR, 1, RAR));
  }

  prog.add_inst(SMC_SUBI(RAR, 3, SRC));
  prog.add_inst(SMC_SUBI(RAR, 2, DST));
  prog.add_below(genActPreActSequence(t1, t2, SRC, DST, BAR));

  prog.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
  prog.add_inst(SMC_PRE(BAR, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());

  //prog.dump_registers();

  prog.add_below(genReadRange(SRC, 3, BAR));
  prog.add_branch(prog.BR_TYPE::BL, RAR, NUM_ROWS_REG, "SEGMENT_BEGIN");
  prog.add_inst(SMC_END());

  return prog;
}

int main(int argc, char * argv[])
{
  if(platform.init() != SOFTMC_SUCCESS){
      cerr << "Could not initialize SoftMC Platform" << endl;
  }

  platform.reset_fpga();

  if (argc != 3)
  {
    cout << "Give me two arguments" << endl;
    exit(0);
  }
  bool andOp = false;

  if (atoi(argv[1]))
    andOp = true;
  else
    andOp = false;

  srand(time(NULL));

  ofstream fileOutput;
  fileOutput.open(argv[2]);
  fileOutput << "row,operation,op1,op2,t1,t2,op1-placement,op2-placement,constant-placement,bit-flips" << endl;

  for(int i_data = 0 ; i_data < 4 ; i_data++)
  {
    unsigned int dp1; 
    unsigned int dp2;

    if (i_data == 0) 
    {
      dp1 = 0x00000000;
      dp2 = 0x00000000;
    } 
    else if (i_data == 1)
    {
      dp1 = 0x00000000;
      dp2 = 0xffffffff;
    }
    else if (i_data == 2)
    {
      dp1 = 0xffffffff;
      dp2 = 0x00000000;
    }
    else if (i_data == 3)
    {
      dp1 = 0xffffffff;
      dp2 = 0xffffffff;
    }

    unsigned int expected = andOp ? (dp1 & dp2) : (dp1 | dp2);

    for (int t1 = 0 ; t1 < 10 ; t1++)
    {
      for (int t2 = 0 ; t2 < 10 ; t2++)
      {
        for (int pla = 0 ; pla < 3 ; pla++)
        {
          string platext;
          if (pla == 0)
          {
            cout << "Begin with " << (andOp ? "AND" : "OR") << " T1:" << t1 << " T2:" << t2 << " OP1:" << 0 << " OP2:" << 1 << " C:" << 2 << endl;
            Program prog = AMBITTest(andOp, dp1, dp2, t1, t2, 0, 1, 2);
            platext = "0,1,2";
            platform.execute(prog);
          }
          else if (pla == 1)
          {
            cout << "Begin with T1:" << t1 << " T2:" << t2 << " OP1:" << 0 << " OP2:" << 2 << " C:" << 1 << endl;
            Program prog = AMBITTest(andOp, dp1, dp2, t1, t2, 0, 2, 1);
            platext = "0,2,1";
            platform.execute(prog);          
          }
          else if (pla == 2)
          {
            cout << "Begin with T1:" << t1 << " T2:" << t2 << " OP1:" << 1 << " OP2:" << 2 << " C:" << 0 << endl;
            Program prog = AMBITTest(andOp, dp1, dp2, t1, t2, 1, 2, 0);
            platext = "1,2,0";
            platform.execute(prog);          
          }

          //platform.readRegisterDump();
          //exit(0);

          for (int row = 0 ; row < NUM_ROWS ; row += 4)
          {
            uint8_t rd_rows[3][8192];

            for(int i = 0 ; i < 3 ; i++) // Read three rows each main iteration
              platform.receiveData((void*)rd_rows[i], 8192);        

            uint32_t* readData1 = ((uint32_t*) rd_rows[0]); 
            uint32_t* readData2 = ((uint32_t*) rd_rows[1]); 
            uint32_t* readData3 = ((uint32_t*) rd_rows[2]); 
            unsigned long long errors = 0;
            bool noTRA = false;
            for(int i = 0 ; i < 8192/4 ; i++)
            {
              unsigned int differences;
              if (readData1[i] == readData2[i] && readData2[i] == readData3[i])
                differences = __builtin_popcount(readData1[i]^expected);
              else{ // if !TRA, assume errors
                noTRA = true;
                break;
              }
              errors += differences;
            }
            if(noTRA)
            {
              fileOutput << row << "," << (andOp ? "AND" : "OR") << "," << dp1 << "," << dp2 << "," << t1 << "," << t2 << "," << platext << "," << -1 << endl; 
              cout << "Row:" << row << " No TRA " << endl;
            }
            else
            {
              fileOutput << row << "," << (andOp ? "AND" : "OR") << "," << dp1 << "," << dp2 << "," << t1 << "," << t2 << "," << platext << "," << errors << endl; 
              cout << "Row:" << row << " Errors:" << errors << endl;             
            }
          }
        }
      }
    }
  }
  fileOutput.close();
  printf("\nTest Finished\n");
}
