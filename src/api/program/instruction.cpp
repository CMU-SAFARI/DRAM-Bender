#include "drambender/api/program/instruction.h"

#include <cstddef>
#include <stdexcept>

#include "instruction_internal.h"

namespace DRAMBender {

using namespace InstrEncoding;

namespace {

uint64_t function_code(Inst inst) {
  return (inst >> k_function_code_shift) & 0x7ff;
}

uint64_t opcode(Inst inst) {
  return inst >> k_opcode_shift;
}

}  // namespace

Inst all_nops() {
  return pack_mininsts(SMC_NOP(), SMC_NOP(), SMC_NOP(), SMC_NOP());
}

// ---------------------------------------------------------------------------
// Arithmetic
// ---------------------------------------------------------------------------

Inst SMC_ADD(int rs1, int rs2, int rt) {
  Inst fu = k_add << k_function_code_shift;
  Inst sr = (Inst(rs2) << k_rs2_shift) | Inst(rs1);
  Inst tr = Inst(rt) << k_rt_shift;
  return fu | sr | tr;
}

Inst SMC_ADDI(int rs1, uint32_t imd, int rt) {
  Inst fu = k_addi << k_function_code_shift;
  Inst sr = Inst(rs1);
  Inst im = Inst(imd) << k_immediate_low_shift;
  Inst tr = Inst(rt) << k_rt_shift;
  return fu | sr | im | tr;
}

Inst SMC_SUB(int rs1, int rs2, int rt) {
  Inst fu = k_sub << k_function_code_shift;
  Inst sr = (Inst(rs2) << k_rs2_shift) | Inst(rs1);
  Inst tr = Inst(rt) << k_rt_shift;
  return fu | sr | tr;
}

Inst SMC_SUBI(int rs1, uint32_t imd, int rt) {
  Inst fu = k_subi << k_function_code_shift;
  Inst sr = Inst(rs1);
  Inst im = Inst(imd) << k_immediate_low_shift;
  Inst tr = Inst(rt) << k_rt_shift;
  return fu | sr | im | tr;
}

Inst SMC_LI(uint32_t imd, int rt) {
  Inst fu   = k_li << k_function_code_shift;
  Inst low  = Inst(uint16_t(imd)) << k_immediate_low_shift;
  Inst high = Inst(imd >> 16) << k_immediate_high_shift;
  Inst tr   = Inst(rt) << k_rt_shift;
  return fu | low | high | tr;
}

Inst SMC_MV(int rs1, int rt) {
  Inst fu = k_mv << k_function_code_shift;
  return fu | Inst(rs1) | (Inst(rt) << k_rt_shift);
}

Inst SMC_SRC(int rs1, int rt) {
  Inst fu = k_src << k_function_code_shift;
  return fu | Inst(rs1) | (Inst(rt) << k_rt_shift);
}

// ---------------------------------------------------------------------------
// Bitwise
// ---------------------------------------------------------------------------

Inst SMC_AND(int rs1, int rs2, int rt) {
  Inst op = Inst(1) << k_opcode_shift;
  Inst fu = k_and << k_function_code_shift;
  Inst sr = (Inst(rs2) << k_rs2_shift) | Inst(rs1);
  Inst tr = Inst(rt) << k_rt_shift;
  return op | fu | sr | tr;
}

Inst SMC_OR(int rs1, int rs2, int rt) {
  Inst op = Inst(1) << k_opcode_shift;
  Inst fu = k_or << k_function_code_shift;
  Inst sr = (Inst(rs2) << k_rs2_shift) | Inst(rs1);
  Inst tr = Inst(rt) << k_rt_shift;
  return op | fu | sr | tr;
}

Inst SMC_XOR(int rs1, int rs2, int rt) {
  Inst op = Inst(1) << k_opcode_shift;
  Inst fu = k_xor << k_function_code_shift;
  Inst sr = (Inst(rs2) << k_rs2_shift) | Inst(rs1);
  Inst tr = Inst(rt) << k_rt_shift;
  return op | fu | sr | tr;
}

// ---------------------------------------------------------------------------
// Memory
// ---------------------------------------------------------------------------

Inst SMC_LD(int rb, int offset, int rt) {
  Inst op = Inst(1) << 60;  // IS_MEM
  Inst fu = k_ld << k_function_code_shift;
  Inst im = Inst(offset) << k_immediate_low_shift;
  Inst tr = Inst(rt) << k_rt_shift;
  return op | fu | Inst(rb) | im | tr;
}

Inst SMC_ST(int rb, int offset, int rv) {
  Inst op = Inst(1) << 60;  // IS_MEM
  Inst fu = k_st << k_function_code_shift;
  Inst im = Inst(offset) << k_immediate_low_shift;
  Inst vr = Inst(rv) << k_rt_shift;
  return op | fu | Inst(rb) | im | vr;
}

Inst SMC_LDWD(int rs1, int off) {
  Inst fu = k_ldwd << k_function_code_shift;
  return fu | Inst(rs1) | (Inst(off) << k_rt_shift);
}

Inst SMC_LDPC(PC_TYPE pc_type, int rt) {
  Inst fu = k_ldpc << k_function_code_shift;
  Inst tr = Inst(rt) << k_rt_shift;
  Inst pc_reg = 2;
  switch (pc_type) {
    case PC_TYPE::WRITE:  pc_reg = 0; break;
    case PC_TYPE::READ:   pc_reg = 1; break;
    case PC_TYPE::PRE:    pc_reg = 2; break;
    case PC_TYPE::ACT:    pc_reg = 3; break;
    case PC_TYPE::SEL_CH: pc_reg = 4; break;
    case PC_TYPE::REF:    pc_reg = 5; break;
    case PC_TYPE::CYC:    pc_reg = 6; break;
  }
  return fu | pc_reg | tr;
}

// ---------------------------------------------------------------------------
// Control flow
// ---------------------------------------------------------------------------

Inst SMC_BL(int rs1, int rs2, int tgt) {
  Inst op = Inst(1) << k_is_branch_shift;
  Inst fu = k_bl << k_function_code_shift;
  Inst sr = (Inst(rs2) << k_rs2_shift) | Inst(rs1);
  Inst tg = Inst(tgt) << k_branch_target_shift;
  return op | fu | sr | tg;
}

Inst SMC_BEQ(int rs1, int rs2, int tgt) {
  Inst op = Inst(1) << k_is_branch_shift;
  Inst fu = k_beq << k_function_code_shift;
  Inst sr = (Inst(rs2) << k_rs2_shift) | Inst(rs1);
  Inst tg = Inst(tgt) << k_branch_target_shift;
  return op | fu | sr | tg;
}

Inst SMC_JUMP(int tgt) {
  Inst op = Inst(1) << k_is_branch_shift;
  Inst fu = k_jump << k_function_code_shift;
  return op | fu | Inst(tgt);
}

Inst SMC_SLEEP(uint32_t samt) {
  if (samt <= 2) {
    throw std::invalid_argument("Cannot sleep for fewer than 3 cycles.");
  }
  Inst op = Inst(1) << k_is_branch_shift;
  Inst fu = k_sleep << k_function_code_shift;
  return op | fu | Inst(samt - 2);
}

Inst SMC_END() {
  return 0;
}

Inst SMC_INFO(int rdcnt) {
  Inst op = Inst(1) << 61;  // IS_MISC
  Inst fu = k_info << k_function_code_shift;
  return op | fu | Inst(rdcnt);
}

// ---------------------------------------------------------------------------
// Self-refresh
// ---------------------------------------------------------------------------

Inst SMC_SRE() {
  Inst op = Inst(1) << 56;
  Inst fu = k_sre << k_function_code_shift;
  return fu | op;
}

Inst SMC_SRX() {
  Inst op = Inst(1) << 56;
  Inst fu = k_srx << k_function_code_shift;
  return fu | op;
}

// ---------------------------------------------------------------------------
// DDR commands (16-bit mininsts)
// ---------------------------------------------------------------------------

Mininst SMC_WRITE(int bar, int ibar, int car, int icar, int rank, int ap) {
  Mininst cmd  = k_write << k_ddr_command_shift;
  Mininst ibl  = Mininst(ibar) << k_ddr_increment_bank_shift;
  Mininst icl  = Mininst(icar) << k_ddr_increment_column_shift;
  Mininst rk   = Mininst(rank) << k_ddr_rank_shift;
  Mininst apre = Mininst(ap) << k_ddr_auto_precharge_shift;
  return cmd | Mininst(bar) | (Mininst(car) << k_ddr_column_shift) | ibl | icl | rk | apre;
}

Mininst SMC_READ(int bar, int ibar, int car, int icar, int rank, int ap) {
  Mininst cmd  = k_read << k_ddr_command_shift;
  Mininst ibl  = Mininst(ibar) << k_ddr_increment_bank_shift;
  Mininst icl  = Mininst(icar) << k_ddr_increment_column_shift;
  Mininst rk   = Mininst(rank) << k_ddr_rank_shift;
  Mininst apre = Mininst(ap) << k_ddr_auto_precharge_shift;
  return cmd | Mininst(bar) | (Mininst(car) << k_ddr_column_shift) | ibl | icl | rk | apre;
}

Mininst SMC_PRE(int bar, int ibar, int pall, int rank) {
  Mininst cmd = k_pre << k_ddr_command_shift;
  Mininst ibl = Mininst(ibar) << k_ddr_increment_bank_shift;
  Mininst pal = Mininst(pall) << k_ddr_precharge_all_shift;
  Mininst rk  = Mininst(rank) << k_ddr_rank_shift;
  return cmd | Mininst(bar) | ibl | pal | rk;
}

Mininst SMC_ACT(int bar, int ibar, int rar, int irar, int rank) {
  Mininst cmd = k_act << k_ddr_command_shift;
  Mininst ibl = Mininst(ibar) << k_ddr_increment_bank_shift;
  Mininst irl = Mininst(irar) << k_ddr_increment_row_shift;
  Mininst rk  = Mininst(rank) << k_ddr_rank_shift;
  return cmd | Mininst(bar) | (Mininst(rar) << k_ddr_row_shift) | ibl | irl | rk;
}

Mininst SMC_SEL_CH(int channel, int pseudo_channel) {
  Mininst cmd = k_sel_ch << k_ddr_command_shift;
  Mininst pc  = Mininst(pseudo_channel) << k_ddr_rank_shift;
  return cmd | Mininst(channel) | pc;
}

Mininst SMC_REF(int rank) {
  return (k_ref << k_ddr_command_shift) | (Mininst(rank) << k_ddr_rank_shift);
}

Mininst SMC_NOP(int rank) {
  return (k_nop << k_ddr_command_shift) | (Mininst(rank) << k_ddr_rank_shift);
}

// ---------------------------------------------------------------------------
// InstrEncoding implementation
// ---------------------------------------------------------------------------

namespace InstrEncoding {

Inst pack_mininsts(Mininst i1, Mininst i2, Mininst i3, Mininst i4) {
  return Inst(i4) << 48 | Inst(i3) << 32 | Inst(i2) << 16 | i1;
}

bool is_conditional_branch(Inst inst) {
  const uint64_t fc = function_code(inst);
  return fc == k_bl || fc == k_beq;
}

bool is_branch(Inst inst) {
  return opcode(inst) == 0x8;
}

bool is_ddr(Inst inst) {
  return (inst >> k_is_ddr_shift) == 1;
}

bool is_load(Inst inst) {
  return opcode(inst) == 0x2 && function_code(inst) == k_ld;
}

bool is_sleep(Inst inst) {
  return is_branch(inst) && function_code(inst) == k_sleep;
}

int count_ddr_reads(Inst inst) {
  int count = 0;
  for (size_t i = 0; i < 4; ++i) {
    Mininst mi = Mininst(inst >> (i * 16));
    count += (mi >> k_ddr_command_shift) == k_read;
  }
  return count;
}


}  // namespace InstrEncoding

}  // namespace DRAMBender
