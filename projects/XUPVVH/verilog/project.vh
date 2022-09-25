`define XUPP3R_x4// MIG does not support DM|DBI w/ RDIMMs.
`define DQ_WIDTH   72

// DIMM related - x8 double ranks
`ifdef XUPP3R_x4
// DEFAULT CONFIGS USE BELOW
`define ODT_WIDTH  2
`define CS_WIDTH   2
`define CKE_WIDTH  2
`define CK_WIDTH   1
`endif