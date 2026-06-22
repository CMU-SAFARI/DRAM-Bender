#ifndef DRAMBENDER_API_PROGRAM_INSTRUCTION_H
#define DRAMBENDER_API_PROGRAM_INSTRUCTION_H

#include <cstdint>

namespace DRAMBender {

// 64 bit instructions
using Inst = uint64_t;
// 16 bit mini ddr-instructions
using Mininst = uint16_t;

//Counter types for LDPC Inst
enum class PC_TYPE { WRITE, READ, PRE, ACT, SEL_CH, REF, CYC };

/**
 * Load a word from memory into rt
 * rt = [rb] + offset
 * To handle structural hazards, the API adds a
 * "buffer" NOP instruction following loads.
 * @param rb register holding the base address
 * @param offset memory address offset
 * @param rt register to load the value with
 */
Inst SMC_LD(int rb, int offset, int rt);
/**
 * Store a word to memory
 * [rb] + offset = rt
 * @param rb register holding the base address
 * @param offset memory address offset
 * @param rv register holding the value to store
 */
Inst SMC_ST(int rb, int offset, int rv);

Inst SMC_AND(int rs1, int rs2, int rt);
Inst SMC_OR(int rs1, int rs2, int rt);
Inst SMC_XOR(int rs1, int rs2, int rt);

Inst SMC_ADD(int rs1, int rs2, int rt);
Inst SMC_ADDI(int rs1, uint32_t imd, int rt);
Inst SMC_SUB(int rs1, int rs2, int rt);
Inst SMC_SUBI(int rs1, uint32_t imd, int rt);
Inst SMC_LI(uint32_t imd, int rt);
Inst SMC_MV(int rs1, int rt);
/**
 * Shift right circular, shift one bit to right and copy
 * the rightmost bit to the leftmost bit of the result.
 * @param rs1 register to shift
 * @param rt register to load the shifted value into
 */
Inst SMC_SRC(int rs1, int rt);
/**
 * Move 32 bit data to wide register's specified offset
 * @param rs1 source register where 32-bit data resides
 * @param off 32-bit offset (e.g. 0 = bytes(0,4) - 5 = bytes(20,24))
 */
Inst SMC_LDWD(int rs1, int off);
Inst SMC_LDPC(PC_TYPE pc_type, int rt);
Inst SMC_BL(int rs1, int rs2, int tgt);
Inst SMC_BEQ(int rs1, int rs2, int tgt);
Inst SMC_JUMP(int tgt);
Inst SMC_END();
Inst SMC_INFO(int rdcnt);
  
/**
 * Wait for a specified amount of fabric cycles (6ns by default) before 
 * executing the next instruction
 * @param samt how many cycles to wait for, must be greater than 2
 */
Inst SMC_SLEEP(uint32_t samt);

/**
 * Generate a DDR-WR command
 * @param bar bank address register ID
 * @param ibar increment BAR (BAR=BAR+BASR) after issuing the write
 * @param car column address register ID
 * @param icar increment CAR (CAR=CAR+CASR) after issuing the write
 * @param rank target rank
 * @param ap auto-precharge after issuing write
 */
Mininst SMC_WRITE(int bar, int ibar, int car, int icar, int rank, int ap);
/**
 * Generate a DDR-RD command
 * @param bar bank address register ID
 * @param ibar increment BAR (BAR=BAR+BASR) after issuing the read
 * @param car column address register ID
 * @param icar increment CAR (CAR=CAR+CASR) after issuing the read
 * @param rank target rank
 * @param ap auto-precharge after issuing read
 */
Mininst SMC_READ(int bar, int ibar, int car, int icar, int rank, int ap);
/**
 * Generate a DDR-PRE command
 * @param bar bank address register ID
 * @param ibar increment BAR (BAR=BAR+BASR) after issuing the write
 * @param pall precharge all banks
 * @param rank target rank
 */
Mininst SMC_PRE(int bar, int ibar, int pall, int rank = 0);
/**
 * Generate a DDR-RD command
 * @param bar bank address register ID
 * @param ibar increment BAR (BAR=BAR+BASR) after issuing the activate
 * @param rar row address register ID
 * @param irar increment RAR (RAR=RAR+RASR) after issuing the activate
 * @param rank target rank
 */
Mininst SMC_ACT(int bar, int ibar, int rar, int irar, int rank = 0);
/**
 * Select a channel (for HBM)
 * @param pseudo_channel target pseudo channel ID
 */ 
Mininst SMC_SEL_CH(int channel, int pseudo_channel = 0);
/**
 * Generate a refresh command
 */ 
Mininst SMC_REF(int rank = 0);
/**
 * Generate a no-operation command
 */ 
Mininst SMC_NOP(int rank = 0);
/**
 * Enters Self-Refresh Mode
 */
Inst SMC_SRE();
/**
 * Exits Self-Refresh Mode
 */
Inst SMC_SRX();
/**
 * @brief Common function to add four NOPs
 * 
 */
Inst all_nops();

}

#endif  // DRAMBENDER_API_PROGRAM_INSTRUCTION_H
