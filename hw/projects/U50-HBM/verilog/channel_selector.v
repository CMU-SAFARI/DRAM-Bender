`include "project.vh"
`include "parameters.vh"


module channel_selector (
        // Input these to HBM adapter
		input	[2*`ROW_ADDR_WIDTH-1:0]	    row_addr,
		input	[2*`COL_ADDR_WIDTH-1:0]	    col_addr,
		input	[2*`BA_ADDR_WIDTH-1:0]	    ba_addr,
		input	[2*`WR_DATA_WIDTH-1:0]      i_wrdata,
		input	[2*`CMD_TYPE_WIDTH-1:0]	    cmd_type,
		input 	[2*`PC_WIDTH-1:0]		    BA4, // indicates target PC
		input   [2*`HBM_CH_WIDTH-1:0]       channel_id,
		input   [15:0]                      channel_id_oh,

		input            	dfi_clk,
	input           	dfi_rst_n,

        // CH0
        input dfi_0_init_complete,
		input [255 : 0] dfi_0_dw_rddata_p0,
		input [255 : 0] dfi_0_dw_rddata_p1,
		input [3 : 0] dfi_0_dw_rddata_valid,
		input dfi_0_out_rst_n,
		input ready_0,

		// CH1
        input dfi_1_init_complete,
		input [255 : 0] dfi_1_dw_rddata_p0,
		input [255 : 0] dfi_1_dw_rddata_p1,
		input [3 : 0] dfi_1_dw_rddata_valid,
		input dfi_1_out_rst_n,
		input ready_1,

		// CH2
        input dfi_2_init_complete,
		input [255 : 0] dfi_2_dw_rddata_p0,
		input [255 : 0] dfi_2_dw_rddata_p1,
		input [3 : 0] dfi_2_dw_rddata_valid,
		input dfi_2_out_rst_n,
		input ready_2,

		// CH3
        input dfi_3_init_complete,
		input [255 : 0] dfi_3_dw_rddata_p0,
		input [255 : 0] dfi_3_dw_rddata_p1,
		input [3 : 0] dfi_3_dw_rddata_valid,
		input dfi_3_out_rst_n,
		input ready_3,

		// CH4
        input dfi_4_init_complete,
		input [255 : 0] dfi_4_dw_rddata_p0,
		input [255 : 0] dfi_4_dw_rddata_p1,
		input [3 : 0] dfi_4_dw_rddata_valid,
		input dfi_4_out_rst_n,
		input ready_4,

		// CH5
        input dfi_5_init_complete,
		input [255 : 0] dfi_5_dw_rddata_p0,
		input [255 : 0] dfi_5_dw_rddata_p1,
		input [3 : 0] dfi_5_dw_rddata_valid,
		input dfi_5_out_rst_n,
		input ready_5,

		// CH6
        input dfi_6_init_complete,
		input [255 : 0] dfi_6_dw_rddata_p0,
		input [255 : 0] dfi_6_dw_rddata_p1,
		input [3 : 0] dfi_6_dw_rddata_valid,
		input dfi_6_out_rst_n,
		input ready_6,

		// CH7
        input dfi_7_init_complete,
		input [255 : 0] dfi_7_dw_rddata_p0,
		input [255 : 0] dfi_7_dw_rddata_p1,
		input [3 : 0] dfi_7_dw_rddata_valid,
		input dfi_7_out_rst_n,
		input ready_7,

		// CH8
        input dfi_8_init_complete,
		input [255 : 0] dfi_8_dw_rddata_p0,
		input [255 : 0] dfi_8_dw_rddata_p1,
		input [3 : 0] dfi_8_dw_rddata_valid,
		input dfi_8_out_rst_n,
		input ready_8,

		// CH9
        input dfi_9_init_complete,
		input [255 : 0] dfi_9_dw_rddata_p0,
		input [255 : 0] dfi_9_dw_rddata_p1,
		input [3 : 0] dfi_9_dw_rddata_valid,
		input dfi_9_out_rst_n,
		input ready_9,

		// CH10
        input dfi_10_init_complete,
		input [255 : 0] dfi_10_dw_rddata_p0,
		input [255 : 0] dfi_10_dw_rddata_p1,
		input [3 : 0] dfi_10_dw_rddata_valid,
		input dfi_10_out_rst_n,
		input ready_10,

		// CH11
        input dfi_11_init_complete,
		input [255 : 0] dfi_11_dw_rddata_p0,
		input [255 : 0] dfi_11_dw_rddata_p1,
		input [3 : 0] dfi_11_dw_rddata_valid,
		input dfi_11_out_rst_n,
		input ready_11,

		// CH12
        input dfi_12_init_complete,
		input [255 : 0] dfi_12_dw_rddata_p0,
		input [255 : 0] dfi_12_dw_rddata_p1,
		input [3 : 0] dfi_12_dw_rddata_valid,
		input dfi_12_out_rst_n,
		input ready_12,

		// CH13
        input dfi_13_init_complete,
		input [255 : 0] dfi_13_dw_rddata_p0,
		input [255 : 0] dfi_13_dw_rddata_p1,
		input [3 : 0] dfi_13_dw_rddata_valid,
		input dfi_13_out_rst_n,
		input ready_13,

		// CH14
        input dfi_14_init_complete,
		input [255 : 0] dfi_14_dw_rddata_p0,
		input [255 : 0] dfi_14_dw_rddata_p1,
		input [3 : 0] dfi_14_dw_rddata_valid,
		input dfi_14_out_rst_n,
		input ready_14,

		// CH15
        input dfi_15_init_complete,
		input [255 : 0] dfi_15_dw_rddata_p0,
		input [255 : 0] dfi_15_dw_rddata_p1,
		input [3 : 0] dfi_15_dw_rddata_valid,
		input dfi_15_out_rst_n,
		input ready_15,

		// output depending on channel chosen
        output o_ch_dfi_init_complete,
		output [255 : 0] o_ch_dfi_dw_rddata_p0,
		output [255 : 0] o_ch_dfi_dw_rddata_p1,
		output [3 : 0] o_ch_dfi_dw_rddata_valid,
		output o_ch_dfi_out_rst_n,
		output o_ch_ready,

		output [2*`CMD_TYPE_WIDTH-1:0] o_0_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_1_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_2_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_3_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_4_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_5_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_6_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_7_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_8_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_9_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_10_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_11_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_12_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_13_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_14_cmd_type,
		output [2*`CMD_TYPE_WIDTH-1:0] o_15_cmd_type,

		output	[2*`ROW_ADDR_WIDTH-1:0]	    o_row_addr,
		output	[2*`COL_ADDR_WIDTH-1:0]	    o_col_addr,
		output	[2*`BA_ADDR_WIDTH-1:0]	    o_ba_addr,
		output	[2*`WR_DATA_WIDTH-1:0]      o_i_wrdata,
		output 	[2*`PC_WIDTH-1:0]		    o_BA4 // indicates target PC

    );

	localparam [2*`CMD_TYPE_WIDTH-1:0] RNOP_PAIR = {2*`CMD_TYPE_WIDTH{1'b0}};

    reg [2*`CMD_TYPE_WIDTH-1:0] r_0_cmd_type,  ns_0_cmd_type,    rr_0_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_1_cmd_type,  ns_1_cmd_type,    rr_1_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_2_cmd_type,  ns_2_cmd_type,    rr_2_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_3_cmd_type,  ns_3_cmd_type,    rr_3_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_4_cmd_type,  ns_4_cmd_type,    rr_4_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_5_cmd_type,  ns_5_cmd_type,    rr_5_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_6_cmd_type,  ns_6_cmd_type,    rr_6_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_7_cmd_type,  ns_7_cmd_type,    rr_7_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_8_cmd_type,  ns_8_cmd_type,    rr_8_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_9_cmd_type,  ns_9_cmd_type,    rr_9_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_10_cmd_type, ns_10_cmd_type,   rr_10_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_11_cmd_type, ns_11_cmd_type,   rr_11_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_12_cmd_type, ns_12_cmd_type,   rr_12_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_13_cmd_type, ns_13_cmd_type,   rr_13_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_14_cmd_type, ns_14_cmd_type,   rr_14_cmd_type;
	reg [2*`CMD_TYPE_WIDTH-1:0] r_15_cmd_type, ns_15_cmd_type,   rr_15_cmd_type;

    reg r_ch_dfi_init_complete, ns_ch_dfi_init_complete, rr_ch_dfi_init_complete;
	reg [255 : 0] r_ch_dfi_dw_rddata_p0, ns_ch_dfi_dw_rddata_p0;

	reg [255 : 0] r_ch_dfi_dw_rddata_p0_or_tree_0_3;
	reg [255 : 0] r_ch_dfi_dw_rddata_p0_or_tree_4_7;
	reg [255 : 0] r_ch_dfi_dw_rddata_p0_or_tree_8_11;
	reg [255 : 0] r_ch_dfi_dw_rddata_p0_or_tree_12_15;

    reg [255 : 0] ns_ch_dfi_dw_rddata_p0_or_tree_0_3;
	reg [255 : 0] ns_ch_dfi_dw_rddata_p0_or_tree_4_7;
	reg [255 : 0] ns_ch_dfi_dw_rddata_p0_or_tree_8_11;
	reg [255 : 0] ns_ch_dfi_dw_rddata_p0_or_tree_12_15;

    reg [255 : 0] r_ch_dfi_dw_rddata_p1_or_tree_0_3;
	reg [255 : 0] r_ch_dfi_dw_rddata_p1_or_tree_4_7;
	reg [255 : 0] r_ch_dfi_dw_rddata_p1_or_tree_8_11;
	reg [255 : 0] r_ch_dfi_dw_rddata_p1_or_tree_12_15;

    reg [255 : 0] ns_ch_dfi_dw_rddata_p1_or_tree_0_3;
	reg [255 : 0] ns_ch_dfi_dw_rddata_p1_or_tree_4_7;
	reg [255 : 0] ns_ch_dfi_dw_rddata_p1_or_tree_8_11;
	reg [255 : 0] ns_ch_dfi_dw_rddata_p1_or_tree_12_15;

	reg [255 : 0] r_ch_dfi_dw_rddata_p1, ns_ch_dfi_dw_rddata_p1;
	reg [3 : 0] r_ch_dfi_dw_rddata_valid, ns_ch_dfi_dw_rddata_valid, rr_ch_dfi_dw_rddata_valid;
	reg r_ch_dfi_out_rst_n, ns_ch_dfi_out_rst_n, rr_ch_dfi_out_rst_n;
	reg r_ch_ready, ns_ch_ready, rr_ch_ready;

	reg	[2*`ROW_ADDR_WIDTH-1:0]	    rr_row_addr, r_row_addr, ns_row_addr;
    reg	[2*`COL_ADDR_WIDTH-1:0]	    rr_col_addr, r_col_addr, ns_col_addr;
    reg	[2*`BA_ADDR_WIDTH-1:0]	    rr_ba_addr, r_ba_addr, ns_ba_addr;
    reg	[2*`WR_DATA_WIDTH-1:0]      rr_i_wrdata, r_i_wrdata, ns_i_wrdata;
    reg [2*`PC_WIDTH-1:0]		    rr_BA4, r_BA4, ns_BA4; // indicates target PC

    integer n;

    always @* begin
	ns_0_cmd_type  = RNOP_PAIR;
		ns_1_cmd_type  = RNOP_PAIR;
		ns_2_cmd_type  = RNOP_PAIR;
		ns_3_cmd_type  = RNOP_PAIR;
		ns_4_cmd_type  = RNOP_PAIR;
		ns_5_cmd_type  = RNOP_PAIR;
		ns_6_cmd_type  = RNOP_PAIR;
		ns_7_cmd_type  = RNOP_PAIR;
		ns_8_cmd_type  = RNOP_PAIR;
		ns_9_cmd_type  = RNOP_PAIR;
		ns_10_cmd_type = RNOP_PAIR;
		ns_11_cmd_type = RNOP_PAIR;
		ns_12_cmd_type = RNOP_PAIR;
		ns_13_cmd_type = RNOP_PAIR;
		ns_14_cmd_type = RNOP_PAIR;
		ns_15_cmd_type = RNOP_PAIR;

        ns_row_addr = row_addr;
        ns_col_addr = col_addr;
        ns_ba_addr = ba_addr;
        ns_i_wrdata = i_wrdata;
        ns_BA4 = BA4;

//        ns_ch_dfi_dw_rddata_p0 = (dfi_0_dw_rddata_p0 & {256{channel_id_oh[0]}}) |
//        (dfi_1_dw_rddata_p0 & {256{channel_id_oh[1]}}) |
//        (dfi_2_dw_rddata_p0 & {256{channel_id_oh[2]}}) |
//        (dfi_3_dw_rddata_p0 & {256{channel_id_oh[3]}}) |
//        (dfi_4_dw_rddata_p0 & {256{channel_id_oh[4]}}) |
//        (dfi_5_dw_rddata_p0 & {256{channel_id_oh[5]}}) |
//        (dfi_6_dw_rddata_p0 & {256{channel_id_oh[6]}}) |
//        (dfi_7_dw_rddata_p0 & {256{channel_id_oh[7]}}) |
//        (dfi_8_dw_rddata_p0 & {256{channel_id_oh[8]}}) |
//        (dfi_9_dw_rddata_p0 & {256{channel_id_oh[9]}}) |
//        (dfi_10_dw_rddata_p0 & {256{channel_id_oh[10]}}) |
//        (dfi_11_dw_rddata_p0 & {256{channel_id_oh[11]}}) |
//        (dfi_12_dw_rddata_p0 & {256{channel_id_oh[12]}}) |
//        (dfi_13_dw_rddata_p0 & {256{channel_id_oh[13]}}) |
//        (dfi_14_dw_rddata_p0 & {256{channel_id_oh[14]}}) |
//        (dfi_15_dw_rddata_p0 & {256{channel_id_oh[15]}});

        ns_ch_dfi_dw_rddata_p0_or_tree_0_3 = (dfi_0_dw_rddata_p0 & {256{channel_id_oh[0]}}) |
        (dfi_1_dw_rddata_p0 & {256{channel_id_oh[1]}}) |
        (dfi_2_dw_rddata_p0 & {256{channel_id_oh[2]}}) |
        (dfi_3_dw_rddata_p0 & {256{channel_id_oh[3]}});

        ns_ch_dfi_dw_rddata_p0_or_tree_4_7 = (dfi_4_dw_rddata_p0 & {256{channel_id_oh[4]}}) |
        (dfi_5_dw_rddata_p0 & {256{channel_id_oh[5]}}) |
        (dfi_6_dw_rddata_p0 & {256{channel_id_oh[6]}}) |
        (dfi_7_dw_rddata_p0 & {256{channel_id_oh[7]}});

        ns_ch_dfi_dw_rddata_p0_or_tree_8_11 = (dfi_8_dw_rddata_p0 & {256{channel_id_oh[8]}}) |
        (dfi_9_dw_rddata_p0 & {256{channel_id_oh[9]}}) |
        (dfi_10_dw_rddata_p0 & {256{channel_id_oh[10]}}) |
        (dfi_11_dw_rddata_p0 & {256{channel_id_oh[11]}});

        ns_ch_dfi_dw_rddata_p0_or_tree_12_15 =  (dfi_12_dw_rddata_p0 & {256{channel_id_oh[12]}}) |
        (dfi_13_dw_rddata_p0 & {256{channel_id_oh[13]}}) |
        (dfi_14_dw_rddata_p0 & {256{channel_id_oh[14]}}) |
        (dfi_15_dw_rddata_p0 & {256{channel_id_oh[15]}});

//        ns_ch_dfi_dw_rddata_p1 = (dfi_0_dw_rddata_p1 & {256{channel_id_oh[0]}}) |
//        (dfi_1_dw_rddata_p1 & {256{channel_id_oh[1]}}) |
//        (dfi_2_dw_rddata_p1 & {256{channel_id_oh[2]}}) |
//        (dfi_3_dw_rddata_p1 & {256{channel_id_oh[3]}}) |
//        (dfi_4_dw_rddata_p1 & {256{channel_id_oh[4]}}) |
//        (dfi_5_dw_rddata_p1 & {256{channel_id_oh[5]}}) |
//        (dfi_6_dw_rddata_p1 & {256{channel_id_oh[6]}}) |
//        (dfi_7_dw_rddata_p1 & {256{channel_id_oh[7]}}) |
//        (dfi_8_dw_rddata_p1 & {256{channel_id_oh[8]}}) |
//        (dfi_9_dw_rddata_p1 & {256{channel_id_oh[9]}}) |
//        (dfi_10_dw_rddata_p1 & {256{channel_id_oh[10]}}) |
//        (dfi_11_dw_rddata_p1 & {256{channel_id_oh[11]}}) |
//        (dfi_12_dw_rddata_p1 & {256{channel_id_oh[12]}}) |
//        (dfi_13_dw_rddata_p1 & {256{channel_id_oh[13]}}) |
//        (dfi_14_dw_rddata_p1 & {256{channel_id_oh[14]}}) |
//        (dfi_15_dw_rddata_p1 & {256{channel_id_oh[15]}});

        ns_ch_dfi_dw_rddata_p1_or_tree_0_3 = (dfi_0_dw_rddata_p1 & {256{channel_id_oh[0]}}) |
        (dfi_1_dw_rddata_p1 & {256{channel_id_oh[1]}}) |
        (dfi_2_dw_rddata_p1 & {256{channel_id_oh[2]}}) |
        (dfi_3_dw_rddata_p1 & {256{channel_id_oh[3]}});

        ns_ch_dfi_dw_rddata_p1_or_tree_4_7 = (dfi_4_dw_rddata_p1 & {256{channel_id_oh[4]}}) |
        (dfi_5_dw_rddata_p1 & {256{channel_id_oh[5]}}) |
        (dfi_6_dw_rddata_p1 & {256{channel_id_oh[6]}}) |
        (dfi_7_dw_rddata_p1 & {256{channel_id_oh[7]}});

        ns_ch_dfi_dw_rddata_p1_or_tree_8_11 = (dfi_8_dw_rddata_p1 & {256{channel_id_oh[8]}}) |
        (dfi_9_dw_rddata_p1 & {256{channel_id_oh[9]}}) |
        (dfi_10_dw_rddata_p1 & {256{channel_id_oh[10]}}) |
        (dfi_11_dw_rddata_p1 & {256{channel_id_oh[11]}});

        ns_ch_dfi_dw_rddata_p1_or_tree_12_15 = (dfi_12_dw_rddata_p1 & {256{channel_id_oh[12]}}) |
        (dfi_13_dw_rddata_p1 & {256{channel_id_oh[13]}}) |
        (dfi_14_dw_rddata_p1 & {256{channel_id_oh[14]}}) |
        (dfi_15_dw_rddata_p1 & {256{channel_id_oh[15]}});

        ns_ch_dfi_dw_rddata_p0 = r_ch_dfi_dw_rddata_p0_or_tree_0_3 | r_ch_dfi_dw_rddata_p0_or_tree_4_7 | r_ch_dfi_dw_rddata_p0_or_tree_8_11 | r_ch_dfi_dw_rddata_p0_or_tree_12_15;
        ns_ch_dfi_dw_rddata_p1 = r_ch_dfi_dw_rddata_p1_or_tree_0_3 | r_ch_dfi_dw_rddata_p1_or_tree_4_7 | r_ch_dfi_dw_rddata_p1_or_tree_8_11 | r_ch_dfi_dw_rddata_p1_or_tree_12_15;

	case (channel_id)
		4'b0000 :  begin
			ns_ch_dfi_init_complete 		= dfi_0_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_0_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_0_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_0_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_0_out_rst_n;
			ns_ch_ready 					= ready_0;
			ns_0_cmd_type                = cmd_type;
		end
		4'b0001 :  begin
			ns_ch_dfi_init_complete 		= dfi_1_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_1_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_1_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_1_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_1_out_rst_n;
			ns_ch_ready 					= ready_1;
			ns_1_cmd_type                = cmd_type;
		end
		4'b0010 :  begin
			ns_ch_dfi_init_complete 		= dfi_2_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_2_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_2_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_2_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_2_out_rst_n;
			ns_ch_ready 					= ready_2;
			ns_2_cmd_type                = cmd_type;
		end
		4'b0011 :  begin
			ns_ch_dfi_init_complete 		= dfi_3_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_3_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_3_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_3_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_3_out_rst_n;
			ns_ch_ready 					= ready_3;
			ns_3_cmd_type                = cmd_type;
		end
		4'b0100 :  begin
			ns_ch_dfi_init_complete 		= dfi_4_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_4_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_4_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_4_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_4_out_rst_n;
			ns_ch_ready 					= ready_4;
			ns_4_cmd_type                = cmd_type;
		end
		4'b0101 :  begin
			ns_ch_dfi_init_complete 		= dfi_5_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_5_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_5_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_5_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_5_out_rst_n;
			ns_ch_ready 					= ready_5;
			ns_5_cmd_type                = cmd_type;
		end
		4'b0110 :  begin
			ns_ch_dfi_init_complete 		= dfi_6_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_6_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_6_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_6_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_6_out_rst_n;
			ns_ch_ready 					= ready_6;
			ns_6_cmd_type                = cmd_type;
		end
		4'b0111 :  begin
			ns_ch_dfi_init_complete 		= dfi_7_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_7_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_7_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_7_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_7_out_rst_n;
			ns_ch_ready 					= ready_7;
			ns_7_cmd_type                = cmd_type;
		end
		4'b1000 :  begin
			ns_ch_dfi_init_complete 		= dfi_8_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_8_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_8_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_8_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_8_out_rst_n;
			ns_ch_ready 					= ready_8;
			ns_8_cmd_type                = cmd_type;
		end
		4'b1001 :  begin
			ns_ch_dfi_init_complete 		= dfi_9_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_9_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_9_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_9_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_9_out_rst_n;
			ns_ch_ready 					= ready_9;
			ns_9_cmd_type                = cmd_type;
		end
		4'b1010 :  begin
			ns_ch_dfi_init_complete 		= dfi_10_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_10_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_10_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_10_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_10_out_rst_n;
			ns_ch_ready 					= ready_10;
			ns_10_cmd_type               = cmd_type;
		end
		4'b1011 :  begin
			ns_ch_dfi_init_complete 		= dfi_11_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_11_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_11_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_11_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_11_out_rst_n;
			ns_ch_ready 					= ready_11;
			ns_11_cmd_type               = cmd_type;
		end
		4'b1100 :  begin
			ns_ch_dfi_init_complete 		= dfi_12_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_12_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_12_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_12_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_12_out_rst_n;
			ns_ch_ready 					= ready_12;
			ns_12_cmd_type               = cmd_type;
		end
		4'b1101 :  begin
			ns_ch_dfi_init_complete 		= dfi_13_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_13_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_13_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_13_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_13_out_rst_n;
			ns_ch_ready 					= ready_13;
			ns_13_cmd_type               = cmd_type;
		end
		4'b1110 :  begin
			ns_ch_dfi_init_complete 		= dfi_14_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_14_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_14_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_14_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_14_out_rst_n;
			ns_ch_ready 					= ready_14;
			ns_14_cmd_type               = cmd_type;
		end
		4'b1111 :  begin
			ns_ch_dfi_init_complete 		= dfi_15_init_complete;
//    			ns_ch_dfi_dw_rddata_p0  		= dfi_15_dw_rddata_p0;
//    			ns_ch_dfi_dw_rddata_p1  		= dfi_15_dw_rddata_p1;
			ns_ch_dfi_dw_rddata_valid 	= dfi_15_dw_rddata_valid;
			ns_ch_dfi_out_rst_n 			= dfi_15_out_rst_n;
			ns_ch_ready 					= ready_15;
			ns_15_cmd_type               = cmd_type;
		end
		default :  begin
					ns_ch_dfi_init_complete 		= dfi_0_init_complete;
					ns_ch_dfi_dw_rddata_valid 	= dfi_0_dw_rddata_valid;
					ns_ch_dfi_out_rst_n 			= dfi_0_out_rst_n;
					ns_ch_ready 					= ready_0;
		end
	endcase
    end

    always @ (posedge dfi_clk) begin
        if (!dfi_rst_n) begin
            r_ch_dfi_init_complete 		<= 0;
            r_ch_dfi_dw_rddata_p0  		<= 0;
            r_ch_dfi_dw_rddata_p1  		<= 0;
            r_ch_dfi_dw_rddata_valid 	    <= 0;
            r_ch_dfi_out_rst_n 			<= 0;
            r_ch_ready 					<= 0;

            rr_ch_dfi_init_complete 		<= 0;
            rr_ch_dfi_dw_rddata_valid 	    <= 0;
            rr_ch_dfi_out_rst_n 			<= 0;
            rr_ch_ready 					<= 0;

			r_0_cmd_type  <= RNOP_PAIR;
			r_1_cmd_type  <= RNOP_PAIR;
			r_2_cmd_type  <= RNOP_PAIR;
			r_3_cmd_type  <= RNOP_PAIR;
			r_4_cmd_type  <= RNOP_PAIR;
			r_5_cmd_type  <= RNOP_PAIR;
			r_6_cmd_type  <= RNOP_PAIR;
			r_7_cmd_type  <= RNOP_PAIR;
			r_8_cmd_type  <= RNOP_PAIR;
			r_9_cmd_type  <= RNOP_PAIR;
			r_10_cmd_type <= RNOP_PAIR;
			r_11_cmd_type <= RNOP_PAIR;
			r_12_cmd_type <= RNOP_PAIR;
			r_13_cmd_type <= RNOP_PAIR;
			r_14_cmd_type <= RNOP_PAIR;
			r_15_cmd_type <= RNOP_PAIR;
            r_row_addr <= 0;
            r_col_addr <= 0;
            r_ba_addr <= 0;
            r_i_wrdata <= 0;
            r_BA4 <= 0;
			rr_0_cmd_type  <= RNOP_PAIR;
			rr_1_cmd_type  <= RNOP_PAIR;
			rr_2_cmd_type  <= RNOP_PAIR;
			rr_3_cmd_type  <= RNOP_PAIR;
			rr_4_cmd_type  <= RNOP_PAIR;
			rr_5_cmd_type  <= RNOP_PAIR;
			rr_6_cmd_type  <= RNOP_PAIR;
			rr_7_cmd_type  <= RNOP_PAIR;
			rr_8_cmd_type  <= RNOP_PAIR;
			rr_9_cmd_type  <= RNOP_PAIR;
			rr_10_cmd_type <= RNOP_PAIR;
			rr_11_cmd_type <= RNOP_PAIR;
			rr_12_cmd_type <= RNOP_PAIR;
			rr_13_cmd_type <= RNOP_PAIR;
			rr_14_cmd_type <= RNOP_PAIR;
			rr_15_cmd_type <= RNOP_PAIR;
            rr_row_addr <= 0;
            rr_col_addr <= 0;
            rr_ba_addr <= 0;
            rr_i_wrdata <= 0;
            rr_BA4 <= 0;
            r_ch_dfi_dw_rddata_p0_or_tree_0_3 <= 0;
	        r_ch_dfi_dw_rddata_p0_or_tree_4_7 <= 0;
	        r_ch_dfi_dw_rddata_p0_or_tree_8_11 <= 0;
	        r_ch_dfi_dw_rddata_p0_or_tree_12_15 <= 0;
            r_ch_dfi_dw_rddata_p1_or_tree_0_3 <= 0;
	        r_ch_dfi_dw_rddata_p1_or_tree_4_7 <= 0;
	        r_ch_dfi_dw_rddata_p1_or_tree_8_11 <= 0;
	        r_ch_dfi_dw_rddata_p1_or_tree_12_15 <= 0;

        end else begin
            r_ch_dfi_init_complete 		<= ns_ch_dfi_init_complete;
            r_ch_dfi_dw_rddata_p0  		<= ns_ch_dfi_dw_rddata_p0;
            r_ch_dfi_dw_rddata_p1  		<= ns_ch_dfi_dw_rddata_p1;
            r_ch_dfi_dw_rddata_valid 	    <= ns_ch_dfi_dw_rddata_valid;
            r_ch_dfi_out_rst_n 			<= ns_ch_dfi_out_rst_n;
            r_ch_ready 					<= ns_ch_ready;

            rr_ch_dfi_init_complete 		<= r_ch_dfi_init_complete;
            rr_ch_dfi_dw_rddata_valid 	    <= r_ch_dfi_dw_rddata_valid;
            rr_ch_dfi_out_rst_n 			<= r_ch_dfi_out_rst_n;
            rr_ch_ready 					<= r_ch_ready;

            r_0_cmd_type  <= ns_0_cmd_type;
            r_1_cmd_type  <= ns_1_cmd_type;
            r_2_cmd_type  <= ns_2_cmd_type;
            r_3_cmd_type  <= ns_3_cmd_type;
            r_4_cmd_type  <= ns_4_cmd_type;
            r_5_cmd_type  <= ns_5_cmd_type;
            r_6_cmd_type  <= ns_6_cmd_type;
            r_7_cmd_type  <= ns_7_cmd_type;
            r_8_cmd_type  <= ns_8_cmd_type;
            r_9_cmd_type  <= ns_9_cmd_type;
            r_10_cmd_type <= ns_10_cmd_type;
            r_11_cmd_type <= ns_11_cmd_type;
            r_12_cmd_type <= ns_12_cmd_type;
            r_13_cmd_type <= ns_13_cmd_type;
            r_14_cmd_type <= ns_14_cmd_type;
            r_15_cmd_type <= ns_15_cmd_type;
            r_row_addr <= ns_row_addr;
            r_col_addr <= ns_col_addr;
            r_ba_addr <= ns_ba_addr;
            r_i_wrdata <= ns_i_wrdata;
            r_BA4 <= ns_BA4;
            rr_0_cmd_type  <= r_0_cmd_type;
            rr_1_cmd_type  <= r_1_cmd_type;
            rr_2_cmd_type  <= r_2_cmd_type;
            rr_3_cmd_type  <= r_3_cmd_type;
            rr_4_cmd_type  <= r_4_cmd_type;
            rr_5_cmd_type  <= r_5_cmd_type;
            rr_6_cmd_type  <= r_6_cmd_type;
            rr_7_cmd_type  <= r_7_cmd_type;
            rr_8_cmd_type  <= r_8_cmd_type;
            rr_9_cmd_type  <= r_9_cmd_type;
            rr_10_cmd_type <= r_10_cmd_type;
            rr_11_cmd_type <= r_11_cmd_type;
            rr_12_cmd_type <= r_12_cmd_type;
            rr_13_cmd_type <= r_13_cmd_type;
            rr_14_cmd_type <= r_14_cmd_type;
            rr_15_cmd_type <= r_15_cmd_type;
            rr_row_addr <= r_row_addr;
            rr_col_addr <= r_col_addr;
            rr_ba_addr <= r_ba_addr;
            rr_i_wrdata <= r_i_wrdata;
            rr_BA4 <= r_BA4;

            r_ch_dfi_dw_rddata_p0_or_tree_0_3 <= ns_ch_dfi_dw_rddata_p0_or_tree_0_3;
	        r_ch_dfi_dw_rddata_p0_or_tree_4_7 <= ns_ch_dfi_dw_rddata_p0_or_tree_4_7;
	        r_ch_dfi_dw_rddata_p0_or_tree_8_11 <= ns_ch_dfi_dw_rddata_p0_or_tree_8_11;
	        r_ch_dfi_dw_rddata_p0_or_tree_12_15 <= ns_ch_dfi_dw_rddata_p0_or_tree_12_15;
            r_ch_dfi_dw_rddata_p1_or_tree_0_3 <= ns_ch_dfi_dw_rddata_p1_or_tree_0_3;
	        r_ch_dfi_dw_rddata_p1_or_tree_4_7 <= ns_ch_dfi_dw_rddata_p1_or_tree_4_7;
	        r_ch_dfi_dw_rddata_p1_or_tree_8_11 <= ns_ch_dfi_dw_rddata_p1_or_tree_8_11;
	        r_ch_dfi_dw_rddata_p1_or_tree_12_15 <= ns_ch_dfi_dw_rddata_p1_or_tree_12_15;

        end
    end

    assign o_ch_dfi_init_complete = rr_ch_dfi_init_complete;
    assign o_ch_dfi_dw_rddata_p0 = r_ch_dfi_dw_rddata_p0; // this signal and others nearby are in the same pipeline stage
    assign o_ch_dfi_dw_rddata_p1 = r_ch_dfi_dw_rddata_p1;
    assign o_ch_dfi_dw_rddata_valid = rr_ch_dfi_dw_rddata_valid;
    assign o_ch_dfi_out_rst_n = rr_ch_dfi_out_rst_n;
	assign o_ch_ready = rr_ch_ready;

    assign o_0_cmd_type = rr_0_cmd_type;
    assign o_1_cmd_type = rr_1_cmd_type;
    assign o_2_cmd_type = rr_2_cmd_type;
    assign o_3_cmd_type = rr_3_cmd_type;
    assign o_4_cmd_type = rr_4_cmd_type;
    assign o_5_cmd_type = rr_5_cmd_type;
    assign o_6_cmd_type = rr_6_cmd_type;
    assign o_7_cmd_type = rr_7_cmd_type;
    assign o_8_cmd_type = rr_8_cmd_type;
    assign o_9_cmd_type = rr_9_cmd_type;
    assign o_10_cmd_type = rr_10_cmd_type;
    assign o_11_cmd_type = rr_11_cmd_type;
    assign o_12_cmd_type = rr_12_cmd_type;
    assign o_13_cmd_type = rr_13_cmd_type;
    assign o_14_cmd_type = rr_14_cmd_type;
    assign o_15_cmd_type = rr_15_cmd_type;

    assign o_row_addr = rr_row_addr;
    assign o_col_addr = rr_col_addr;
    assign o_ba_addr = rr_ba_addr;
    assign o_i_wrdata = rr_i_wrdata;
    assign o_BA4 = rr_BA4;

endmodule
