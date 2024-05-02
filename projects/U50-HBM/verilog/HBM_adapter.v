`include "parameters.vh"
`include "project.vh"

module HBM_adapter(
      // common signals
      input                                             c0_sys_clk_p,
      input                                             sys_rst,
      input                                             fab_clk,
      input                                             dfi_clk,
      input                                             dfi_rst_n,
      
      // ddr_pipeline <-> HBM_adapter
      input [3:0]                 ddr_write,
      input [3:0]                 ddr_read,
      input [3:0]                 ddr_pre,
      input [3:0]                 ddr_act,
      input [3:0]                 ddr_ref,
      input [3:0]                 hbm_sel_ch,
      input [3:0]                 ddr_nop,
      input [3:0]                 ddr_ap,
      input [3:0]                 ddr_rank,
      input [3:0]                 ddr_pall,
      input [4*`HBM_CH_WIDTH-1:0] hbm_ch,
      input [4*`BG_WIDTH-1:0]     ddr_bg,
      input [4*`BANK_WIDTH-1:0]   ddr_bank,
      input [4*`COL_WIDTH-1:0]    ddr_col,
      input [4*`ROW_WIDTH-1:0]    ddr_row,
      input [511:0]               ddr_wdata,
      
      output o_dfi_0_init_complete,
      output o_HBM_ready,
      
      // Received by readback engine
      output [255 : 0] o_dfi_0_dw_rddata_p0,
      output [255 : 0] o_dfi_0_dw_rddata_p1,
      output o_dfi_0_dw_rddata_valid,
      
      output [6:0] hbm0_temp,
      output [6:0] hbm1_temp                 
    );
    
    // HBM PHY signals
    wire dfi_0_init_complete;
    wire [255 : 0] dfi_0_dw_rddata_p0;
    wire [255 : 0] dfi_0_dw_rddata_p1;
    wire [3 : 0] dfi_0_dw_rddata_valid;
    wire dfi_0_out_rst_n;
    
    wire	[2*`ROW_ADDR_WIDTH-1:0]	    row_addr_2;
    wire	[2*`COL_ADDR_WIDTH-1:0]	    col_addr_2;
    wire	[2*`BA_ADDR_WIDTH-1:0]	    ba_addr_2;
    wire	[511:0]                     wrdata_2;
    wire	[2*`CMD_TYPE_WIDTH-1:0]	    cmd_type_2;
    wire    [2*`PC_WIDTH-1:0]		    BA4_2;
    wire    [2*`HBM_CH_WIDTH-1:0]   channel_id_2;
    
    /*
    wire	[4*`ROW_ADDR_WIDTH-1:0]	    row_addr_4;
    wire	[4*`COL_ADDR_WIDTH-1:0]	    col_addr_4;
    wire	[4*`BA_ADDR_WIDTH-1:0]	    ba_addr_4;
    wire	[511:0]                     wrdata_4;
    wire	[4*`CMD_TYPE_WIDTH-1:0]	    cmd_type_4;
    wire    [4*`PC_WIDTH-1:0]		    BA4_4;
    */
    
    wire w_dfi_0_dw_rddata_valid;
    wire [255:0] w_dfi_0_dw_rddata_p0;
    wire [255:0] w_dfi_0_dw_rddata_p1;
      
    wire HBM_ready;
    
    wire [1023:0] wrdata;
    wire [511:0]  o_wrdata;
    wire [127:0]  fifo_data;
    wire [63:0]   o_fifo_data;
    
    assign o_dfi_0_dw_rddata_p0     = w_dfi_0_dw_rddata_p0;
    assign o_dfi_0_dw_rddata_p1     = w_dfi_0_dw_rddata_p1;
    assign o_dfi_0_dw_rddata_valid  = w_dfi_0_dw_rddata_valid;
    assign o_dfi_0_init_complete    = dfi_0_init_complete;
    assign o_HBM_ready              = HBM_ready;
    
    
    cmd_gen cmd_genn(
      .clk(fab_clk),
      .rst(~HBM_ready),
      
      // ddr_pipeline <-> HBM_adapter
      .ddr_write(ddr_write),  
      .ddr_read(ddr_read),  
      .ddr_pre(ddr_pre),    
      .ddr_act(ddr_act),    
      .ddr_ref(ddr_ref),    
      .hbm_sel_ch(hbm_sel_ch),
      .hbm_ch(hbm_ch),      
      .ddr_nop(ddr_nop),    
      .ddr_ap(ddr_ap),    
      .ddr_rank(ddr_rank), 
      .ddr_pall(ddr_pall), 
      .ddr_bg(ddr_bg),    
      .ddr_bank(ddr_bank),  
      .ddr_col(ddr_col),    
      .ddr_row(ddr_row),    
      .ddr_wdata(ddr_wdata),
      
      /*
      .row_addr_4(row_addr_4),
      .col_addr_4(col_addr_4),
      .ba_addr_4(ba_addr_4),
      .wrdata_4(wrdata_4),
      .cmd_type_4(cmd_type_4),
      .BA4_4(BA4_4)
      */
      .fifo_data(fifo_data),
      .wrdata(wrdata)
      
    );
    
    cmd_fifo cmd_fifo (
        .srst(~dfi_rst_n),
        .wr_clk(fab_clk),
        .rd_clk(dfi_clk),
        .din(fifo_data),
        .wr_en(1'b1), // not sure of this
        .rd_en(1'b1),
        .dout(o_fifo_data)
        //.full(),
        //.empty(),
        //.wr_rst_busy(),
        //.rd_rst_busy()
    );
    
    wrdata_fifo wrdata_fifo (
        .srst(~dfi_rst_n),
        .wr_clk(fab_clk),
        .rd_clk(dfi_clk),
        .din(wrdata),
        .wr_en(1'b1),
        .rd_en(1'b1),
        .dout(o_wrdata)
        //.full(),
        //.empty(),
        //.wr_rst_busy(),
        //.rd_rst_busy()
    );
    
    /*
    (* dont_touch = "yes" *) cmd_buf cmd_buff(
        .dfi_clk(dfi_clk),
    	.dfi_rst_n(dfi_rst_n),
    	
    	.row_addr_4(row_addr_4),
		.col_addr_4(col_addr_4),
		.ba_addr_4(ba_addr_4),
		.wrdata_4(wrdata_4),
		.cmd_type_4(cmd_type_4),
		.BA4_4(BA4_4),
		
		.row_addr_2(row_addr_2),
		.col_addr_2(col_addr_2),
		.ba_addr_2(ba_addr_2),
		.wrdata_2(wrdata_2),
		.cmd_type_2(cmd_type_2),
		.BA4_2(BA4_2)
    );
    */
    
    controller_top ctrl_top(
		// Input these to HBM_interface
		.row_addr(o_fifo_data[2*`CMD_TYPE_WIDTH +: 2*`ROW_ADDR_WIDTH]),
		.col_addr(o_fifo_data[2*`ROW_ADDR_WIDTH + 2*`CMD_TYPE_WIDTH  +: 2*`COL_ADDR_WIDTH]),
		.ba_addr(o_fifo_data[2*`ROW_ADDR_WIDTH + 2*`CMD_TYPE_WIDTH + 2*`COL_ADDR_WIDTH +: 2*`BA_ADDR_WIDTH]),
		.i_wrdata(o_wrdata),
		.cmd_type(o_fifo_data[0 +: 2*`CMD_TYPE_WIDTH]),
		.BA4(o_fifo_data[2*`ROW_ADDR_WIDTH + 2*`CMD_TYPE_WIDTH + 2*`COL_ADDR_WIDTH + 2*`BA_ADDR_WIDTH +: 2*`PC_WIDTH]),
		.channel_id(o_fifo_data[2*`ROW_ADDR_WIDTH + 2*`CMD_TYPE_WIDTH + 2*`COL_ADDR_WIDTH + 2*`BA_ADDR_WIDTH + 2*`PC_WIDTH  +: 2*`HBM_CH_WIDTH]),
		
		.dfi_clk(dfi_clk),
    	.dfi_rst_n(dfi_rst_n),
    	
    	// Input these to HBM PHY IP
		.HBM_REF_CLK_0(c0_sys_clk_p),
		.HBM_REF_CLK_1(c0_sys_clk_p),
	    .APB_0_PCLK(c0_sys_clk_p),
		.APB_0_PRESET_N(sys_rst),
		.APB_1_PCLK(c0_sys_clk_p),
		.APB_1_PRESET_N(sys_rst),
		
		.hbm0_temp(hbm0_temp),
		.hbm1_temp(hbm1_temp),
		
		.dfi_0_init_complete(dfi_0_init_complete),
		.dfi_0_dw_rddata_p0(dfi_0_dw_rddata_p0),
		.dfi_0_dw_rddata_p1(dfi_0_dw_rddata_p1),
		.dfi_0_dw_rddata_valid(dfi_0_dw_rddata_valid),
		.dfi_0_out_rst_n(dfi_0_out_rst_n),
		.ready(HBM_ready)
		
    );
    
    
   cdc_HBM_to_rbe cdc_HBM(
        .dfi_clk(dfi_clk),
        .dfi_rst_n(dfi_rst_n),
        .fab_clk(fab_clk),
        .dfi_0_dw_rddata_p0(dfi_0_dw_rddata_p0),
		.dfi_0_dw_rddata_p1(dfi_0_dw_rddata_p1),
        .dfi_0_dw_rddata_valid(dfi_0_dw_rddata_valid),
        .o_dfi_0_dw_rddata_p0(w_dfi_0_dw_rddata_p0),
		.o_dfi_0_dw_rddata_p1(w_dfi_0_dw_rddata_p1),
		.o_dfi_0_dw_rddata_valid(w_dfi_0_dw_rddata_valid)
   );
    
    
endmodule
