`define XUPVVH_HBM
`define HBM_BENDER

// Row Commands
`define RNOP	0
`define ACTT	1
`define PREE	2  
`define PREA	3
`define REFSB	4
`define REFF	5
`define PDE		6 
`define SREE	7 
`define PDX_SRX	8 
// Column Commands
`define CNOP	9 
`define RD		10
`define RDA		11
`define WR		12
`define WRA		13
//`define MRS		14

`define ROW_ADDR_WIDTH		14
`define COL_ADDR_WIDTH		5
`define BA_ADDR_WIDTH		4
`define CMD_TYPE_WIDTH		4
`define PC_WIDTH		    1
`define WR_DATA_WIDTH       256