#include "instruction.h"
#include <assert.h>
#include <stdio.h>

Inst SMC_ADD(int rs1, int rs2, int rt)
{
  Inst fu_code = (uint64_t)__ADD << __FU_CODE;
  Inst s_regs  = (rs2 << __RS2) | rs1;
  Inst t_reg   = rt << __RT;

  Inst inst    = fu_code | s_regs | t_reg;

  return inst;
}
Inst SMC_ADDI(int rs1, uint32_t imd, int rt)
{
  Inst fu_code = (uint64_t)__ADDI << __FU_CODE;
  Inst s_reg   = rs1;
  Inst imd1    = imd << __IMD1;
  Inst t_reg   = rt << __RT;

  Inst inst    = fu_code | s_reg | imd1 | t_reg;

  return inst;
}
Inst SMC_SUB(int rs1, int rs2, int rt)
{
  Inst fu_code = (uint64_t)__SUB << __FU_CODE;
  Inst s_regs  = (rs2 << __RS2) | rs1;
  Inst t_reg   = rt << __RT;

  Inst inst    = fu_code | s_regs | t_reg;

  return inst;
}
Inst SMC_SUBI(int rs1, uint32_t imd, int rt)
{
  Inst fu_code = (uint64_t)__SUBI << __FU_CODE;
  Inst s_reg   = rs1;
  Inst imd1    = imd << __IMD1;
  Inst t_reg   = rt << __RT;

  Inst inst    = fu_code | s_reg | imd1 | t_reg;

  return inst;
}
Inst SMC_LI(uint32_t imd, int rt)
{
  Inst fu_code = (uint64_t)__LI << __FU_CODE;
  Inst imd1    = ((uint32_t)(imd<<16)>>16) << __IMD1;
  Inst imd2    = (uint64_t)(((uint32_t)imd)>>16) << __IMD3;
  Inst t_reg   = rt << __RT;

  Inst inst    = fu_code | imd1 | imd2 | t_reg;

  return inst;
}
Inst SMC_MV(int rs1, int rt)
{
  Inst fu_code = (uint64_t)__MV << __FU_CODE;
  Inst s_reg   = rs1;
  Inst t_reg   = rt << __RT;

  Inst inst    = fu_code | s_reg | t_reg;

  return inst;
}
Inst SMC_SRC(int rs1, int rt)
{
  Inst fu_code = (uint64_t)__SRC << __FU_CODE;
  Inst s_reg   = rs1;
  Inst t_reg   = rt << __RT;

  Inst inst    = fu_code | s_reg | t_reg;

  return inst;
}
Inst SMC_LDWD(int rs1, int off)
{
  Inst fu_code = (uint64_t)__LDWD << __FU_CODE;
  Inst s_reg   = rs1;
  Inst offset  = off << __RT;

  Inst inst    = fu_code | s_reg | offset;

  return inst;
}
Inst SMC_LDPC(PC_TYPE pc_type, int rt)
{
  Inst fu_code = (uint64_t)__LDPC << __FU_CODE;
  Inst pc_reg = 2;
  Inst t_reg   = rt << __RT;
  switch(pc_type){
    case PC_TYPE::WRITE:
      pc_reg = 0;
      break;
    case PC_TYPE::READ:
      pc_reg = 1;
      break;
    case PC_TYPE::PRE:
      pc_reg = 2;
      break;
    case PC_TYPE::ACT:
      pc_reg = 3;
      break;
    case PC_TYPE::ZQ:
      pc_reg = 4;
      break;
    case PC_TYPE::REF:
      pc_reg = 5;
      break;
    case PC_TYPE::CYC:
      pc_reg = 6;
      break;
  }

  Inst inst    = fu_code | pc_reg | t_reg;

  return inst;
}
Inst SMC_BL(int rs1, int rs2, int tgt)
{
  Inst op_code = (uint64_t)0x1 << __IS_BR;
  Inst fu_code = (uint64_t)__BL << __FU_CODE;
  Inst s_regs  = (rs2 << __RS2) | rs1;
  Inst target  = (uint64_t)tgt << __BR_TGT;

  Inst inst    = op_code | fu_code | s_regs | target;

  return inst;
}
Inst SMC_BEQ(int rs1, int rs2, int tgt)
{
  Inst op_code = (uint64_t)0x1 << __IS_BR;
  Inst fu_code = (uint64_t)__BEQ << __FU_CODE;
  Inst s_regs  = (rs2 << __RS2) | rs1;
  Inst target  = (uint64_t)tgt << __BR_TGT;

  Inst inst    = op_code | fu_code | s_regs | target;

  return inst;
}
Inst SMC_JUMP(int tgt)
{
  Inst op_code = (uint64_t)0x1 << __IS_BR;
  Inst fu_code = (uint64_t)__JUMP << __FU_CODE;
  Inst target  = tgt;

  Inst inst    = op_code | fu_code | target;

  return inst;
}
Inst SMC_SLEEP(uint32_t samt)
{
  assert(samt > 2 && "Cannot sleep for less than 3 cycles.");
  Inst op_code = (uint64_t)0x1 << __IS_BR;
  Inst fu_code = (uint64_t)__SLEEP << __FU_CODE;

  samt        -= 2;

  Inst inst    = op_code | fu_code | samt;

  return inst;
}
Inst SMC_LD(int rb, int offset, int rt)
{
  Inst op_code = (uint64_t)0x1 << __IS_MEM;
  Inst fu_code = (uint64_t)__LD << __FU_CODE;
  Inst s_reg   = rb;
  Inst imd1    = offset << __IMD1;
  Inst t_reg   = rt << __RT;

  Inst inst    = op_code | fu_code | s_reg | imd1 | t_reg;

  return inst;
}
Inst SMC_ST(int rb, int offset, int rv)
{
  Inst op_code = (uint64_t)0x1 << __IS_MEM;
  Inst fu_code = (uint64_t)__ST << __FU_CODE;
  Inst b_reg   = rb;
  Inst imd1    = offset << __IMD1;
  Inst v_reg   = rv << __RT; // We cannot have imd1 and rs2 present simultaneously

  Inst inst    = op_code | fu_code | b_reg | imd1 | v_reg;

  return inst;
}
Inst SMC_AND(int rs1, int rs2, int rt)
{
  Inst op_code = (uint64_t)0x1 << __IS_BW;
  Inst fu_code = (uint64_t)__AND << __FU_CODE;
  Inst s_regs  = (rs2 << __RS2) | rs1;
  Inst t_reg   = rt << __RT;

  Inst inst    = op_code | fu_code | s_regs | t_reg;

  return inst;
}
Inst SMC_OR(int rs1, int rs2, int rt)
{
  Inst op_code = (uint64_t)0x1 << __IS_BW;
  Inst fu_code = (uint64_t)__OR << __FU_CODE;
  Inst s_regs  = (rs2 << __RS2) | rs1;
  Inst t_reg   = rt << __RT;

  Inst inst    = op_code | fu_code | s_regs | t_reg;

  return inst;
}
Inst SMC_XOR(int rs1, int rs2, int rt)
{
  Inst op_code = (uint64_t)0x1 << __IS_BW;
  Inst fu_code = (uint64_t)__XOR << __FU_CODE;
  Inst s_regs  = (rs2 << __RS2) | rs1;
  Inst t_reg   = rt << __RT;

  Inst inst    = op_code | fu_code | s_regs | t_reg;

  return inst;
}
Inst SMC_END()
{
  return 0;
}
Inst SMC_INFO(int rdcnt)
{
  Inst op_code = (uint64_t)0x1 << __IS_MISC;
  Inst fu_code = (uint64_t)__INFO << __FU_CODE;
  return op_code | fu_code | (uint64_t) rdcnt;
}
Mininst SMC_WRITE(int bar, int ibar, int car, int icar, int BL4, int ap)
{
  Mininst fu_code   = ((uint64_t)__WRITE) << __DDR_CMD;
  Mininst i_bar     = bar;
  Mininst i_car     = car << __DDR_CAR;
  Mininst i_ibar    = ibar << __DDR_IBAR;
  Mininst i_icar    = icar << __DDR_ICAR;
  Mininst i_BL4     = BL4 << __DDR_BL4;
  Mininst i_ap      = ap <<__DDR_AP;

  Mininst inst = fu_code | i_bar | i_car | i_ibar |
          i_icar | i_BL4 | i_ap;

  return inst;
}
Mininst SMC_READ(int bar, int ibar, int car, int icar, int BL4, int ap)
{
  Mininst fu_code   = ((uint64_t)__READ) << __DDR_CMD;
  Mininst i_bar     = bar;
  Mininst i_car     = car << __DDR_CAR;
  Mininst i_ibar    = ibar << __DDR_IBAR;
  Mininst i_icar    = icar << __DDR_ICAR;
  Mininst i_BL4     = BL4 << __DDR_BL4;
  Mininst i_ap      = ap <<__DDR_AP;

  Mininst inst = fu_code | i_bar | i_car | i_ibar |
          i_icar | i_BL4 | i_ap;

  return inst;
}
Mininst SMC_PRE(int bar, int ibar, int pall)
{
  Mininst fu_code   = ((uint64_t)__PRE) << __DDR_CMD;
  Mininst i_bar     = bar;
  Mininst i_ibar    = ibar << __DDR_IBAR;
  Mininst i_pall    = pall << __DDR_PALL;

  Mininst inst = fu_code | i_bar | i_ibar | i_pall;

  return inst;
}
Mininst SMC_ACT(int bar, int ibar, int rar, int irar)
{
  Mininst fu_code   = ((uint64_t)__ACT) << __DDR_CMD;
  Mininst i_bar     = bar;
  Mininst i_rar     = rar << __DDR_RAR;
  Mininst i_ibar    = ibar << __DDR_IBAR;
  Mininst i_irar    = irar << __DDR_IRAR;

  Mininst inst = fu_code | i_bar | i_rar | i_ibar | i_irar;

  return inst;
}
Mininst SMC_ZQ()
{
  Mininst fu_code   = ((uint64_t)__ZQ) << __DDR_CMD;

  return fu_code;
}
Mininst SMC_REF()
{
  Mininst fu_code   = ((uint64_t)__REF) << __DDR_CMD;

  return fu_code;
}
Mininst SMC_NOP()
{
  Mininst fu_code   = ((uint64_t)__NOP) << __DDR_CMD;

  return fu_code;
}
Inst SMC_SRE()
{
  Inst op_code = (uint64_t) 0x1 << 56;
  Inst fu_code = (uint64_t)__SRE << __FU_CODE;

  return fu_code | op_code;
}
Inst SMC_SRX()
{
  Inst op_code = (uint64_t) 0x1 << 56;
  Inst fu_code = (uint64_t)__SRX << __FU_CODE;

  return fu_code | op_code;
}
Inst __pack_mininsts(Mininst i1, Mininst i2, Mininst i3, Mininst i4)
{
  return (uint64_t) i4 << 48 |
        (uint64_t) i3 << 32 |
        (uint64_t) i2 << 16 |
        i1  ;
}

int is_conditional(Inst i)
{
  uint64_t fcode = (i >> __FU_CODE) & 0x7ff;
  switch (fcode) {
    case 0:
      return 1;
    case 1:
      return 1;
  }
  return 0;
}

int is_branch(Inst i)
{
  uint64_t fcode = (i >> __OP_CODE);
  //printf("%ld\n",fcode);
  switch (fcode) {
    case 8:
      return 1;
  }
  return 0;
}

int is_ddr(Inst i)
{
  uint64_t fcode = i >> __IS_DDR;
  return fcode == 1;
}

int is_load(Inst i)
{
  uint64_t fcode = i >> __FU_CODE;
  return fcode == 4096;
}

int is_sleep(Inst i)
{
  uint64_t fcode = i >> __FU_CODE;
  return fcode == 19;
}

int is_ddr_read(Inst inst)
{
  int ctr = 0;
  for (size_t i = 0 ; i < 4 ; i++)
  {
    Mininst min = inst >> (i*16);
    ctr += (min >> __DDR_CMD) == (Mininst) __READ;
  }
  return ctr;
}

void decode_inst(Inst inst)
{
  if(is_ddr(inst))
  {
    for(int i = 0 ; i < 4 ; i++)
    {
      Mininst mini = (inst >> i*16);
      decode_ddr(mini);
      if (i<3) printf(" : ");
    }
  }
  else
  {
    int fu_code = inst >> __FU_CODE;
    int fc_mask = 0x7ff;
    fu_code     = fu_code & fc_mask;
    int op_code = inst >> __OP_CODE;
    int is_br   = op_code == 0x8;
    int is_mem  = op_code == 0x2;
    int is_bw   = op_code == 0x1;
    int is_misc = op_code == 0x4;
    int is_arit = op_code == 0x0;
    uint64_t rid_mask = 0xf;
    uint64_t imd_mask = 0xffff;
    uint64_t br_tgt_mask = 0x7ffff;
    uint64_t jmp_tgt_mask = 0x7ffffff;
    int rs1     = (inst >> __RS1) & rid_mask;
    int rs2     = (inst >> __RS2) & rid_mask;
    int rt      = (inst >> __RT)  & rid_mask;
    int imd1    = (inst >> __IMD1) & imd_mask;
    int imd3    = (inst >> __IMD3) & imd_mask;
    int bt      = (inst >> __BR_TGT) & br_tgt_mask;
    int jt      = (inst >> __J_TGT) & jmp_tgt_mask;
    int samt    = (uint32_t)inst;
    uint64_t imd_concat = ((uint64_t)imd3 << 16) + imd1;
    if (is_arit)
    {
      switch (fu_code)
      {
        case __ADD:
          if(inst == 0)
            printf("END");
          else 
            printf("ADD r%d r%d r%d", rt, rs1, rs2);
          break;
        case __ADDI:
          printf("ADDI r%d r%d %d", rt, rs1, imd1);
          break;
        case __SUB:
          printf("SUB r%d r%d r%d", rt, rs1, rs2);
          break;
        case __SUBI:
          printf("SUBI r%d r%d %d", rt, rs1, imd1);
          break;
        case __MV:
          printf("MOV r%d r%d", rt, rs1);
          break;
        case __LI:
          printf("LI r%d %ld", rt, imd_concat);
          break;
        case __SRC:
          printf("SRC r%d r%d", rt, rs1);
          break;
        case __LDWD:
          printf("LDWD %d r%d", rt, rs1);
          break;
        case __LDPC:
          switch(rs1){
            case 0:
              printf("LDPC r%d WRITE_COUNTER", rt);
              break;
            case 1:
              printf("LDPC r%d READ_COUNTER", rt);
              break;
            case 2:
              printf("LDPC r%d PRE_COUNTER", rt);
              break;
            case 3:
              printf("LDPC r%d ACT_COUNTER", rt);
              break;
            case 4:
              printf("LDPC r%d ZQ_COUNTER", rt);
              break;
            case 5:
              printf("LDPC r%d REF_COUNTER", rt);
              break;
            case 6:
              printf("LDPC r%d TOTAL_CYCLE", rt);
              break;
          }
          break;
        case __SRE:
          printf("SRE");
          break;
        case __SRX:
          printf("SRX");
          break;
      }
    } else if (is_br)
    {
      switch (fu_code)
      {
        case __BL:
          printf("BL PC:%d r%d r%d", bt, rs1, rs2);
          break;
        case __BEQ:
          printf("BEQ PC:0x%x r%d r%d", bt, rs1, rs2);
          break;
        case __JUMP:
          printf("JUMP PC:%d", jt);
          break;
        case __SLEEP:
          printf("SLEEP %d cycles", samt);
          break;
      } 
    } else if (is_misc)
    {
      switch (fu_code)
      {
        case __INFO:
          printf("Auto-generated instruction.");
          break;
      }
    } else if (is_mem)
    {
      switch (fu_code)
      {
        case __LD:
          printf("LD r%d [r%d]%d", rt, rs1, imd1);
          break;
        case __ST:
          printf("ST [r%d]%d r%d", rs1, imd1, rt);
          break;
      } 
    } else if (is_bw)
    {
      switch (fu_code)
      {
        case __AND:
          printf("AND r%d r%d r%d", rt, rs1, rs2);
          break;
        case __OR:
          printf("OR r%d r%d r%d", rt, rs1, rs2);
          break;
        case __XOR:
          printf("XOR r%d r%d r%d", rt, rs1, rs2);
          break;
      } 
    }
  }
}

void decode_ddr(Mininst i)
{
  int ddr_code = i >> __DDR_CMD;
  uint64_t rid_mask = 0xf;
  int car      = (i >> __DDR_CAR) & rid_mask;
  int bar      = (i >> __DDR_BAR) & rid_mask;
  int rar      = (i >> __DDR_RAR) & rid_mask;
  int icar     = (i >> __DDR_ICAR) & 0x1;
  int ibar     = (i >> __DDR_IBAR) & 0x1;
  int irar     = (i >> __DDR_IRAR) & 0x1;
  int pall     = (i >> __DDR_PALL) & 0x1;
  int ap       = (i >> __DDR_AP) & 0x1;
  int bc       = (i >> __DDR_BL4) & 0x1;

  switch(ddr_code)
  {
    case __WRITE:
      printf("WR r%d%s r%d%s%s%s", bar, ibar?"++":"", car, icar?"++":"",
        ap?" AP":"",bc?" BC":"");
      break;
    case __READ:
      printf("RD r%d%s r%d%s%s%s", bar, ibar?"++":"", car, icar?"++":"",
        ap?" AP":"",bc?" BC":"");
      break;
    case __PRE:
      printf("PRE r%d%s%s", bar, ibar?"++":"", pall?" PALL":"");
      break;
    case __ACT:
      printf("ACT r%d%s r%d%s", bar, ibar?"++":"", rar, irar?"++":"");
      break;
    case __ZQ:
      printf("ZQ");
      break;
    case __REF:
      printf("REF");
      break;
    case __NOP:
      printf("NOP");
      break;
  }
}

void print_bits(size_t const size, void const * const ptr)
{
  unsigned char *b = (unsigned char*) ptr;
  unsigned char byte;
  int i, j;

  for (i=size-1;i>=0;i--)
  {
    for (j=7;j>=0;j--)
    {
      byte = (b[i] >> j) & 1;
      printf("%u", byte);
    }
  }
  printf("\n");
}
