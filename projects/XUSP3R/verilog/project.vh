`define XUPP3R_x8_1R_UDIMM// MIG does not support DM|DBI w/ RDIMMs.
`define DQ_WIDTH   64

// DIMM related - x8 double ranks
`ifdef XUPP3R_x8
`define ODT_WIDTH  2
`define CS_WIDTH   2
`define CKE_WIDTH  2
`define CK_WIDTH   1
`elsif XUPP3R_x8_1R_UDIMM // Redundant here aswell.
`define ODT_WIDTH  1
`define CS_WIDTH   1
`define CKE_WIDTH  1
`define CK_WIDTH   1
`elsif XUPP3R_x4
// DEFAULT CONFIGS USE BELOW
`define ODT_WIDTH  1
`define CS_WIDTH   1
`define CKE_WIDTH  1
`define CK_WIDTH   1
`endif