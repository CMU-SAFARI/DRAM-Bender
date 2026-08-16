`include "project.vh"
`include "parameters.vh"

// This module takes 2 DDR commands as input at every dfi_clock cycle
// The HBM is 2x dfi_clock, which means that it can process 2 commands per dfi_clock cycle

module HBM_interface # (
		parameter		ROW_ADDR_WIDTH         = 14,
		parameter		COL_ADDR_WIDTH         = 5,
		parameter		BA_ADDR_WIDTH          = 4,
		// these are used for MRS
		parameter		P_DRIVE_PRECHARGE_CMD  = 114,
		parameter		P_DRIVE_ACT_CMD        = 240,
		parameter		P_MRS_CNT              = 8'hc0
    )(
	
	// USER INPUTS
	input	[2*`ROW_ADDR_WIDTH-1:0]	   row_addr,
    input	[2*`COL_ADDR_WIDTH-1:0]	   col_addr,
    input	[2*`BA_ADDR_WIDTH-1:0]	   ba_addr,
    input	[2*`WR_DATA_WIDTH-1:0]     i_wrdata,
    input	[2*`CMD_TYPE_WIDTH-1:0]	   cmd_type,
    input 	[2*`PC_WIDTH-1:0]		   BA4, // indicates target PC
						
    // DFI INTERFACE SIGNALS
    input            	dfi_clk,
    input           	dfi_rst_n,
    input            	dfi_rst_buf_n,
    
    // Get these from output of PHY. Not used by this module in example design.
    input            	dfi_ctrlupd_req,
    input            	dfi_phyupd_ack,  
    input               apb_complete_0,
    input               apb_complete_1,
	input               DRAM_0_STAT_CATTRIP,
	input  [6:0]        DRAM_0_STAT_TEMP,
	input               DRAM_1_STAT_CATTRIP,
	input  [6:0]        DRAM_1_STAT_TEMP,
    
    input            	dfi_init_complete,
	
    output	           	dfi_init_start,
    output	[1:0]   	dfi_aw_ck_p0,
    output  [1:0]   	dfi_aw_cke_p0,
    output	[11:0]  	dfi_aw_row_p0,
    output	[15:0]		dfi_aw_col_p0,
    output	[255:0] 	dfi_dw_wrdata_p0,
    
    output  [31:0]		dfi_dw_wrdata_mask_p0,
    output  [31:0]		dfi_dw_wrdata_dbi_p0,
    output  [7:0]		dfi_dw_wrdata_par_p0,
    output  [7:0]		dfi_dw_wrdata_dq_en_p0,
    output  [7:0]		dfi_dw_wrdata_par_en_p0,

    output  [1:0]		dfi_aw_ck_p1,
    output  [1:0]		dfi_aw_cke_p1,
    output	[11:0]		dfi_aw_row_p1,
    output	[15:0]		dfi_aw_col_p1,
    output	[255:0]		dfi_dw_wrdata_p1,
    
    output  [31:0]		dfi_dw_wrdata_mask_p1,
    output  [31:0]		dfi_dw_wrdata_dbi_p1,
    output  [7:0]		dfi_dw_wrdata_par_p1,
    output  [7:0]		dfi_dw_wrdata_dq_en_p1,
    output  [7:0]		dfi_dw_wrdata_par_en_p1,

    output           	dfi_aw_ck_dis,
    output           	dfi_lp_pwr_e_req,
    output           	dfi_lp_sr_e_req,
    output           	dfi_lp_pwr_x_e_req,
    output           	dfi_aw_tx_indx_ld,
    output           	dfi_dw_tx_indx_ld,
    output           	dfi_dw_rx_indx_ld,
    output           	dfi_ctrlupd_ack,
    output           	dfi_phyupd_req,
    
    output              ready
    
    );
    
    
    // FSM states
	localparam IDLE_S		= 2'b00;
	localparam MRS_S		= 2'b01;
	localparam READY_S		= 2'b10;

	// Row Commands
	localparam CMD_RNOP		= 3'b111;
	localparam CMD_ACT		= 3'b010; // 3rd bit is SID0, set to 0 for this HBM configuration.
	localparam CMD_PRE		= 3'b011;  
	localparam CMD_PREA		= 3'b011;
	localparam CMD_REFSB	= 3'b100;
	localparam CMD_REF		= 3'b100;
	localparam CMD_PDE		= 3'b111; // Not needed
	localparam CMD_SRE		= 3'b100; // Not needed
	localparam CMD_PDX_SRX	= 3'b111; // Not needed
	
	// Column Commands
	localparam CMD_CNOP		= 4'b1111; 
	localparam CMD_RD		= 4'b0101;
	localparam CMD_RDA		= 4'b1101;
	localparam CMD_WR		= 4'b0001;
	localparam CMD_WRA		= 4'b1001;
	localparam CMD_MRS		= 3'b000;
	
	// Other parameters
	localparam PAR		    = 1'b1; // Parity signal
	localparam BA4_0	    = 1'b0; // Direct commands to PC0
	localparam BA4_1	    = 1'b1; // Direct commands to PC1
	
	localparam LP_MRS0_A 	= 4'b0001;
	localparam LP_MRS1_A 	= 4'b0001;
	localparam LP_MRS2_A 	= 4'b0010;
	localparam LP_MRS3_A 	= 4'b0011;
	localparam LP_MRS4_A 	= 4'b0100;
	localparam LP_MRS5_A 	= 4'b0101;
	localparam LP_MRS6_A 	= 4'b0110;
	localparam LP_MRS7_A 	= 4'b0111;
	

	// Wires declaration
	wire				           w_fsm_rst_b;
	wire				           w_mrs_lat_cnt_done;
	wire				           w_precharge_lat_done; 
	
	// Registers declaration
	reg				               r_fsm_rst_b;	
	reg		[3:0]	               r_fsm_ps;
	reg		[3:0]	               r_fsm_ns;
	
	reg     [11:0]                 r_row_cmd [1:0];
	reg     [15:0]                 r_col_cmd [1:0];
	
	reg	           		           r_dfi_init_start;
	reg  	[1:0]		           r_dfi_aw_ck_p0;
	reg     [1:0] 		           r_dfi_aw_cke_p0;
	reg     [1:0]	 	           r_dfi_aw_ck_p1;
	reg     [1:0] 		           r_dfi_aw_cke_p1;
	reg		[3:0]		           cke_cnt; 
	   
	reg 	[7:0]		             r_mrs_reg_cnt;
	reg		[11:0]		             r_activate_lat_cnt;
	reg 	[11:0]		             r_precharge_lat_cnt;
	reg					             r_precharge_lat_done; 
	reg					             r_mrs_lat_cnt_done;
	
	
	reg     [`CMD_TYPE_WIDTH-1:0]     r_cmd_type_ps [1:0];
	reg     [2*`ROW_ADDR_WIDTH-1:0]   r_row_addr;
	reg     [2*`COL_ADDR_WIDTH-1:0]   r_col_addr;
	reg     [2*`BA_ADDR_WIDTH-1:0]    r_ba_addr;
    reg     [2*`WR_DATA_WIDTH-1:0]    r_wrdata;
	reg     [2*`PC_WIDTH-1:0]         r_BA4;
	
	reg r_ready;
	
	integer i;
	
	// Unused signals
    assign dfi_dw_wrdata_mask_p0   = 32'h0000_0000;
	assign dfi_dw_wrdata_dbi_p0    = 32'h0000_0000;
	assign dfi_dw_wrdata_par_p0    = 8'h00;
	assign dfi_dw_wrdata_dq_en_p0  = 8'h00;
	assign dfi_dw_wrdata_par_en_p0 = 8'h00;
	
	assign dfi_dw_wrdata_mask_p1   = 32'h0000_0000;
	assign dfi_dw_wrdata_dbi_p1    = 32'h0000_0000;
	assign dfi_dw_wrdata_par_p1    = 8'h00;
	assign dfi_dw_wrdata_dq_en_p1  = 8'h00;
	assign dfi_dw_wrdata_par_en_p1 = 8'h00;
	
	assign dfi_aw_ck_dis           = 1'b0;
	assign dfi_lp_pwr_e_req        = 1'b0;
	assign dfi_lp_sr_e_req         = 1'b0;
	assign dfi_lp_pwr_x_e_req      = 1'b0;
	assign dfi_aw_tx_indx_ld       = 1'b0;
	assign dfi_dw_tx_indx_ld       = 1'b0;
	assign dfi_dw_rx_indx_ld       = 1'b0;
	assign dfi_ctrlupd_ack         = 1'b0; // left as Z in example design
	assign dfi_phyupd_req          = 1'b0;
	
	// Output mapping
	assign dfi_init_start 		   = r_dfi_init_start;
	
	assign dfi_aw_ck_p0  		   = r_dfi_aw_ck_p0;
	assign dfi_aw_cke_p0 		   = r_dfi_aw_cke_p0;
	assign dfi_aw_row_p0		   = r_row_cmd[0];
	assign dfi_aw_col_p0		   = r_col_cmd[0];
	// other version
	//assign dfi_dw_wrdata_p0 	   = r_wrdata[0 +: `WR_DATA_WIDTH];
	assign dfi_dw_wrdata_p0 	   = {r_wrdata[192 +: 64], r_wrdata[128 +: 64], r_wrdata[64 +: 64], r_wrdata[0 +: 64]};
	
	assign dfi_aw_ck_p1  		   = r_dfi_aw_ck_p1;
	assign dfi_aw_cke_p1		   = r_dfi_aw_cke_p1;
	assign dfi_aw_row_p1		   = r_row_cmd[1];
	assign dfi_aw_col_p1		   = r_col_cmd[1];
	
	// other version
	//assign dfi_dw_wrdata_p1 	   = r_wrdata[`WR_DATA_WIDTH +: `WR_DATA_WIDTH];
	assign dfi_dw_wrdata_p1 	   = {r_wrdata[448 +: 64], r_wrdata[384 +: 64], r_wrdata[320 +: 64], r_wrdata[256 +: 64]};

	
	assign ready = r_ready;
	
	
	// Counter to wait for driving CKE signal
	// We basically wait for initialization to complete, and then drive CKE and CK
	// After that, we can start performing regular writes/reads
	
	always @ (posedge dfi_clk or negedge dfi_rst_n) begin
	  if (~dfi_rst_n) begin
		cke_cnt <= 4'h0;
	  end else if (dfi_init_complete == 1'b1 && cke_cnt != 4'hf) begin
		cke_cnt <= cke_cnt + 1'b1;
	  end
	end

	always @ (posedge dfi_clk or negedge dfi_rst_n) begin
	  if (~dfi_rst_n) begin
		r_dfi_aw_cke_p0 <= 2'b00;
		r_dfi_aw_cke_p1 <= 2'b00;
		r_dfi_aw_ck_p0  <= 2'b00;
		r_dfi_aw_ck_p1  <= 2'b00;
	  end else if (cke_cnt == 4'he) begin
		r_dfi_aw_cke_p0 <= 2'b11;
		r_dfi_aw_cke_p1 <= 2'b11;
		r_dfi_aw_ck_p0  <= 2'b01;
		r_dfi_aw_ck_p1  <= 2'b01;
	  end
	end

	
	// Driving init_start signal after APB initialization sequence is complete
	// We read the dfi_rst_buf_n coming from the HBM IP to determine when initialization completes
	// We can use dfi_rst_buf_n or dfi_init_complete (dfi_rst_buf_n is set by the HBM IP 1CC after dfi_init_complete)
	
	always @ (posedge dfi_clk or negedge dfi_rst_n) begin
	  if (~dfi_rst_n) begin
		r_dfi_init_start <= 1'b0;
	  end else if (dfi_rst_buf_n == 1'b1) begin
		r_dfi_init_start <= 1'b1;
	  end
	end
	
	// Counter to count pre-charge latency before issuing Mode Registers commands
	// This makes sure that we correctly set the mode registers
	
	always @ (posedge dfi_clk or negedge dfi_rst_n) begin
	  if (~dfi_rst_n) begin
		r_precharge_lat_cnt <= 12'h000;
		r_precharge_lat_done <= 1'b0; 
	  end else
	  begin
		r_precharge_lat_done <= w_precharge_lat_done; 
		if (r_fsm_ps == IDLE_S && dfi_init_complete == 1'b1 && r_precharge_lat_cnt != P_DRIVE_PRECHARGE_CMD) begin
		r_precharge_lat_cnt <= r_precharge_lat_cnt + 1'b1;
	  end
	  end
	end

	assign w_precharge_lat_done = (r_precharge_lat_cnt >= P_DRIVE_PRECHARGE_CMD) ? 1'b1 : 1'b0;
	
	// FSM is in IDLE_S state until initialization completes
	// After that, we move to the MRS_S state where we can initialize the mode registers
	assign w_fsm_rst_b = r_precharge_lat_done && dfi_init_complete;
	
	
	// Counter to count activate latency before issuing ACT command for correct operation
	// We are using this for the purpose of appropriately setting the Mode Registers
	// After that, we move to the READY_S state, where we can start sending arbitrary DDR commands
	
	always @ (posedge dfi_clk or negedge dfi_rst_n) begin
	  if (~dfi_rst_n) begin
		r_activate_lat_cnt <= 12'h000;
		r_mrs_lat_cnt_done	<= 1'b0; 
	  end else
	  begin
		r_mrs_lat_cnt_done	<= w_mrs_lat_cnt_done; 
	  if (r_fsm_ps == MRS_S && ( r_mrs_reg_cnt == P_MRS_CNT) && r_activate_lat_cnt != P_DRIVE_ACT_CMD) begin
		r_activate_lat_cnt <= r_activate_lat_cnt + 1'b1;
	  end
	  end
	end

	assign w_mrs_lat_cnt_done = (r_activate_lat_cnt >= P_DRIVE_ACT_CMD) ? 1'b1 : 0;

	// Counter to count the MR commands sent
	// Also used to induce tMRC latency between back-to-back MRS commands
	
	always @ (posedge dfi_clk or negedge dfi_rst_n) begin
	  if (~dfi_rst_n) begin
		r_mrs_reg_cnt <= 8'h00;
	  end else if ((r_fsm_ps == MRS_S) && (r_mrs_reg_cnt != P_MRS_CNT)) begin
		r_mrs_reg_cnt <= r_mrs_reg_cnt + 1'b1;
	  end
	end
	
	
	
	// Registers Assignment
	always @ ( posedge dfi_clk or negedge dfi_rst_n )
	begin
		if( dfi_rst_n == 1'b0 )
		begin
			r_fsm_ps			<= IDLE_S;
			r_fsm_rst_b	 		<= 1'b0;
			
			r_cmd_type_ps[0] <= {4{1'b1}};
			r_cmd_type_ps[1] <= {4{1'b1}};
            r_row_addr 			<= {2*ROW_ADDR_WIDTH{1'b0}};
            r_col_addr 			<= {2*COL_ADDR_WIDTH{1'b0}};
            r_ba_addr 			<= {2*BA_ADDR_WIDTH{1'b0}};
            r_wrdata 			<= {2*`WR_DATA_WIDTH{1'b0}};
            r_BA4 				<= 2'b00;
		end
		else
		begin
			r_fsm_ps			<= r_fsm_ns;
			r_fsm_rst_b	 		<= w_fsm_rst_b;
			
			r_cmd_type_ps[0]    <= cmd_type[`CMD_TYPE_WIDTH*0 +: `CMD_TYPE_WIDTH];
		    r_cmd_type_ps[1]    <= cmd_type[`CMD_TYPE_WIDTH*1 +: `CMD_TYPE_WIDTH];
			r_row_addr 			<= row_addr;
			r_col_addr 			<= col_addr;
			r_ba_addr 			<= ba_addr;
			r_BA4 				<= BA4;
			
			// wrDATA [255:0] corresponds to the data we want to write using the first command
			// wrDATA [511:256] corresponds to the data we want to write using the second command
			
			// Each command can target a different PC
			// Depending on the target PC, we need to write the data accordingly
			
			// Sent to PC0:
			// {dfi_dw_wrdata_p1[191:128], dfi_dw_wrdata_p1[63:0], dfi_dw_wrdata_p0[191:128], dfi_dw_wrdata_p0[63:0]}
			// Sent to PC1:
			// {dfi_dw_wrdata_p1[255:192], dfi_dw_wrdata_p1[127:64], dfi_dw_wrdata_p0[255:192], dfi_dw_wrdata_p0[127:64]}
			
			// However, we are still not sure if this is how 256 consecutive bits are stored in memory
			
			for (i = 0; i < 2; i = i + 1) begin
                if (r_cmd_type_ps[i] == `WR || r_cmd_type_ps[i] == `WRA) begin
                    // This could be one option
                    
                    //r_wrdata[0   + 64*BA4[i] +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*i + 0   +: 64];
                    //r_wrdata[128 + 64*BA4[i] +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*i + 64  +: 64];
                    //r_wrdata[256 + 64*BA4[i] +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*i + 128 +: 64];
                    //r_wrdata[384 + 64*BA4[i] +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*i + 192 +: 64];
                    
                    // Another option we will use is that we assume wrData [255:0] always targets PC0 and wrData[511:256] always targets PC1
                    r_wrdata[0   + 64*0 +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*0 + 0   +: 64];
                    r_wrdata[128 + 64*0 +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*0 + 64  +: 64];
                    r_wrdata[256 + 64*0 +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*0 + 128 +: 64];
                    r_wrdata[384 + 64*0 +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*0 + 192 +: 64];
                    r_wrdata[0   + 64*1 +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*1 + 0   +: 64];
                    r_wrdata[128 + 64*1 +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*1 + 64  +: 64];
                    r_wrdata[256 + 64*1 +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*1 + 128 +: 64];
                    r_wrdata[384 + 64*1 +: 64]    <=  i_wrdata[`WR_DATA_WIDTH*1 + 192 +: 64];
                end else begin
                    //r_wrdata[`WR_DATA_WIDTH*i +: `WR_DATA_WIDTH] <= r_wrdata[`WR_DATA_WIDTH*i +: `WR_DATA_WIDTH];
                end
            end
		end
	end

	// State Transition
	always @ (*)
	begin
		case( r_fsm_ps )
			IDLE_S:
			begin
				if( r_fsm_rst_b == 1'b0  ) begin
					r_fsm_ns	= IDLE_S;
				end
				else begin
					r_fsm_ns = MRS_S;
				end
			end
			MRS_S: 
			begin
				if( r_fsm_rst_b == 1'b0 ) begin
					r_fsm_ns = IDLE_S;
				end
				else begin
					if( r_mrs_lat_cnt_done == 1'b1 ) begin
						r_fsm_ns = READY_S;
					end
					else begin
						r_fsm_ns = MRS_S;
					end
				end
			end
			READY_S:
			begin
				if( r_fsm_rst_b == 1'b0 ) begin
					r_fsm_ns = IDLE_S;
				end
				else begin
					r_fsm_ns = READY_S;
				end
			end
			default:
			begin
				r_fsm_ns = IDLE_S;
			end
		endcase
	end
	
	// assert ready signal so that other modules know when to start running user program
	// We cannot use the dfi_init_complete or dfi_0_out_rst_n for this purpose 
	// since we also need to wait for the MRS sequence to complete
	
	always @ ( posedge dfi_clk or negedge dfi_rst_n )
	begin
		if( dfi_rst_n == 1'b0 )
		begin
		  r_ready <= 1'b0;
		end else begin
		  if (r_fsm_ps == READY_S) begin
		      r_ready <= 1'b1;
		  end else begin
		      r_ready <= 1'b0;
		  end
		end
	end
	
	// Row Commands
	always @ ( posedge dfi_clk or negedge dfi_rst_n )
	begin
		if( dfi_rst_n == 1'b0 )
		begin
			r_row_cmd[0]		<= 12'hfff;
			r_row_cmd[1]		<= 12'hfff;
		end
		else
		begin
			case( r_fsm_ps )
			IDLE_S:
			begin
				r_row_cmd[0]		<= 12'hfff;
				r_row_cmd[1]		<= 12'hfff;
			end
			MRS_S: // Initialize Mode Registers
			begin
				r_row_cmd[0]		<= 12'hfff;
				r_row_cmd[1]		<= 12'hfff;
			end
			READY_S: // Ready to start performing regular operations
			begin
			    // Handle ACT command
			    // Since we can only issue a single ACT per DFI_CLK cycle, any other command alongside an ACT will be ignored
			    if (r_cmd_type_ps[0] == `ACTT) begin
			        // CC1
                    r_row_cmd[0]	    <= {r_ba_addr[`BA_ADDR_WIDTH*0 + 3], r_row_addr[`ROW_ADDR_WIDTH*0 + 13], r_BA4[0], PAR, r_row_addr[`ROW_ADDR_WIDTH*0+11 +: 2], r_ba_addr[`BA_ADDR_WIDTH*0 +: 3], CMD_ACT};
                    // CC2
                    r_row_cmd[1]	    <= {r_row_addr[`ROW_ADDR_WIDTH*0+2 +: 3], PAR, r_row_addr[`ROW_ADDR_WIDTH*0 +: 2], r_row_addr[`ROW_ADDR_WIDTH*0+5 +: 6]};
			    end else if (r_cmd_type_ps[1] == `ACTT) begin
			        // CC1
			        r_row_cmd[0]	    <= {r_ba_addr[`BA_ADDR_WIDTH*1 + 3], r_row_addr[`ROW_ADDR_WIDTH*1 + 13], r_BA4[1], PAR, r_row_addr[`ROW_ADDR_WIDTH*1+11 +: 2], r_ba_addr[`BA_ADDR_WIDTH*1 +: 3], CMD_ACT};
			        // CC2
                    r_row_cmd[1]	    <= {r_row_addr[`ROW_ADDR_WIDTH*1+2 +: 3], PAR, r_row_addr[`ROW_ADDR_WIDTH*1 +: 2], r_row_addr[`ROW_ADDR_WIDTH*1+5 +: 6]};
			    end else begin
                    for (i = 0; i < 2; i = i + 1) begin
                        case (r_cmd_type_ps[i])
                            `RNOP:
                            begin
                                r_row_cmd[i]		<= {3'b111, PAR, 5'b11111, CMD_RNOP};
                            end
                            `PREE:
                            begin
                                r_row_cmd[i]		<= {r_ba_addr[`BA_ADDR_WIDTH*i + 3], 1'b0, r_BA4[i], PAR, 2'b11, r_ba_addr[`BA_ADDR_WIDTH*i +: 3], CMD_PRE};
                            end
                            `PREA:
                            begin
                                r_row_cmd[i]		<= {2'b11, r_BA4[i], PAR, 5'b11111, CMD_PREA};
                            end
                            `REFSB:
                            begin
                                r_row_cmd[i]		<= {r_ba_addr[`BA_ADDR_WIDTH*i + 3], 1'b0, r_BA4[i], PAR, 2'b11, r_ba_addr[`BA_ADDR_WIDTH*i +: 3], CMD_REFSB};
                            end
                            `REFF:
                            begin
                                r_row_cmd[i]		<= {2'b11, r_BA4[i], PAR, 5'b11111, CMD_REF};
                            end
                            // Not sure how we can use the following commands or if they work
                            // They are not necessary for the purpose of DRAM Bender
                            `PDE:
                            begin
                                r_row_cmd[i]		<= {3'b111, PAR, 5'b11111, CMD_PDE};
                            end
                            `SREE:
                            begin
                                r_row_cmd[i]		<= {3'b111, PAR, 5'b11111, CMD_SRE};
                            end
                            `PDX_SRX:
                            begin
                                r_row_cmd[i]		<= 12'hfff;
                            end
                            default:
                            begin
                                r_row_cmd[i]		<= 12'hfff;
                            end
                        endcase
                    end
                end
			end
			default:
			begin
				r_row_cmd[0]		<= 12'hfff;
				r_row_cmd[1]		<= 12'hfff;
			end
			endcase
		end
	end
	
	
	// Col Commands
	always @ ( posedge dfi_clk or negedge dfi_rst_n )
	begin
		if( dfi_rst_n == 1'b0 )
		begin
			r_col_cmd[0]		<= 16'hffff;
			r_col_cmd[1]		<= 16'hffff;
		end
		else
		begin
			case( r_fsm_ps )
			IDLE_S:
			begin
				r_col_cmd[0]		<= 16'hffff;
				r_col_cmd[1]		<= 16'hffff;
			end
			MRS_S: // Initialize Mode Registers
			begin
				case (r_mrs_reg_cnt)
				8'h00: begin
				  r_col_cmd[0] <= 16'h0000; //MR-0
				  r_col_cmd[1] <= 16'hffff;
				end
			 	8'h10: begin
				  r_col_cmd[0] <= 16'hffff;
				  //r_col_cmd_p1 <= 16'hea10; //MR-1
				  r_col_cmd[1] <= 16'ha010; //MR-1
				end
			 	8'h20: begin
				  //r_col_cmd_p0 <= 16'h2e28; //w_T_WL_MRS2 MR-2
				  r_col_cmd[0] <= {4'b0010, 1'b1, PAR, 2'b10, LP_MRS2_A, 1'b1, CMD_MRS}; //MR-2
				  r_col_cmd[1] <= 16'hffff;
				end
			 	8'h30: begin
				  r_col_cmd[0] <= 16'hffff;
				  //r_col_cmd_p1 <= 16'h4138; //MR-3
				  r_col_cmd[1] <= 16'hc138; //MR-3
				end
			 	8'h40: begin
				  //r_col_cmd_p0 <= 16'h1c40; //MR-4
				  r_col_cmd[0] <= 16'h0440; //MR-4
				  r_col_cmd[1] <= 16'hffff;
				end
			 	8'h50: begin
				  r_col_cmd[0] <= 16'hffff;
				  r_col_cmd[1] <= 16'h0050; //MR-5
				end
			 	8'h60: begin
				  r_col_cmd[0] <= 16'hc060; //MR-6
				  r_col_cmd[1] <= 16'hffff;
				end
			 	8'h70: begin
				  r_col_cmd[0] <= 16'hffff;
				  r_col_cmd[1] <= 16'h0270; //MR-7
				end
			 	8'h80: begin
				  r_col_cmd[0] <= 16'h00f0;
				  r_col_cmd[1] <= 16'hffff; //MR-7
				end
				default : begin
				  r_col_cmd[0] <= 16'hffff;
				  r_col_cmd[1] <= 16'hffff;
				end
				endcase
			end
			READY_S: // Ready to start performing regular operations
			begin
			    for (i = 0; i < 2; i = i + 1) begin
                    case (r_cmd_type_ps[i])
                        `CNOP:
                        begin
                            r_col_cmd[i]		<= {5'b11111, PAR, 6'b111111, CMD_CNOP};
                        end
                        `RD:
                        begin
                            // Here we assume the column address is 5 bits.
                            // According to JEDEC, it is 6 bits, but only col_addr[5:1] are used (so its actually 5 bits)
                            // So here col_addr[4:0] corresponds to col_addr[5:1] in the JEDEC standard
                              r_col_cmd[i]		<= {r_BA4[i], r_col_addr[`COL_ADDR_WIDTH*i+1 +: 4], PAR, r_col_addr[`COL_ADDR_WIDTH*i], 1'b0, r_ba_addr[`BA_ADDR_WIDTH*i +: 4], CMD_RD};                       
                        end
                        `RDA:
                        begin
                              r_col_cmd[i]		<= {r_BA4[i], r_col_addr[`COL_ADDR_WIDTH*i+1 +: 4], PAR, r_col_addr[`COL_ADDR_WIDTH*i], 1'b0, r_ba_addr[`BA_ADDR_WIDTH*i +: 4], CMD_RDA};                         
                        end
                        `WR:
                        begin
                              r_col_cmd[i]		<= {r_BA4[i], r_col_addr[`COL_ADDR_WIDTH*i+1 +: 4], PAR, r_col_addr[`COL_ADDR_WIDTH*i], 1'b0, r_ba_addr[`BA_ADDR_WIDTH*i +: 4], CMD_WR};  
                        end
                        `WRA:
                        begin
                              r_col_cmd[i]		<= {r_BA4[i], r_col_addr[`COL_ADDR_WIDTH*i+1 +: 4], PAR, r_col_addr[`COL_ADDR_WIDTH*i], 1'b0, r_ba_addr[`BA_ADDR_WIDTH*i +: 4], CMD_WRA};  
                        end
                        // We don't support sending custom MRS commands from the user side in DRAM Bender
                        default:
                        begin
                              r_col_cmd[i]		<= 16'hffff;
                        end
                    endcase
	            end
			end
			default:
			begin
				r_col_cmd[0]		<= 16'hffff;
				r_col_cmd[1]		<= 16'hffff;
			end
			endcase
		end
	end

endmodule


