#ifndef DRAMINSPECTOR_SRC_API_PROGRAM_INSTRUCTION_INTERNAL_H
#define DRAMINSPECTOR_SRC_API_PROGRAM_INSTRUCTION_INTERNAL_H

#include "draminspector/api/program/instruction.h"

namespace DRAMBender::InstrEncoding {

// --- Inst (64-bit) bit-field shifts ----------------------------------------
inline constexpr Inst k_opcode_shift = 59;
inline constexpr Inst k_function_code_shift = 48;
inline constexpr Inst k_is_branch_shift = 62;
inline constexpr Inst k_is_ddr_shift = 63;

inline constexpr Inst k_rs1_shift = 0;
inline constexpr Inst k_rs2_shift = 4;
inline constexpr Inst k_rt_shift = 20;
inline constexpr Inst k_immediate_low_shift = 4;
inline constexpr Inst k_immediate_high_shift = 24;
inline constexpr Inst k_branch_target_shift = 8;
inline constexpr Inst k_jump_target_shift = 0;

// --- Inst (64-bit) function codes ------------------------------------------
inline constexpr Inst k_add = 0;
inline constexpr Inst k_addi = 1;
inline constexpr Inst k_sub = 2;
inline constexpr Inst k_subi = 3;
inline constexpr Inst k_mv = 4;
inline constexpr Inst k_src = 5;
inline constexpr Inst k_li = 6;
inline constexpr Inst k_ldwd = 7;
inline constexpr Inst k_ldpc = 8;
inline constexpr Inst k_sre = 0x100;
inline constexpr Inst k_srx = 0x101;
inline constexpr Inst k_bl = 0;
inline constexpr Inst k_beq = 1;
inline constexpr Inst k_jump = 2;
inline constexpr Inst k_sleep = 3;
inline constexpr Inst k_info = 0;
inline constexpr Inst k_and = 0;
inline constexpr Inst k_or = 1;
inline constexpr Inst k_xor = 2;
inline constexpr Inst k_ld = 0;
inline constexpr Inst k_st = 1;

// --- Mininst (16-bit) bit-field shifts -------------------------------------
inline constexpr Mininst k_ddr_command_shift = 12;
inline constexpr Mininst k_ddr_column_shift = 4;
inline constexpr Mininst k_ddr_bank_shift = 0;
inline constexpr Mininst k_ddr_row_shift = 4;
inline constexpr Mininst k_ddr_increment_bank_shift = 10;
inline constexpr Mininst k_ddr_increment_column_shift = 11;
inline constexpr Mininst k_ddr_increment_row_shift = 11;
inline constexpr Mininst k_ddr_precharge_all_shift = 11;
inline constexpr Mininst k_ddr_auto_precharge_shift = 9;
inline constexpr Mininst k_ddr_rank_shift = 8;

// --- Mininst (16-bit) DDR command codes ------------------------------------
inline constexpr Mininst k_write = 8;
inline constexpr Mininst k_read = 9;
inline constexpr Mininst k_pre = 10;
inline constexpr Mininst k_act = 11;
inline constexpr Mininst k_sel_ch = 12;
inline constexpr Mininst k_ref = 13;
inline constexpr Mininst k_nop = 15;

Inst pack_mininsts(Mininst i1, Mininst i2, Mininst i3, Mininst i4);
bool is_branch(Inst inst);
bool is_conditional_branch(Inst inst);
bool is_ddr(Inst inst);
bool is_load(Inst inst);
bool is_sleep(Inst inst);
int count_ddr_reads(Inst inst);

}  // namespace DRAMBender::InstrEncoding

#endif  // DRAMINSPECTOR_SRC_API_PROGRAM_INSTRUCTION_INTERNAL_H
