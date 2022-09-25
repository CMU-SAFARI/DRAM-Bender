#ifndef UTIL_HH
#define UTIL_HH

#include "prog.h"

#define ITERS_DUMP 1024*1024
#define READ_CL_DUMP 8

#define ITERS 10000 //1024*1024 // 256*8
#define READ_CL 128

#define NO_BANKS 1
#define NO_ROWS 1024*32

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

#define COPY_REG1 10
#define COPY_REG2 11

#define ITER_REG 7
#define CTR_REG  8

#define INIT_LOOP 15

Program genActPreActSequence(int t1, int t2, int row1_reg, int row2_reg, int bank_reg);
Program genReadRange(int row_reg, int no_rows, int bank_reg, int read_cols);
Program genWriteRange1000(int row_reg, int no_rows, int bank_reg);
Program genWriteRange1111(int row_reg, int no_rows, int bank_reg);
Program genWriteRange1001(int row_reg, int no_rows, int bank_reg);
Program genWriteRange1010(int row_reg, int no_rows, int bank_reg);
Program genWriteRange1011(int row_reg, int no_rows, int bank_reg);
Program genWriteRange1100(int row_reg, int no_rows, int bank_reg);
Program genWriteRange1101(int row_reg, int no_rows, int bank_reg);
Program genWriteRange1110(int row_reg, int no_rows, int bank_reg);
Inst all_nops();



#endif
