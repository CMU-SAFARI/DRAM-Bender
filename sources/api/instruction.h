#ifndef INSTRUCTION_H
#define INSTRUCTION_H

#include <stdint.h>
#include <stdlib.h>
// SoftMC decode
#define __OP_CODE 59
#define __FU_CODE 48
#define __IS_BR   62
#define __IS_DDR  63
#define __IS_MISC 61
#define __IS_MEM  60
#define __IS_BW   59
// EXE decode
#define __RS1     0
#define __RS2     4
#define __RT      20
#define __IMD1    4
#define __IMD2    0
#define __IMD3    24
#define __BR_TGT  8
#define __J_TGT   0
#define __SLP_AMT 0
// DDR decode
#define __DDR_CMD   12
#define __DDR_CAR   4
#define __DDR_BAR   0
#define __DDR_RAR   4
#define __DDR_IBAR  10
#define __DDR_ICAR  11
#define __DDR_IRAR  11
#define __DDR_PALL  11
#define __DDR_AP    9
#define __DDR_BL4   8
// EXE function codes
#define __ADD   0
#define __ADDI  1
#define __SUB   2
#define __SUBI  3
#define __MV    4
#define __SRC   5
#define __LI    6
#define __LDWD  7
#define __LDPC	8
#define __SRE   0x100
#define __SRX   0x101
#define __BL    0
#define __BEQ   1
#define __JUMP  2
#define __SLEEP 3
#define __INFO  0 // Various information about upcoming block
#define __AND   0
#define __OR    1
#define __XOR   2
#define __LD    0
#define __ST    1
// DDR function codes
#define __WRITE 8
#define __READ  9
#define __PRE   10
#define __ACT   11
#define __ZQ    12
#define __REF   13
#define __NOP   15

// 64 bit instructions
typedef uint64_t Inst;
// 16 bit mini ddr-instructions
typedef uint16_t Mininst;

//Counter types for LDPC Inst
enum class PC_TYPE { WRITE, READ, PRE, ACT, ZQ, REF, CYC };

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
 * @param BL4 burst-chop write
 * @param ap auto-precharge after issuing write
 */
Mininst SMC_WRITE(int bar, int ibar, int car, int icar, int BL4, int ap);
/**
 * Generate a DDR-RD command
 * @param bar bank address register ID
 * @param ibar increment BAR (BAR=BAR+BASR) after issuing the read
 * @param car column address register ID
 * @param icar increment CAR (CAR=CAR+CASR) after issuing the read
 * @param BL4 burst-chop read
 * @param ap auto-precharge after issuing read
 */
Mininst SMC_READ(int bar, int ibar, int car, int icar, int BL4, int ap);
/**
 * Generate a DDR-PRE command
 * @param bar bank address register ID
 * @param ibar increment BAR (BAR=BAR+BASR) after issuing the write
 * @param pall precharge all banks
 */
Mininst SMC_PRE(int bar, int ibar, int pall);
/**
 * Generate a DDR-RD command
 * @param bar bank address register ID
 * @param ibar increment BAR (BAR=BAR+BASR) after issuing the activate
 * @param rar row address register ID
 * @param irar increment RAR (RAR=RAR+RASR) after issuing the activate
 */
Mininst SMC_ACT(int bar, int ibar, int rar, int irar);
/**
 * Generate a zq-calibration command
 */ 
Mininst SMC_ZQ();
/**
 * Generate a refresh command
 */ 
Mininst SMC_REF();
/**
 * Generate a no-operation command
 */ 
Mininst SMC_NOP();
/**
 * Enters Self-Refresh Mode
 */
Inst SMC_SRE();
/**
 * Exits Self-Refresh Mode
 */
Inst SMC_SRX();
/**
 * Packs four DDR commands together
 */
Inst __pack_mininsts(Mininst i1, Mininst i2, Mininst i3, Mininst i4);

int is_branch(Inst i);
int is_conditional(Inst i);
int is_load(Inst i);
int is_ddr(Inst i);
int is_sleep(Inst i);
int is_ddr_read(Inst i);
void decode_inst(Inst inst);
void decode_ddr(Mininst i);
void print_bits(size_t const size, void const * const ptr);

#endif
