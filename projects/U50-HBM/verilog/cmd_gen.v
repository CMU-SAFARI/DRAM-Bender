`include "project.vh"
`include "parameters.vh"

// The DRAM Bender programmmable core that generates 4 DDR instructions per cycle and is clocked at 1/4 DDR4 memory clock
// This is due to the fact that the DDR4 PHY interface can process 4 commands per dfi_clock cycle

// Unlike the DDR4 PHY interface, the HBM PHY can process 2 commands per dfi_clock cycle
// Since DRAM Bender is designed in a way to generate 4 DDR instructions, we will buffer 4 instructions per fab_clock cycle,
// and clock the HBM_adapter at 2x fab_clock (e.g. dfi_clock = 2x fab_clock). And then we will have HBM_clock = 2x dfi_clock.
// In this way, we will still be able to process 4 instructions per fab_clock cycle.

module cmd_gen #(parameter CKE_WIDTH = 1, RANK_WIDTH = 1, DQ_WIDTH = 64, DRAM_CMD_SLOTS = 4,
				 DATA_BUF_ADDR_WIDTH = 5, DBUF_WIDTH = 4, DQ_BURST = 8)
	(
      // common signals
      input                                             clk,
      input                                             rst,
      //input                                             dfi_clk,
      //input                                             dfi_rst_n,
      
      //other control signals
      //input                                             init_calib_complete,
      //input                                             process_iseq,
      
      // ddr_pipeline <-> outer module if
      input [3:0]                 ddr_write,
      input [3:0]                 ddr_read,
      input [3:0]                 ddr_pre,
      input [3:0]                 ddr_act,
      input [3:0]                 ddr_ref,
      input [3:0]                 hbm_sel_ch, // used for channel select
      input [3:0]                 ddr_nop,
      input [3:0]                 ddr_ap,
    //input [3:0]                 ddr_half_bl,
      input [3:0]                 ddr_rank, // can be used to indicate PC
      input [3:0]                 ddr_pall,
      input [4*`HBM_CH_WIDTH-1:0] hbm_ch,
      input [4*`BG_WIDTH-1:0]     ddr_bg,
      input [4*`BANK_WIDTH-1:0]   ddr_bank,
      input [4*`COL_WIDTH-1:0]    ddr_col,
      input [4*`ROW_WIDTH-1:0]    ddr_row,
      input [511:0]               ddr_wdata,
      
      //output	[4*`ROW_ADDR_WIDTH-1:0]	   row_addr_4,
      //output	[4*`COL_ADDR_WIDTH-1:0]	   col_addr_4,
      //output	[4*`BA_ADDR_WIDTH-1:0]	   ba_addr_4,
      //output	[511:0]                    wrdata_4,
      //output	[4*`CMD_TYPE_WIDTH-1:0]	   cmd_type_4,
      //output 	[4*`PC_WIDTH-1:0]		   BA4_4, // indicates target PC
      
      output [127:0]             fifo_data,
      output [1023:0]            wrdata    // have one output of 1024 bit for fifo, the other signals are now wires. Make sure to layout data as needed.
      
    );
    
    reg	[4*`ROW_ADDR_WIDTH-1:0]	   row_addr_ns;
    reg	[4*`COL_ADDR_WIDTH-1:0]	   col_addr_ns;
    reg	[4*`BA_ADDR_WIDTH-1:0]	   ba_addr_ns;
    reg	[511:0]                    wrdata_ns;
    reg	[4*`CMD_TYPE_WIDTH-1:0]	   cmd_type_ns;
    reg [4*`PC_WIDTH-1:0]	       BA4_ns;
    reg [4*`HBM_CH_WIDTH-1:0]  channel_id_ns; 
    
    reg	[4*`ROW_ADDR_WIDTH-1:0]	   row_addr_r;
    reg	[4*`COL_ADDR_WIDTH-1:0]	   col_addr_r;
    reg	[4*`BA_ADDR_WIDTH-1:0]	   ba_addr_r;
    reg	[511:0]                    wrdata_r;
    reg	[4*`CMD_TYPE_WIDTH-1:0]	   cmd_type_r;
    reg [4*`PC_WIDTH-1:0]	       BA4_r;
    reg [4*`HBM_CH_WIDTH-1:0]  channel_id_r; 
    
    integer i;
    
    /*
    assign row_addr_4 = row_addr_r;
    assign col_addr_4 = col_addr_r;
    assign ba_addr_4 = ba_addr_r;
    assign wrdata_4 = wrdata_r;
    assign cmd_type_4 = cmd_type_r;
    assign BA4_4 = BA4_r;
    */
    
    assign fifo_data[127:64]    =  {    channel_id_r[0 +: 2*`HBM_CH_WIDTH], 
                                        BA4_r[0 +: 2*`PC_WIDTH],
                                        ba_addr_r[0 +: 2*`BA_ADDR_WIDTH], 
                                        col_addr_r[0 +: 2*`COL_ADDR_WIDTH], 
                                        row_addr_r[0 +: 2*`ROW_ADDR_WIDTH],
                                        cmd_type_r[0 +: 2*`CMD_TYPE_WIDTH]    };
                                    
    assign fifo_data[63:0]      =  {    channel_id_r[2*`HBM_CH_WIDTH +: 2*`HBM_CH_WIDTH], 
                                        BA4_r[2*`PC_WIDTH +: 2*`PC_WIDTH], 
                                        ba_addr_r[2*`BA_ADDR_WIDTH +: 2*`BA_ADDR_WIDTH], 
                                        col_addr_r[2*`COL_ADDR_WIDTH +: 2*`COL_ADDR_WIDTH], 
                                        row_addr_r[2*`ROW_ADDR_WIDTH +: 2*`ROW_ADDR_WIDTH],
                                        cmd_type_r[2*`CMD_TYPE_WIDTH +: 2*`CMD_TYPE_WIDTH]    };
                                    
    assign wrdata[511:0]    = wrdata_r; // here we are writing double the data redundantly. If we can fix it its better.
    assign wrdata[1023:512] = wrdata_r;
    
    
    always @ (*)
    begin
        row_addr_ns = {4*`ROW_ADDR_WIDTH{1'b0}};
        col_addr_ns = {4*`COL_ADDR_WIDTH{1'b0}};
        ba_addr_ns = {4*`BA_ADDR_WIDTH{1'b0}};
        cmd_type_ns = {4*`CMD_TYPE_WIDTH{1'b1}};
        BA4_ns = {4*`PC_WIDTH{1'b0}};
        wrdata_ns = {512{1'b0}};
        channel_id_ns = {4*`HBM_CH_WIDTH{1'b0}};
        
        for(i = 0 ; i < 4 ; i = i + 1) begin
            if (ddr_write[i]) begin
            	if (ddr_ap[i])
            		cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `WRA;
            	else
            		cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `WR;
            end 
            else if (ddr_read[i]) begin
            	if (ddr_ap[i])
            		cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `RDA;
            	else
            		cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `RD;
            end
            else if (ddr_pre[i]) begin
            	if (ddr_pall[i])
            		cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `PREA;
            	else
            		cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `PREE;
            end
            else if (ddr_act[i]) begin
            	cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `ACTT;
            end
            else if (ddr_ref[i]) begin
            	cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `REFF;
            end
            else if (ddr_nop[i]) begin
            	cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `RNOP;
            end
            else if (hbm_sel_ch[i]) begin // this is now a command to select channel
            	cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `RNOP;
            	// duplicate channel ID four times. This would make it easier to appropriately select channel.
            	// This is fine since we initially assume we would need to wait for some delay before switching between channels 
            	channel_id_ns[0 +: `HBM_CH_WIDTH]                   = hbm_ch[`HBM_CH_WIDTH*i +: `HBM_CH_WIDTH];
            	channel_id_ns[`HBM_CH_WIDTH +: `HBM_CH_WIDTH]   = hbm_ch[`HBM_CH_WIDTH*i +: `HBM_CH_WIDTH];
            	channel_id_ns[`HBM_CH_WIDTH*2 +: `HBM_CH_WIDTH] = hbm_ch[`HBM_CH_WIDTH*i +: `HBM_CH_WIDTH];
            	channel_id_ns[`HBM_CH_WIDTH*3 +: `HBM_CH_WIDTH] = hbm_ch[`HBM_CH_WIDTH*i +: `HBM_CH_WIDTH];
            end
            else begin
            	cmd_type_ns[`CMD_TYPE_WIDTH*i +: `CMD_TYPE_WIDTH] = `RNOP;
            end
            
            row_addr_ns[`ROW_ADDR_WIDTH*i +: `ROW_ADDR_WIDTH] = ddr_row[`ROW_WIDTH*i +: `ROW_ADDR_WIDTH];
            col_addr_ns[`COL_ADDR_WIDTH*i +: `COL_ADDR_WIDTH] = ddr_col[`COL_WIDTH*i +: `COL_ADDR_WIDTH];
            ba_addr_ns[`BA_ADDR_WIDTH*i + `BANK_WIDTH +: `BG_WIDTH] = ddr_bg[`BG_WIDTH*i +: `BG_WIDTH];
            ba_addr_ns[`BA_ADDR_WIDTH*i +: `BANK_WIDTH] = ddr_bank[`BANK_WIDTH*i +: `BANK_WIDTH];
            BA4_ns[i] = ddr_rank[i]; // In our case it represents the PC
        end
        
        wrdata_ns = ddr_wdata;

    end
    
    always @(posedge clk) begin // slow clock
		if(rst) begin
		  row_addr_r <= {4*`ROW_ADDR_WIDTH{1'b0}};
		  col_addr_r <= {4*`COL_ADDR_WIDTH{1'b0}};
		  ba_addr_r <= {4*`BA_ADDR_WIDTH{1'b0}};
		  BA4_r <= {4*`PC_WIDTH{1'b0}};
		  wrdata_r <= {512{1'b0}};
		  cmd_type_r <= {4*`CMD_TYPE_WIDTH{1'b1}};
		  channel_id_r <= {4*`HBM_CH_WIDTH{1'b0}};
		end
		else begin
          row_addr_r <= row_addr_ns;
          col_addr_r <= col_addr_ns;
          ba_addr_r  <= ba_addr_ns;
          BA4_r      <= BA4_ns;
          wrdata_r   <= wrdata_ns;
          cmd_type_r <= cmd_type_ns;
          
          if (hbm_sel_ch[3] | hbm_sel_ch[2] | hbm_sel_ch[1] | hbm_sel_ch[0]) begin // only update channel_id when we have a select channel command. It always needs to be the first command out of the 4.
            channel_id_r <= channel_id_ns;
          end else begin    // otherwise, keep value from last select channel command
            channel_id_r <= channel_id_r;
          end
		end
  	end
    
endmodule
