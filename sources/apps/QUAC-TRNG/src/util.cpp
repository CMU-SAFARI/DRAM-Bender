#include "util.h"

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

Program genReadRange(int row_reg, int no_rows, int bank_reg, int read_cols)
{
  Program ret;
  ret.add_inst(SMC_LI(no_rows, INIT_LOOP));
  ret.add_inst(SMC_ADD(INIT_LOOP, row_reg, INIT_LOOP)); // read until this row
  ret.add_label("genReadRange:LOOP_BEGIN");
  ret.add_inst(SMC_LI(0, CAR));
  ret.add_inst(SMC_ACT(bank_reg, 0, row_reg, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_inst(SMC_SLEEP(4));

  for(int i = 0 ; i < read_cols/4 ; i++)
  {
    ret.add_inst(SMC_READ(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_READ(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP(), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_READ(bank_reg, 0, CAR, 1, 0, 0), SMC_NOP());
    ret.add_inst(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_READ(bank_reg, 0, CAR, 1, 0, 0));
    ret.add_inst(SMC_NOP(),SMC_NOP(),SMC_NOP(),SMC_NOP());
  }
  ret.add_inst(SMC_SLEEP(4));
  ret.add_inst(SMC_PRE(bank_reg, 0, 1), SMC_NOP(), SMC_NOP(), SMC_NOP());
  ret.add_branch(ret.BR_TYPE::BL, row_reg, INIT_LOOP, "genReadRange:LOOP_BEGIN");
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
Program genWriteRange1001(int row_reg, int no_rows, int bank_reg)
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

  ret.add_inst(SMC_SUBI(row_reg, no_rows, row_reg));
  return ret;
}

/**
 * This function will generate a block of instructions that will
 * write to a range of rows. It assumes the bank will be precharged.
 */
Program genWriteRange1010(int row_reg, int no_rows, int bank_reg)
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

  ret.add_branch(ret.BR_TYPE::BL, row_reg, INIT_LOOP, "genWriteRange:LOOP_BEGIN");
  ret.add_inst(SMC_SUBI(row_reg, no_rows, row_reg));
  return ret;
}

/**
 * This function will generate a block of instructions that will
 * write to a range of rows. It assumes the bank will be precharged.
 */
Program genWriteRange1011(int row_reg, int no_rows, int bank_reg)
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

  ret.add_inst(SMC_SUBI(row_reg, no_rows, row_reg));
  return ret;
}

/**
 * This function will generate a block of instructions that will
 * write to a range of rows. It assumes the bank will be precharged.
 */
Program genWriteRange1100(int row_reg, int no_rows, int bank_reg)
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
Program genWriteRange1101(int row_reg, int no_rows, int bank_reg)
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



  ret.add_inst(SMC_SUBI(row_reg, no_rows, row_reg));
  return ret;
}

/**
 * This function will generate a block of instructions that will
 * write to a range of rows. It assumes the bank will be precharged.
 */
Program genWriteRange1110(int row_reg, int no_rows, int bank_reg)
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
Program genWriteRange1111(int row_reg, int no_rows, int bank_reg)
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

  ret.add_branch(ret.BR_TYPE::BL, row_reg, INIT_LOOP, "genWriteRange:LOOP_BEGIN");
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
