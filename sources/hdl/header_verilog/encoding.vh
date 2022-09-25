// SoftMC instructions
`define FU_CODE_OFFSET    48
`define BRANCH_OFFSET     62 
`define DDR_OFFSET        63
`define INFO_OFFSET       61
`define MEM_OFFSET        60
`define BW_OFFSET         59
`define DEC_RS1           0
`define DEC_RS2           4
`define DEC_IMD1          4
`define DEC_IMD2          0
`define DEC_IMD3          24
`define DEC_RT            20
`define DEC_WO            20
`define DEC_JUMP_OFFSET   0
`define DEC_SLEEP_OFFSET  0
`define DEC_BR_TGT_OFFSET 8
`define SR_OFFSET         56
// DDR related
`define DDR_CODE_OFFSET   12
`define DEC_CAR           4
`define DEC_BAR           0
`define DEC_RAR           4
`define DEC_INC_BAR       10
`define DEC_PRE_ALL       11
`define DEC_INC_RAR       11
`define DEC_INC_CAR       11
`define DEC_AP            9
`define DEC_BL4           8
// function codes - exe
`define ADD               0
`define ADDI              1
`define SUB               2
`define SUBI              3
`define MV                4
`define SRC               5
`define LI                6
`define LDWD              7
`define LDPC              8
`define SRE               0     //DDR command but no space left in ISA DDR instructions.
`define SRX               1     //DDR command but no space left in ISA DDR instructions.
`define BL                0
`define BEQ               1
`define JUMP              2
`define SLEEP             3
`define LD                0
`define ST                1
`define AND               0
`define OR                1
`define XOR               2
// function codes - ddr
`define WRITE             0
`define READ              1
`define PRE               2
`define ACT               3
`define ZQ                4
`define REF               5
`define NOP               7

// SoftMC ddr uops
`define IS_WRITE          0
`define IS_READ           1
`define IS_PRE            2
`define IS_ACT            3
`define IS_ZQ             4
`define IS_REF            5
`define CAR               6  // column address register identifier
`define RAR               10 // row address register identifier
`define BAR               14 // bank address register identifier
`define PRE_ALL           18  
`define INC_CAR           19 // increment CAR after executing this
`define INC_RAR           20
`define INC_BAR           21
`define IS_NOP            22
`define IS_BL4            23
`define DO_AP             24
`define IS_SRE            25
`define IS_SRX            26
// SoftMC exe uops
`define IS_ADD            0
`define IS_SUB            1
`define IS_MOV            2
`define IS_LI             3
`define IS_LDWD           4
`define HAS_IMD           5
`define IS_BL             6
`define IS_BEQ            7
`define IS_JUMP           8
`define IS_SLEEP          9
`define RS1               10
`define RS2               14
`define RT                18
`define IMD               22
`define IMD2              38
`define IS_SRC            54
`define IS_MEM            55
`define IS_LD             56
`define IS_ST             57
`define IS_AND            58
`define IS_OR             59
`define IS_XOR            60
`define IS_LDPC           61

