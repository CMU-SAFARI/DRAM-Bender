`define UDIMM_x8

`ifdef UDIMM_x8

    `define DQ_WIDTH 64
    `define ODT_WIDTH 2
    `define CS_WIDTH 2
    `define CKE_WIDTH 2
    `define CK_WIDTH 1
    `define ROW_ADDR_WIDTH 17

`elsif RDIMM_x8

    `define DQ_WIDTH   72
    `define ODT_WIDTH  2
    `define CS_WIDTH   2
    `define CKE_WIDTH  2
    `define CK_WIDTH   1
    `define ROW_ADDR_WIDTH 17
    
`elsif RDIMM_x4

    `define DQ_WIDTH   72
    `define ODT_WIDTH  2
    `define CS_WIDTH   2
    `define CKE_WIDTH  2
    `define CK_WIDTH   1
    `define ROW_ADDR_WIDTH 18
    
`endif

