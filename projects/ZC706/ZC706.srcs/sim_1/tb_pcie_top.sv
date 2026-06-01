`timescale 1ns / 1ps

module tb_pcie_top();

localparam SOFTMC_STREAM_WIDTH = 256;
localparam C_DATA_WIDTH = 64;
localparam C_ADDR_WIDTH = 64;
localparam KEEP_WIDTH = C_DATA_WIDTH / 8;

reg                     			user_clk;
reg                     			user_reset;
reg                     			user_lnk_up;

reg 	[7:0]						cfg_bus_number;
reg 	[4:0]						cfg_device_number;
reg 	[2:0]						cfg_function_number;
wire								cfg_interrupt;
wire								cfg_interrupt_assert;
reg									cfg_interrupt_rdy;
wire	[7:0]						cfg_interrupt_di;
reg									cfg_interrupt_msienable;
					
wire                     			m_axis_rx_tready;
reg 	[C_DATA_WIDTH-1:0]			m_axis_rx_tdata;
reg 	[KEEP_WIDTH-1:0]  			m_axis_rx_tkeep;
reg                     			m_axis_rx_tlast;
reg                     			m_axis_rx_tvalid;
reg		[21:0]						m_axis_rx_tuser;
reg                     			tx_src_dsc;
					
wire	[C_DATA_WIDTH-1:0]			s_axis_tx_tdata;
wire	[KEEP_WIDTH-1:0]  			s_axis_tx_tkeep;
wire                    			s_axis_tx_tlast;
wire                    			s_axis_tx_tvalid;
reg                   				s_axis_tx_tready;

reg                     			cfg_to_turnoff;
wire                    			cfg_turnoff_ok;
reg		[15:0]            			cfg_completer_id;

wire	[9:0]						pci_cfg_dwaddr;
wire								pci_cfg_rd_en;
wire	[31:0]						pci_cfg_dout;
wire								pci_cfg_rd_wr_done;

wire	[15:0]						cfg_dcommand;
reg		[15:0]						cfg_command;
 
wire	[SOFTMC_STREAM_WIDTH-1:0]	softmc_h2c_tdata;
wire								softmc_h2c_tvalid;
reg									softmc_h2c_tready;
wire								softmc_h2c_tlast;

reg		[SOFTMC_STREAM_WIDTH-1:0]   softmc_c2h_tdata;
reg									softmc_c2h_tvalid;
wire								softmc_c2h_tready;
reg									softmc_c2h_tlast;

pcie_app_softmc uut(
	.user_clk(user_clk),
    .user_reset(user_reset),
    .user_lnk_up(user_lnk_up),

	.softmc_h2c_tdata(softmc_h2c_tdata),
	.softmc_h2c_tvalid(softmc_h2c_tvalid),
	.softmc_h2c_tready(softmc_h2c_tready),
	.softmc_h2c_tlast(softmc_h2c_tlast),

	.softmc_c2h_tdata(softmc_c2h_tdata),
	.softmc_c2h_tvalid(softmc_c2h_tvalid),
	.softmc_c2h_tready(softmc_c2h_tready),
	.softmc_c2h_tlast(softmc_c2h_tlast),

	.cfg_bus_number(cfg_bus_number),
	.cfg_device_number(cfg_device_number),
	.cfg_function_number(cfg_function_number),
	.cfg_interrupt(cfg_interrupt),	
	.cfg_interrupt_assert(cfg_interrupt_assert),	
	.cfg_interrupt_rdy(cfg_interrupt_rdy),
	.cfg_interrupt_di(cfg_interrupt_di),
	.cfg_interrupt_msienable(cfg_interrupt_msienable),

	.cfg_dcommand(cfg_dcommand),
	.cfg_command(cfg_command),
	
	.pci_cfg_dwaddr(pci_cfg_dwaddr),
	.pci_cfg_rd_en(pci_cfg_rd_en),
	.pci_cfg_dout(pci_cfg_dout),
	.pci_cfg_rd_wr_done(pci_cfg_rd_wr_done),
	
    .m_axis_rx_tready(m_axis_rx_tready),
    .m_axis_rx_tdata(m_axis_rx_tdata),
    .m_axis_rx_tkeep(m_axis_rx_tkeep),
    .m_axis_rx_tlast(m_axis_rx_tlast),
    .m_axis_rx_tvalid(m_axis_rx_tvalid),
    .m_axis_rx_tuser(m_axis_rx_tuser),
	
    .tx_src_dsc(tx_src_dsc),
	
    .s_axis_tx_tdata(s_axis_tx_tdata),
    .s_axis_tx_tkeep(s_axis_tx_tkeep),
    .s_axis_tx_tlast(s_axis_tx_tlast),
    .s_axis_tx_tvalid(s_axis_tx_tvalid),
    .s_axis_tx_tready(s_axis_tx_tready),
	
    .cfg_to_turnoff(cfg_to_turnoff),
    .cfg_turnoff_ok(cfg_turnoff_ok),
    .cfg_completer_id(cfg_completer_id)
);

always begin
	user_clk = 0;
	#5;
	user_clk = 1;
	#5;
end


// PCIe IP CFG Channel Simulation
localparam							READ_LATENCY	= 'd3;

reg									cfg_read_en;
reg									cfg_read_en_prev;
wire								cfg_read_en_spike;

reg		[31:0]						cfg_dout		[0:READ_LATENCY-1];
reg									cfg_rd_done		[0:READ_LATENCY-1];

assign cfg_read_en_spike 	=	cfg_read_en && !cfg_read_en_prev;
assign pci_cfg_dout			= 	cfg_dout[0];
assign pci_cfg_rd_wr_done	= 	cfg_rd_done[0];
assign cfg_dcommand			=	'b0000_0000_0000_0000;

integer j;
always @(posedge user_clk) begin
	cfg_read_en				<=	pci_cfg_rd_en;
	cfg_read_en_prev		<=	cfg_read_en;
	cfg_dout[READ_LATENCY-1]	<=	pci_cfg_dwaddr == 'h04 ? 'hf0100000 :
									pci_cfg_dwaddr == 'h05 ? 'hf0900000 : 'hffffffff;
	cfg_rd_done[READ_LATENCY-1] <=	cfg_read_en_spike;
	for(j = 0; j < READ_LATENCY - 1; j = j + 1) begin
		cfg_dout[j]			<=	cfg_dout[j+1];
		cfg_rd_done[j]		<=	cfg_rd_done[j+1];
	end
end

// c2h data generator
localparam c2h_cap = 1024 * 8 * 8 / SOFTMC_STREAM_WIDTH;
reg [31:0] c2h_count;
reg	[15:0] c2h_repeat;
always @(posedge user_clk) begin
	if (user_reset) begin
		softmc_c2h_tdata <= 0;
		softmc_c2h_tvalid <= 0;
		softmc_c2h_tlast <= 0;
		c2h_repeat <= 0;
		c2h_count <= 0;
	end
	else if (softmc_c2h_tready && softmc_c2h_tvalid) begin
		softmc_c2h_tdata <= {(SOFTMC_STREAM_WIDTH/16){c2h_repeat}};
		softmc_c2h_tvalid <= c2h_count < (c2h_cap - 1);
		softmc_c2h_tlast <= c2h_count == (c2h_cap - 2);
		c2h_repeat <= c2h_repeat + (c2h_count < (c2h_cap - 1) ? 1 : 0);
		c2h_count <= c2h_count + 1;
	end
	else if (!softmc_c2h_tvalid) begin
		softmc_c2h_tdata <= {(SOFTMC_STREAM_WIDTH/16){c2h_repeat}};
		softmc_c2h_tvalid <= c2h_count < (c2h_cap);
		softmc_c2h_tlast <= c2h_count == (c2h_cap - 1);
		c2h_repeat <= c2h_repeat + (c2h_count < (c2h_cap) ? 1 : 0);
	end
end

always @(posedge user_clk) begin
	if (cfg_interrupt) begin
		cfg_command <= 'b0000_0100_0000_0100;
	end
	else begin
		cfg_command <= 'b0000_0000_0000_0100;
	end
end

// TLPs
localparam CMD_LEN = 8;
localparam TEST_DATA_LEN = 10 + 2;  // 20 Data + 3 Header -> 12 in DW pacets

reg 	[C_DATA_WIDTH-1:0]			tb_dw_queue			[0:CMD_LEN-1];
reg 	[KEEP_WIDTH-1:0]			tb_keep_queue		[0:CMD_LEN-1];
reg 								tb_tlast_queue		[0:CMD_LEN-1];
reg		[21:0]						tb_user_queue		[0:CMD_LEN-1];

reg		[C_DATA_WIDTH-1:0]			tb_cmp_queue		[0:TEST_DATA_LEN-1];
reg 	[KEEP_WIDTH-1:0]			tb_cmp_keep_queue	[0:TEST_DATA_LEN-1];
reg 								tb_cmp_tlast_queue	[0:TEST_DATA_LEN-1];
reg		[21:0]						tb_cmp_user_queue	[0:TEST_DATA_LEN-1];

integer i;
reg	[7:0] data_repeat;
initial begin
	softmc_h2c_tready = 0;

	tb_cmp_queue		['h00]	= 'h0000000f_4a000014;
	tb_cmp_keep_queue	['h00]	= 'hff;
	tb_cmp_tlast_queue	['h00]	= 'h0;
	tb_cmp_user_queue	['h00]	= 'b00000000;
	tb_cmp_queue		['h01]	= 'h01010101_00000100;
	tb_cmp_keep_queue	['h01]	= 'hff;
	tb_cmp_tlast_queue	['h01]	= 'h0;
	tb_cmp_user_queue	['h01]	= 'b00000000;
	for (i = 0; i < 9; i = i + 1) begin
		data_repeat 					= 2 * i + 3;
		tb_cmp_queue ['h02 + i][63:32]  = {4{data_repeat}};
		data_repeat 					= 2 * i + 2;
		tb_cmp_queue  ['h02 + i][31:0] 	= {4{data_repeat}};
		tb_cmp_keep_queue	['h02 + i]	= 'hff;
		tb_cmp_tlast_queue	['h02 + i]	= 'h0;
		tb_cmp_user_queue	['h02 + i]	= 'b00000000;
	end
	tb_cmp_queue		['h0b]	= 'h00000000_14141414;
	tb_cmp_keep_queue	['h0b]	= 'h0f;
	tb_cmp_tlast_queue	['h0b]	= 'h1;
	tb_cmp_user_queue	['h0b]	= 'b00000000;

	tb_dw_queue		['h00]  = 'h0000000f_40000001;
	tb_keep_queue	['h00]	= 'hff;
	tb_tlast_queue	['h00]	= 'h0;
	tb_user_queue	['h00]	= 'b00000100;
	tb_dw_queue		['h01]	= 'h000001f8_f0100008;
	tb_keep_queue	['h01]	= 'hff;
	tb_tlast_queue	['h01]	= 'h1;
	tb_user_queue	['h01]	= 'b00000100;
	tb_dw_queue		['h02]  = 'h0000000f_40000001;
	tb_keep_queue	['h02]	= 'hff;
	tb_tlast_queue	['h02]	= 'h0;
	tb_user_queue	['h02]	= 'b00000100;
	tb_dw_queue		['h03]	= 'h01000000_f0100004;
	tb_keep_queue	['h03]	= 'hff;
	tb_tlast_queue	['h03]	= 'h1;
	tb_user_queue	['h03]	= 'b00000100;
	tb_dw_queue		['h04]  = 'h0000000f_40000001;
	tb_keep_queue	['h04]	= 'hff;
	tb_tlast_queue	['h04]	= 'h0;
	tb_user_queue	['h04]	= 'b00000100;
	tb_dw_queue		['h05]	= 'h09005000_f0100000;
	tb_keep_queue	['h05]	= 'hff;
	tb_tlast_queue	['h05]	= 'h1;
	tb_user_queue	['h05]	= 'b00000100;
	tb_dw_queue		['h06]  = 'h0000000f_40000001;
	tb_keep_queue	['h06]	= 'hff;
	tb_tlast_queue	['h06]	= 'h0;
	tb_user_queue	['h06]	= 'b00000100;
	tb_dw_queue		['h07]	= 'h000002f8_f0100014;
	tb_keep_queue	['h07]	= 'hff;
	tb_tlast_queue	['h07]	= 'h1;
	tb_user_queue	['h07]	= 'b00000100;
	
	cfg_interrupt_msienable	= 0;

	cfg_bus_number 			= 0;	
	cfg_device_number 		= 1;
	cfg_function_number 	= 0;
    cfg_interrupt_rdy		= 0;
	user_reset 				= 1;
    user_lnk_up				= 0;
    m_axis_rx_tvalid 		= 0;
	s_axis_tx_tready		= 0;
	#100;
	@(posedge user_clk) #1;
	user_reset = 0;
	user_lnk_up = 1;
	cfg_interrupt_rdy = 1;
	s_axis_tx_tready = 1;
	softmc_h2c_tready = 1;

	for (i = 0; i < CMD_LEN; ) begin
		m_axis_rx_tdata		= tb_dw_queue[i];
		m_axis_rx_tkeep 	= tb_keep_queue[i];
		m_axis_rx_tlast 	= tb_tlast_queue[i];
		m_axis_rx_tuser		= tb_user_queue[i];
		m_axis_rx_tvalid	= 1;
		if (m_axis_rx_tready && m_axis_rx_tvalid) begin
			i = i + 1;
		end
		@(posedge user_clk) #1;
	end
	m_axis_rx_tvalid        = 0;
	m_axis_rx_tlast			= 0;
	m_axis_rx_tkeep			= 0;

	wait(s_axis_tx_tlast);
	@(posedge user_clk) #1;
	for (i = 0; i < TEST_DATA_LEN; ) begin
		m_axis_rx_tdata		= tb_cmp_queue[i];
		m_axis_rx_tkeep 	= tb_cmp_keep_queue[i];
		m_axis_rx_tlast 	= tb_cmp_tlast_queue[i];
		m_axis_rx_tuser		= tb_cmp_user_queue[i];
		m_axis_rx_tvalid	= 1;
		if (m_axis_rx_tready && m_axis_rx_tvalid) begin
			i = i + 1;
		end
		@(posedge user_clk) #1;
	end
	m_axis_rx_tvalid        = 0;
	m_axis_rx_tlast			= 0;
	m_axis_rx_tkeep			= 0;

	wait(c2h_count == c2h_cap);
	tb_dw_queue		['h00]  = 'h0000000f_40000001;
	tb_keep_queue	['h00]	= 'hff;
	tb_tlast_queue	['h00]	= 'h0;
	tb_user_queue	['h00]	= 'b00000100;
	tb_dw_queue		['h01]	= 'h000002f8_f0100008;
	tb_keep_queue	['h01]	= 'hff;
	tb_tlast_queue	['h01]	= 'h1;
	tb_user_queue	['h01]	= 'b00000100;
	tb_dw_queue		['h02]  = 'h0000000f_40000001;
	tb_keep_queue	['h02]	= 'hff;
	tb_tlast_queue	['h02]	= 'h0;
	tb_user_queue	['h02]	= 'b00000100;
	tb_dw_queue		['h03]	= 'h01000000_f0100004;
	tb_keep_queue	['h03]	= 'hff;
	tb_tlast_queue	['h03]	= 'h1;
	tb_user_queue	['h03]	= 'b00000100;
	tb_dw_queue		['h04]  = 'h0000000f_40000001;
	tb_keep_queue	['h04]	= 'hff;
	tb_tlast_queue	['h04]	= 'h0;
	tb_user_queue	['h04]	= 'b00000100;
	tb_dw_queue		['h05]	= 'h03000020_f0100000;
	tb_keep_queue	['h05]	= 'hff;
	tb_tlast_queue	['h05]	= 'h1;
	tb_user_queue	['h05]	= 'b00000100;

	for (i = 0; i < CMD_LEN; ) begin
		m_axis_rx_tdata		= tb_dw_queue[i];
		m_axis_rx_tkeep 	= tb_keep_queue[i];
		m_axis_rx_tlast 	= tb_tlast_queue[i];
		m_axis_rx_tuser		= tb_user_queue[i];
		m_axis_rx_tvalid	= 1;
		if (m_axis_rx_tready && m_axis_rx_tvalid) begin
			i = i + 1;
		end
		@(posedge user_clk) #1;
	end
	m_axis_rx_tvalid        = 0;
	m_axis_rx_tlast			= 0;
	m_axis_rx_tkeep			= 0;
end

endmodule
