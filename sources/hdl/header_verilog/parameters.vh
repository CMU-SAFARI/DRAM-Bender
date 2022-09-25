// Fetch
`define INSTR_WIDTH 64
`define IMEM_ADDR_WIDTH 11

// Decode - Execute
`define DDR_UOP_WIDTH 27
`define EXE_UOP_WIDTH 62
`define BG_WIDTH       2
`define BANK_WIDTH     2
`define COL_WIDTH     10
`define ROW_WIDTH     17

//Frontend
`define XDMA_AXI_DATA_WIDTH 256
`define IMEM_RD_LATENCY 1
//`define IMEM_SR // please only define when IMEM_RD_LATENCY > 1

//Common
`define HIGH 1'b1
`define LOW  1'b0

