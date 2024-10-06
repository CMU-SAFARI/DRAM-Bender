`timescale 1ps/1ps

`include "project.vh"

module pcie_app_softmc #(
	parameter							C_DATA_WIDTH 			= 64,
	parameter							KEEP_WIDTH				= C_DATA_WIDTH / 8,
	
	// TLP Field Constants
	parameter							DW_WIDTH				= 32,
	parameter							MAX_ADDR_WIDTH			= 64,
	parameter							DW_COUNT				= 2,
	parameter							PKT_REQUESTER_ID_WIDTH 	= 16,
	parameter							PKT_LENGTH_WIDTH		= 10,
	parameter							PKT_TAG_WIDTH			= 8,
	parameter							PKT_TYPE_WIDTH			= 5,
	parameter							PKT_FORMAT_WIDTH		= 3,
	parameter							PKT_FIRST_WD_WIDTH		= 4,
	parameter							PKT_LAST_WD_WIDTH		= 4,
	
	// Internal Memory Parameters
	parameter							INTERNAL_MEM_DEPTH		= 1024,
	parameter							BAR_BITS				= 20	// MAX number of bits required for BAR adress space
																		// might seem unnecessary but saves us a subtraction
																		// which reduces latency (needs to be pipelined at 250+ MHz)
)(	
	input                     			user_clk,
	input                     			user_reset,
	input                     			user_lnk_up,

	output	[`SOFTMC_STREAM_WIDTH-1:0]	softmc_h2c_tdata,
	output								softmc_h2c_tvalid,
	input								softmc_h2c_tready,
	output								softmc_h2c_tlast,

	input	[`SOFTMC_STREAM_WIDTH-1:0]  softmc_c2h_tdata,
	input								softmc_c2h_tvalid,
	output								softmc_c2h_tready,
	input								softmc_c2h_tlast,

	input 	[7:0]						cfg_bus_number,
	input	[4:0]						cfg_device_number,
	input	[2:0]						cfg_function_number,
	input	[15:0]						cfg_dcommand,
	input	[15:0]						cfg_command,
	output								cfg_interrupt,
	output								cfg_interrupt_assert,
	input								cfg_interrupt_rdy,
	output	[7:0]						cfg_interrupt_di,
	input								cfg_interrupt_msienable,
	
	output	[9:0]						pci_cfg_dwaddr,
	output								pci_cfg_rd_en,
	input	[31:0]						pci_cfg_dout,
	input								pci_cfg_rd_wr_done,
	
	input                     			s_axis_tx_tready,
	output	[C_DATA_WIDTH-1:0]			s_axis_tx_tdata,
	output	[KEEP_WIDTH-1:0]  			s_axis_tx_tkeep,
	output                    			s_axis_tx_tlast,
	output                    			s_axis_tx_tvalid,
	output								tx_src_dsc,
						
	input	[C_DATA_WIDTH-1:0]			m_axis_rx_tdata,
	input	[KEEP_WIDTH-1:0]  			m_axis_rx_tkeep,
	input                     			m_axis_rx_tlast,
	input                     			m_axis_rx_tvalid,
	output                    			m_axis_rx_tready,
	input	[21:0]            			m_axis_rx_tuser,
						
	input                     			cfg_to_turnoff,
	output                    			cfg_turnoff_ok,
	input	[15:0]            			cfg_completer_id
);

wire  									app_reset;

// RX FSM Declarations
localparam								RECV_IDLE				= 'd0;
localparam								RECV_HEAD1				= 'd1;
localparam								RECV_HEAD2				= 'd2;
localparam								RECV_DATA				= 'd3;
localparam                              UNDEFINED_STATE         = 'bz;

reg		[2:0]							fsm_recv_state_r;
reg										m_axis_rx_tready_r;
wire	[7:0]							rx_bar_hit;

// TLP Declarations
localparam								DW3_NODATA				= 'b000;
localparam								DW4_NODATA				= 'b001;
localparam								DW3_DATA				= 'b010;
localparam								DW4_DATA				= 'b011;

wire	[15:0]							dma_requester_id		= {cfg_bus_number, cfg_device_number, cfg_function_number};

wire	[PKT_LENGTH_WIDTH-1:0] 			pkt_len;
wire	[PKT_REQUESTER_ID_WIDTH-1:0] 	pkt_requester_id;
wire	[PKT_TAG_WIDTH-1:0]				pkt_tag;
wire	[PKT_TYPE_WIDTH-1:0]			pkt_type;
wire	[PKT_FORMAT_WIDTH-1:0]			pkt_fmt;
wire	[PKT_FIRST_WD_WIDTH-1:0]		pkt_first_wd_be;
wire	[PKT_LAST_WD_WIDTH-1:0]			pkt_last_wd_be;
wire    [3:0]                           pkt_valid_bytes;
wire									pkt_is_MRd;
wire									pkt_is_MWr;
wire									pkt_is_IORd;
wire									pkt_is_IOWr;

reg		[MAX_ADDR_WIDTH-1:0]			pkt_local_addr;
reg										pkt_bar_id;
wire	[DW_WIDTH-1:0]					tlp_dw[0:DW_COUNT-1];

reg										pkt_bar_id_r;
reg		[PKT_LENGTH_WIDTH-1:0] 			pkt_len_r;
reg		[PKT_REQUESTER_ID_WIDTH-1:0] 	pkt_requester_id_r;
reg		[PKT_TAG_WIDTH-1:0]				pkt_tag_r;
reg		[PKT_TYPE_WIDTH-1:0]			pkt_type_r;
reg		[PKT_FORMAT_WIDTH-1:0]			pkt_fmt_r;
reg		[PKT_FIRST_WD_WIDTH-1:0]		pkt_first_wd_be_r;
reg		[PKT_LAST_WD_WIDTH-1:0]			pkt_last_wd_be_r;
reg		[MAX_ADDR_WIDTH-1:0]			pkt_addr_r;
reg		[C_DATA_WIDTH-1:0]				pkt_data_r;
reg		[KEEP_WIDTH-1:0]				pkt_data_valid_r;
reg 	[11:0]							pkt_data_byte_ctr_r;

// Internal Packet Data Routing Decalarations
reg 	[(C_DATA_WIDTH/2)-1:0] 			pkt_a_din;
reg 	[MAX_ADDR_WIDTH-1:0] 			pkt_a_addr;
reg										pkt_a_wr_en;

reg 	[(C_DATA_WIDTH/2)-1:0] 			pkt_b_din;
reg 	[MAX_ADDR_WIDTH-1:0] 			pkt_b_addr;
reg										pkt_b_wr_en;


// Internal Memory Declarations
reg 	[(C_DATA_WIDTH/2)-1:0] 			mem_a_din;
reg 	[MAX_ADDR_WIDTH-1:0] 			mem_a_addr;
reg										mem_a_dout;
reg										mem_a_wr_en;

reg 	[(C_DATA_WIDTH/2)-1:0] 			mem_b_din;
reg 	[MAX_ADDR_WIDTH-1:0] 			mem_b_addr;
reg										mem_b_dout;
reg										mem_b_wr_en;

// TxN Buffer Declarations
wire    [C_DATA_WIDTH-1:0]	    		send_buff_tdata;
wire    [C_DATA_WIDTH/2-1:0]    		send_buff_upper_half_data;
wire    [KEEP_WIDTH-1:0]		    	send_buff_tkeep;
wire    [KEEP_WIDTH/2-1:0]          	send_buff_upper_half_keep;
wire							    	send_buff_tvalid;
wire							    	send_buff_upper_half_valid;
wire								   	send_buff_tready;
wire								   	send_buff_upper_half_ready;

wire 	[11:0] 							send_buff_full_data_count;
wire 	[12:0]	    					send_buff_half_data_count;
wire							    	send_buff_programmed_stop;

reg								    	send_buff_tready_r;
reg								    	send_buff_upper_half_ready_r;



// Application Control Declarations
localparam								COMMAND_RD				= 'b01;
localparam								COMMAND_WR				= 'b11;
localparam								COMMAND_NOP				= 'b00;
localparam								COMMAND_LAST_BIT		= 'd3;
localparam								INTR_RD_DONE			= 8'd0;
localparam								INTR_WR_DONE			= 8'd0;

localparam								ABANDON_COUNT			= 50_000_000;

localparam                              SEND_IDLE         		= 'd0;
localparam								SEND_WRITE0  			= 'd1;	// Starts from 0, checks buffers and timers before initiating txn.
localparam                              SEND_WRITE1         	= 'd2;
localparam                              SEND_WRITE2         	= 'd3;
localparam                              SEND_READ1         		= 'd4;
localparam                              SEND_READ2         		= 'd5;
localparam                              SEND_READ3         		= 'd6;
localparam								SEND_DATA1				= 'd7;
localparam								SEND_DATA2				= 'd8;
localparam								SEND_ISSUE				= 'd9;
localparam								SEND_INTR1				= 'd10;
localparam								SEND_INTR_LEGACY1		= 'd11;
localparam								SEND_INTR_LEGACY2		= 'd12;
localparam								SEND_INTR_LEGACY3		= 'd13;
localparam								SEND_INTR_MSI1			= 'd14;
localparam								SEND_INTR_MSI2			= 'd15;
localparam								SEND_STALL_READ			= 'd16;
localparam								SEND_TXN_REG1			= 'd17;
localparam								SEND_TXN_REG2			= 'd18;
localparam								SEND_TXN_REG3			= 'd19;

reg										cfg_interrupt_r;
reg		[7:0]							cfg_interrupt_di_r;
reg										cfg_interrupt_assert_r;

wire	[10:0]							cfg_max_rd_size;
wire	[10:0]							cfg_max_wr_size;

reg		[4:0]							fsm_send_state_r;
reg		[PKT_TAG_WIDTH-1:0]				cmd_tag_r;
reg										cmd_tag_completed_r;
reg		[15:0]							cmd_tag_req_len_r;
reg		[15:0]							tag_dw_count_r;
reg										cmd_rd_is_last_r;
reg										tag_tlast_r;

reg		[15:0]							cmd_sent_r;
reg		[15:0]							cmd_remaining_r;
reg		[PKT_TAG_WIDTH-1:0]				cmd_remaining_tag_r;
reg		[1:0]							cmd_remaining_type_r;
reg		[63:0]							cmd_remaining_addr_r;


reg										cmd_stat_update_r;
reg		[3:0]							cmd_stat_idx_r;
reg 	[31:0]							cmd_stat_data_r;
wire									cmd_bar_hit;

wire									bus_master_enabled;
wire									intr_enabled;

/*
	command_controls_r:
	// Temporary Regs (cleared after each command)
		0 -> command initiator
		1 -> high 32 bit address, only used for 64 bit addressing mode
		2 -> low 32 bit address
		3 -> reserved for later
	// Permanent Regs (never cleared by device, must be overwritten by host)
		0 -> high 32 bit address for status writes, only used for 64 bit addressing mode
		1 -> low 32 bit address for status writes (i.e. number of bytes written, errors etc)
		2 -> 32 bit status register {16 bits->bytes written by last command, 16 bits->reserved}
*/

localparam								NUM_TEMP_REGS			= 'd4;
localparam								NUM_PERM_REGS			= 'd3;
localparam								CMD_EXEC_REG			= 'd0;
localparam								CMD_HI_ADDR				= 'd1;
localparam								CMD_LO_ADDR				= 'd2;
localparam								CMD_RESERVED0			= 'd3;
localparam								TXN_STATUS_HI_ADDR  	= NUM_TEMP_REGS + 'd0;
localparam								TXN_STATUS_LO_ADDR		= NUM_TEMP_REGS + 'd1;
localparam								TXN_STATUS_REG			= NUM_TEMP_REGS + 'd2;

reg		[31:0]							command_controls_r[0:NUM_TEMP_REGS + NUM_PERM_REGS - 1];
reg										command_clear_r;

reg		[15:0]							cmd_len_r;
wire	[1:0]							cmd_type;
wire	[15:0]							cmd_len;
wire									cmd_tlast;
wire	[15:0]							cmd_wr_pkt_len;
wire	[15:0]							cmd_rd_pkt_len;

reg		[15:0]							cmd_wr_pkt_len_r;
reg		[15:0]							cmd_rd_pkt_len_r;

// Master AXIS Port Declarations
reg 	[C_DATA_WIDTH-1:0]				s_axis_tx_tdata_r;
reg 	[KEEP_WIDTH-1:0]				s_axis_tx_tkeep_r;
reg 									s_axis_tx_tlast_r;
reg 									s_axis_tx_tvalid_r;

// Instruction Memory Declarations
wire	[C_DATA_WIDTH-1:0]				s_axis_instr_mem_tdata;
wire 									s_axis_instr_mem_tvalid;
wire									s_axis_instr_mem_tready;
wire	[KEEP_WIDTH-1:0]				s_axis_instr_mem_tkeep;
wire									s_axis_instr_mem_tlast;
wire	[`SOFTMC_STREAM_WIDTH-1:0]		m_axis_instr_mem_tdata;
wire									m_axis_instr_mem_tvalid;
wire									m_axis_instr_mem_tready;
wire									m_axis_instr_mem_tlast;

// Loop and Generation Declarations
integer i;
genvar j;

// Relabelling Packet Double Words To Increase Readability
generate
	for (j = 0; j < DW_COUNT; j = j + 1) begin : tlp_dw_assg
		assign tlp_dw[j] = m_axis_rx_tdata[j*DW_WIDTH +: DW_WIDTH];
	end
endgenerate

initial begin
	for (i = 0; i < NUM_PERM_REGS + NUM_TEMP_REGS; i = i + 1) begin
		command_controls_r[i] 		<= 0;
	end
	fsm_recv_state_r 				<= RECV_IDLE;
	fsm_send_state_r				<= SEND_IDLE;
	m_axis_rx_tready_r 				<= 0;
	pkt_data_byte_ctr_r				<= 0;
	pkt_a_din						<= 0;
	pkt_a_addr						<= 0;
	pkt_a_wr_en						<= 0;
	pkt_b_din						<= 0;
	pkt_b_addr						<= 0;
	pkt_b_wr_en						<= 0;
	cmd_rd_is_last_r				<= 0;
	command_clear_r					<= 0;
	s_axis_tx_tdata_r				<= 0;
	s_axis_tx_tkeep_r				<= 0;
	s_axis_tx_tlast_r				<= 0;
	s_axis_tx_tvalid_r				<= 0;
	cmd_sent_r						<= 0;
	cmd_remaining_r					<= 0;
	cmd_remaining_type_r			<= 0;
	cfg_interrupt_r					<= 0;
	cfg_interrupt_assert_r			<= 0;
	cfg_interrupt_di_r				<= 0;
	cmd_stat_update_r				<= 0;
	cmd_stat_idx_r					<= 0;
	cmd_stat_data_r					<= 0;
	tag_tlast_r						<= 0;
end

// Local address Conversion And Bus ID Assignment
always @(*) begin
	pkt_local_addr					= {64'd0, pkt_addr_r[BAR_BITS-1:0]};
	pkt_bar_id						= rx_bar_hit[0] ? 'd0 : 'hFF;
end

always @(posedge user_clk) begin
	cmd_wr_pkt_len_r <= cmd_wr_pkt_len;
	cmd_rd_pkt_len_r <= cmd_rd_pkt_len;
end

// Packet Decode FSM
always @(posedge user_clk) begin
	if (command_clear_r) begin
		tag_dw_count_r 				<= 0;
	end
	if (app_reset) begin
		fsm_recv_state_r 			<= RECV_IDLE;
		m_axis_rx_tready_r 			<= 0;
		pkt_data_byte_ctr_r			<= 0;
		tag_dw_count_r 				<= 0;
	end
	else begin
		case (fsm_recv_state_r)
		RECV_IDLE: begin
			if (m_axis_rx_tready_r && m_axis_rx_tvalid) begin
				fsm_recv_state_r 	<= (pkt_fmt == 'b001 || pkt_fmt == 'b011) ? RECV_HEAD1 :
								 	   (pkt_fmt == 'b000 || pkt_fmt == 'b010) ? RECV_HEAD2	: RECV_IDLE;
				pkt_len_r 			<= pkt_len;
				pkt_requester_id_r 	<= pkt_requester_id;
				pkt_tag_r 			<= pkt_tag;
				pkt_type_r			<= pkt_type;
				pkt_fmt_r			<= pkt_fmt;
				pkt_first_wd_be_r	<= pkt_first_wd_be;
				pkt_last_wd_be_r	<= pkt_last_wd_be;
				pkt_bar_id_r		<= pkt_bar_id;
				pkt_data_byte_ctr_r	<= 0;
			end
			else begin
				m_axis_rx_tready_r 	<= 1;
				pkt_bar_id_r		<= 'hFF;
			end
			pkt_data_valid_r		<= 0;
			tag_tlast_r				<= 0;
		end
		RECV_HEAD1: begin
			if (m_axis_rx_tready_r && m_axis_rx_tvalid) begin
				pkt_addr_r[63:2]	<= {tlp_dw[1], tlp_dw[0][31:2]};
				pkt_addr_r[1:0]		<= pkt_first_wd_be_r[0] ? 	'b00 :
								       pkt_first_wd_be_r[1] ? 	'b01 :
								       pkt_first_wd_be_r[2] ? 	'b10 :
								       pkt_first_wd_be_r[3] ? 	'b11 : 'b00;
				fsm_recv_state_r 	<= (pkt_fmt_r == 'b010 || pkt_fmt_r == 'b011) && (pkt_len_r != 'b1) ? RECV_DATA : RECV_IDLE;
			end
			else begin
				m_axis_rx_tready_r 	<= 	1;
			end
			pkt_data_valid_r		<= 	0;
		end
		RECV_HEAD2: begin 
			if (m_axis_rx_tready_r && m_axis_rx_tvalid) begin
				if (pkt_type_r == 5'h0a) begin	// Read Completion, update tag
					pkt_tag_r		<= tlp_dw[0][15:8];
					tag_tlast_r		<= cmd_rd_is_last_r && (pkt_tag_r == cmd_tag_r) && (tag_dw_count_r == (cmd_tag_req_len_r - (pkt_valid_bytes / 4)));
					tag_dw_count_r	<= m_axis_rx_tkeep[7:4] == 'hF ? tag_dw_count_r + 1 : tag_dw_count_r;
				end
				pkt_addr_r[63:2]	<= {32'd0, tlp_dw[0][31:2]};
				pkt_addr_r[1:0]		<= pkt_first_wd_be_r[0] ? 	'b00 :
									   pkt_first_wd_be_r[1] ? 	'b01 :
									   pkt_first_wd_be_r[2] ? 	'b10 :
									   pkt_first_wd_be_r[3] ? 	'b11 : 'b00;
				pkt_data_r[63:32]	<= 32'd0;
				pkt_data_r[31:0]    <= tlp_dw[1];
				pkt_data_valid_r	<= {4'b0, m_axis_rx_tkeep[7:4]};
				pkt_data_byte_ctr_r	<= m_axis_rx_tkeep[7:4] == 'hF ?	pkt_data_byte_ctr_r + 'd4 : pkt_data_byte_ctr_r;
				fsm_recv_state_r	<= (pkt_fmt_r == 'b010 || pkt_fmt_r == 'b011) && (pkt_len_r != 'b1) ? RECV_DATA : RECV_IDLE;
			end
			else begin
				m_axis_rx_tready_r 	<= 	1;
				pkt_data_valid_r	<= 	0;
			end
		end
		RECV_DATA: begin
			if (m_axis_rx_tready_r && m_axis_rx_tvalid) begin
				pkt_data_r[63:32]	<= tlp_dw[1];
				pkt_data_r[31:0]    <= tlp_dw[0];
				pkt_data_valid_r 	<= m_axis_rx_tkeep;
				tag_tlast_r			<= cmd_rd_is_last_r && (pkt_tag_r == cmd_tag_r) && (tag_dw_count_r == (cmd_tag_req_len_r - (pkt_valid_bytes / 4)));
				tag_dw_count_r		<= pkt_tag_r == cmd_tag_r ? tag_dw_count_r + (pkt_valid_bytes / 4) : tag_dw_count_r;
				pkt_data_byte_ctr_r	<= pkt_data_byte_ctr_r + pkt_valid_bytes;
				fsm_recv_state_r	<= m_axis_rx_tlast											||
									   pkt_data_byte_ctr_r + pkt_valid_bytes >= pkt_len_r << 2	||
									   pkt_data_byte_ctr_r == 'd4096							? 	RECV_IDLE : RECV_DATA;
			end
			else begin
				m_axis_rx_tready_r	<= 1;
				pkt_data_valid_r 	<= 0;
				tag_tlast_r			<= 0;
			end
		end
		endcase
	end
end

// Write Request Routing
// Left Port B Empty So Read Requests can be paralellized in the future
always @(*) begin
	pkt_a_din						= 0;
	pkt_a_addr						= 0;
	pkt_a_wr_en						= 0;
	pkt_b_din						= 0;
	pkt_b_addr						= 0;
	pkt_b_wr_en						= 0;
	case (pkt_data_valid_r)
	'h0F: begin
		pkt_a_addr 					= pkt_local_addr / 4;
		pkt_a_din					= pkt_data_r[31:0];
		pkt_a_wr_en					= 1;
	end	
	'hF0: begin	
		pkt_a_addr 					= pkt_local_addr / 4;
		pkt_a_din					= pkt_data_r[63:32];
		pkt_a_wr_en					= 1;
	end	
	'hFF: begin	
		pkt_a_addr 					= pkt_local_addr / 4;
		pkt_a_din					= pkt_data_r[31:0];
		pkt_a_wr_en					= 1;
		pkt_b_addr 					= pkt_local_addr / 4 + 1;
		pkt_b_din					= pkt_data_r[63:32];
		pkt_b_wr_en					= 1;
	end	
	default: begin	
		pkt_a_addr 					= pkt_local_addr / 4;
		pkt_a_wr_en					= 0;
		pkt_b_addr 					= pkt_local_addr / 4 + 1;
		pkt_b_wr_en					= 0;
	end
	endcase
end

// Handling Writes to command registers
always @(posedge user_clk) begin
	if (app_reset) begin
		for (i = 0; i < NUM_TEMP_REGS + NUM_PERM_REGS; i = i + 1) begin
			command_controls_r[i]	<= 0;
		end
	end
	else begin	
		if (command_clear_r) begin
			for (i = 0; i < NUM_TEMP_REGS; i = i + 1) begin
				command_controls_r[i]	<= 0;
			end
		end
		if (cmd_bar_hit && !(command_clear_r && pkt_a_addr < NUM_TEMP_REGS)) begin
			if (pkt_a_wr_en) begin
				command_controls_r[pkt_a_addr] <= {<<8{pkt_a_din}};	// Big Endian -> Little Endian
			end
			if (pkt_b_wr_en) begin
				command_controls_r[pkt_b_addr] <= {<<8{pkt_b_din}};	// Big Endian -> Little Endian
			end
		end
		if (cmd_stat_update_r) begin
			command_controls_r[cmd_stat_idx_r] <= cmd_stat_data_r;
		end
	end
end

reg [14:0] 	available_bytes_r;
reg [14:0] 	available_bytes_ns;

reg [31:0]	abandon_ctr_r;
reg [31:0]	abandon_ctr_ns;

// Implement these if your module should be able to flush buffers
// One implementation could be to connect timers and apply these
// Flush just sends a single packet early, abandon drops remaining requests as well
// MUST be held high until fsm_send_state_r : SEND_WRITE0 -> SEND_WRITE1 happens
reg			flush_early_r;
reg			flush_early_ns;
reg			abandon_cmd_r;
reg			abandon_cmd_ns;

always @(posedge user_clk) begin
	if (app_reset) begin
		available_bytes_r <= 0;
		flush_early_r <= 0;
		abandon_cmd_r <= 0;
		abandon_ctr_r <= 0;
	end
	else begin
		available_bytes_r <= available_bytes_ns;
		flush_early_r <= flush_early_ns;
		abandon_cmd_r <= abandon_cmd_ns;
		abandon_ctr_r <= abandon_ctr_ns;
	end
end

// Combinational Application Control
always @(*) begin
	flush_early_ns = fsm_send_state_r == SEND_WRITE0 ? 0 : flush_early_r;
	abandon_cmd_ns = fsm_send_state_r == SEND_WRITE0 ? 0 : abandon_cmd_r;
	abandon_ctr_ns = (softmc_c2h_tvalid || fsm_send_state_r != SEND_WRITE0) ? 0 : abandon_ctr_r + 1;
	available_bytes_ns = send_buff_full_data_count * C_DATA_WIDTH / 8;
	if (app_reset) begin
		send_buff_tready_r = 0;
		send_buff_upper_half_ready_r = 0;
	end
	else begin
		if (abandon_ctr_r == ABANDON_COUNT) begin
			flush_early_ns = 1;
			abandon_cmd_ns = 1;
			abandon_ctr_ns = 1;
		end
		send_buff_tready_r = 0;
		send_buff_upper_half_ready_r = 0;
		case (fsm_send_state_r)
		SEND_WRITE2: begin
			send_buff_upper_half_ready_r = s_axis_tx_tvalid_r && s_axis_tx_tready;
		end
		SEND_DATA1: begin
			send_buff_upper_half_ready_r = s_axis_tx_tvalid_r && s_axis_tx_tready && cmd_len_r == 1;
			send_buff_tready_r = s_axis_tx_tvalid_r && s_axis_tx_tready && cmd_len_r != 1;
		end
		endcase
	end
end

// Sequential Application Control
always @(posedge user_clk) begin
	if (app_reset) begin
		fsm_send_state_r			<= SEND_IDLE;
		command_clear_r				<= 0;
		cmd_sent_r					<= 0;
		cmd_remaining_r				<= 0;
		cmd_remaining_type_r		<= COMMAND_NOP;
		cmd_tag_r					<= 0;
		cmd_tag_completed_r			<= 1;
	end
	else begin
		case (fsm_send_state_r)
		SEND_IDLE: begin
			if (cmd_type == COMMAND_WR) begin
				fsm_send_state_r			<= SEND_ISSUE;
				cmd_sent_r					<= 0;
				cmd_remaining_r				<= cmd_len;
				cmd_remaining_type_r		<= COMMAND_WR;
				cmd_rd_is_last_r			<= 0;
				cmd_remaining_addr_r		<= {command_controls_r[CMD_HI_ADDR][31:0], command_controls_r[CMD_LO_ADDR][31:2], 2'b00};
				command_clear_r				<= 1;
			end
			else if (cmd_type == COMMAND_RD) begin
				fsm_send_state_r			<= SEND_ISSUE;
				cmd_tag_req_len_r			<= cmd_len;
				cmd_remaining_r				<= cmd_len;
				cmd_remaining_tag_r			<= cmd_tag_r + 1;
				cmd_remaining_type_r		<= COMMAND_RD;
				cmd_rd_is_last_r			<= cmd_tlast;
				cmd_remaining_addr_r		<= {command_controls_r[CMD_HI_ADDR][31:0], command_controls_r[CMD_LO_ADDR][31:2], 2'b00};
				command_clear_r				<= 1;
			end
			else begin
				cmd_remaining_type_r		<= COMMAND_NOP;
				command_clear_r				<= 0;
				cmd_rd_is_last_r			<= 0;
			end
			s_axis_tx_tvalid_r				<= 0;
			s_axis_tx_tlast_r				<= 0;
			cfg_interrupt_r					<= 0;
			cmd_stat_update_r				<= 0;
		end
		SEND_ISSUE: begin
			if (!bus_master_enabled) begin
				cmd_remaining_type_r		<= COMMAND_NOP;
				fsm_send_state_r			<= SEND_ISSUE;
			end	
			else if (cmd_remaining_type_r == COMMAND_WR) begin
				fsm_send_state_r			<= SEND_WRITE0;
			end
			else if (cmd_remaining_type_r == COMMAND_RD) begin
				if (cmd_tag_r == cmd_remaining_tag_r) begin
					fsm_send_state_r			<= SEND_READ1;
					cmd_len_r					<= cmd_rd_pkt_len_r;
					cmd_remaining_r				<= cmd_remaining_r - cmd_rd_pkt_len_r;
					cmd_tag_completed_r			<= 0;
				end
				if (cmd_tag_completed_r) begin
					cmd_tag_r					<= cmd_remaining_tag_r;
				end
			end
			else begin
				cmd_remaining_type_r		<= COMMAND_NOP;
				fsm_send_state_r			<= SEND_IDLE;
			end
			s_axis_tx_tvalid_r				<= 0;
			s_axis_tx_tlast_r				<= 0;
		end
		SEND_INTR1: begin
			if (intr_enabled) begin
				fsm_send_state_r			<= cfg_interrupt_msienable	? SEND_INTR_MSI1 : SEND_INTR_LEGACY1;
			end
			else begin
				fsm_send_state_r			<= SEND_INTR1;
			end
		end
		SEND_INTR_MSI1: begin
			if (cfg_interrupt_r && cfg_interrupt_rdy) begin
				fsm_send_state_r			<= SEND_IDLE;
				cmd_remaining_type_r		<= COMMAND_NOP;
				cfg_interrupt_r				<= 0;
			end
			else begin
				cfg_interrupt_r				<= 1;
				cfg_interrupt_assert_r		<= 1;
				cfg_interrupt_di_r			<= cmd_remaining_r	== COMMAND_WR ? INTR_WR_DONE :
											   cmd_remaining_r	== COMMAND_RD ? INTR_RD_DONE : 0;
			end
		end
		SEND_INTR_LEGACY1: begin
			if (cfg_interrupt_r && cfg_interrupt_rdy) begin
				fsm_send_state_r			<= SEND_INTR_LEGACY2;
				cfg_interrupt_r				<= 0;
				cfg_interrupt_assert_r		<= 1;
			end
			else begin
				cfg_interrupt_r				<= 1;
				cfg_interrupt_assert_r		<= 1;
			end
		end
		SEND_INTR_LEGACY2: begin
			if (!intr_enabled) begin
				fsm_send_state_r			<= SEND_INTR_LEGACY3;
				cfg_interrupt_r				<= 1;
				cfg_interrupt_assert_r		<= 0;
			end
			else begin
				cfg_interrupt_r				<= 0;
				cfg_interrupt_assert_r		<= 1;
			end
		end
		SEND_INTR_LEGACY3: begin
			if (cfg_interrupt_r && cfg_interrupt_rdy) begin
				fsm_send_state_r			<= SEND_IDLE;
				cmd_remaining_type_r		<= COMMAND_NOP;
				cfg_interrupt_r				<= 0;
				cfg_interrupt_assert_r		<= 0;
			end
			else begin
				cfg_interrupt_r				<= 1;
				cfg_interrupt_assert_r		<= 0;
			end
		end
		SEND_READ1: begin
			fsm_send_state_r				<= SEND_READ2;
			s_axis_tx_tdata_r[9:0]			<= cmd_len_r;
			s_axis_tx_tdata_r[23:10]		<= 'd0;
			s_axis_tx_tdata_r[28:24] 		<= 'b0_0000;
			s_axis_tx_tdata_r[31:29] 		<= DW3_NODATA;
			s_axis_tx_tdata_r[35:32] 		<= 'hF;
			s_axis_tx_tdata_r[39:36] 		<= cmd_len_r == 1 ? 'h0 : 'hF;
			s_axis_tx_tdata_r[47:40] 		<= cmd_remaining_tag_r;
			s_axis_tx_tdata_r[63:48] 		<= dma_requester_id;
			s_axis_tx_tkeep_r				<= 'hFF;
			s_axis_tx_tvalid_r				<= 1;
			command_clear_r					<= 0;
			cmd_stat_update_r				<= 0;
		end
		SEND_READ2: begin
			if (s_axis_tx_tvalid_r && s_axis_tx_tready) begin
				fsm_send_state_r			<= SEND_READ3;
				s_axis_tx_tdata_r[1:0]		<= 'd0;
				s_axis_tx_tdata_r[63:2]		<= cmd_remaining_addr_r[63:2];
				cmd_remaining_addr_r		<= cmd_remaining_addr_r + (cmd_len_r * 4);
				s_axis_tx_tkeep_r			<= 'h0F;
				s_axis_tx_tlast_r			<= 1;
			end
			s_axis_tx_tvalid_r				<= 1;
			command_clear_r					<= 0;
			cmd_stat_update_r				<= 0;
		end
		SEND_READ3: begin
			if (s_axis_tx_tvalid_r && s_axis_tx_tready) begin
				fsm_send_state_r			<= cmd_remaining_r	== 0 	? SEND_STALL_READ : SEND_ISSUE;
				s_axis_tx_tvalid_r			<= 0;
				s_axis_tx_tlast_r			<= 0;
			end
			else begin
				s_axis_tx_tvalid_r			<= 1;
			end
			command_clear_r					<= 0;
			cmd_stat_update_r				<= 0;
		end
		SEND_STALL_READ: begin
			if (tag_dw_count_r == cmd_tag_req_len_r) begin
				fsm_send_state_r			<= SEND_INTR1;
				cmd_tag_completed_r			<= 1;
			end
		end
		SEND_WRITE0: begin
			if ((available_bytes_r / 4) >= cmd_wr_pkt_len_r) begin
				fsm_send_state_r			<= SEND_WRITE1;
				cmd_len_r					<= cmd_wr_pkt_len_r;
				cmd_sent_r					<= cmd_sent_r + cmd_wr_pkt_len_r * 4;
				cmd_remaining_r				<= cmd_remaining_r - cmd_wr_pkt_len_r;
			end
			else if (send_buff_programmed_stop) begin
				fsm_send_state_r			<= SEND_WRITE1;
				cmd_len_r					<= available_bytes_r >= 4 ? available_bytes_r / 4 : 1;
				cmd_sent_r					<= cmd_sent_r + available_bytes_r;
				cmd_remaining_r				<= 0;
			end
			else if (flush_early_r) begin
				fsm_send_state_r			<= SEND_WRITE1;
				cmd_len_r					<= available_bytes_r > 4 ? available_bytes_r / 4 : 1;
				cmd_sent_r					<= cmd_sent_r + available_bytes_r;
				cmd_remaining_r				<= abandon_cmd_r ? 0 : cmd_remaining_r - (available_bytes_r / 4);
			end
			else begin
				fsm_send_state_r			<= SEND_WRITE0;
			end
		end
		SEND_WRITE1: begin
			fsm_send_state_r				<= SEND_WRITE2;
			s_axis_tx_tdata_r[9:0]			<= cmd_len_r;
			s_axis_tx_tdata_r[23:10]		<= 'd0;
			s_axis_tx_tdata_r[28:24] 		<= 'b0_0000;
			s_axis_tx_tdata_r[31:29] 		<= DW3_DATA;
			s_axis_tx_tdata_r[35:32] 		<= 'hF;
			s_axis_tx_tdata_r[39:36] 		<= cmd_len_r == 1 ? 'h0 : 'hF;
			s_axis_tx_tdata_r[47:40] 		<= 'd0;
			s_axis_tx_tdata_r[63:48] 		<= dma_requester_id;
			s_axis_tx_tkeep_r				<= 'hFF;
			s_axis_tx_tvalid_r				<= 1;
			command_clear_r					<= 0;
			cmd_stat_update_r				<= 0;
		end
		SEND_WRITE2: begin
			if (s_axis_tx_tvalid_r && s_axis_tx_tready) begin
				fsm_send_state_r			<= cmd_len_r == 1 ? SEND_DATA2 : SEND_DATA1;
				s_axis_tx_tdata_r[1:0]		<= 'd0;
				s_axis_tx_tdata_r[31:2]		<= cmd_remaining_addr_r[31:2];
				cmd_remaining_addr_r		<= cmd_remaining_addr_r + (cmd_len_r * 4);
				s_axis_tx_tdata_r[63:32]	<= send_buff_upper_half_data;
				s_axis_tx_tkeep_r			<= 'hFF;
				s_axis_tx_tlast_r			<= cmd_len_r == 1 ? 1 : 0;
				cmd_len_r					<= cmd_len_r - 1;
			end
			s_axis_tx_tvalid_r				<= 1;
			command_clear_r					<= 0;
			cmd_stat_update_r				<= 0;
		end
		SEND_DATA1: begin
			if (s_axis_tx_tvalid_r && s_axis_tx_tready) begin
				fsm_send_state_r			<= (cmd_len_r != 2 && cmd_len_r != 1)	? SEND_DATA1 :
											   (cmd_remaining_r == 0) 				? SEND_DATA2 : SEND_ISSUE;
				s_axis_tx_tdata_r[31:0]		<= cmd_len_r != 1	? send_buff_tdata[63:32] : send_buff_upper_half_data;
				s_axis_tx_tdata_r[63:32]	<= send_buff_tdata[31:0];
				s_axis_tx_tkeep_r			<= cmd_len_r != 1	? 'hFF : 'h0F;
				s_axis_tx_tlast_r			<= (cmd_len_r != 2 && cmd_len_r != 1) 	? 0 : 1;
				cmd_len_r 					<= cmd_len_r - 2;
			end
			s_axis_tx_tvalid_r				<= 1;
			command_clear_r					<= 0;
			cmd_stat_update_r				<= 0;
		end
		SEND_DATA2: begin
			if (s_axis_tx_tvalid_r && s_axis_tx_tready) begin
				fsm_send_state_r			<= SEND_TXN_REG1;
				s_axis_tx_tvalid_r			<= 0;
				s_axis_tx_tlast_r			<= 0;
				cmd_stat_update_r			<= 1;
				cmd_stat_idx_r				<= TXN_STATUS_REG;
				cmd_stat_data_r				<= {<<8{16'b0, cmd_sent_r}};
			end
			command_clear_r					<= 0;
		end
		SEND_TXN_REG1: begin
			fsm_send_state_r				<= SEND_TXN_REG2;
			s_axis_tx_tdata_r[9:0]			<= 'd1;
			s_axis_tx_tdata_r[23:10]		<= 'd0;
			s_axis_tx_tdata_r[28:24] 		<= 'b0_0000;
			s_axis_tx_tdata_r[31:29] 		<= DW3_DATA;
			s_axis_tx_tdata_r[35:32] 		<= 'hF;
			s_axis_tx_tdata_r[39:36] 		<= 'h0;
			s_axis_tx_tdata_r[47:40] 		<= 'd0;
			s_axis_tx_tdata_r[63:48] 		<= dma_requester_id;
			s_axis_tx_tkeep_r				<= 'hFF;
			s_axis_tx_tvalid_r				<= 1;
			command_clear_r					<= 0;
			cmd_stat_update_r				<= 0;
		end
		SEND_TXN_REG2: begin
			if (s_axis_tx_tvalid_r && s_axis_tx_tready) begin
				fsm_send_state_r			<= SEND_TXN_REG3;
				s_axis_tx_tdata_r[1:0]		<= 'd0;
				s_axis_tx_tdata_r[31:2]		<= command_controls_r[TXN_STATUS_LO_ADDR][31:2];
				s_axis_tx_tdata_r[63:32]	<= command_controls_r[TXN_STATUS_REG];
				s_axis_tx_tkeep_r			<= 'hFF;
				s_axis_tx_tlast_r			<= 'd1;
			end
			s_axis_tx_tvalid_r				<= 1;
			command_clear_r					<= 0;
			cmd_stat_update_r				<= 0;
		end
		SEND_TXN_REG3: begin
			if (s_axis_tx_tvalid_r && s_axis_tx_tready) begin
				fsm_send_state_r			<= SEND_INTR1;
				s_axis_tx_tvalid_r			<= 0;
				s_axis_tx_tlast_r			<= 0;
			end
		end
		endcase
	end
end

assign app_reset							= user_reset || !user_lnk_up;
assign m_axis_rx_tready 					= m_axis_rx_tready_r;
assign pkt_len 								= tlp_dw[0][9:0];
assign pkt_type		 						= tlp_dw[0][28:24];
assign pkt_fmt		 						= tlp_dw[0][31:29];
assign pkt_requester_id  					= tlp_dw[1][31:16];
assign pkt_tag 								= tlp_dw[1][15:8];
assign pkt_first_wd_be						= tlp_dw[1][3:0];
assign pkt_last_wd_be						= tlp_dw[1][7:4];
assign pkt_is_MRd		 					= (pkt_fmt == DW3_NODATA || pkt_fmt == DW3_NODATA) && pkt_type == 'b0_0000;
assign pkt_is_MWr		 					= (pkt_fmt == DW3_DATA || pkt_fmt == DW3_DATA) && pkt_type == 'b0_0000;
assign pkt_is_IORd		 					= pkt_fmt == DW3_NODATA && pkt_type == 'b0_0010;
assign pkt_is_IOWr		 					= pkt_fmt == DW4_NODATA && pkt_type == 'b0_0010;
assign pkt_valid_bytes						= m_axis_rx_tkeep == 'hF0 ?	'd4 :
											  m_axis_rx_tkeep == 'h0F ?	'd4 :
											  m_axis_rx_tkeep == 'hFF ?	'd8 : 'd0;
assign cmd_tlast							= command_controls_r[CMD_EXEC_REG][COMMAND_LAST_BIT];
assign cmd_type								= command_controls_r[CMD_EXEC_REG][1:0];
assign cmd_len								= command_controls_r[CMD_EXEC_REG][31:16] / 4;
assign cmd_bar_hit							= pkt_bar_id_r == 'd0;
assign s_axis_tx_tdata						= s_axis_tx_tdata_r;
assign s_axis_tx_tkeep						= s_axis_tx_tkeep_r;
assign s_axis_tx_tlast						= s_axis_tx_tlast_r;
assign s_axis_tx_tvalid						= s_axis_tx_tvalid_r;
assign tx_src_dsc							= 'b0;
assign cfg_turnoff_ok						= 'b1;
assign rx_bar_hit							= m_axis_rx_tuser[9:2];
assign cfg_max_rd_size						= (1 << (cfg_dcommand[14:12] + 'd5));
assign cfg_max_wr_size						= (1 << (cfg_dcommand[7:5] 	 + 'd5));
assign cfg_interrupt						= cfg_interrupt_r;
assign cfg_interrupt_assert					= cfg_interrupt_assert_r;
assign cfg_interrupt_di						= cfg_interrupt_di_r;
assign s_axis_instr_mem_tdata				= {pkt_a_din, pkt_b_din};
assign s_axis_instr_mem_tvalid				= (pkt_a_wr_en || pkt_b_wr_en) && (!cmd_bar_hit);
assign s_axis_instr_mem_tkeep				= {{4{pkt_a_wr_en}}, {4{pkt_b_wr_en}}};
assign s_axis_instr_mem_tlast				= tag_tlast_r;
assign softmc_h2c_tdata 					= m_axis_instr_mem_tdata;
assign softmc_h2c_tvalid 					= m_axis_instr_mem_tvalid;
assign softmc_h2c_tlast						= m_axis_instr_mem_tlast;
assign m_axis_instr_mem_tready 				= softmc_h2c_tready;
assign cmd_wr_pkt_len						= cmd_remaining_r > cfg_max_wr_size 	? cfg_max_wr_size : cmd_remaining_r;
assign cmd_rd_pkt_len						= cmd_remaining_r > cfg_max_rd_size 	? cfg_max_rd_size : cmd_remaining_r;
assign send_buff_full_data_count			= send_buff_half_data_count / 2;
assign send_buff_tready 					= send_buff_tready_r;
assign send_buff_upper_half_ready 			= send_buff_upper_half_ready_r;
assign bus_master_enabled					= cfg_command[2];
assign intr_enabled							= ~cfg_command[10];
assign pci_cfg_dwaddr						= 0;
assign pci_cfg_rd_en						= 0;

pcie_txn_buffer #(
	.C_IN_DATA_WIDTH(`SOFTMC_STREAM_WIDTH),
	.C_OUT_DATA_WIDTH(C_DATA_WIDTH)
) send_buff (
    .clk(user_clk),
    .reset(app_reset),
    .s_axis_tdata(softmc_c2h_tdata),
    .s_axis_tkeep('hFFFFFFFFFFFFFFFF),
    .s_axis_tvalid(softmc_c2h_tvalid),
    .s_axis_tready(softmc_c2h_tready),
    .s_axis_tlast(softmc_c2h_tlast),
    .m_axis_tdata(send_buff_tdata),
    .m_axis_tkeep(send_buff_tkeep),
    .m_axis_tvalid(send_buff_tvalid),
    .m_axis_tready(send_buff_tready),
    .m_axis_upper_half_data(send_buff_upper_half_data),
    .m_axis_upper_half_keep(send_buff_upper_half_keep),
    .m_axis_upper_half_valid(send_buff_upper_half_valid),
    .m_axis_upper_half_ready(send_buff_upper_half_ready),
    .data_count(send_buff_half_data_count),
    .programmed_stop(send_buff_programmed_stop)
);

instruction_buffer #(
	.C_DATA_WIDTH(C_DATA_WIDTH),
	.FIFO_WIDTH(`SOFTMC_STREAM_WIDTH)
) instr_buff (
	.clk(user_clk),
	.reset(app_reset),
	.s_axis_tdata(s_axis_instr_mem_tdata),
	.s_axis_tvalid(s_axis_instr_mem_tvalid),
	.s_axis_tready(s_axis_instr_mem_tready),
	.s_axis_tkeep(s_axis_instr_mem_tkeep),
	.s_axis_tlast(s_axis_instr_mem_tlast),
	.m_axis_tdata(m_axis_instr_mem_tdata),
	.m_axis_tvalid(m_axis_instr_mem_tvalid),
	.m_axis_tready(m_axis_instr_mem_tready),
	.m_axis_tlast(m_axis_instr_mem_tlast)
);

// ila_app debug_app (
// 	.clk(user_clk),
// 	.probe0(cmd_rd_is_last_r),					  
// 	.probe1(app_reset), 			 
// 	.probe2(cfg_interrupt_rdy),				 
// 	.probe3(intr_enabled), 					 
// 	.probe4(fsm_recv_state_r), 				 
// 	.probe5(fsm_send_state_r), 				
// 	.probe6(command_controls_r[CMD_EXEC_REG]),
// 	.probe7(tag_tlast_r),			
// 	.probe8(cmd_sent_r),			
// 	.probe9(command_controls_r[TXN_STATUS_REG]),				
// 	.probe10(available_bytes_r)				
// );

// ila_instr_fifo debug_instr_fifo (
// 	.clk(user_clk), // input wire clk
// 	.probe0(s_axis_instr_mem_tlast), // input wire [0:0]  probe0  
// 	.probe1(s_axis_instr_mem_tdata), // input wire [63:0]  probe1 
// 	.probe2(s_axis_instr_mem_tvalid), // input wire [0:0]  probe2 
// 	.probe3(s_axis_instr_mem_tready), // input wire [0:0]  probe3 
// 	.probe4(s_axis_instr_mem_tkeep), // input wire [7:0]  probe4 
// 	.probe5(m_axis_instr_mem_tdata), // input wire [255:0]  probe5 
// 	.probe6(m_axis_instr_mem_tvalid), // input wire [0:0]  probe6 
// 	.probe7(m_axis_instr_mem_tready), // input wire [0:0]  probe7
// 	.probe8(m_axis_instr_mem_tlast) // input wire [0:0]  probe8
// );

endmodule