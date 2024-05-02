`include "project.vh"
`include "parameters.vh"

module controller_top (
		// Input these to HBM adapter
		input	[2*`ROW_ADDR_WIDTH-1:0]	    row_addr,
		input	[2*`COL_ADDR_WIDTH-1:0]	    col_addr,
		input	[2*`BA_ADDR_WIDTH-1:0]	    ba_addr,
		input	[2*`WR_DATA_WIDTH-1:0]      i_wrdata,
		input	[2*`CMD_TYPE_WIDTH-1:0]	    cmd_type,
		input 	[2*`PC_WIDTH-1:0]		    BA4, // indicates target PC
		input   [2*`HBM_CH_WIDTH-1:0]   channel_id,
		
		input            	dfi_clk,
    	input           	dfi_rst_n,
    	
    	// Input these to HBM PHY IP
		input wire HBM_REF_CLK_0,
		input wire HBM_REF_CLK_1,
		input wire APB_0_PCLK,
		input wire APB_0_PRESET_N,
		input wire APB_1_PCLK,
		input wire APB_1_PRESET_N,
		
		output dfi_0_init_complete,
		output [255 : 0] dfi_0_dw_rddata_p0,
		output [255 : 0] dfi_0_dw_rddata_p1,
		output [3 : 0] dfi_0_dw_rddata_valid,
		output dfi_0_out_rst_n,
		output ready,
		
		output [6:0] hbm0_temp,
		output [6:0] hbm1_temp
    );
    

    // CHANNEL 0
	/*wire dfi_0_init_start;
	wire [1 : 0] dfi_0_aw_ck_p0;
	wire [1 : 0] dfi_0_aw_cke_p0;
	wire [11 : 0] dfi_0_aw_row_p0;
	wire [15 : 0] dfi_0_aw_col_p0;
	wire [255 : 0] dfi_0_dw_wrdata_p0;
	wire [31 : 0] dfi_0_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_0_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_0_dw_wrdata_par_p0;
	wire [7 : 0] dfi_0_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_0_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_0_aw_ck_p1;
	wire [1 : 0] dfi_0_aw_cke_p1;
	wire [11 : 0] dfi_0_aw_row_p1;
	wire [15 : 0] dfi_0_aw_col_p1;
	wire [255 : 0] dfi_0_dw_wrdata_p1;
	wire [31 : 0] dfi_0_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_0_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_0_dw_wrdata_par_p1;
	wire [7 : 0] dfi_0_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_0_dw_wrdata_par_en_p1;
	wire dfi_0_aw_ck_dis;
	wire dfi_0_lp_pwr_e_req;
	wire dfi_0_lp_sr_e_req;
	wire dfi_0_lp_pwr_x_req;
	wire dfi_0_aw_tx_indx_ld;
	wire dfi_0_dw_tx_indx_ld;
	wire dfi_0_dw_rx_indx_ld;
	wire dfi_0_ctrlupd_ack;
	wire dfi_0_phyupd_req;
	
	wire [255 : 0] w_dfi_0_dw_rddata_p0;
	wire [31 : 0] dfi_0_dw_rddata_dm_p0;
	wire [31 : 0] dfi_0_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_0_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_0_dw_rddata_p1;
	wire [31 : 0] dfi_0_dw_rddata_dm_p1;
	wire [31 : 0] dfi_0_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_0_dw_rddata_par_p1;
	//wire [15 : 0] dfi_0_dbi_byte_disable;
	wire [3 : 0] w_dfi_0_dw_rddata_valid;
	//wire [7 : 0] dfi_0_dw_derr_n;
	//wire [1 : 0] dfi_0_aw_aerr_n;
	wire dfi_0_ctrlupd_req;
	wire dfi_0_phyupd_ack;
	//wire dfi_0_clk_init;
	wire w_dfi_0_init_complete;
	wire w_dfi_0_out_rst_n;
	
	
	// CHANNEL 1
	wire dfi_1_init_start;
	wire [1 : 0] dfi_1_aw_ck_p0;
	wire [1 : 0] dfi_1_aw_cke_p0;
	wire [11 : 0] dfi_1_aw_row_p0;
	wire [15 : 0] dfi_1_aw_col_p0;
	wire [255 : 0] dfi_1_dw_wrdata_p0;
	wire [31 : 0] dfi_1_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_1_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_1_dw_wrdata_par_p0;
	wire [7 : 0] dfi_1_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_1_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_1_aw_ck_p1;
	wire [1 : 0] dfi_1_aw_cke_p1;
	wire [11 : 0] dfi_1_aw_row_p1;
	wire [15 : 0] dfi_1_aw_col_p1;
	wire [255 : 0] dfi_1_dw_wrdata_p1;
	wire [31 : 0] dfi_1_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_1_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_1_dw_wrdata_par_p1;
	wire [7 : 0] dfi_1_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_1_dw_wrdata_par_en_p1;
	wire dfi_1_aw_ck_dis;
	wire dfi_1_lp_pwr_e_req;
	wire dfi_1_lp_sr_e_req;
	wire dfi_1_lp_pwr_x_req;
	wire dfi_1_aw_tx_indx_ld;
	wire dfi_1_dw_tx_indx_ld;
	wire dfi_1_dw_rx_indx_ld;
	wire dfi_1_ctrlupd_ack;
	wire dfi_1_phyupd_req;
	
	wire [255 : 0] w_dfi_1_dw_rddata_p0;
	wire [31 : 0] dfi_1_dw_rddata_dm_p0;
	wire [31 : 0] dfi_1_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_1_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_1_dw_rddata_p1;
	wire [31 : 0] dfi_1_dw_rddata_dm_p1;
	wire [31 : 0] dfi_1_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_1_dw_rddata_par_p1;
	//wire [15 : 0] dfi_1_dbi_byte_disable;
	wire [3 : 0] w_dfi_1_dw_rddata_valid;
	//wire [7 : 0] dfi_1_dw_derr_n;
	//wire [1 : 0] dfi_1_aw_aerr_n;
	wire dfi_1_ctrlupd_req;
	wire dfi_1_phyupd_ack;
	//wire dfi_1_clk_init;
	wire w_dfi_1_init_complete;
	wire w_dfi_1_out_rst_n;
	
	
	// CHANNEL 2
	wire dfi_2_init_start;
	wire [1 : 0] dfi_2_aw_ck_p0;
	wire [1 : 0] dfi_2_aw_cke_p0;
	wire [11 : 0] dfi_2_aw_row_p0;
	wire [15 : 0] dfi_2_aw_col_p0;
	wire [255 : 0] dfi_2_dw_wrdata_p0;
	wire [31 : 0] dfi_2_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_2_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_2_dw_wrdata_par_p0;
	wire [7 : 0] dfi_2_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_2_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_2_aw_ck_p1;
	wire [1 : 0] dfi_2_aw_cke_p1;
	wire [11 : 0] dfi_2_aw_row_p1;
	wire [15 : 0] dfi_2_aw_col_p1;
	wire [255 : 0] dfi_2_dw_wrdata_p1;
	wire [31 : 0] dfi_2_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_2_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_2_dw_wrdata_par_p1;
	wire [7 : 0] dfi_2_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_2_dw_wrdata_par_en_p1;
	wire dfi_2_aw_ck_dis;
	wire dfi_2_lp_pwr_e_req;
	wire dfi_2_lp_sr_e_req;
	wire dfi_2_lp_pwr_x_req;
	wire dfi_2_aw_tx_indx_ld;
	wire dfi_2_dw_tx_indx_ld;
	wire dfi_2_dw_rx_indx_ld;
	wire dfi_2_ctrlupd_ack;
	wire dfi_2_phyupd_req;
	
	wire [255 : 0] w_dfi_2_dw_rddata_p0;
	wire [31 : 0] dfi_2_dw_rddata_dm_p0;
	wire [31 : 0] dfi_2_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_2_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_2_dw_rddata_p1;
	wire [31 : 0] dfi_2_dw_rddata_dm_p1;
	wire [31 : 0] dfi_2_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_2_dw_rddata_par_p1;
	//wire [15 : 0] dfi_2_dbi_byte_disable;
	wire [3 : 0] w_dfi_2_dw_rddata_valid;
	//wire [7 : 0] dfi_2_dw_derr_n;
	//wire [1 : 0] dfi_2_aw_aerr_n;
	wire dfi_2_ctrlupd_req;
	wire dfi_2_phyupd_ack;
	//wire dfi_2_clk_init;
	wire w_dfi_2_init_complete;
	wire w_dfi_2_out_rst_n;
	
	
	// CHANNEL 3
	wire dfi_3_init_start;
	wire [1 : 0] dfi_3_aw_ck_p0;
	wire [1 : 0] dfi_3_aw_cke_p0;
	wire [11 : 0] dfi_3_aw_row_p0;
	wire [15 : 0] dfi_3_aw_col_p0;
	wire [255 : 0] dfi_3_dw_wrdata_p0;
	wire [31 : 0] dfi_3_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_3_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_3_dw_wrdata_par_p0;
	wire [7 : 0] dfi_3_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_3_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_3_aw_ck_p1;
	wire [1 : 0] dfi_3_aw_cke_p1;
	wire [11 : 0] dfi_3_aw_row_p1;
	wire [15 : 0] dfi_3_aw_col_p1;
	wire [255 : 0] dfi_3_dw_wrdata_p1;
	wire [31 : 0] dfi_3_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_3_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_3_dw_wrdata_par_p1;
	wire [7 : 0] dfi_3_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_3_dw_wrdata_par_en_p1;
	wire dfi_3_aw_ck_dis;
	wire dfi_3_lp_pwr_e_req;
	wire dfi_3_lp_sr_e_req;
	wire dfi_3_lp_pwr_x_req;
	wire dfi_3_aw_tx_indx_ld;
	wire dfi_3_dw_tx_indx_ld;
	wire dfi_3_dw_rx_indx_ld;
	wire dfi_3_ctrlupd_ack;
	wire dfi_3_phyupd_req;
	
	wire [255 : 0] w_dfi_3_dw_rddata_p0;
	wire [31 : 0] dfi_3_dw_rddata_dm_p0;
	wire [31 : 0] dfi_3_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_3_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_3_dw_rddata_p1;
	wire [31 : 0] dfi_3_dw_rddata_dm_p1;
	wire [31 : 0] dfi_3_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_3_dw_rddata_par_p1;
	//wire [15 : 0] dfi_3_dbi_byte_disable;
	wire [3 : 0] w_dfi_3_dw_rddata_valid;
	//wire [7 : 0] dfi_3_dw_derr_n;
	//wire [1 : 0] dfi_3_aw_aerr_n;
	wire dfi_3_ctrlupd_req;
	wire dfi_3_phyupd_ack;
	//wire dfi_3_clk_init;
	wire w_dfi_3_init_complete;
	wire w_dfi_3_out_rst_n;
	
	
	// CHANNEL 4
	wire dfi_4_init_start;
	wire [1 : 0] dfi_4_aw_ck_p0;
	wire [1 : 0] dfi_4_aw_cke_p0;
	wire [11 : 0] dfi_4_aw_row_p0;
	wire [15 : 0] dfi_4_aw_col_p0;
	wire [255 : 0] dfi_4_dw_wrdata_p0;
	wire [31 : 0] dfi_4_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_4_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_4_dw_wrdata_par_p0;
	wire [7 : 0] dfi_4_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_4_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_4_aw_ck_p1;
	wire [1 : 0] dfi_4_aw_cke_p1;
	wire [11 : 0] dfi_4_aw_row_p1;
	wire [15 : 0] dfi_4_aw_col_p1;
	wire [255 : 0] dfi_4_dw_wrdata_p1;
	wire [31 : 0] dfi_4_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_4_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_4_dw_wrdata_par_p1;
	wire [7 : 0] dfi_4_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_4_dw_wrdata_par_en_p1;
	wire dfi_4_aw_ck_dis;
	wire dfi_4_lp_pwr_e_req;
	wire dfi_4_lp_sr_e_req;
	wire dfi_4_lp_pwr_x_req;
	wire dfi_4_aw_tx_indx_ld;
	wire dfi_4_dw_tx_indx_ld;
	wire dfi_4_dw_rx_indx_ld;
	wire dfi_4_ctrlupd_ack;
	wire dfi_4_phyupd_req;
	
	wire [255 : 0] w_dfi_4_dw_rddata_p0;
	wire [31 : 0] dfi_4_dw_rddata_dm_p0;
	wire [31 : 0] dfi_4_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_4_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_4_dw_rddata_p1;
	wire [31 : 0] dfi_4_dw_rddata_dm_p1;
	wire [31 : 0] dfi_4_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_4_dw_rddata_par_p1;
	//wire [15 : 0] dfi_4_dbi_byte_disable;
	wire [3 : 0] w_dfi_4_dw_rddata_valid;
	//wire [7 : 0] dfi_4_dw_derr_n;
	//wire [1 : 0] dfi_4_aw_aerr_n;
	wire dfi_4_ctrlupd_req;
	wire dfi_4_phyupd_ack;
	//wire dfi_4_clk_init;
	wire w_dfi_4_init_complete;
	wire w_dfi_4_out_rst_n;
	
	// CHANNEL 5
	wire dfi_5_init_start;
	wire [1 : 0] dfi_5_aw_ck_p0;
	wire [1 : 0] dfi_5_aw_cke_p0;
	wire [11 : 0] dfi_5_aw_row_p0;
	wire [15 : 0] dfi_5_aw_col_p0;
	wire [255 : 0] dfi_5_dw_wrdata_p0;
	wire [31 : 0] dfi_5_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_5_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_5_dw_wrdata_par_p0;
	wire [7 : 0] dfi_5_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_5_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_5_aw_ck_p1;
	wire [1 : 0] dfi_5_aw_cke_p1;
	wire [11 : 0] dfi_5_aw_row_p1;
	wire [15 : 0] dfi_5_aw_col_p1;
	wire [255 : 0] dfi_5_dw_wrdata_p1;
	wire [31 : 0] dfi_5_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_5_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_5_dw_wrdata_par_p1;
	wire [7 : 0] dfi_5_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_5_dw_wrdata_par_en_p1;
	wire dfi_5_aw_ck_dis;
	wire dfi_5_lp_pwr_e_req;
	wire dfi_5_lp_sr_e_req;
	wire dfi_5_lp_pwr_x_req;
	wire dfi_5_aw_tx_indx_ld;
	wire dfi_5_dw_tx_indx_ld;
	wire dfi_5_dw_rx_indx_ld;
	wire dfi_5_ctrlupd_ack;
	wire dfi_5_phyupd_req;
	
	wire [255 : 0] w_dfi_5_dw_rddata_p0;
	wire [31 : 0] dfi_5_dw_rddata_dm_p0;
	wire [31 : 0] dfi_5_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_5_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_5_dw_rddata_p1;
	wire [31 : 0] dfi_5_dw_rddata_dm_p1;
	wire [31 : 0] dfi_5_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_5_dw_rddata_par_p1;
	//wire [15 : 0] dfi_5_dbi_byte_disable;
	wire [3 : 0] w_dfi_5_dw_rddata_valid;
	//wire [7 : 0] dfi_5_dw_derr_n;
	//wire [1 : 0] dfi_5_aw_aerr_n;
	wire dfi_5_ctrlupd_req;
	wire dfi_5_phyupd_ack;
	//wire dfi_5_clk_init;
	wire w_dfi_5_init_complete;
	wire w_dfi_5_out_rst_n;
	
	
	// CHANNEL 6
	wire dfi_6_init_start;
	wire [1 : 0] dfi_6_aw_ck_p0;
	wire [1 : 0] dfi_6_aw_cke_p0;
	wire [11 : 0] dfi_6_aw_row_p0;
	wire [15 : 0] dfi_6_aw_col_p0;
	wire [255 : 0] dfi_6_dw_wrdata_p0;
	wire [31 : 0] dfi_6_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_6_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_6_dw_wrdata_par_p0;
	wire [7 : 0] dfi_6_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_6_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_6_aw_ck_p1;
	wire [1 : 0] dfi_6_aw_cke_p1;
	wire [11 : 0] dfi_6_aw_row_p1;
	wire [15 : 0] dfi_6_aw_col_p1;
	wire [255 : 0] dfi_6_dw_wrdata_p1;
	wire [31 : 0] dfi_6_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_6_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_6_dw_wrdata_par_p1;
	wire [7 : 0] dfi_6_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_6_dw_wrdata_par_en_p1;
	wire dfi_6_aw_ck_dis;
	wire dfi_6_lp_pwr_e_req;
	wire dfi_6_lp_sr_e_req;
	wire dfi_6_lp_pwr_x_req;
	wire dfi_6_aw_tx_indx_ld;
	wire dfi_6_dw_tx_indx_ld;
	wire dfi_6_dw_rx_indx_ld;
	wire dfi_6_ctrlupd_ack;
	wire dfi_6_phyupd_req;
	
	wire [255 : 0] w_dfi_6_dw_rddata_p0;
	wire [31 : 0] dfi_6_dw_rddata_dm_p0;
	wire [31 : 0] dfi_6_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_6_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_6_dw_rddata_p1;
	wire [31 : 0] dfi_6_dw_rddata_dm_p1;
	wire [31 : 0] dfi_6_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_6_dw_rddata_par_p1;
	//wire [15 : 0] dfi_6_dbi_byte_disable;
	wire [3 : 0] w_dfi_6_dw_rddata_valid;
	//wire [7 : 0] dfi_6_dw_derr_n;
	//wire [1 : 0] dfi_6_aw_aerr_n;
	wire dfi_6_ctrlupd_req;
	wire dfi_6_phyupd_ack;
	//wire dfi_6_clk_init;
	wire w_dfi_6_init_complete;
	wire w_dfi_6_out_rst_n;
	
	
	// CHANNEL 7
	wire dfi_7_init_start;
	wire [1 : 0] dfi_7_aw_ck_p0;
	wire [1 : 0] dfi_7_aw_cke_p0;
	wire [11 : 0] dfi_7_aw_row_p0;
	wire [15 : 0] dfi_7_aw_col_p0;
	wire [255 : 0] dfi_7_dw_wrdata_p0;
	wire [31 : 0] dfi_7_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_7_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_7_dw_wrdata_par_p0;
	wire [7 : 0] dfi_7_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_7_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_7_aw_ck_p1;
	wire [1 : 0] dfi_7_aw_cke_p1;
	wire [11 : 0] dfi_7_aw_row_p1;
	wire [15 : 0] dfi_7_aw_col_p1;
	wire [255 : 0] dfi_7_dw_wrdata_p1;
	wire [31 : 0] dfi_7_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_7_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_7_dw_wrdata_par_p1;
	wire [7 : 0] dfi_7_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_7_dw_wrdata_par_en_p1;
	wire dfi_7_aw_ck_dis;
	wire dfi_7_lp_pwr_e_req;
	wire dfi_7_lp_sr_e_req;
	wire dfi_7_lp_pwr_x_req;
	wire dfi_7_aw_tx_indx_ld;
	wire dfi_7_dw_tx_indx_ld;
	wire dfi_7_dw_rx_indx_ld;
	wire dfi_7_ctrlupd_ack;
	wire dfi_7_phyupd_req;
	
	wire [255 : 0] w_dfi_7_dw_rddata_p0;
	wire [31 : 0] dfi_7_dw_rddata_dm_p0;
	wire [31 : 0] dfi_7_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_7_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_7_dw_rddata_p1;
	wire [31 : 0] dfi_7_dw_rddata_dm_p1;
	wire [31 : 0] dfi_7_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_7_dw_rddata_par_p1;
	//wire [15 : 0] dfi_7_dbi_byte_disable;
	wire [3 : 0] w_dfi_7_dw_rddata_valid;
	//wire [7 : 0] dfi_7_dw_derr_n;
	//wire [1 : 0] dfi_7_aw_aerr_n;
	wire dfi_7_ctrlupd_req;
	wire dfi_7_phyupd_ack;
	//wire dfi_7_clk_init;
	wire w_dfi_7_init_complete;
	wire w_dfi_7_out_rst_n;*/
	
	
	// CHANNEL 8
	wire dfi_8_init_start;
	wire [1 : 0] dfi_8_aw_ck_p0;
	wire [1 : 0] dfi_8_aw_cke_p0;
	wire [11 : 0] dfi_8_aw_row_p0;
	wire [15 : 0] dfi_8_aw_col_p0;
	wire [255 : 0] dfi_8_dw_wrdata_p0;
	wire [31 : 0] dfi_8_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_8_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_8_dw_wrdata_par_p0;
	wire [7 : 0] dfi_8_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_8_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_8_aw_ck_p1;
	wire [1 : 0] dfi_8_aw_cke_p1;
	wire [11 : 0] dfi_8_aw_row_p1;
	wire [15 : 0] dfi_8_aw_col_p1;
	wire [255 : 0] dfi_8_dw_wrdata_p1;
	wire [31 : 0] dfi_8_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_8_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_8_dw_wrdata_par_p1;
	wire [7 : 0] dfi_8_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_8_dw_wrdata_par_en_p1;
	wire dfi_8_aw_ck_dis;
	wire dfi_8_lp_pwr_e_req;
	wire dfi_8_lp_sr_e_req;
	wire dfi_8_lp_pwr_x_req;
	wire dfi_8_aw_tx_indx_ld;
	wire dfi_8_dw_tx_indx_ld;
	wire dfi_8_dw_rx_indx_ld;
	wire dfi_8_ctrlupd_ack;
	wire dfi_8_phyupd_req;
	
	wire [255 : 0] w_dfi_8_dw_rddata_p0;
	wire [31 : 0] dfi_8_dw_rddata_dm_p0;
	wire [31 : 0] dfi_8_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_8_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_8_dw_rddata_p1;
	wire [31 : 0] dfi_8_dw_rddata_dm_p1;
	wire [31 : 0] dfi_8_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_8_dw_rddata_par_p1;
	//wire [15 : 0] dfi_8_dbi_byte_disable;
	wire [3 : 0] w_dfi_8_dw_rddata_valid;
	//wire [7 : 0] dfi_8_dw_derr_n;
	//wire [1 : 0] dfi_8_aw_aerr_n;
	wire dfi_8_ctrlupd_req;
	wire dfi_8_phyupd_ack;
	//wire dfi_8_clk_init;
	wire w_dfi_8_init_complete;
	wire w_dfi_8_out_rst_n;
	
	
	// CHANNEL 9
	wire dfi_9_init_start;
	wire [1 : 0] dfi_9_aw_ck_p0;
	wire [1 : 0] dfi_9_aw_cke_p0;
	wire [11 : 0] dfi_9_aw_row_p0;
	wire [15 : 0] dfi_9_aw_col_p0;
	wire [255 : 0] dfi_9_dw_wrdata_p0;
	wire [31 : 0] dfi_9_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_9_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_9_dw_wrdata_par_p0;
	wire [7 : 0] dfi_9_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_9_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_9_aw_ck_p1;
	wire [1 : 0] dfi_9_aw_cke_p1;
	wire [11 : 0] dfi_9_aw_row_p1;
	wire [15 : 0] dfi_9_aw_col_p1;
	wire [255 : 0] dfi_9_dw_wrdata_p1;
	wire [31 : 0] dfi_9_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_9_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_9_dw_wrdata_par_p1;
	wire [7 : 0] dfi_9_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_9_dw_wrdata_par_en_p1;
	wire dfi_9_aw_ck_dis;
	wire dfi_9_lp_pwr_e_req;
	wire dfi_9_lp_sr_e_req;
	wire dfi_9_lp_pwr_x_req;
	wire dfi_9_aw_tx_indx_ld;
	wire dfi_9_dw_tx_indx_ld;
	wire dfi_9_dw_rx_indx_ld;
	wire dfi_9_ctrlupd_ack;
	wire dfi_9_phyupd_req;
	
	wire [255 : 0] w_dfi_9_dw_rddata_p0;
	wire [31 : 0] dfi_9_dw_rddata_dm_p0;
	wire [31 : 0] dfi_9_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_9_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_9_dw_rddata_p1;
	wire [31 : 0] dfi_9_dw_rddata_dm_p1;
	wire [31 : 0] dfi_9_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_9_dw_rddata_par_p1;
	//wire [15 : 0] dfi_9_dbi_byte_disable;
	wire [3 : 0] w_dfi_9_dw_rddata_valid;
	//wire [7 : 0] dfi_9_dw_derr_n;
	//wire [1 : 0] dfi_9_aw_aerr_n;
	wire dfi_9_ctrlupd_req;
	wire dfi_9_phyupd_ack;
	//wire dfi_9_clk_init;
	wire w_dfi_9_init_complete;
	wire w_dfi_9_out_rst_n;
	
	
	// CHANNEL 10
	wire dfi_10_init_start;
	wire [1 : 0] dfi_10_aw_ck_p0;
	wire [1 : 0] dfi_10_aw_cke_p0;
	wire [11 : 0] dfi_10_aw_row_p0;
	wire [15 : 0] dfi_10_aw_col_p0;
	wire [255 : 0] dfi_10_dw_wrdata_p0;
	wire [31 : 0] dfi_10_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_10_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_10_dw_wrdata_par_p0;
	wire [7 : 0] dfi_10_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_10_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_10_aw_ck_p1;
	wire [1 : 0] dfi_10_aw_cke_p1;
	wire [11 : 0] dfi_10_aw_row_p1;
	wire [15 : 0] dfi_10_aw_col_p1;
	wire [255 : 0] dfi_10_dw_wrdata_p1;
	wire [31 : 0] dfi_10_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_10_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_10_dw_wrdata_par_p1;
	wire [7 : 0] dfi_10_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_10_dw_wrdata_par_en_p1;
	wire dfi_10_aw_ck_dis;
	wire dfi_10_lp_pwr_e_req;
	wire dfi_10_lp_sr_e_req;
	wire dfi_10_lp_pwr_x_req;
	wire dfi_10_aw_tx_indx_ld;
	wire dfi_10_dw_tx_indx_ld;
	wire dfi_10_dw_rx_indx_ld;
	wire dfi_10_ctrlupd_ack;
	wire dfi_10_phyupd_req;
	
	wire [255 : 0] w_dfi_10_dw_rddata_p0;
	wire [31 : 0] dfi_10_dw_rddata_dm_p0;
	wire [31 : 0] dfi_10_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_10_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_10_dw_rddata_p1;
	wire [31 : 0] dfi_10_dw_rddata_dm_p1;
	wire [31 : 0] dfi_10_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_10_dw_rddata_par_p1;
	//wire [15 : 0] dfi_10_dbi_byte_disable;
	wire [3 : 0] w_dfi_10_dw_rddata_valid;
	//wire [7 : 0] dfi_10_dw_derr_n;
	//wire [1 : 0] dfi_10_aw_aerr_n;
	wire dfi_10_ctrlupd_req;
	wire dfi_10_phyupd_ack;
	//wire dfi_10_clk_init;
	wire w_dfi_10_init_complete;
	wire w_dfi_10_out_rst_n;
	
	
	// CHANNEL 11
	wire dfi_11_init_start;
	wire [1 : 0] dfi_11_aw_ck_p0;
	wire [1 : 0] dfi_11_aw_cke_p0;
	wire [11 : 0] dfi_11_aw_row_p0;
	wire [15 : 0] dfi_11_aw_col_p0;
	wire [255 : 0] dfi_11_dw_wrdata_p0;
	wire [31 : 0] dfi_11_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_11_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_11_dw_wrdata_par_p0;
	wire [7 : 0] dfi_11_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_11_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_11_aw_ck_p1;
	wire [1 : 0] dfi_11_aw_cke_p1;
	wire [11 : 0] dfi_11_aw_row_p1;
	wire [15 : 0] dfi_11_aw_col_p1;
	wire [255 : 0] dfi_11_dw_wrdata_p1;
	wire [31 : 0] dfi_11_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_11_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_11_dw_wrdata_par_p1;
	wire [7 : 0] dfi_11_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_11_dw_wrdata_par_en_p1;
	wire dfi_11_aw_ck_dis;
	wire dfi_11_lp_pwr_e_req;
	wire dfi_11_lp_sr_e_req;
	wire dfi_11_lp_pwr_x_req;
	wire dfi_11_aw_tx_indx_ld;
	wire dfi_11_dw_tx_indx_ld;
	wire dfi_11_dw_rx_indx_ld;
	wire dfi_11_ctrlupd_ack;
	wire dfi_11_phyupd_req;
	
	wire [255 : 0] w_dfi_11_dw_rddata_p0;
	wire [31 : 0] dfi_11_dw_rddata_dm_p0;
	wire [31 : 0] dfi_11_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_11_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_11_dw_rddata_p1;
	wire [31 : 0] dfi_11_dw_rddata_dm_p1;
	wire [31 : 0] dfi_11_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_11_dw_rddata_par_p1;
	//wire [15 : 0] dfi_11_dbi_byte_disable;
	wire [3 : 0] w_dfi_11_dw_rddata_valid;
	//wire [7 : 0] dfi_11_dw_derr_n;
	//wire [1 : 0] dfi_11_aw_aerr_n;
	wire dfi_11_ctrlupd_req;
	wire dfi_11_phyupd_ack;
	//wire dfi_11_clk_init;
	wire w_dfi_11_init_complete;
	wire w_dfi_11_out_rst_n;
	
	
	// CHANNEL 12
	wire dfi_12_init_start;
	wire [1 : 0] dfi_12_aw_ck_p0;
	wire [1 : 0] dfi_12_aw_cke_p0;
	wire [11 : 0] dfi_12_aw_row_p0;
	wire [15 : 0] dfi_12_aw_col_p0;
	wire [255 : 0] dfi_12_dw_wrdata_p0;
	wire [31 : 0] dfi_12_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_12_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_12_dw_wrdata_par_p0;
	wire [7 : 0] dfi_12_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_12_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_12_aw_ck_p1;
	wire [1 : 0] dfi_12_aw_cke_p1;
	wire [11 : 0] dfi_12_aw_row_p1;
	wire [15 : 0] dfi_12_aw_col_p1;
	wire [255 : 0] dfi_12_dw_wrdata_p1;
	wire [31 : 0] dfi_12_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_12_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_12_dw_wrdata_par_p1;
	wire [7 : 0] dfi_12_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_12_dw_wrdata_par_en_p1;
	wire dfi_12_aw_ck_dis;
	wire dfi_12_lp_pwr_e_req;
	wire dfi_12_lp_sr_e_req;
	wire dfi_12_lp_pwr_x_req;
	wire dfi_12_aw_tx_indx_ld;
	wire dfi_12_dw_tx_indx_ld;
	wire dfi_12_dw_rx_indx_ld;
	wire dfi_12_ctrlupd_ack;
	wire dfi_12_phyupd_req;
	
	wire [255 : 0] w_dfi_12_dw_rddata_p0;
	wire [31 : 0] dfi_12_dw_rddata_dm_p0;
	wire [31 : 0] dfi_12_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_12_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_12_dw_rddata_p1;
	wire [31 : 0] dfi_12_dw_rddata_dm_p1;
	wire [31 : 0] dfi_12_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_12_dw_rddata_par_p1;
	//wire [15 : 0] dfi_12_dbi_byte_disable;
	wire [3 : 0] w_dfi_12_dw_rddata_valid;
	//wire [7 : 0] dfi_12_dw_derr_n;
	//wire [1 : 0] dfi_12_aw_aerr_n;
	wire dfi_12_ctrlupd_req;
	wire dfi_12_phyupd_ack;
	//wire dfi_12_clk_init;
	wire w_dfi_12_init_complete;
	wire w_dfi_12_out_rst_n;
	
	
	// CHANNEL 13
	wire dfi_13_init_start;
	wire [1 : 0] dfi_13_aw_ck_p0;
	wire [1 : 0] dfi_13_aw_cke_p0;
	wire [11 : 0] dfi_13_aw_row_p0;
	wire [15 : 0] dfi_13_aw_col_p0;
	wire [255 : 0] dfi_13_dw_wrdata_p0;
	wire [31 : 0] dfi_13_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_13_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_13_dw_wrdata_par_p0;
	wire [7 : 0] dfi_13_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_13_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_13_aw_ck_p1;
	wire [1 : 0] dfi_13_aw_cke_p1;
	wire [11 : 0] dfi_13_aw_row_p1;
	wire [15 : 0] dfi_13_aw_col_p1;
	wire [255 : 0] dfi_13_dw_wrdata_p1;
	wire [31 : 0] dfi_13_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_13_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_13_dw_wrdata_par_p1;
	wire [7 : 0] dfi_13_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_13_dw_wrdata_par_en_p1;
	wire dfi_13_aw_ck_dis;
	wire dfi_13_lp_pwr_e_req;
	wire dfi_13_lp_sr_e_req;
	wire dfi_13_lp_pwr_x_req;
	wire dfi_13_aw_tx_indx_ld;
	wire dfi_13_dw_tx_indx_ld;
	wire dfi_13_dw_rx_indx_ld;
	wire dfi_13_ctrlupd_ack;
	wire dfi_13_phyupd_req;
	
	wire [255 : 0] w_dfi_13_dw_rddata_p0;
	wire [31 : 0] dfi_13_dw_rddata_dm_p0;
	wire [31 : 0] dfi_13_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_13_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_13_dw_rddata_p1;
	wire [31 : 0] dfi_13_dw_rddata_dm_p1;
	wire [31 : 0] dfi_13_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_13_dw_rddata_par_p1;
	//wire [15 : 0] dfi_13_dbi_byte_disable;
	wire [3 : 0] w_dfi_13_dw_rddata_valid;
	//wire [7 : 0] dfi_13_dw_derr_n;
	//wire [1 : 0] dfi_13_aw_aerr_n;
	wire dfi_13_ctrlupd_req;
	wire dfi_13_phyupd_ack;
	//wire dfi_13_clk_init;
	wire w_dfi_13_init_complete;
	wire w_dfi_13_out_rst_n;
	
	
	// CHANNEL 14
	wire dfi_14_init_start;
	wire [1 : 0] dfi_14_aw_ck_p0;
	wire [1 : 0] dfi_14_aw_cke_p0;
	wire [11 : 0] dfi_14_aw_row_p0;
	wire [15 : 0] dfi_14_aw_col_p0;
	wire [255 : 0] dfi_14_dw_wrdata_p0;
	wire [31 : 0] dfi_14_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_14_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_14_dw_wrdata_par_p0;
	wire [7 : 0] dfi_14_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_14_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_14_aw_ck_p1;
	wire [1 : 0] dfi_14_aw_cke_p1;
	wire [11 : 0] dfi_14_aw_row_p1;
	wire [15 : 0] dfi_14_aw_col_p1;
	wire [255 : 0] dfi_14_dw_wrdata_p1;
	wire [31 : 0] dfi_14_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_14_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_14_dw_wrdata_par_p1;
	wire [7 : 0] dfi_14_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_14_dw_wrdata_par_en_p1;
	wire dfi_14_aw_ck_dis;
	wire dfi_14_lp_pwr_e_req;
	wire dfi_14_lp_sr_e_req;
	wire dfi_14_lp_pwr_x_req;
	wire dfi_14_aw_tx_indx_ld;
	wire dfi_14_dw_tx_indx_ld;
	wire dfi_14_dw_rx_indx_ld;
	wire dfi_14_ctrlupd_ack;
	wire dfi_14_phyupd_req;
	
	wire [255 : 0] w_dfi_14_dw_rddata_p0;
	wire [31 : 0] dfi_14_dw_rddata_dm_p0;
	wire [31 : 0] dfi_14_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_14_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_14_dw_rddata_p1;
	wire [31 : 0] dfi_14_dw_rddata_dm_p1;
	wire [31 : 0] dfi_14_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_14_dw_rddata_par_p1;
	//wire [15 : 0] dfi_14_dbi_byte_disable;
	wire [3 : 0] w_dfi_14_dw_rddata_valid;
	//wire [7 : 0] dfi_14_dw_derr_n;
	//wire [1 : 0] dfi_14_aw_aerr_n;
	wire dfi_14_ctrlupd_req;
	wire dfi_14_phyupd_ack;
	//wire dfi_14_clk_init;
	wire w_dfi_14_init_complete;
	wire w_dfi_14_out_rst_n;
	
	
	// CHANNEL 15
	wire dfi_15_init_start;
	wire [1 : 0] dfi_15_aw_ck_p0;
	wire [1 : 0] dfi_15_aw_cke_p0;
	wire [11 : 0] dfi_15_aw_row_p0;
	wire [15 : 0] dfi_15_aw_col_p0;
	wire [255 : 0] dfi_15_dw_wrdata_p0;
	wire [31 : 0] dfi_15_dw_wrdata_mask_p0;
	wire [31 : 0] dfi_15_dw_wrdata_dbi_p0;
	wire [7 : 0] dfi_15_dw_wrdata_par_p0;
	wire [7 : 0] dfi_15_dw_wrdata_dq_en_p0;
	wire [7 : 0] dfi_15_dw_wrdata_par_en_p0;
	wire [1 : 0] dfi_15_aw_ck_p1;
	wire [1 : 0] dfi_15_aw_cke_p1;
	wire [11 : 0] dfi_15_aw_row_p1;
	wire [15 : 0] dfi_15_aw_col_p1;
	wire [255 : 0] dfi_15_dw_wrdata_p1;
	wire [31 : 0] dfi_15_dw_wrdata_mask_p1;
	wire [31 : 0] dfi_15_dw_wrdata_dbi_p1;
	wire [7 : 0] dfi_15_dw_wrdata_par_p1;
	wire [7 : 0] dfi_15_dw_wrdata_dq_en_p1;
	wire [7 : 0] dfi_15_dw_wrdata_par_en_p1;
	wire dfi_15_aw_ck_dis;
	wire dfi_15_lp_pwr_e_req;
	wire dfi_15_lp_sr_e_req;
	wire dfi_15_lp_pwr_x_req;
	wire dfi_15_aw_tx_indx_ld;
	wire dfi_15_dw_tx_indx_ld;
	wire dfi_15_dw_rx_indx_ld;
	wire dfi_15_ctrlupd_ack;
	wire dfi_15_phyupd_req;
	
	wire [255 : 0] w_dfi_15_dw_rddata_p0;
	wire [31 : 0] dfi_15_dw_rddata_dm_p0;
	wire [31 : 0] dfi_15_dw_rddata_dbi_p0;
	wire [7 : 0] dfi_15_dw_rddata_par_p0;
	wire [255 : 0] w_dfi_15_dw_rddata_p1;
	wire [31 : 0] dfi_15_dw_rddata_dm_p1;
	wire [31 : 0] dfi_15_dw_rddata_dbi_p1;
	wire [7 : 0] dfi_15_dw_rddata_par_p1;
	//wire [15 : 0] dfi_15_dbi_byte_disable;
	wire [3 : 0] w_dfi_15_dw_rddata_valid;
	//wire [7 : 0] dfi_15_dw_derr_n;
	//wire [1 : 0] dfi_15_aw_aerr_n;
	wire dfi_15_ctrlupd_req;
	wire dfi_15_phyupd_ack;
	//wire dfi_15_clk_init;
	wire w_dfi_15_init_complete;
	wire w_dfi_15_out_rst_n;
	
	wire apb_complete_0;
	wire apb_complete_1;
	wire DRAM_0_STAT_CATTRIP;
	wire [6 : 0] DRAM_0_STAT_TEMP;
	wire DRAM_1_STAT_CATTRIP;
	wire [6 : 0] DRAM_1_STAT_TEMP;
	
	assign hbm0_temp = DRAM_0_STAT_TEMP;
	assign hbm1_temp = DRAM_1_STAT_TEMP;
	
	/*wire w_0_ready;
	wire w_1_ready;
	wire w_2_ready;
	wire w_3_ready;
	wire w_4_ready;
	wire w_5_ready;
	wire w_6_ready;
	wire w_7_ready;*/
	wire w_8_ready;
	wire w_9_ready;
	wire w_10_ready;
	wire w_11_ready;
	wire w_12_ready;
	wire w_13_ready;
	wire w_14_ready;
	wire w_15_ready;
	
	/*wire [2*`CMD_TYPE_WIDTH-1:0]	w_0_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_1_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_2_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_3_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_4_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_5_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_6_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_7_cmd_type;*/
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_8_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_9_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_10_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_11_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_12_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_13_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_14_cmd_type;
	wire [2*`CMD_TYPE_WIDTH-1:0]	w_15_cmd_type;
	
	wire w_ch_dfi_init_complete;
	wire [255 : 0] w_ch_dfi_dw_rddata_p0;
	wire [255 : 0] w_ch_dfi_dw_rddata_p1;
	wire [3 : 0] w_ch_dfi_dw_rddata_valid;
	wire w_ch_dfi_out_rst_n;
	wire w_ch_ready;
	
	wire	[2*`ROW_ADDR_WIDTH-1:0]	    o_row_addr;
	wire	[2*`COL_ADDR_WIDTH-1:0]	    o_col_addr;
	wire	[2*`BA_ADDR_WIDTH-1:0]	    o_ba_addr;
	wire	[2*`WR_DATA_WIDTH-1:0]      o_i_wrdata;
	wire 	[2*`PC_WIDTH-1:0]		    o_BA4; // indicates target PC
	
	assign dfi_0_init_complete     = w_ch_dfi_init_complete;
	assign dfi_0_dw_rddata_p0      = w_ch_dfi_dw_rddata_p0;
	assign dfi_0_dw_rddata_p1      = w_ch_dfi_dw_rddata_p1;
	assign dfi_0_dw_rddata_valid   = w_ch_dfi_dw_rddata_valid;
	assign dfi_0_out_rst_n         = w_ch_dfi_out_rst_n;
	assign ready                   = w_ch_ready;
	
	channel_selector ch_sel (
        .row_addr(row_addr),
		.col_addr(col_addr),
		.ba_addr(ba_addr),
		.i_wrdata(i_wrdata),
		.cmd_type(cmd_type),
		.BA4(BA4), // indicates target PC
		.channel_id(channel_id[3:0]),
		
		.dfi_clk(dfi_clk),
    	.dfi_rst_n(dfi_rst_n),
        
        /*.dfi_0_init_complete(w_dfi_0_init_complete),
		.dfi_0_dw_rddata_p0(w_dfi_0_dw_rddata_p0),
		.dfi_0_dw_rddata_p1(w_dfi_0_dw_rddata_p1),
		.dfi_0_dw_rddata_valid(w_dfi_0_dw_rddata_valid),
		.dfi_0_out_rst_n(w_dfi_0_out_rst_n),
	    .ready_0(w_0_ready),
	    
	    .dfi_1_init_complete(w_dfi_1_init_complete),
		.dfi_1_dw_rddata_p0(w_dfi_1_dw_rddata_p0),
		.dfi_1_dw_rddata_p1(w_dfi_1_dw_rddata_p1),
		.dfi_1_dw_rddata_valid(w_dfi_1_dw_rddata_valid),
		.dfi_1_out_rst_n(w_dfi_1_out_rst_n),
	    .ready_1(w_1_ready),
	    
	    .dfi_2_init_complete(w_dfi_2_init_complete),
		.dfi_2_dw_rddata_p0(w_dfi_2_dw_rddata_p0),
		.dfi_2_dw_rddata_p1(w_dfi_2_dw_rddata_p1),
		.dfi_2_dw_rddata_valid(w_dfi_2_dw_rddata_valid),
		.dfi_2_out_rst_n(w_dfi_2_out_rst_n),
	    .ready_2(w_2_ready),
	    
	    .dfi_3_init_complete(w_dfi_3_init_complete),
		.dfi_3_dw_rddata_p0(w_dfi_3_dw_rddata_p0),
		.dfi_3_dw_rddata_p1(w_dfi_3_dw_rddata_p1),
		.dfi_3_dw_rddata_valid(w_dfi_3_dw_rddata_valid),
		.dfi_3_out_rst_n(w_dfi_3_out_rst_n),
	    .ready_3(w_3_ready),
	    
	    .dfi_4_init_complete(w_dfi_4_init_complete),
		.dfi_4_dw_rddata_p0(w_dfi_4_dw_rddata_p0),
		.dfi_4_dw_rddata_p1(w_dfi_4_dw_rddata_p1),
		.dfi_4_dw_rddata_valid(w_dfi_4_dw_rddata_valid),
		.dfi_4_out_rst_n(w_dfi_4_out_rst_n),
	    .ready_4(w_4_ready),
	    
	    .dfi_5_init_complete(w_dfi_5_init_complete),
		.dfi_5_dw_rddata_p0(w_dfi_5_dw_rddata_p0),
		.dfi_5_dw_rddata_p1(w_dfi_5_dw_rddata_p1),
		.dfi_5_dw_rddata_valid(w_dfi_5_dw_rddata_valid),
		.dfi_5_out_rst_n(w_dfi_5_out_rst_n),
	    .ready_5(w_5_ready),
	    
	    .dfi_6_init_complete(w_dfi_6_init_complete),
		.dfi_6_dw_rddata_p0(w_dfi_6_dw_rddata_p0),
		.dfi_6_dw_rddata_p1(w_dfi_6_dw_rddata_p1),
		.dfi_6_dw_rddata_valid(w_dfi_6_dw_rddata_valid),
		.dfi_6_out_rst_n(w_dfi_6_out_rst_n),
	    .ready_6(w_6_ready),
	    
	    .dfi_7_init_complete(w_dfi_7_init_complete),
		.dfi_7_dw_rddata_p0(w_dfi_7_dw_rddata_p0),
		.dfi_7_dw_rddata_p1(w_dfi_7_dw_rddata_p1),
		.dfi_7_dw_rddata_valid(w_dfi_7_dw_rddata_valid),
		.dfi_7_out_rst_n(w_dfi_7_out_rst_n),
	    .ready_7(w_7_ready),*/
	    
	    .dfi_8_init_complete(w_dfi_8_init_complete),
		.dfi_8_dw_rddata_p0(w_dfi_8_dw_rddata_p0),
		.dfi_8_dw_rddata_p1(w_dfi_8_dw_rddata_p1),
		.dfi_8_dw_rddata_valid(w_dfi_8_dw_rddata_valid),
		.dfi_8_out_rst_n(w_dfi_8_out_rst_n),
	    .ready_8(w_8_ready),
	    
	    .dfi_9_init_complete(w_dfi_9_init_complete),
		.dfi_9_dw_rddata_p0(w_dfi_9_dw_rddata_p0),
		.dfi_9_dw_rddata_p1(w_dfi_9_dw_rddata_p1),
		.dfi_9_dw_rddata_valid(w_dfi_9_dw_rddata_valid),
		.dfi_9_out_rst_n(w_dfi_9_out_rst_n),
	    .ready_9(w_9_ready),
	    
	    .dfi_10_init_complete(w_dfi_10_init_complete),
		.dfi_10_dw_rddata_p0(w_dfi_10_dw_rddata_p0),
		.dfi_10_dw_rddata_p1(w_dfi_10_dw_rddata_p1),
		.dfi_10_dw_rddata_valid(w_dfi_10_dw_rddata_valid),
		.dfi_10_out_rst_n(w_dfi_10_out_rst_n),
	    .ready_10(w_10_ready),
	    
	    .dfi_11_init_complete(w_dfi_11_init_complete),
		.dfi_11_dw_rddata_p0(w_dfi_11_dw_rddata_p0),
		.dfi_11_dw_rddata_p1(w_dfi_11_dw_rddata_p1),
		.dfi_11_dw_rddata_valid(w_dfi_11_dw_rddata_valid),
		.dfi_11_out_rst_n(w_dfi_11_out_rst_n),
	    .ready_11(w_11_ready),
	    
	    .dfi_12_init_complete(w_dfi_12_init_complete),
		.dfi_12_dw_rddata_p0(w_dfi_12_dw_rddata_p0),
		.dfi_12_dw_rddata_p1(w_dfi_12_dw_rddata_p1),
		.dfi_12_dw_rddata_valid(w_dfi_12_dw_rddata_valid),
		.dfi_12_out_rst_n(w_dfi_12_out_rst_n),
	    .ready_12(w_12_ready),
	    
	    .dfi_13_init_complete(w_dfi_13_init_complete),
		.dfi_13_dw_rddata_p0(w_dfi_13_dw_rddata_p0),
		.dfi_13_dw_rddata_p1(w_dfi_13_dw_rddata_p1),
		.dfi_13_dw_rddata_valid(w_dfi_13_dw_rddata_valid),
		.dfi_13_out_rst_n(w_dfi_13_out_rst_n),
	    .ready_13(w_13_ready),
	    
	    .dfi_14_init_complete(w_dfi_14_init_complete),
		.dfi_14_dw_rddata_p0(w_dfi_14_dw_rddata_p0),
		.dfi_14_dw_rddata_p1(w_dfi_14_dw_rddata_p1),
		.dfi_14_dw_rddata_valid(w_dfi_14_dw_rddata_valid),
		.dfi_14_out_rst_n(w_dfi_14_out_rst_n),
	    .ready_14(w_14_ready),
	    
	    .dfi_15_init_complete(w_dfi_15_init_complete),
		.dfi_15_dw_rddata_p0(w_dfi_15_dw_rddata_p0),
		.dfi_15_dw_rddata_p1(w_dfi_15_dw_rddata_p1),
		.dfi_15_dw_rddata_valid(w_dfi_15_dw_rddata_valid),
		.dfi_15_out_rst_n(w_dfi_15_out_rst_n),
	    .ready_15(w_15_ready),
	    
	    .o_ch_dfi_init_complete(w_ch_dfi_init_complete),
		.o_ch_dfi_dw_rddata_p0(w_ch_dfi_dw_rddata_p0),
		.o_ch_dfi_dw_rddata_p1(w_ch_dfi_dw_rddata_p1),
		.o_ch_dfi_dw_rddata_valid(w_ch_dfi_dw_rddata_valid),
		.o_ch_dfi_out_rst_n(w_ch_dfi_out_rst_n),
		.o_ch_ready(w_ch_ready),
		
		/*.o_0_cmd_type(w_0_cmd_type),
		.o_1_cmd_type(w_1_cmd_type),
		.o_2_cmd_type(w_2_cmd_type),
		.o_3_cmd_type(w_3_cmd_type),
		.o_4_cmd_type(w_4_cmd_type),
		.o_5_cmd_type(w_5_cmd_type),
		.o_6_cmd_type(w_6_cmd_type),
		.o_7_cmd_type(w_7_cmd_type),*/
		.o_8_cmd_type(w_8_cmd_type),
		.o_9_cmd_type(w_9_cmd_type),
		.o_10_cmd_type(w_10_cmd_type),
		.o_11_cmd_type(w_11_cmd_type),
		.o_12_cmd_type(w_12_cmd_type),
		.o_13_cmd_type(w_13_cmd_type),
		.o_14_cmd_type(w_14_cmd_type),
		.o_15_cmd_type(w_15_cmd_type),
		
		.o_row_addr(o_row_addr),
		.o_col_addr(o_col_addr),
		.o_ba_addr(o_ba_addr),
		.o_i_wrdata(o_i_wrdata),
		.o_BA4(o_BA4) // indicates target PC
    );
    
    /*HBM_interface HBM_interface_CH0 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_0_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_0_out_rst_n), // this was dfi_0_out_rst_n
		.dfi_ctrlupd_req					   (dfi_0_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_0_phyupd_ack),
		.dfi_init_complete					   (w_dfi_0_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_0_init_start),
		.dfi_aw_ck_p0            			   (dfi_0_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_0_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_0_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_0_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_0_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_0_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_0_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_0_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_0_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_0_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_0_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_0_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_0_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_0_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_0_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_0_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_0_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_0_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_0_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_0_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_0_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_0_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_0_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_0_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_0_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_0_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_0_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_0_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_0_phyupd_req),
    	.ready                                 (w_0_ready)
    );
    
    
    HBM_interface HBM_interface_CH1 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_1_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_1_out_rst_n), // this was dfi_1_out_rst_n
		.dfi_ctrlupd_req					   (dfi_1_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_1_phyupd_ack),
		.dfi_init_complete					   (w_dfi_1_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_1_init_start),
		.dfi_aw_ck_p0            			   (dfi_1_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_1_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_1_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_1_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_1_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_1_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_1_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_1_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_1_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_1_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_1_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_1_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_1_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_1_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_1_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_1_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_1_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_1_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_1_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_1_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_1_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_1_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_1_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_1_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_1_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_1_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_1_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_1_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_1_phyupd_req),
    	.ready                                 (w_1_ready)
    );
    
    HBM_interface HBM_interface_CH2 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_2_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_2_out_rst_n), // this was dfi_2_out_rst_n
		.dfi_ctrlupd_req					   (dfi_2_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_2_phyupd_ack),
		.dfi_init_complete					   (w_dfi_2_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_2_init_start),
		.dfi_aw_ck_p0            			   (dfi_2_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_2_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_2_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_2_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_2_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_2_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_2_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_2_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_2_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_2_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_2_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_2_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_2_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_2_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_2_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_2_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_2_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_2_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_2_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_2_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_2_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_2_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_2_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_2_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_2_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_2_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_2_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_2_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_2_phyupd_req),
    	.ready                                 (w_2_ready)
    );
    
    HBM_interface HBM_interface_CH3 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_3_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_3_out_rst_n), // this was dfi_3_out_rst_n
		.dfi_ctrlupd_req					   (dfi_3_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_3_phyupd_ack),
		.dfi_init_complete					   (w_dfi_3_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_3_init_start),
		.dfi_aw_ck_p0            			   (dfi_3_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_3_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_3_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_3_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_3_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_3_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_3_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_3_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_3_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_3_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_3_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_3_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_3_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_3_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_3_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_3_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_3_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_3_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_3_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_3_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_3_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_3_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_3_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_3_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_3_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_3_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_3_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_3_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_3_phyupd_req),
    	.ready                                 (w_3_ready)
    );
    
    HBM_interface HBM_interface_CH4 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_4_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_4_out_rst_n), // this was dfi_4_out_rst_n
		.dfi_ctrlupd_req					   (dfi_4_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_4_phyupd_ack),
		.dfi_init_complete					   (w_dfi_4_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_4_init_start),
		.dfi_aw_ck_p0            			   (dfi_4_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_4_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_4_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_4_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_4_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_4_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_4_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_4_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_4_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_4_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_4_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_4_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_4_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_4_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_4_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_4_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_4_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_4_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_4_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_4_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_4_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_4_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_4_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_4_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_4_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_4_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_4_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_4_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_4_phyupd_req),
    	.ready                                 (w_4_ready)
    );
    
    HBM_interface HBM_interface_CH5 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_5_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_5_out_rst_n), // this was dfi_5_out_rst_n
		.dfi_ctrlupd_req					   (dfi_5_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_5_phyupd_ack),
		.dfi_init_complete					   (w_dfi_5_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_5_init_start),
		.dfi_aw_ck_p0            			   (dfi_5_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_5_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_5_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_5_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_5_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_5_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_5_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_5_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_5_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_5_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_5_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_5_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_5_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_5_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_5_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_5_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_5_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_5_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_5_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_5_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_5_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_5_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_5_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_5_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_5_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_5_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_5_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_5_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_5_phyupd_req),
    	.ready                                 (w_5_ready)
    );
    
    HBM_interface HBM_interface_CH6 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_6_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_6_out_rst_n), // this was dfi_6_out_rst_n
		.dfi_ctrlupd_req					   (dfi_6_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_6_phyupd_ack),
		.dfi_init_complete					   (w_dfi_6_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_6_init_start),
		.dfi_aw_ck_p0            			   (dfi_6_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_6_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_6_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_6_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_6_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_6_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_6_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_6_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_6_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_6_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_6_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_6_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_6_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_6_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_6_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_6_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_6_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_6_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_6_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_6_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_6_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_6_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_6_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_6_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_6_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_6_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_6_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_6_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_6_phyupd_req),
    	.ready                                 (w_6_ready)
    );
    
    HBM_interface HBM_interface_CH7 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_7_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_7_out_rst_n), // this was dfi_7_out_rst_n
		.dfi_ctrlupd_req					   (dfi_7_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_7_phyupd_ack),
		.dfi_init_complete					   (w_dfi_7_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_7_init_start),
		.dfi_aw_ck_p0            			   (dfi_7_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_7_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_7_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_7_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_7_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_7_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_7_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_7_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_7_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_7_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_7_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_7_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_7_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_7_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_7_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_7_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_7_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_7_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_7_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_7_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_7_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_7_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_7_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_7_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_7_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_7_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_7_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_7_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_7_phyupd_req),
    	.ready                                 (w_7_ready)
    );*/
    
    HBM_interface HBM_interface_CH8 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_8_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_8_out_rst_n), // this was dfi_8_out_rst_n
		.dfi_ctrlupd_req					   (dfi_8_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_8_phyupd_ack),
		.dfi_init_complete					   (w_dfi_8_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_8_init_start),
		.dfi_aw_ck_p0            			   (dfi_8_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_8_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_8_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_8_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_8_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_8_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_8_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_8_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_8_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_8_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_8_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_8_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_8_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_8_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_8_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_8_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_8_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_8_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_8_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_8_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_8_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_8_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_8_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_8_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_8_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_8_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_8_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_8_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_8_phyupd_req),
    	.ready                                 (w_8_ready)
    );
    
    HBM_interface HBM_interface_CH9 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_9_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_9_out_rst_n), // this was dfi_9_out_rst_n
		.dfi_ctrlupd_req					   (dfi_9_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_9_phyupd_ack),
		.dfi_init_complete					   (w_dfi_9_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_9_init_start),
		.dfi_aw_ck_p0            			   (dfi_9_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_9_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_9_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_9_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_9_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_9_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_9_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_9_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_9_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_9_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_9_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_9_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_9_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_9_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_9_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_9_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_9_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_9_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_9_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_9_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_9_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_9_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_9_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_9_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_9_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_9_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_9_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_9_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_9_phyupd_req),
    	.ready                                 (w_9_ready)
    );
    
    HBM_interface HBM_interface_CH10 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_10_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_10_out_rst_n), // this was dfi_10_out_rst_n
		.dfi_ctrlupd_req					   (dfi_10_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_10_phyupd_ack),
		.dfi_init_complete					   (w_dfi_10_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_10_init_start),
		.dfi_aw_ck_p0            			   (dfi_10_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_10_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_10_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_10_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_10_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_10_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_10_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_10_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_10_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_10_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_10_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_10_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_10_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_10_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_10_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_10_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_10_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_10_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_10_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_10_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_10_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_10_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_10_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_10_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_10_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_10_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_10_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_10_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_10_phyupd_req),
    	.ready                                 (w_10_ready)
    );
    
    HBM_interface HBM_interface_CH11 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_11_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_11_out_rst_n), // this was dfi_11_out_rst_n
		.dfi_ctrlupd_req					   (dfi_11_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_11_phyupd_ack),
		.dfi_init_complete					   (w_dfi_11_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_11_init_start),
		.dfi_aw_ck_p0            			   (dfi_11_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_11_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_11_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_11_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_11_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_11_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_11_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_11_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_11_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_11_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_11_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_11_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_11_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_11_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_11_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_11_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_11_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_11_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_11_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_11_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_11_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_11_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_11_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_11_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_11_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_11_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_11_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_11_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_11_phyupd_req),
    	.ready                                 (w_11_ready)
    );
    
    HBM_interface HBM_interface_CH12 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_12_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_12_out_rst_n), // this was dfi_12_out_rst_n
		.dfi_ctrlupd_req					   (dfi_12_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_12_phyupd_ack),
		.dfi_init_complete					   (w_dfi_12_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_12_init_start),
		.dfi_aw_ck_p0            			   (dfi_12_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_12_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_12_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_12_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_12_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_12_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_12_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_12_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_12_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_12_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_12_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_12_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_12_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_12_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_12_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_12_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_12_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_12_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_12_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_12_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_12_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_12_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_12_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_12_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_12_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_12_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_12_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_12_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_12_phyupd_req),
    	.ready                                 (w_12_ready)
    );
    
    HBM_interface HBM_interface_CH13 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_13_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_13_out_rst_n), // this was dfi_13_out_rst_n
		.dfi_ctrlupd_req					   (dfi_13_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_13_phyupd_ack),
		.dfi_init_complete					   (w_dfi_13_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_13_init_start),
		.dfi_aw_ck_p0            			   (dfi_13_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_13_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_13_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_13_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_13_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_13_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_13_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_13_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_13_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_13_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_13_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_13_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_13_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_13_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_13_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_13_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_13_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_13_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_13_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_13_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_13_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_13_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_13_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_13_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_13_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_13_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_13_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_13_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_13_phyupd_req),
    	.ready                                 (w_13_ready)
    );
    
    HBM_interface HBM_interface_CH14 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_14_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_14_out_rst_n), // this was dfi_14_out_rst_n
		.dfi_ctrlupd_req					   (dfi_14_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_14_phyupd_ack),
		.dfi_init_complete					   (w_dfi_14_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_14_init_start),
		.dfi_aw_ck_p0            			   (dfi_14_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_14_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_14_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_14_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_14_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_14_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_14_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_14_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_14_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_14_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_14_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_14_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_14_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_14_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_14_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_14_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_14_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_14_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_14_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_14_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_14_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_14_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_14_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_14_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_14_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_14_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_14_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_14_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_14_phyupd_req),
    	.ready                                 (w_14_ready)
    );
    
    HBM_interface HBM_interface_CH15 (
		.row_addr					    	   (o_row_addr),
		.col_addr							   (o_col_addr),
		.ba_addr							   (o_ba_addr),
		.i_wrdata							   (o_i_wrdata),
		.cmd_type							   (w_15_cmd_type),
		.BA4								   (o_BA4),
		
		.dfi_clk							   (dfi_clk),
		.dfi_rst_n							   (dfi_rst_n),
		.dfi_rst_buf_n						   (w_dfi_15_out_rst_n), // this was dfi_15_out_rst_n
		.dfi_ctrlupd_req					   (dfi_15_ctrlupd_req),
		.dfi_phyupd_ack						   (dfi_15_phyupd_ack),
		.dfi_init_complete					   (w_dfi_15_init_complete),
		
		.apb_complete_0                        (apb_complete_0),
	  	.apb_complete_1                        (apb_complete_1),
	  	.DRAM_0_STAT_CATTRIP                   (DRAM_0_STAT_CATTRIP),
	  	.DRAM_0_STAT_TEMP                      (DRAM_0_STAT_TEMP   ),
	  	.DRAM_1_STAT_CATTRIP                   (DRAM_1_STAT_CATTRIP),
	  	.DRAM_1_STAT_TEMP                      (DRAM_1_STAT_TEMP   ),
	  	
		.dfi_init_start 					   (dfi_15_init_start),
		.dfi_aw_ck_p0            			   (dfi_15_aw_ck_p0),
		.dfi_aw_cke_p0           			   (dfi_15_aw_cke_p0),
		.dfi_aw_row_p0                         (dfi_15_aw_row_p0),
		.dfi_aw_col_p0                         (dfi_15_aw_col_p0),
		.dfi_dw_wrdata_p0              	       (dfi_15_dw_wrdata_p0),
		.dfi_dw_wrdata_mask_p0                 (dfi_15_dw_wrdata_mask_p0),
		.dfi_dw_wrdata_dbi_p0                  (dfi_15_dw_wrdata_dbi_p0),
		.dfi_dw_wrdata_par_p0                  (dfi_15_dw_wrdata_par_p0),
		.dfi_dw_wrdata_dq_en_p0                (dfi_15_dw_wrdata_dq_en_p0),
		.dfi_dw_wrdata_par_en_p0               (dfi_15_dw_wrdata_par_en_p0),
		.dfi_aw_ck_p1            			   (dfi_15_aw_ck_p1),
		.dfi_aw_cke_p1           			   (dfi_15_aw_cke_p1),
		.dfi_aw_row_p1                         (dfi_15_aw_row_p1),
		.dfi_aw_col_p1                         (dfi_15_aw_col_p1),
		.dfi_dw_wrdata_p1              	       (dfi_15_dw_wrdata_p1),
		.dfi_dw_wrdata_mask_p1                 (dfi_15_dw_wrdata_mask_p1),
		.dfi_dw_wrdata_dbi_p1                  (dfi_15_dw_wrdata_dbi_p1),
		.dfi_dw_wrdata_par_p1                  (dfi_15_dw_wrdata_par_p1),
		.dfi_dw_wrdata_dq_en_p1                (dfi_15_dw_wrdata_dq_en_p1),
		.dfi_dw_wrdata_par_en_p1               (dfi_15_dw_wrdata_par_en_p1),
		.dfi_aw_ck_dis                         (dfi_15_aw_ck_dis),
		.dfi_lp_pwr_e_req                      (dfi_15_lp_pwr_e_req),
		.dfi_lp_sr_e_req                       (dfi_15_lp_sr_e_req),
		.dfi_lp_pwr_x_e_req                    (dfi_15_lp_pwr_x_e_req),
		.dfi_aw_tx_indx_ld                     (dfi_15_aw_tx_indx_ld),
		.dfi_dw_tx_indx_ld                     (dfi_15_dw_tx_indx_ld),
		.dfi_dw_rx_indx_ld                     (dfi_15_dw_rx_indx_ld),
		.dfi_ctrlupd_ack                       (dfi_15_ctrlupd_ack),
    	.dfi_phyupd_req                        (dfi_15_phyupd_req),
    	.ready                                 (w_15_ready)
    );
    
    
    
    hbm_0 hbm_inst (
        .HBM_REF_CLK_0                 (HBM_REF_CLK_0)
	  	,.HBM_REF_CLK_1                (HBM_REF_CLK_1)
	  	

	  	/*,.dfi_0_clk                    (dfi_clk)
	  	,.dfi_0_rst_n                  (dfi_rst_n   )
	  	,.dfi_0_init_start             (dfi_0_init_start         )
	  	,.dfi_0_aw_ck_p0               (dfi_0_aw_ck_p0           )
	  	,.dfi_0_aw_cke_p0              (dfi_0_aw_cke_p0          )
	  	,.dfi_0_aw_row_p0              (dfi_0_aw_row_p0          )
	  	,.dfi_0_aw_col_p0              (dfi_0_aw_col_p0          )
	  	,.dfi_0_dw_wrdata_p0           (dfi_0_dw_wrdata_p0       )
	  	,.dfi_0_dw_wrdata_mask_p0      (dfi_0_dw_wrdata_mask_p0  )
	  	,.dfi_0_dw_wrdata_dbi_p0       (dfi_0_dw_wrdata_dbi_p0   )
	  	,.dfi_0_dw_wrdata_par_p0       (dfi_0_dw_wrdata_par_p0   )
	  	,.dfi_0_dw_wrdata_dq_en_p0     (dfi_0_dw_wrdata_dq_en_p0 )
	  	,.dfi_0_dw_wrdata_par_en_p0    (dfi_0_dw_wrdata_par_en_p0)
	  	,.dfi_0_aw_ck_p1               (dfi_0_aw_ck_p1           )
	  	,.dfi_0_aw_cke_p1              (dfi_0_aw_cke_p1          )
	  	,.dfi_0_aw_row_p1              (dfi_0_aw_row_p1          )
	  	,.dfi_0_aw_col_p1              (dfi_0_aw_col_p1          )
	  	,.dfi_0_dw_wrdata_p1           (dfi_0_dw_wrdata_p1       )
	  	,.dfi_0_dw_wrdata_mask_p1      (dfi_0_dw_wrdata_mask_p1  )
	  	,.dfi_0_dw_wrdata_dbi_p1       (dfi_0_dw_wrdata_dbi_p1   )
	  	,.dfi_0_dw_wrdata_par_p1       (dfi_0_dw_wrdata_par_p1   )
	  	,.dfi_0_dw_wrdata_dq_en_p1     (dfi_0_dw_wrdata_dq_en_p1 )
	  	,.dfi_0_dw_wrdata_par_en_p1    (dfi_0_dw_wrdata_par_en_p1)
	  	,.dfi_0_aw_ck_dis              (dfi_0_aw_ck_dis          )
	  	,.dfi_0_lp_pwr_e_req           (dfi_0_lp_pwr_e_req       )
	  	,.dfi_0_lp_sr_e_req            (dfi_0_lp_sr_e_req        )
	  	,.dfi_0_lp_pwr_x_req           (dfi_0_lp_pwr_x_e_req     )
	  	,.dfi_0_aw_tx_indx_ld          (dfi_0_aw_tx_indx_ld      )
	  	,.dfi_0_dw_tx_indx_ld          (dfi_0_dw_tx_indx_ld      )
	  	,.dfi_0_dw_rx_indx_ld          (dfi_0_dw_rx_indx_ld      )
	  	,.dfi_0_ctrlupd_ack            (dfi_0_ctrlupd_ack        )
	  	,.dfi_0_phyupd_req             (dfi_0_phyupd_req         )
	  	,.dfi_0_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_0_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_0_dw_rddata_p0           (w_dfi_0_dw_rddata_p0    )
	  	,.dfi_0_dw_rddata_dm_p0        (dfi_0_dw_rddata_dm_p0 )
	  	,.dfi_0_dw_rddata_dbi_p0       (dfi_0_dw_rddata_dbi_p0)
	  	,.dfi_0_dw_rddata_par_p0       (dfi_0_dw_rddata_par_p0)
	  	,.dfi_0_dw_rddata_p1           (w_dfi_0_dw_rddata_p1    )
	  	,.dfi_0_dw_rddata_dm_p1        (dfi_0_dw_rddata_dm_p1 )
	  	,.dfi_0_dw_rddata_dbi_p1       (dfi_0_dw_rddata_dbi_p1)
	  	,.dfi_0_dw_rddata_par_p1       (dfi_0_dw_rddata_par_p1)
	  	,.dfi_0_dbi_byte_disable       ( *//* Not Connected *//*  )
	  	,.dfi_0_dw_rddata_valid        (w_dfi_0_dw_rddata_valid)
	  	,.dfi_0_dw_derr_n              ( *//* Not Connected *//*  )
	  	,.dfi_0_aw_aerr_n              ( *//* Not Connected *//*  )
	  	,.dfi_0_ctrlupd_req            (dfi_0_ctrlupd_req)
	  	,.dfi_0_phyupd_ack             (dfi_0_phyupd_ack )
	  	,.dfi_0_clk_init               ( *//* Not Connected *//*  )
	  	,.dfi_0_init_complete          (w_dfi_0_init_complete)
	  	,.dfi_0_out_rst_n              (w_dfi_0_out_rst_n    )


	  	,.dfi_1_clk                    (dfi_clk)
	  	,.dfi_1_rst_n                  (dfi_rst_n   )
	  	,.dfi_1_init_start             (dfi_1_init_start         )
	  	,.dfi_1_aw_ck_p0               (dfi_1_aw_ck_p0           )
	  	,.dfi_1_aw_cke_p0              (dfi_1_aw_cke_p0          )
	  	,.dfi_1_aw_row_p0              (dfi_1_aw_row_p0          )
	  	,.dfi_1_aw_col_p0              (dfi_1_aw_col_p0          )
	  	,.dfi_1_dw_wrdata_p0           (dfi_1_dw_wrdata_p0       )
	  	,.dfi_1_dw_wrdata_mask_p0      (dfi_1_dw_wrdata_mask_p0  )
	  	,.dfi_1_dw_wrdata_dbi_p0       (dfi_1_dw_wrdata_dbi_p0   )
	  	,.dfi_1_dw_wrdata_par_p0       (dfi_1_dw_wrdata_par_p0   )
	  	,.dfi_1_dw_wrdata_dq_en_p0     (dfi_1_dw_wrdata_dq_en_p0 )
	  	,.dfi_1_dw_wrdata_par_en_p0    (dfi_1_dw_wrdata_par_en_p0)
	  	,.dfi_1_aw_ck_p1               (dfi_1_aw_ck_p1           )
	  	,.dfi_1_aw_cke_p1              (dfi_1_aw_cke_p1          )
	  	,.dfi_1_aw_row_p1              (dfi_1_aw_row_p1          )
	  	,.dfi_1_aw_col_p1              (dfi_1_aw_col_p1          )
	  	,.dfi_1_dw_wrdata_p1           (dfi_1_dw_wrdata_p1       )
	  	,.dfi_1_dw_wrdata_mask_p1      (dfi_1_dw_wrdata_mask_p1  )
	  	,.dfi_1_dw_wrdata_dbi_p1       (dfi_1_dw_wrdata_dbi_p1   )
	  	,.dfi_1_dw_wrdata_par_p1       (dfi_1_dw_wrdata_par_p1   )
	  	,.dfi_1_dw_wrdata_dq_en_p1     (dfi_1_dw_wrdata_dq_en_p1 )
	  	,.dfi_1_dw_wrdata_par_en_p1    (dfi_1_dw_wrdata_par_en_p1)
	  	,.dfi_1_aw_ck_dis              (dfi_1_aw_ck_dis          )
	  	,.dfi_1_lp_pwr_e_req           (dfi_1_lp_pwr_e_req       )
	  	,.dfi_1_lp_sr_e_req            (dfi_1_lp_sr_e_req        )
	  	,.dfi_1_lp_pwr_x_req           (dfi_1_lp_pwr_x_e_req     )
	  	,.dfi_1_aw_tx_indx_ld          (dfi_1_aw_tx_indx_ld      )
	  	,.dfi_1_dw_tx_indx_ld          (dfi_1_dw_tx_indx_ld      )
	  	,.dfi_1_dw_rx_indx_ld          (dfi_1_dw_rx_indx_ld      )
	  	,.dfi_1_ctrlupd_ack            (dfi_1_ctrlupd_ack        )
	  	,.dfi_1_phyupd_req             (dfi_1_phyupd_req         )
	  	,.dfi_1_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_1_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_1_dw_rddata_p0           (w_dfi_1_dw_rddata_p0    )
	  	,.dfi_1_dw_rddata_dm_p0        (dfi_1_dw_rddata_dm_p0 )
	  	,.dfi_1_dw_rddata_dbi_p0       (dfi_1_dw_rddata_dbi_p0)
	  	,.dfi_1_dw_rddata_par_p0       (dfi_1_dw_rddata_par_p0)
	  	,.dfi_1_dw_rddata_p1           (w_dfi_1_dw_rddata_p1    )
	  	,.dfi_1_dw_rddata_dm_p1        (dfi_1_dw_rddata_dm_p1 )
	  	,.dfi_1_dw_rddata_dbi_p1       (dfi_1_dw_rddata_dbi_p1)
	  	,.dfi_1_dw_rddata_par_p1       (dfi_1_dw_rddata_par_p1)
	  	,.dfi_1_dbi_byte_disable       ( *//* Not Connected *//*  )
	  	,.dfi_1_dw_rddata_valid        (w_dfi_1_dw_rddata_valid)
	  	,.dfi_1_dw_derr_n              ( *//* Not Connected *//*  )
	  	,.dfi_1_aw_aerr_n              ( *//* Not Connected *//*  )
	  	,.dfi_1_ctrlupd_req            (dfi_1_ctrlupd_req)
	  	,.dfi_1_phyupd_ack             (dfi_1_phyupd_ack )
	  	,.dfi_1_clk_init               ( *//* Not Connected *//*  )
	  	,.dfi_1_init_complete          (w_dfi_1_init_complete)
	  	,.dfi_1_out_rst_n              (w_dfi_1_out_rst_n    )
	  	

	  	,.dfi_2_clk                    (dfi_clk)
	  	,.dfi_2_rst_n                  (dfi_rst_n   )
	  	,.dfi_2_init_start             (dfi_2_init_start         )
	  	,.dfi_2_aw_ck_p0               (dfi_2_aw_ck_p0           )
	  	,.dfi_2_aw_cke_p0              (dfi_2_aw_cke_p0          )
	  	,.dfi_2_aw_row_p0              (dfi_2_aw_row_p0          )
	  	,.dfi_2_aw_col_p0              (dfi_2_aw_col_p0          )
	  	,.dfi_2_dw_wrdata_p0           (dfi_2_dw_wrdata_p0       )
	  	,.dfi_2_dw_wrdata_mask_p0      (dfi_2_dw_wrdata_mask_p0  )
	  	,.dfi_2_dw_wrdata_dbi_p0       (dfi_2_dw_wrdata_dbi_p0   )
	  	,.dfi_2_dw_wrdata_par_p0       (dfi_2_dw_wrdata_par_p0   )
	  	,.dfi_2_dw_wrdata_dq_en_p0     (dfi_2_dw_wrdata_dq_en_p0 )
	  	,.dfi_2_dw_wrdata_par_en_p0    (dfi_2_dw_wrdata_par_en_p0)
	  	,.dfi_2_aw_ck_p1               (dfi_2_aw_ck_p1           )
	  	,.dfi_2_aw_cke_p1              (dfi_2_aw_cke_p1          )
	  	,.dfi_2_aw_row_p1              (dfi_2_aw_row_p1          )
	  	,.dfi_2_aw_col_p1              (dfi_2_aw_col_p1          )
	  	,.dfi_2_dw_wrdata_p1           (dfi_2_dw_wrdata_p1       )
	  	,.dfi_2_dw_wrdata_mask_p1      (dfi_2_dw_wrdata_mask_p1  )
	  	,.dfi_2_dw_wrdata_dbi_p1       (dfi_2_dw_wrdata_dbi_p1   )
	  	,.dfi_2_dw_wrdata_par_p1       (dfi_2_dw_wrdata_par_p1   )
	  	,.dfi_2_dw_wrdata_dq_en_p1     (dfi_2_dw_wrdata_dq_en_p1 )
	  	,.dfi_2_dw_wrdata_par_en_p1    (dfi_2_dw_wrdata_par_en_p1)
	  	,.dfi_2_aw_ck_dis              (dfi_2_aw_ck_dis          )
	  	,.dfi_2_lp_pwr_e_req           (dfi_2_lp_pwr_e_req       )
	  	,.dfi_2_lp_sr_e_req            (dfi_2_lp_sr_e_req        )
	  	,.dfi_2_lp_pwr_x_req           (dfi_2_lp_pwr_x_e_req     )
	  	,.dfi_2_aw_tx_indx_ld          (dfi_2_aw_tx_indx_ld      )
	  	,.dfi_2_dw_tx_indx_ld          (dfi_2_dw_tx_indx_ld      )
	  	,.dfi_2_dw_rx_indx_ld          (dfi_2_dw_rx_indx_ld      )
	  	,.dfi_2_ctrlupd_ack            (dfi_2_ctrlupd_ack        )
	  	,.dfi_2_phyupd_req             (dfi_2_phyupd_req         )
	  	,.dfi_2_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_2_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_2_dw_rddata_p0           (w_dfi_2_dw_rddata_p0    )
	  	,.dfi_2_dw_rddata_dm_p0        (dfi_2_dw_rddata_dm_p0 )
	  	,.dfi_2_dw_rddata_dbi_p0       (dfi_2_dw_rddata_dbi_p0)
	  	,.dfi_2_dw_rddata_par_p0       (dfi_2_dw_rddata_par_p0)
	  	,.dfi_2_dw_rddata_p1           (w_dfi_2_dw_rddata_p1    )
	  	,.dfi_2_dw_rddata_dm_p1        (dfi_2_dw_rddata_dm_p1 )
	  	,.dfi_2_dw_rddata_dbi_p1       (dfi_2_dw_rddata_dbi_p1)
	  	,.dfi_2_dw_rddata_par_p1       (dfi_2_dw_rddata_par_p1)
	  	,.dfi_2_dbi_byte_disable       ( *//* Not Connected *//*  )
	  	,.dfi_2_dw_rddata_valid        (w_dfi_2_dw_rddata_valid)
	  	,.dfi_2_dw_derr_n              ( *//* Not Connected *//*  )
	  	,.dfi_2_aw_aerr_n              ( *//* Not Connected *//*  )
	  	,.dfi_2_ctrlupd_req            (dfi_2_ctrlupd_req)
	  	,.dfi_2_phyupd_ack             (dfi_2_phyupd_ack )
	  	,.dfi_2_clk_init               ( *//* Not Connected *//*  )
	  	,.dfi_2_init_complete          (w_dfi_2_init_complete)
	  	,.dfi_2_out_rst_n              (w_dfi_2_out_rst_n    )
	  	

	  	,.dfi_3_clk                    (dfi_clk)
	  	,.dfi_3_rst_n                  (dfi_rst_n   )
	  	,.dfi_3_init_start             (dfi_3_init_start         )
	  	,.dfi_3_aw_ck_p0               (dfi_3_aw_ck_p0           )
	  	,.dfi_3_aw_cke_p0              (dfi_3_aw_cke_p0          )
	  	,.dfi_3_aw_row_p0              (dfi_3_aw_row_p0          )
	  	,.dfi_3_aw_col_p0              (dfi_3_aw_col_p0          )
	  	,.dfi_3_dw_wrdata_p0           (dfi_3_dw_wrdata_p0       )
	  	,.dfi_3_dw_wrdata_mask_p0      (dfi_3_dw_wrdata_mask_p0  )
	  	,.dfi_3_dw_wrdata_dbi_p0       (dfi_3_dw_wrdata_dbi_p0   )
	  	,.dfi_3_dw_wrdata_par_p0       (dfi_3_dw_wrdata_par_p0   )
	  	,.dfi_3_dw_wrdata_dq_en_p0     (dfi_3_dw_wrdata_dq_en_p0 )
	  	,.dfi_3_dw_wrdata_par_en_p0    (dfi_3_dw_wrdata_par_en_p0)
	  	,.dfi_3_aw_ck_p1               (dfi_3_aw_ck_p1           )
	  	,.dfi_3_aw_cke_p1              (dfi_3_aw_cke_p1          )
	  	,.dfi_3_aw_row_p1              (dfi_3_aw_row_p1          )
	  	,.dfi_3_aw_col_p1              (dfi_3_aw_col_p1          )
	  	,.dfi_3_dw_wrdata_p1           (dfi_3_dw_wrdata_p1       )
	  	,.dfi_3_dw_wrdata_mask_p1      (dfi_3_dw_wrdata_mask_p1  )
	  	,.dfi_3_dw_wrdata_dbi_p1       (dfi_3_dw_wrdata_dbi_p1   )
	  	,.dfi_3_dw_wrdata_par_p1       (dfi_3_dw_wrdata_par_p1   )
	  	,.dfi_3_dw_wrdata_dq_en_p1     (dfi_3_dw_wrdata_dq_en_p1 )
	  	,.dfi_3_dw_wrdata_par_en_p1    (dfi_3_dw_wrdata_par_en_p1)
	  	,.dfi_3_aw_ck_dis              (dfi_3_aw_ck_dis          )
	  	,.dfi_3_lp_pwr_e_req           (dfi_3_lp_pwr_e_req       )
	  	,.dfi_3_lp_sr_e_req            (dfi_3_lp_sr_e_req        )
	  	,.dfi_3_lp_pwr_x_req           (dfi_3_lp_pwr_x_e_req     )
	  	,.dfi_3_aw_tx_indx_ld          (dfi_3_aw_tx_indx_ld      )
	  	,.dfi_3_dw_tx_indx_ld          (dfi_3_dw_tx_indx_ld      )
	  	,.dfi_3_dw_rx_indx_ld          (dfi_3_dw_rx_indx_ld      )
	  	,.dfi_3_ctrlupd_ack            (dfi_3_ctrlupd_ack        )
	  	,.dfi_3_phyupd_req             (dfi_3_phyupd_req         )
	  	,.dfi_3_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_3_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_3_dw_rddata_p0           (w_dfi_3_dw_rddata_p0    )
	  	,.dfi_3_dw_rddata_dm_p0        (dfi_3_dw_rddata_dm_p0 )
	  	,.dfi_3_dw_rddata_dbi_p0       (dfi_3_dw_rddata_dbi_p0)
	  	,.dfi_3_dw_rddata_par_p0       (dfi_3_dw_rddata_par_p0)
	  	,.dfi_3_dw_rddata_p1           (w_dfi_3_dw_rddata_p1    )
	  	,.dfi_3_dw_rddata_dm_p1        (dfi_3_dw_rddata_dm_p1 )
	  	,.dfi_3_dw_rddata_dbi_p1       (dfi_3_dw_rddata_dbi_p1)
	  	,.dfi_3_dw_rddata_par_p1       (dfi_3_dw_rddata_par_p1)
	  	,.dfi_3_dbi_byte_disable       ( *//* Not Connected *//*  )
	  	,.dfi_3_dw_rddata_valid        (w_dfi_3_dw_rddata_valid)
	  	,.dfi_3_dw_derr_n              ( *//* Not Connected *//*  )
	  	,.dfi_3_aw_aerr_n              ( *//* Not Connected *//*  )
	  	,.dfi_3_ctrlupd_req            (dfi_3_ctrlupd_req)
	  	,.dfi_3_phyupd_ack             (dfi_3_phyupd_ack )
	  	,.dfi_3_clk_init               ( *//* Not Connected *//*  )
	  	,.dfi_3_init_complete          (w_dfi_3_init_complete)
	  	,.dfi_3_out_rst_n              (w_dfi_3_out_rst_n    )
	  	

	  	,.dfi_4_clk                    (dfi_clk)
	  	,.dfi_4_rst_n                  (dfi_rst_n   )
	  	,.dfi_4_init_start             (dfi_4_init_start         )
	  	,.dfi_4_aw_ck_p0               (dfi_4_aw_ck_p0           )
	  	,.dfi_4_aw_cke_p0              (dfi_4_aw_cke_p0          )
	  	,.dfi_4_aw_row_p0              (dfi_4_aw_row_p0          )
	  	,.dfi_4_aw_col_p0              (dfi_4_aw_col_p0          )
	  	,.dfi_4_dw_wrdata_p0           (dfi_4_dw_wrdata_p0       )
	  	,.dfi_4_dw_wrdata_mask_p0      (dfi_4_dw_wrdata_mask_p0  )
	  	,.dfi_4_dw_wrdata_dbi_p0       (dfi_4_dw_wrdata_dbi_p0   )
	  	,.dfi_4_dw_wrdata_par_p0       (dfi_4_dw_wrdata_par_p0   )
	  	,.dfi_4_dw_wrdata_dq_en_p0     (dfi_4_dw_wrdata_dq_en_p0 )
	  	,.dfi_4_dw_wrdata_par_en_p0    (dfi_4_dw_wrdata_par_en_p0)
	  	,.dfi_4_aw_ck_p1               (dfi_4_aw_ck_p1           )
	  	,.dfi_4_aw_cke_p1              (dfi_4_aw_cke_p1          )
	  	,.dfi_4_aw_row_p1              (dfi_4_aw_row_p1          )
	  	,.dfi_4_aw_col_p1              (dfi_4_aw_col_p1          )
	  	,.dfi_4_dw_wrdata_p1           (dfi_4_dw_wrdata_p1       )
	  	,.dfi_4_dw_wrdata_mask_p1      (dfi_4_dw_wrdata_mask_p1  )
	  	,.dfi_4_dw_wrdata_dbi_p1       (dfi_4_dw_wrdata_dbi_p1   )
	  	,.dfi_4_dw_wrdata_par_p1       (dfi_4_dw_wrdata_par_p1   )
	  	,.dfi_4_dw_wrdata_dq_en_p1     (dfi_4_dw_wrdata_dq_en_p1 )
	  	,.dfi_4_dw_wrdata_par_en_p1    (dfi_4_dw_wrdata_par_en_p1)
	  	,.dfi_4_aw_ck_dis              (dfi_4_aw_ck_dis          )
	  	,.dfi_4_lp_pwr_e_req           (dfi_4_lp_pwr_e_req       )
	  	,.dfi_4_lp_sr_e_req            (dfi_4_lp_sr_e_req        )
	  	,.dfi_4_lp_pwr_x_req           (dfi_4_lp_pwr_x_e_req     )
	  	,.dfi_4_aw_tx_indx_ld          (dfi_4_aw_tx_indx_ld      )
	  	,.dfi_4_dw_tx_indx_ld          (dfi_4_dw_tx_indx_ld      )
	  	,.dfi_4_dw_rx_indx_ld          (dfi_4_dw_rx_indx_ld      )
	  	,.dfi_4_ctrlupd_ack            (dfi_4_ctrlupd_ack        )
	  	,.dfi_4_phyupd_req             (dfi_4_phyupd_req         )
	  	,.dfi_4_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_4_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_4_dw_rddata_p0           (w_dfi_4_dw_rddata_p0    )
	  	,.dfi_4_dw_rddata_dm_p0        (dfi_4_dw_rddata_dm_p0 )
	  	,.dfi_4_dw_rddata_dbi_p0       (dfi_4_dw_rddata_dbi_p0)
	  	,.dfi_4_dw_rddata_par_p0       (dfi_4_dw_rddata_par_p0)
	  	,.dfi_4_dw_rddata_p1           (w_dfi_4_dw_rddata_p1    )
	  	,.dfi_4_dw_rddata_dm_p1        (dfi_4_dw_rddata_dm_p1 )
	  	,.dfi_4_dw_rddata_dbi_p1       (dfi_4_dw_rddata_dbi_p1)
	  	,.dfi_4_dw_rddata_par_p1       (dfi_4_dw_rddata_par_p1)
	  	,.dfi_4_dbi_byte_disable       ( *//* Not Connected *//*  )
	  	,.dfi_4_dw_rddata_valid        (w_dfi_4_dw_rddata_valid)
	  	,.dfi_4_dw_derr_n              ( *//* Not Connected *//*  )
	  	,.dfi_4_aw_aerr_n              ( *//* Not Connected *//*  )
	  	,.dfi_4_ctrlupd_req            (dfi_4_ctrlupd_req)
	  	,.dfi_4_phyupd_ack             (dfi_4_phyupd_ack )
	  	,.dfi_4_clk_init               ( *//* Not Connected *//*  )
	  	,.dfi_4_init_complete          (w_dfi_4_init_complete)
	  	,.dfi_4_out_rst_n              (w_dfi_4_out_rst_n    )
	  	

	  	,.dfi_5_clk                    (dfi_clk)
	  	,.dfi_5_rst_n                  (dfi_rst_n   )
	  	,.dfi_5_init_start             (dfi_5_init_start         )
	  	,.dfi_5_aw_ck_p0               (dfi_5_aw_ck_p0           )
	  	,.dfi_5_aw_cke_p0              (dfi_5_aw_cke_p0          )
	  	,.dfi_5_aw_row_p0              (dfi_5_aw_row_p0          )
	  	,.dfi_5_aw_col_p0              (dfi_5_aw_col_p0          )
	  	,.dfi_5_dw_wrdata_p0           (dfi_5_dw_wrdata_p0       )
	  	,.dfi_5_dw_wrdata_mask_p0      (dfi_5_dw_wrdata_mask_p0  )
	  	,.dfi_5_dw_wrdata_dbi_p0       (dfi_5_dw_wrdata_dbi_p0   )
	  	,.dfi_5_dw_wrdata_par_p0       (dfi_5_dw_wrdata_par_p0   )
	  	,.dfi_5_dw_wrdata_dq_en_p0     (dfi_5_dw_wrdata_dq_en_p0 )
	  	,.dfi_5_dw_wrdata_par_en_p0    (dfi_5_dw_wrdata_par_en_p0)
	  	,.dfi_5_aw_ck_p1               (dfi_5_aw_ck_p1           )
	  	,.dfi_5_aw_cke_p1              (dfi_5_aw_cke_p1          )
	  	,.dfi_5_aw_row_p1              (dfi_5_aw_row_p1          )
	  	,.dfi_5_aw_col_p1              (dfi_5_aw_col_p1          )
	  	,.dfi_5_dw_wrdata_p1           (dfi_5_dw_wrdata_p1       )
	  	,.dfi_5_dw_wrdata_mask_p1      (dfi_5_dw_wrdata_mask_p1  )
	  	,.dfi_5_dw_wrdata_dbi_p1       (dfi_5_dw_wrdata_dbi_p1   )
	  	,.dfi_5_dw_wrdata_par_p1       (dfi_5_dw_wrdata_par_p1   )
	  	,.dfi_5_dw_wrdata_dq_en_p1     (dfi_5_dw_wrdata_dq_en_p1 )
	  	,.dfi_5_dw_wrdata_par_en_p1    (dfi_5_dw_wrdata_par_en_p1)
	  	,.dfi_5_aw_ck_dis              (dfi_5_aw_ck_dis          )
	  	,.dfi_5_lp_pwr_e_req           (dfi_5_lp_pwr_e_req       )
	  	,.dfi_5_lp_sr_e_req            (dfi_5_lp_sr_e_req        )
	  	,.dfi_5_lp_pwr_x_req           (dfi_5_lp_pwr_x_e_req     )
	  	,.dfi_5_aw_tx_indx_ld          (dfi_5_aw_tx_indx_ld      )
	  	,.dfi_5_dw_tx_indx_ld          (dfi_5_dw_tx_indx_ld      )
	  	,.dfi_5_dw_rx_indx_ld          (dfi_5_dw_rx_indx_ld      )
	  	,.dfi_5_ctrlupd_ack            (dfi_5_ctrlupd_ack        )
	  	,.dfi_5_phyupd_req             (dfi_5_phyupd_req         )
	  	,.dfi_5_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_5_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_5_dw_rddata_p0           (w_dfi_5_dw_rddata_p0    )
	  	,.dfi_5_dw_rddata_dm_p0        (dfi_5_dw_rddata_dm_p0 )
	  	,.dfi_5_dw_rddata_dbi_p0       (dfi_5_dw_rddata_dbi_p0)
	  	,.dfi_5_dw_rddata_par_p0       (dfi_5_dw_rddata_par_p0)
	  	,.dfi_5_dw_rddata_p1           (w_dfi_5_dw_rddata_p1    )
	  	,.dfi_5_dw_rddata_dm_p1        (dfi_5_dw_rddata_dm_p1 )
	  	,.dfi_5_dw_rddata_dbi_p1       (dfi_5_dw_rddata_dbi_p1)
	  	,.dfi_5_dw_rddata_par_p1       (dfi_5_dw_rddata_par_p1)
	  	,.dfi_5_dbi_byte_disable       ( *//* Not Connected *//*  )
	  	,.dfi_5_dw_rddata_valid        (w_dfi_5_dw_rddata_valid)
	  	,.dfi_5_dw_derr_n              ( *//* Not Connected *//*  )
	  	,.dfi_5_aw_aerr_n              ( *//* Not Connected *//*  )
	  	,.dfi_5_ctrlupd_req            (dfi_5_ctrlupd_req)
	  	,.dfi_5_phyupd_ack             (dfi_5_phyupd_ack )
	  	,.dfi_5_clk_init               ( *//* Not Connected *//*  )
	  	,.dfi_5_init_complete          (w_dfi_5_init_complete)
	  	,.dfi_5_out_rst_n              (w_dfi_5_out_rst_n    )
	  	

	  	,.dfi_6_clk                    (dfi_clk)
	  	,.dfi_6_rst_n                  (dfi_rst_n   )
	  	,.dfi_6_init_start             (dfi_6_init_start         )
	  	,.dfi_6_aw_ck_p0               (dfi_6_aw_ck_p0           )
	  	,.dfi_6_aw_cke_p0              (dfi_6_aw_cke_p0          )
	  	,.dfi_6_aw_row_p0              (dfi_6_aw_row_p0          )
	  	,.dfi_6_aw_col_p0              (dfi_6_aw_col_p0          )
	  	,.dfi_6_dw_wrdata_p0           (dfi_6_dw_wrdata_p0       )
	  	,.dfi_6_dw_wrdata_mask_p0      (dfi_6_dw_wrdata_mask_p0  )
	  	,.dfi_6_dw_wrdata_dbi_p0       (dfi_6_dw_wrdata_dbi_p0   )
	  	,.dfi_6_dw_wrdata_par_p0       (dfi_6_dw_wrdata_par_p0   )
	  	,.dfi_6_dw_wrdata_dq_en_p0     (dfi_6_dw_wrdata_dq_en_p0 )
	  	,.dfi_6_dw_wrdata_par_en_p0    (dfi_6_dw_wrdata_par_en_p0)
	  	,.dfi_6_aw_ck_p1               (dfi_6_aw_ck_p1           )
	  	,.dfi_6_aw_cke_p1              (dfi_6_aw_cke_p1          )
	  	,.dfi_6_aw_row_p1              (dfi_6_aw_row_p1          )
	  	,.dfi_6_aw_col_p1              (dfi_6_aw_col_p1          )
	  	,.dfi_6_dw_wrdata_p1           (dfi_6_dw_wrdata_p1       )
	  	,.dfi_6_dw_wrdata_mask_p1      (dfi_6_dw_wrdata_mask_p1  )
	  	,.dfi_6_dw_wrdata_dbi_p1       (dfi_6_dw_wrdata_dbi_p1   )
	  	,.dfi_6_dw_wrdata_par_p1       (dfi_6_dw_wrdata_par_p1   )
	  	,.dfi_6_dw_wrdata_dq_en_p1     (dfi_6_dw_wrdata_dq_en_p1 )
	  	,.dfi_6_dw_wrdata_par_en_p1    (dfi_6_dw_wrdata_par_en_p1)
	  	,.dfi_6_aw_ck_dis              (dfi_6_aw_ck_dis          )
	  	,.dfi_6_lp_pwr_e_req           (dfi_6_lp_pwr_e_req       )
	  	,.dfi_6_lp_sr_e_req            (dfi_6_lp_sr_e_req        )
	  	,.dfi_6_lp_pwr_x_req           (dfi_6_lp_pwr_x_e_req     )
	  	,.dfi_6_aw_tx_indx_ld          (dfi_6_aw_tx_indx_ld      )
	  	,.dfi_6_dw_tx_indx_ld          (dfi_6_dw_tx_indx_ld      )
	  	,.dfi_6_dw_rx_indx_ld          (dfi_6_dw_rx_indx_ld      )
	  	,.dfi_6_ctrlupd_ack            (dfi_6_ctrlupd_ack        )
	  	,.dfi_6_phyupd_req             (dfi_6_phyupd_req         )
	  	,.dfi_6_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_6_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_6_dw_rddata_p0           (w_dfi_6_dw_rddata_p0    )
	  	,.dfi_6_dw_rddata_dm_p0        (dfi_6_dw_rddata_dm_p0 )
	  	,.dfi_6_dw_rddata_dbi_p0       (dfi_6_dw_rddata_dbi_p0)
	  	,.dfi_6_dw_rddata_par_p0       (dfi_6_dw_rddata_par_p0)
	  	,.dfi_6_dw_rddata_p1           (w_dfi_6_dw_rddata_p1    )
	  	,.dfi_6_dw_rddata_dm_p1        (dfi_6_dw_rddata_dm_p1 )
	  	,.dfi_6_dw_rddata_dbi_p1       (dfi_6_dw_rddata_dbi_p1)
	  	,.dfi_6_dw_rddata_par_p1       (dfi_6_dw_rddata_par_p1)
	  	,.dfi_6_dbi_byte_disable       ( *//* Not Connected *//*  )
	  	,.dfi_6_dw_rddata_valid        (w_dfi_6_dw_rddata_valid)
	  	,.dfi_6_dw_derr_n              ( *//* Not Connected *//*  )
	  	,.dfi_6_aw_aerr_n              ( *//* Not Connected *//*  )
	  	,.dfi_6_ctrlupd_req            (dfi_6_ctrlupd_req)
	  	,.dfi_6_phyupd_ack             (dfi_6_phyupd_ack )
	  	,.dfi_6_clk_init               ( *//* Not Connected *//*  )
	  	,.dfi_6_init_complete          (w_dfi_6_init_complete)
	  	,.dfi_6_out_rst_n              (w_dfi_6_out_rst_n    )
	  	

	  	,.dfi_7_clk                    (dfi_clk)
	  	,.dfi_7_rst_n                  (dfi_rst_n   )
	  	,.dfi_7_init_start             (dfi_7_init_start         )
	  	,.dfi_7_aw_ck_p0               (dfi_7_aw_ck_p0           )
	  	,.dfi_7_aw_cke_p0              (dfi_7_aw_cke_p0          )
	  	,.dfi_7_aw_row_p0              (dfi_7_aw_row_p0          )
	  	,.dfi_7_aw_col_p0              (dfi_7_aw_col_p0          )
	  	,.dfi_7_dw_wrdata_p0           (dfi_7_dw_wrdata_p0       )
	  	,.dfi_7_dw_wrdata_mask_p0      (dfi_7_dw_wrdata_mask_p0  )
	  	,.dfi_7_dw_wrdata_dbi_p0       (dfi_7_dw_wrdata_dbi_p0   )
	  	,.dfi_7_dw_wrdata_par_p0       (dfi_7_dw_wrdata_par_p0   )
	  	,.dfi_7_dw_wrdata_dq_en_p0     (dfi_7_dw_wrdata_dq_en_p0 )
	  	,.dfi_7_dw_wrdata_par_en_p0    (dfi_7_dw_wrdata_par_en_p0)
	  	,.dfi_7_aw_ck_p1               (dfi_7_aw_ck_p1           )
	  	,.dfi_7_aw_cke_p1              (dfi_7_aw_cke_p1          )
	  	,.dfi_7_aw_row_p1              (dfi_7_aw_row_p1          )
	  	,.dfi_7_aw_col_p1              (dfi_7_aw_col_p1          )
	  	,.dfi_7_dw_wrdata_p1           (dfi_7_dw_wrdata_p1       )
	  	,.dfi_7_dw_wrdata_mask_p1      (dfi_7_dw_wrdata_mask_p1  )
	  	,.dfi_7_dw_wrdata_dbi_p1       (dfi_7_dw_wrdata_dbi_p1   )
	  	,.dfi_7_dw_wrdata_par_p1       (dfi_7_dw_wrdata_par_p1   )
	  	,.dfi_7_dw_wrdata_dq_en_p1     (dfi_7_dw_wrdata_dq_en_p1 )
	  	,.dfi_7_dw_wrdata_par_en_p1    (dfi_7_dw_wrdata_par_en_p1)
	  	,.dfi_7_aw_ck_dis              (dfi_7_aw_ck_dis          )
	  	,.dfi_7_lp_pwr_e_req           (dfi_7_lp_pwr_e_req       )
	  	,.dfi_7_lp_sr_e_req            (dfi_7_lp_sr_e_req        )
	  	,.dfi_7_lp_pwr_x_req           (dfi_7_lp_pwr_x_e_req     )
	  	,.dfi_7_aw_tx_indx_ld          (dfi_7_aw_tx_indx_ld      )
	  	,.dfi_7_dw_tx_indx_ld          (dfi_7_dw_tx_indx_ld      )
	  	,.dfi_7_dw_rx_indx_ld          (dfi_7_dw_rx_indx_ld      )
	  	,.dfi_7_ctrlupd_ack            (dfi_7_ctrlupd_ack        )
	  	,.dfi_7_phyupd_req             (dfi_7_phyupd_req         )
	  	,.dfi_7_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_7_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_7_dw_rddata_p0           (w_dfi_7_dw_rddata_p0    )
	  	,.dfi_7_dw_rddata_dm_p0        (dfi_7_dw_rddata_dm_p0 )
	  	,.dfi_7_dw_rddata_dbi_p0       (dfi_7_dw_rddata_dbi_p0)
	  	,.dfi_7_dw_rddata_par_p0       (dfi_7_dw_rddata_par_p0)
	  	,.dfi_7_dw_rddata_p1           (w_dfi_7_dw_rddata_p1    )
	  	,.dfi_7_dw_rddata_dm_p1        (dfi_7_dw_rddata_dm_p1 )
	  	,.dfi_7_dw_rddata_dbi_p1       (dfi_7_dw_rddata_dbi_p1)
	  	,.dfi_7_dw_rddata_par_p1       (dfi_7_dw_rddata_par_p1)
	  	,.dfi_7_dbi_byte_disable       ( *//* Not Connected *//*  )
	  	,.dfi_7_dw_rddata_valid        (w_dfi_7_dw_rddata_valid)
	  	,.dfi_7_dw_derr_n              ( *//* Not Connected *//*  )
	  	,.dfi_7_aw_aerr_n              ( *//* Not Connected *//*  )
	  	,.dfi_7_ctrlupd_req            (dfi_7_ctrlupd_req)
	  	,.dfi_7_phyupd_ack             (dfi_7_phyupd_ack )
	  	,.dfi_7_clk_init               ( *//* Not Connected *//*  )
	  	,.dfi_7_init_complete          (w_dfi_7_init_complete)
	  	,.dfi_7_out_rst_n              (w_dfi_7_out_rst_n    )*/
	  	

	  	,.dfi_8_clk                    (dfi_clk)
	  	,.dfi_8_rst_n                  (dfi_rst_n   )
	  	,.dfi_8_init_start             (dfi_8_init_start         )
	  	,.dfi_8_aw_ck_p0               (dfi_8_aw_ck_p0           )
	  	,.dfi_8_aw_cke_p0              (dfi_8_aw_cke_p0          )
	  	,.dfi_8_aw_row_p0              (dfi_8_aw_row_p0          )
	  	,.dfi_8_aw_col_p0              (dfi_8_aw_col_p0          )
	  	,.dfi_8_dw_wrdata_p0           (dfi_8_dw_wrdata_p0       )
	  	,.dfi_8_dw_wrdata_mask_p0      (dfi_8_dw_wrdata_mask_p0  )
	  	,.dfi_8_dw_wrdata_dbi_p0       (dfi_8_dw_wrdata_dbi_p0   )
	  	,.dfi_8_dw_wrdata_par_p0       (dfi_8_dw_wrdata_par_p0   )
	  	,.dfi_8_dw_wrdata_dq_en_p0     (dfi_8_dw_wrdata_dq_en_p0 )
	  	,.dfi_8_dw_wrdata_par_en_p0    (dfi_8_dw_wrdata_par_en_p0)
	  	,.dfi_8_aw_ck_p1               (dfi_8_aw_ck_p1           )
	  	,.dfi_8_aw_cke_p1              (dfi_8_aw_cke_p1          )
	  	,.dfi_8_aw_row_p1              (dfi_8_aw_row_p1          )
	  	,.dfi_8_aw_col_p1              (dfi_8_aw_col_p1          )
	  	,.dfi_8_dw_wrdata_p1           (dfi_8_dw_wrdata_p1       )
	  	,.dfi_8_dw_wrdata_mask_p1      (dfi_8_dw_wrdata_mask_p1  )
	  	,.dfi_8_dw_wrdata_dbi_p1       (dfi_8_dw_wrdata_dbi_p1   )
	  	,.dfi_8_dw_wrdata_par_p1       (dfi_8_dw_wrdata_par_p1   )
	  	,.dfi_8_dw_wrdata_dq_en_p1     (dfi_8_dw_wrdata_dq_en_p1 )
	  	,.dfi_8_dw_wrdata_par_en_p1    (dfi_8_dw_wrdata_par_en_p1)
	  	,.dfi_8_aw_ck_dis              (dfi_8_aw_ck_dis          )
	  	,.dfi_8_lp_pwr_e_req           (dfi_8_lp_pwr_e_req       )
	  	,.dfi_8_lp_sr_e_req            (dfi_8_lp_sr_e_req        )
	  	,.dfi_8_lp_pwr_x_req           (dfi_8_lp_pwr_x_e_req     )
	  	,.dfi_8_aw_tx_indx_ld          (dfi_8_aw_tx_indx_ld      )
	  	,.dfi_8_dw_tx_indx_ld          (dfi_8_dw_tx_indx_ld      )
	  	,.dfi_8_dw_rx_indx_ld          (dfi_8_dw_rx_indx_ld      )
	  	,.dfi_8_ctrlupd_ack            (dfi_8_ctrlupd_ack        )
	  	,.dfi_8_phyupd_req             (dfi_8_phyupd_req         )
	  	,.dfi_8_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_8_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_8_dw_rddata_p0           (w_dfi_8_dw_rddata_p0    )
	  	,.dfi_8_dw_rddata_dm_p0        (dfi_8_dw_rddata_dm_p0 )
	  	,.dfi_8_dw_rddata_dbi_p0       (dfi_8_dw_rddata_dbi_p0)
	  	,.dfi_8_dw_rddata_par_p0       (dfi_8_dw_rddata_par_p0)
	  	,.dfi_8_dw_rddata_p1           (w_dfi_8_dw_rddata_p1    )
	  	,.dfi_8_dw_rddata_dm_p1        (dfi_8_dw_rddata_dm_p1 )
	  	,.dfi_8_dw_rddata_dbi_p1       (dfi_8_dw_rddata_dbi_p1)
	  	,.dfi_8_dw_rddata_par_p1       (dfi_8_dw_rddata_par_p1)
	  	,.dfi_8_dbi_byte_disable       ( /* Not Connected */  )
	  	,.dfi_8_dw_rddata_valid        (w_dfi_8_dw_rddata_valid)
	  	,.dfi_8_dw_derr_n              ( /* Not Connected */  )
	  	,.dfi_8_aw_aerr_n              ( /* Not Connected */  )
	  	,.dfi_8_ctrlupd_req            (dfi_8_ctrlupd_req)
	  	,.dfi_8_phyupd_ack             (dfi_8_phyupd_ack )
	  	,.dfi_8_clk_init               ( /* Not Connected */  )
	  	,.dfi_8_init_complete          (w_dfi_8_init_complete)
	  	,.dfi_8_out_rst_n              (w_dfi_8_out_rst_n    )
	  	

	  	,.dfi_9_clk                    (dfi_clk)
	  	,.dfi_9_rst_n                  (dfi_rst_n   )
	  	,.dfi_9_init_start             (dfi_9_init_start         )
	  	,.dfi_9_aw_ck_p0               (dfi_9_aw_ck_p0           )
	  	,.dfi_9_aw_cke_p0              (dfi_9_aw_cke_p0          )
	  	,.dfi_9_aw_row_p0              (dfi_9_aw_row_p0          )
	  	,.dfi_9_aw_col_p0              (dfi_9_aw_col_p0          )
	  	,.dfi_9_dw_wrdata_p0           (dfi_9_dw_wrdata_p0       )
	  	,.dfi_9_dw_wrdata_mask_p0      (dfi_9_dw_wrdata_mask_p0  )
	  	,.dfi_9_dw_wrdata_dbi_p0       (dfi_9_dw_wrdata_dbi_p0   )
	  	,.dfi_9_dw_wrdata_par_p0       (dfi_9_dw_wrdata_par_p0   )
	  	,.dfi_9_dw_wrdata_dq_en_p0     (dfi_9_dw_wrdata_dq_en_p0 )
	  	,.dfi_9_dw_wrdata_par_en_p0    (dfi_9_dw_wrdata_par_en_p0)
	  	,.dfi_9_aw_ck_p1               (dfi_9_aw_ck_p1           )
	  	,.dfi_9_aw_cke_p1              (dfi_9_aw_cke_p1          )
	  	,.dfi_9_aw_row_p1              (dfi_9_aw_row_p1          )
	  	,.dfi_9_aw_col_p1              (dfi_9_aw_col_p1          )
	  	,.dfi_9_dw_wrdata_p1           (dfi_9_dw_wrdata_p1       )
	  	,.dfi_9_dw_wrdata_mask_p1      (dfi_9_dw_wrdata_mask_p1  )
	  	,.dfi_9_dw_wrdata_dbi_p1       (dfi_9_dw_wrdata_dbi_p1   )
	  	,.dfi_9_dw_wrdata_par_p1       (dfi_9_dw_wrdata_par_p1   )
	  	,.dfi_9_dw_wrdata_dq_en_p1     (dfi_9_dw_wrdata_dq_en_p1 )
	  	,.dfi_9_dw_wrdata_par_en_p1    (dfi_9_dw_wrdata_par_en_p1)
	  	,.dfi_9_aw_ck_dis              (dfi_9_aw_ck_dis          )
	  	,.dfi_9_lp_pwr_e_req           (dfi_9_lp_pwr_e_req       )
	  	,.dfi_9_lp_sr_e_req            (dfi_9_lp_sr_e_req        )
	  	,.dfi_9_lp_pwr_x_req           (dfi_9_lp_pwr_x_e_req     )
	  	,.dfi_9_aw_tx_indx_ld          (dfi_9_aw_tx_indx_ld      )
	  	,.dfi_9_dw_tx_indx_ld          (dfi_9_dw_tx_indx_ld      )
	  	,.dfi_9_dw_rx_indx_ld          (dfi_9_dw_rx_indx_ld      )
	  	,.dfi_9_ctrlupd_ack            (dfi_9_ctrlupd_ack        )
	  	,.dfi_9_phyupd_req             (dfi_9_phyupd_req         )
	  	,.dfi_9_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_9_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_9_dw_rddata_p0           (w_dfi_9_dw_rddata_p0    )
	  	,.dfi_9_dw_rddata_dm_p0        (dfi_9_dw_rddata_dm_p0 )
	  	,.dfi_9_dw_rddata_dbi_p0       (dfi_9_dw_rddata_dbi_p0)
	  	,.dfi_9_dw_rddata_par_p0       (dfi_9_dw_rddata_par_p0)
	  	,.dfi_9_dw_rddata_p1           (w_dfi_9_dw_rddata_p1    )
	  	,.dfi_9_dw_rddata_dm_p1        (dfi_9_dw_rddata_dm_p1 )
	  	,.dfi_9_dw_rddata_dbi_p1       (dfi_9_dw_rddata_dbi_p1)
	  	,.dfi_9_dw_rddata_par_p1       (dfi_9_dw_rddata_par_p1)
	  	,.dfi_9_dbi_byte_disable       ( /* Not Connected */  )
	  	,.dfi_9_dw_rddata_valid        (w_dfi_9_dw_rddata_valid)
	  	,.dfi_9_dw_derr_n              ( /* Not Connected */  )
	  	,.dfi_9_aw_aerr_n              ( /* Not Connected */  )
	  	,.dfi_9_ctrlupd_req            (dfi_9_ctrlupd_req)
	  	,.dfi_9_phyupd_ack             (dfi_9_phyupd_ack )
	  	,.dfi_9_clk_init               ( /* Not Connected */  )
	  	,.dfi_9_init_complete          (w_dfi_9_init_complete)
	  	,.dfi_9_out_rst_n              (w_dfi_9_out_rst_n    )
	  	

	  	,.dfi_10_clk                    (dfi_clk)
	  	,.dfi_10_rst_n                  (dfi_rst_n   )
	  	,.dfi_10_init_start             (dfi_10_init_start         )
	  	,.dfi_10_aw_ck_p0               (dfi_10_aw_ck_p0           )
	  	,.dfi_10_aw_cke_p0              (dfi_10_aw_cke_p0          )
	  	,.dfi_10_aw_row_p0              (dfi_10_aw_row_p0          )
	  	,.dfi_10_aw_col_p0              (dfi_10_aw_col_p0          )
	  	,.dfi_10_dw_wrdata_p0           (dfi_10_dw_wrdata_p0       )
	  	,.dfi_10_dw_wrdata_mask_p0      (dfi_10_dw_wrdata_mask_p0  )
	  	,.dfi_10_dw_wrdata_dbi_p0       (dfi_10_dw_wrdata_dbi_p0   )
	  	,.dfi_10_dw_wrdata_par_p0       (dfi_10_dw_wrdata_par_p0   )
	  	,.dfi_10_dw_wrdata_dq_en_p0     (dfi_10_dw_wrdata_dq_en_p0 )
	  	,.dfi_10_dw_wrdata_par_en_p0    (dfi_10_dw_wrdata_par_en_p0)
	  	,.dfi_10_aw_ck_p1               (dfi_10_aw_ck_p1           )
	  	,.dfi_10_aw_cke_p1              (dfi_10_aw_cke_p1          )
	  	,.dfi_10_aw_row_p1              (dfi_10_aw_row_p1          )
	  	,.dfi_10_aw_col_p1              (dfi_10_aw_col_p1          )
	  	,.dfi_10_dw_wrdata_p1           (dfi_10_dw_wrdata_p1       )
	  	,.dfi_10_dw_wrdata_mask_p1      (dfi_10_dw_wrdata_mask_p1  )
	  	,.dfi_10_dw_wrdata_dbi_p1       (dfi_10_dw_wrdata_dbi_p1   )
	  	,.dfi_10_dw_wrdata_par_p1       (dfi_10_dw_wrdata_par_p1   )
	  	,.dfi_10_dw_wrdata_dq_en_p1     (dfi_10_dw_wrdata_dq_en_p1 )
	  	,.dfi_10_dw_wrdata_par_en_p1    (dfi_10_dw_wrdata_par_en_p1)
	  	,.dfi_10_aw_ck_dis              (dfi_10_aw_ck_dis          )
	  	,.dfi_10_lp_pwr_e_req           (dfi_10_lp_pwr_e_req       )
	  	,.dfi_10_lp_sr_e_req            (dfi_10_lp_sr_e_req        )
	  	,.dfi_10_lp_pwr_x_req           (dfi_10_lp_pwr_x_e_req     )
	  	,.dfi_10_aw_tx_indx_ld          (dfi_10_aw_tx_indx_ld      )
	  	,.dfi_10_dw_tx_indx_ld          (dfi_10_dw_tx_indx_ld      )
	  	,.dfi_10_dw_rx_indx_ld          (dfi_10_dw_rx_indx_ld      )
	  	,.dfi_10_ctrlupd_ack            (dfi_10_ctrlupd_ack        )
	  	,.dfi_10_phyupd_req             (dfi_10_phyupd_req         )
	  	,.dfi_10_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_10_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_10_dw_rddata_p0           (w_dfi_10_dw_rddata_p0    )
	  	,.dfi_10_dw_rddata_dm_p0        (dfi_10_dw_rddata_dm_p0 )
	  	,.dfi_10_dw_rddata_dbi_p0       (dfi_10_dw_rddata_dbi_p0)
	  	,.dfi_10_dw_rddata_par_p0       (dfi_10_dw_rddata_par_p0)
	  	,.dfi_10_dw_rddata_p1           (w_dfi_10_dw_rddata_p1    )
	  	,.dfi_10_dw_rddata_dm_p1        (dfi_10_dw_rddata_dm_p1 )
	  	,.dfi_10_dw_rddata_dbi_p1       (dfi_10_dw_rddata_dbi_p1)
	  	,.dfi_10_dw_rddata_par_p1       (dfi_10_dw_rddata_par_p1)
	  	,.dfi_10_dbi_byte_disable       ( /* Not Connected */  )
	  	,.dfi_10_dw_rddata_valid        (w_dfi_10_dw_rddata_valid)
	  	,.dfi_10_dw_derr_n              ( /* Not Connected */  )
	  	,.dfi_10_aw_aerr_n              ( /* Not Connected */  )
	  	,.dfi_10_ctrlupd_req            (dfi_10_ctrlupd_req)
	  	,.dfi_10_phyupd_ack             (dfi_10_phyupd_ack )
	  	,.dfi_10_clk_init               ( /* Not Connected */  )
	  	,.dfi_10_init_complete          (w_dfi_10_init_complete)
	  	,.dfi_10_out_rst_n              (w_dfi_10_out_rst_n    )
	  	

	  	,.dfi_11_clk                    (dfi_clk)
	  	,.dfi_11_rst_n                  (dfi_rst_n   )
	  	,.dfi_11_init_start             (dfi_11_init_start         )
	  	,.dfi_11_aw_ck_p0               (dfi_11_aw_ck_p0           )
	  	,.dfi_11_aw_cke_p0              (dfi_11_aw_cke_p0          )
	  	,.dfi_11_aw_row_p0              (dfi_11_aw_row_p0          )
	  	,.dfi_11_aw_col_p0              (dfi_11_aw_col_p0          )
	  	,.dfi_11_dw_wrdata_p0           (dfi_11_dw_wrdata_p0       )
	  	,.dfi_11_dw_wrdata_mask_p0      (dfi_11_dw_wrdata_mask_p0  )
	  	,.dfi_11_dw_wrdata_dbi_p0       (dfi_11_dw_wrdata_dbi_p0   )
	  	,.dfi_11_dw_wrdata_par_p0       (dfi_11_dw_wrdata_par_p0   )
	  	,.dfi_11_dw_wrdata_dq_en_p0     (dfi_11_dw_wrdata_dq_en_p0 )
	  	,.dfi_11_dw_wrdata_par_en_p0    (dfi_11_dw_wrdata_par_en_p0)
	  	,.dfi_11_aw_ck_p1               (dfi_11_aw_ck_p1           )
	  	,.dfi_11_aw_cke_p1              (dfi_11_aw_cke_p1          )
	  	,.dfi_11_aw_row_p1              (dfi_11_aw_row_p1          )
	  	,.dfi_11_aw_col_p1              (dfi_11_aw_col_p1          )
	  	,.dfi_11_dw_wrdata_p1           (dfi_11_dw_wrdata_p1       )
	  	,.dfi_11_dw_wrdata_mask_p1      (dfi_11_dw_wrdata_mask_p1  )
	  	,.dfi_11_dw_wrdata_dbi_p1       (dfi_11_dw_wrdata_dbi_p1   )
	  	,.dfi_11_dw_wrdata_par_p1       (dfi_11_dw_wrdata_par_p1   )
	  	,.dfi_11_dw_wrdata_dq_en_p1     (dfi_11_dw_wrdata_dq_en_p1 )
	  	,.dfi_11_dw_wrdata_par_en_p1    (dfi_11_dw_wrdata_par_en_p1)
	  	,.dfi_11_aw_ck_dis              (dfi_11_aw_ck_dis          )
	  	,.dfi_11_lp_pwr_e_req           (dfi_11_lp_pwr_e_req       )
	  	,.dfi_11_lp_sr_e_req            (dfi_11_lp_sr_e_req        )
	  	,.dfi_11_lp_pwr_x_req           (dfi_11_lp_pwr_x_e_req     )
	  	,.dfi_11_aw_tx_indx_ld          (dfi_11_aw_tx_indx_ld      )
	  	,.dfi_11_dw_tx_indx_ld          (dfi_11_dw_tx_indx_ld      )
	  	,.dfi_11_dw_rx_indx_ld          (dfi_11_dw_rx_indx_ld      )
	  	,.dfi_11_ctrlupd_ack            (dfi_11_ctrlupd_ack        )
	  	,.dfi_11_phyupd_req             (dfi_11_phyupd_req         )
	  	,.dfi_11_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_11_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_11_dw_rddata_p0           (w_dfi_11_dw_rddata_p0    )
	  	,.dfi_11_dw_rddata_dm_p0        (dfi_11_dw_rddata_dm_p0 )
	  	,.dfi_11_dw_rddata_dbi_p0       (dfi_11_dw_rddata_dbi_p0)
	  	,.dfi_11_dw_rddata_par_p0       (dfi_11_dw_rddata_par_p0)
	  	,.dfi_11_dw_rddata_p1           (w_dfi_11_dw_rddata_p1    )
	  	,.dfi_11_dw_rddata_dm_p1        (dfi_11_dw_rddata_dm_p1 )
	  	,.dfi_11_dw_rddata_dbi_p1       (dfi_11_dw_rddata_dbi_p1)
	  	,.dfi_11_dw_rddata_par_p1       (dfi_11_dw_rddata_par_p1)
	  	,.dfi_11_dbi_byte_disable       ( /* Not Connected */  )
	  	,.dfi_11_dw_rddata_valid        (w_dfi_11_dw_rddata_valid)
	  	,.dfi_11_dw_derr_n              ( /* Not Connected */  )
	  	,.dfi_11_aw_aerr_n              ( /* Not Connected */  )
	  	,.dfi_11_ctrlupd_req            (dfi_11_ctrlupd_req)
	  	,.dfi_11_phyupd_ack             (dfi_11_phyupd_ack )
	  	,.dfi_11_clk_init               ( /* Not Connected */  )
	  	,.dfi_11_init_complete          (w_dfi_11_init_complete)
	  	,.dfi_11_out_rst_n              (w_dfi_11_out_rst_n    )
	  	

	  	,.dfi_12_clk                    (dfi_clk)
	  	,.dfi_12_rst_n                  (dfi_rst_n   )
	  	,.dfi_12_init_start             (dfi_12_init_start         )
	  	,.dfi_12_aw_ck_p0               (dfi_12_aw_ck_p0           )
	  	,.dfi_12_aw_cke_p0              (dfi_12_aw_cke_p0          )
	  	,.dfi_12_aw_row_p0              (dfi_12_aw_row_p0          )
	  	,.dfi_12_aw_col_p0              (dfi_12_aw_col_p0          )
	  	,.dfi_12_dw_wrdata_p0           (dfi_12_dw_wrdata_p0       )
	  	,.dfi_12_dw_wrdata_mask_p0      (dfi_12_dw_wrdata_mask_p0  )
	  	,.dfi_12_dw_wrdata_dbi_p0       (dfi_12_dw_wrdata_dbi_p0   )
	  	,.dfi_12_dw_wrdata_par_p0       (dfi_12_dw_wrdata_par_p0   )
	  	,.dfi_12_dw_wrdata_dq_en_p0     (dfi_12_dw_wrdata_dq_en_p0 )
	  	,.dfi_12_dw_wrdata_par_en_p0    (dfi_12_dw_wrdata_par_en_p0)
	  	,.dfi_12_aw_ck_p1               (dfi_12_aw_ck_p1           )
	  	,.dfi_12_aw_cke_p1              (dfi_12_aw_cke_p1          )
	  	,.dfi_12_aw_row_p1              (dfi_12_aw_row_p1          )
	  	,.dfi_12_aw_col_p1              (dfi_12_aw_col_p1          )
	  	,.dfi_12_dw_wrdata_p1           (dfi_12_dw_wrdata_p1       )
	  	,.dfi_12_dw_wrdata_mask_p1      (dfi_12_dw_wrdata_mask_p1  )
	  	,.dfi_12_dw_wrdata_dbi_p1       (dfi_12_dw_wrdata_dbi_p1   )
	  	,.dfi_12_dw_wrdata_par_p1       (dfi_12_dw_wrdata_par_p1   )
	  	,.dfi_12_dw_wrdata_dq_en_p1     (dfi_12_dw_wrdata_dq_en_p1 )
	  	,.dfi_12_dw_wrdata_par_en_p1    (dfi_12_dw_wrdata_par_en_p1)
	  	,.dfi_12_aw_ck_dis              (dfi_12_aw_ck_dis          )
	  	,.dfi_12_lp_pwr_e_req           (dfi_12_lp_pwr_e_req       )
	  	,.dfi_12_lp_sr_e_req            (dfi_12_lp_sr_e_req        )
	  	,.dfi_12_lp_pwr_x_req           (dfi_12_lp_pwr_x_e_req     )
	  	,.dfi_12_aw_tx_indx_ld          (dfi_12_aw_tx_indx_ld      )
	  	,.dfi_12_dw_tx_indx_ld          (dfi_12_dw_tx_indx_ld      )
	  	,.dfi_12_dw_rx_indx_ld          (dfi_12_dw_rx_indx_ld      )
	  	,.dfi_12_ctrlupd_ack            (dfi_12_ctrlupd_ack        )
	  	,.dfi_12_phyupd_req             (dfi_12_phyupd_req         )
	  	,.dfi_12_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_12_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_12_dw_rddata_p0           (w_dfi_12_dw_rddata_p0    )
	  	,.dfi_12_dw_rddata_dm_p0        (dfi_12_dw_rddata_dm_p0 )
	  	,.dfi_12_dw_rddata_dbi_p0       (dfi_12_dw_rddata_dbi_p0)
	  	,.dfi_12_dw_rddata_par_p0       (dfi_12_dw_rddata_par_p0)
	  	,.dfi_12_dw_rddata_p1           (w_dfi_12_dw_rddata_p1    )
	  	,.dfi_12_dw_rddata_dm_p1        (dfi_12_dw_rddata_dm_p1 )
	  	,.dfi_12_dw_rddata_dbi_p1       (dfi_12_dw_rddata_dbi_p1)
	  	,.dfi_12_dw_rddata_par_p1       (dfi_12_dw_rddata_par_p1)
	  	,.dfi_12_dbi_byte_disable       ( /* Not Connected */  )
	  	,.dfi_12_dw_rddata_valid        (w_dfi_12_dw_rddata_valid)
	  	,.dfi_12_dw_derr_n              ( /* Not Connected */  )
	  	,.dfi_12_aw_aerr_n              ( /* Not Connected */  )
	  	,.dfi_12_ctrlupd_req            (dfi_12_ctrlupd_req)
	  	,.dfi_12_phyupd_ack             (dfi_12_phyupd_ack )
	  	,.dfi_12_clk_init               ( /* Not Connected */  )
	  	,.dfi_12_init_complete          (w_dfi_12_init_complete)
	  	,.dfi_12_out_rst_n              (w_dfi_12_out_rst_n    )
	  	

	  	,.dfi_13_clk                    (dfi_clk)
	  	,.dfi_13_rst_n                  (dfi_rst_n   )
	  	,.dfi_13_init_start             (dfi_13_init_start         )
	  	,.dfi_13_aw_ck_p0               (dfi_13_aw_ck_p0           )
	  	,.dfi_13_aw_cke_p0              (dfi_13_aw_cke_p0          )
	  	,.dfi_13_aw_row_p0              (dfi_13_aw_row_p0          )
	  	,.dfi_13_aw_col_p0              (dfi_13_aw_col_p0          )
	  	,.dfi_13_dw_wrdata_p0           (dfi_13_dw_wrdata_p0       )
	  	,.dfi_13_dw_wrdata_mask_p0      (dfi_13_dw_wrdata_mask_p0  )
	  	,.dfi_13_dw_wrdata_dbi_p0       (dfi_13_dw_wrdata_dbi_p0   )
	  	,.dfi_13_dw_wrdata_par_p0       (dfi_13_dw_wrdata_par_p0   )
	  	,.dfi_13_dw_wrdata_dq_en_p0     (dfi_13_dw_wrdata_dq_en_p0 )
	  	,.dfi_13_dw_wrdata_par_en_p0    (dfi_13_dw_wrdata_par_en_p0)
	  	,.dfi_13_aw_ck_p1               (dfi_13_aw_ck_p1           )
	  	,.dfi_13_aw_cke_p1              (dfi_13_aw_cke_p1          )
	  	,.dfi_13_aw_row_p1              (dfi_13_aw_row_p1          )
	  	,.dfi_13_aw_col_p1              (dfi_13_aw_col_p1          )
	  	,.dfi_13_dw_wrdata_p1           (dfi_13_dw_wrdata_p1       )
	  	,.dfi_13_dw_wrdata_mask_p1      (dfi_13_dw_wrdata_mask_p1  )
	  	,.dfi_13_dw_wrdata_dbi_p1       (dfi_13_dw_wrdata_dbi_p1   )
	  	,.dfi_13_dw_wrdata_par_p1       (dfi_13_dw_wrdata_par_p1   )
	  	,.dfi_13_dw_wrdata_dq_en_p1     (dfi_13_dw_wrdata_dq_en_p1 )
	  	,.dfi_13_dw_wrdata_par_en_p1    (dfi_13_dw_wrdata_par_en_p1)
	  	,.dfi_13_aw_ck_dis              (dfi_13_aw_ck_dis          )
	  	,.dfi_13_lp_pwr_e_req           (dfi_13_lp_pwr_e_req       )
	  	,.dfi_13_lp_sr_e_req            (dfi_13_lp_sr_e_req        )
	  	,.dfi_13_lp_pwr_x_req           (dfi_13_lp_pwr_x_e_req     )
	  	,.dfi_13_aw_tx_indx_ld          (dfi_13_aw_tx_indx_ld      )
	  	,.dfi_13_dw_tx_indx_ld          (dfi_13_dw_tx_indx_ld      )
	  	,.dfi_13_dw_rx_indx_ld          (dfi_13_dw_rx_indx_ld      )
	  	,.dfi_13_ctrlupd_ack            (dfi_13_ctrlupd_ack        )
	  	,.dfi_13_phyupd_req             (dfi_13_phyupd_req         )
	  	,.dfi_13_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_13_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_13_dw_rddata_p0           (w_dfi_13_dw_rddata_p0    )
	  	,.dfi_13_dw_rddata_dm_p0        (dfi_13_dw_rddata_dm_p0 )
	  	,.dfi_13_dw_rddata_dbi_p0       (dfi_13_dw_rddata_dbi_p0)
	  	,.dfi_13_dw_rddata_par_p0       (dfi_13_dw_rddata_par_p0)
	  	,.dfi_13_dw_rddata_p1           (w_dfi_13_dw_rddata_p1    )
	  	,.dfi_13_dw_rddata_dm_p1        (dfi_13_dw_rddata_dm_p1 )
	  	,.dfi_13_dw_rddata_dbi_p1       (dfi_13_dw_rddata_dbi_p1)
	  	,.dfi_13_dw_rddata_par_p1       (dfi_13_dw_rddata_par_p1)
	  	,.dfi_13_dbi_byte_disable       ( /* Not Connected */  )
	  	,.dfi_13_dw_rddata_valid        (w_dfi_13_dw_rddata_valid)
	  	,.dfi_13_dw_derr_n              ( /* Not Connected */  )
	  	,.dfi_13_aw_aerr_n              ( /* Not Connected */  )
	  	,.dfi_13_ctrlupd_req            (dfi_13_ctrlupd_req)
	  	,.dfi_13_phyupd_ack             (dfi_13_phyupd_ack )
	  	,.dfi_13_clk_init               ( /* Not Connected */  )
	  	,.dfi_13_init_complete          (w_dfi_13_init_complete)
	  	,.dfi_13_out_rst_n              (w_dfi_13_out_rst_n    )
	  	

	  	,.dfi_14_clk                    (dfi_clk)
	  	,.dfi_14_rst_n                  (dfi_rst_n   )
	  	,.dfi_14_init_start             (dfi_14_init_start         )
	  	,.dfi_14_aw_ck_p0               (dfi_14_aw_ck_p0           )
	  	,.dfi_14_aw_cke_p0              (dfi_14_aw_cke_p0          )
	  	,.dfi_14_aw_row_p0              (dfi_14_aw_row_p0          )
	  	,.dfi_14_aw_col_p0              (dfi_14_aw_col_p0          )
	  	,.dfi_14_dw_wrdata_p0           (dfi_14_dw_wrdata_p0       )
	  	,.dfi_14_dw_wrdata_mask_p0      (dfi_14_dw_wrdata_mask_p0  )
	  	,.dfi_14_dw_wrdata_dbi_p0       (dfi_14_dw_wrdata_dbi_p0   )
	  	,.dfi_14_dw_wrdata_par_p0       (dfi_14_dw_wrdata_par_p0   )
	  	,.dfi_14_dw_wrdata_dq_en_p0     (dfi_14_dw_wrdata_dq_en_p0 )
	  	,.dfi_14_dw_wrdata_par_en_p0    (dfi_14_dw_wrdata_par_en_p0)
	  	,.dfi_14_aw_ck_p1               (dfi_14_aw_ck_p1           )
	  	,.dfi_14_aw_cke_p1              (dfi_14_aw_cke_p1          )
	  	,.dfi_14_aw_row_p1              (dfi_14_aw_row_p1          )
	  	,.dfi_14_aw_col_p1              (dfi_14_aw_col_p1          )
	  	,.dfi_14_dw_wrdata_p1           (dfi_14_dw_wrdata_p1       )
	  	,.dfi_14_dw_wrdata_mask_p1      (dfi_14_dw_wrdata_mask_p1  )
	  	,.dfi_14_dw_wrdata_dbi_p1       (dfi_14_dw_wrdata_dbi_p1   )
	  	,.dfi_14_dw_wrdata_par_p1       (dfi_14_dw_wrdata_par_p1   )
	  	,.dfi_14_dw_wrdata_dq_en_p1     (dfi_14_dw_wrdata_dq_en_p1 )
	  	,.dfi_14_dw_wrdata_par_en_p1    (dfi_14_dw_wrdata_par_en_p1)
	  	,.dfi_14_aw_ck_dis              (dfi_14_aw_ck_dis          )
	  	,.dfi_14_lp_pwr_e_req           (dfi_14_lp_pwr_e_req       )
	  	,.dfi_14_lp_sr_e_req            (dfi_14_lp_sr_e_req        )
	  	,.dfi_14_lp_pwr_x_req           (dfi_14_lp_pwr_x_e_req     )
	  	,.dfi_14_aw_tx_indx_ld          (dfi_14_aw_tx_indx_ld      )
	  	,.dfi_14_dw_tx_indx_ld          (dfi_14_dw_tx_indx_ld      )
	  	,.dfi_14_dw_rx_indx_ld          (dfi_14_dw_rx_indx_ld      )
	  	,.dfi_14_ctrlupd_ack            (dfi_14_ctrlupd_ack        )
	  	,.dfi_14_phyupd_req             (dfi_14_phyupd_req         )
	  	,.dfi_14_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_14_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_14_dw_rddata_p0           (w_dfi_14_dw_rddata_p0    )
	  	,.dfi_14_dw_rddata_dm_p0        (dfi_14_dw_rddata_dm_p0 )
	  	,.dfi_14_dw_rddata_dbi_p0       (dfi_14_dw_rddata_dbi_p0)
	  	,.dfi_14_dw_rddata_par_p0       (dfi_14_dw_rddata_par_p0)
	  	,.dfi_14_dw_rddata_p1           (w_dfi_14_dw_rddata_p1    )
	  	,.dfi_14_dw_rddata_dm_p1        (dfi_14_dw_rddata_dm_p1 )
	  	,.dfi_14_dw_rddata_dbi_p1       (dfi_14_dw_rddata_dbi_p1)
	  	,.dfi_14_dw_rddata_par_p1       (dfi_14_dw_rddata_par_p1)
	  	,.dfi_14_dbi_byte_disable       ( /* Not Connected */  )
	  	,.dfi_14_dw_rddata_valid        (w_dfi_14_dw_rddata_valid)
	  	,.dfi_14_dw_derr_n              ( /* Not Connected */  )
	  	,.dfi_14_aw_aerr_n              ( /* Not Connected */  )
	  	,.dfi_14_ctrlupd_req            (dfi_14_ctrlupd_req)
	  	,.dfi_14_phyupd_ack             (dfi_14_phyupd_ack )
	  	,.dfi_14_clk_init               ( /* Not Connected */  )
	  	,.dfi_14_init_complete          (w_dfi_14_init_complete)
	  	,.dfi_14_out_rst_n              (w_dfi_14_out_rst_n    )
	  	

	  	,.dfi_15_clk                    (dfi_clk)
	  	,.dfi_15_rst_n                  (dfi_rst_n   )
	  	,.dfi_15_init_start             (dfi_15_init_start         )
	  	,.dfi_15_aw_ck_p0               (dfi_15_aw_ck_p0           )
	  	,.dfi_15_aw_cke_p0              (dfi_15_aw_cke_p0          )
	  	,.dfi_15_aw_row_p0              (dfi_15_aw_row_p0          )
	  	,.dfi_15_aw_col_p0              (dfi_15_aw_col_p0          )
	  	,.dfi_15_dw_wrdata_p0           (dfi_15_dw_wrdata_p0       )
	  	,.dfi_15_dw_wrdata_mask_p0      (dfi_15_dw_wrdata_mask_p0  )
	  	,.dfi_15_dw_wrdata_dbi_p0       (dfi_15_dw_wrdata_dbi_p0   )
	  	,.dfi_15_dw_wrdata_par_p0       (dfi_15_dw_wrdata_par_p0   )
	  	,.dfi_15_dw_wrdata_dq_en_p0     (dfi_15_dw_wrdata_dq_en_p0 )
	  	,.dfi_15_dw_wrdata_par_en_p0    (dfi_15_dw_wrdata_par_en_p0)
	  	,.dfi_15_aw_ck_p1               (dfi_15_aw_ck_p1           )
	  	,.dfi_15_aw_cke_p1              (dfi_15_aw_cke_p1          )
	  	,.dfi_15_aw_row_p1              (dfi_15_aw_row_p1          )
	  	,.dfi_15_aw_col_p1              (dfi_15_aw_col_p1          )
	  	,.dfi_15_dw_wrdata_p1           (dfi_15_dw_wrdata_p1       )
	  	,.dfi_15_dw_wrdata_mask_p1      (dfi_15_dw_wrdata_mask_p1  )
	  	,.dfi_15_dw_wrdata_dbi_p1       (dfi_15_dw_wrdata_dbi_p1   )
	  	,.dfi_15_dw_wrdata_par_p1       (dfi_15_dw_wrdata_par_p1   )
	  	,.dfi_15_dw_wrdata_dq_en_p1     (dfi_15_dw_wrdata_dq_en_p1 )
	  	,.dfi_15_dw_wrdata_par_en_p1    (dfi_15_dw_wrdata_par_en_p1)
	  	,.dfi_15_aw_ck_dis              (dfi_15_aw_ck_dis          )
	  	,.dfi_15_lp_pwr_e_req           (dfi_15_lp_pwr_e_req       )
	  	,.dfi_15_lp_sr_e_req            (dfi_15_lp_sr_e_req        )
	  	,.dfi_15_lp_pwr_x_req           (dfi_15_lp_pwr_x_e_req     )
	  	,.dfi_15_aw_tx_indx_ld          (dfi_15_aw_tx_indx_ld      )
	  	,.dfi_15_dw_tx_indx_ld          (dfi_15_dw_tx_indx_ld      )
	  	,.dfi_15_dw_rx_indx_ld          (dfi_15_dw_rx_indx_ld      )
	  	,.dfi_15_ctrlupd_ack            (dfi_15_ctrlupd_ack        )
	  	,.dfi_15_phyupd_req             (dfi_15_phyupd_req         )
	  	,.dfi_15_dw_wrdata_dqs_p0       (8'hff)
	  	,.dfi_15_dw_wrdata_dqs_p1       (8'hff)
	  	,.dfi_15_dw_rddata_p0           (w_dfi_15_dw_rddata_p0    )
	  	,.dfi_15_dw_rddata_dm_p0        (dfi_15_dw_rddata_dm_p0 )
	  	,.dfi_15_dw_rddata_dbi_p0       (dfi_15_dw_rddata_dbi_p0)
	  	,.dfi_15_dw_rddata_par_p0       (dfi_15_dw_rddata_par_p0)
	  	,.dfi_15_dw_rddata_p1           (w_dfi_15_dw_rddata_p1    )
	  	,.dfi_15_dw_rddata_dm_p1        (dfi_15_dw_rddata_dm_p1 )
	  	,.dfi_15_dw_rddata_dbi_p1       (dfi_15_dw_rddata_dbi_p1)
	  	,.dfi_15_dw_rddata_par_p1       (dfi_15_dw_rddata_par_p1)
	  	,.dfi_15_dbi_byte_disable       ( /* Not Connected */  )
	  	,.dfi_15_dw_rddata_valid        (w_dfi_15_dw_rddata_valid)
	  	,.dfi_15_dw_derr_n              ( /* Not Connected */  )
	  	,.dfi_15_aw_aerr_n              ( /* Not Connected */  )
	  	,.dfi_15_ctrlupd_req            (dfi_15_ctrlupd_req)
	  	,.dfi_15_phyupd_ack             (dfi_15_phyupd_ack )
	  	,.dfi_15_clk_init               ( /* Not Connected */  )
	  	,.dfi_15_init_complete          (w_dfi_15_init_complete)
	  	,.dfi_15_out_rst_n              (w_dfi_15_out_rst_n    )
	  	
	  	// Not sure what should these represent
	  	,.APB_0_PCLK                   (APB_0_PCLK)
	  	,.APB_0_PRESET_N               (APB_0_PRESET_N)
	  	,.APB_1_PCLK                   (APB_1_PCLK)
	  	,.APB_1_PRESET_N               (APB_1_PRESET_N)
	  	
	  	,.apb_complete_0               (apb_complete_0)
	  	,.apb_complete_1               (apb_complete_1)
	  	,.DRAM_0_STAT_CATTRIP          (DRAM_0_STAT_CATTRIP)
	  	,.DRAM_0_STAT_TEMP             (DRAM_0_STAT_TEMP   )
	  	,.DRAM_1_STAT_CATTRIP          (DRAM_1_STAT_CATTRIP)
	  	,.DRAM_1_STAT_TEMP             (DRAM_1_STAT_TEMP   )
	);
    
    
endmodule