`timescale 1ns / 1ps

module pcie_txn_buffer #(
	parameter C_IN_DATA_WIDTH = 256,
	parameter C_OUT_DATA_WIDTH = 64,

	localparam C_IN_KEEP = C_IN_DATA_WIDTH / 8,
	localparam C_OUT_KEEP = C_OUT_DATA_WIDTH / 8,
	localparam FIFO_DEPTH = 1024,
	localparam C_IO_WIDTH_RATIO = C_IN_DATA_WIDTH / C_OUT_DATA_WIDTH,
	localparam DATA_COUNT_WIDTH =  $clog2(FIFO_DEPTH * C_IO_WIDTH_RATIO) + 1,
	localparam C_RATIO_WIDTH = C_IO_WIDTH_RATIO,
	localparam C_HALF_RATIO_WIDTH = 2 * C_IO_WIDTH_RATIO
)(
	input                               clk,
	input                               reset,

	input   [C_IN_DATA_WIDTH-1:0]       s_axis_tdata,
	input   [C_IN_KEEP-1:0]             s_axis_tkeep,
	input                               s_axis_tvalid,
	output                              s_axis_tready,
	input								s_axis_tlast,

	output  [C_OUT_DATA_WIDTH-1:0]		m_axis_tdata,
	output  [C_OUT_DATA_WIDTH/2-1:0]    m_axis_upper_half_data,
	output 	[C_OUT_KEEP-1:0]			m_axis_tkeep,
	output  [C_OUT_KEEP/2-1:0]         	m_axis_upper_half_keep,
	output								m_axis_tvalid,
	output								m_axis_upper_half_valid,
	input								m_axis_tready,
	input								m_axis_upper_half_ready,

	output 	[DATA_COUNT_WIDTH-1:0]		data_count,
	output								programmed_stop
);

// Combinational Outputs
reg  	[C_OUT_DATA_WIDTH-1:0]		m_axis_tdata_r;
reg 	[C_OUT_KEEP-1:0]			m_axis_tkeep_r;
reg									m_axis_tvalid_r;
reg									m_axis_upper_half_valid_r;

reg									user_stop_flag_r;
reg									user_stop_flag_ns;

// Fall Through Registers
reg		[C_IN_DATA_WIDTH-1:0]		ft_data_r;
reg		[C_IN_KEEP-1:0]				ft_keep_r;
reg		[C_HALF_RATIO_WIDTH-1:0]	ft_valid_r;
reg 	[DATA_COUNT_WIDTH-1:0] 		ft_half_data_count_r;

reg		[C_IN_DATA_WIDTH-1:0]		ft_data_ns;
reg		[C_IN_KEEP-1:0]				ft_keep_ns;
reg		[C_HALF_RATIO_WIDTH-1:0] 	ft_valid_ns;
reg 	[DATA_COUNT_WIDTH-1:0] 		ft_half_data_count_ns;

wire	[C_IN_DATA_WIDTH-1:0]		fifo_tdata;
wire	[C_IN_KEEP-1:0]				fifo_tkeep;
wire 	 							fifo_tvalid;
reg 	 							fifo_tready_r;
wire	[9:0]						fifo_data_count;

generate
	if (C_IN_DATA_WIDTH == C_OUT_DATA_WIDTH) begin
		always @(*) begin
			ft_half_data_count_ns = ft_half_data_count_r;
			fifo_tready_r = 0;
			user_stop_flag_ns = (user_stop_flag_r || s_axis_tlast) && !s_axis_tvalid;
			ft_data_ns = ft_data_r;
			ft_keep_ns = ft_keep_r;
			ft_valid_ns = ft_valid_r;
			m_axis_tdata_r = ft_data_r[C_IN_DATA_WIDTH-1 -: C_OUT_DATA_WIDTH];
			m_axis_tkeep_r = ft_keep_r[C_IN_KEEP-1 -: C_OUT_KEEP];
			m_axis_tvalid_r = (ft_valid_r[C_HALF_RATIO_WIDTH-2] || fifo_tvalid) && ft_valid_r[C_HALF_RATIO_WIDTH-1];
			m_axis_upper_half_valid_r = ft_valid_r[C_HALF_RATIO_WIDTH-1];
			if (!ft_valid_r[C_HALF_RATIO_WIDTH-1] && fifo_tvalid) begin
				fifo_tready_r = 1;
				m_axis_tdata_r = fifo_tdata;
				m_axis_tkeep_r = fifo_tkeep;
				m_axis_tvalid_r = 1;
				m_axis_upper_half_valid_r = 1;
				if (m_axis_tready) begin
					ft_data_ns = fifo_tdata << C_OUT_DATA_WIDTH;
					ft_keep_ns = fifo_tkeep << C_OUT_KEEP;
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}} << 2;
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH - 2;
				end
				else if (m_axis_upper_half_ready) begin
					ft_data_ns = fifo_tdata << (C_OUT_DATA_WIDTH / 2);
					ft_keep_ns = fifo_tkeep << (C_OUT_KEEP / 2);
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}} << 1;
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH - 1;
				end
				else begin
					ft_data_ns = fifo_tdata;
					ft_keep_ns = fifo_tkeep;
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}};
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH;
				end
			end
			else if (!ft_valid_r[C_HALF_RATIO_WIDTH-2] && fifo_tvalid) begin
				m_axis_tdata_r = {ft_data_r[C_IN_DATA_WIDTH-1 -: C_OUT_DATA_WIDTH/2], fifo_tdata[C_IN_DATA_WIDTH-1 -: C_OUT_DATA_WIDTH/2]};
				m_axis_tkeep_r = {ft_keep_r[C_IN_KEEP-1 -: C_OUT_KEEP/2], fifo_tkeep[C_IN_KEEP-1 -: C_OUT_KEEP/2]};
				if (m_axis_tready) begin
					fifo_tready_r = 1;
					ft_data_ns = fifo_tdata << (C_OUT_DATA_WIDTH / 2);
					ft_keep_ns = fifo_tkeep << (C_OUT_KEEP / 2);
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}} << 1;
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH - 1;
				end
				else if (m_axis_upper_half_ready) begin
					fifo_tready_r = 1;
					ft_data_ns = fifo_tdata;
					ft_keep_ns = fifo_tkeep;
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}};
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH;
				end
			end
			else if (m_axis_tready) begin
				fifo_tready_r = 1;
				ft_data_ns = fifo_tdata;
				ft_keep_ns = fifo_tkeep;
				ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}};
				ft_half_data_count_ns = C_HALF_RATIO_WIDTH;
			end
			else if (m_axis_upper_half_ready) begin
				ft_data_ns = ft_data_r << (C_OUT_DATA_WIDTH / 2);
				ft_keep_ns = ft_keep_r << (C_OUT_KEEP / 2);
				ft_valid_ns = ft_valid_r << 1;
				ft_half_data_count_ns = C_HALF_RATIO_WIDTH - 1;
			end
		end
	end
	else begin
		always @(*) begin
			ft_half_data_count_ns = ft_half_data_count_r;
			fifo_tready_r = 0;
			user_stop_flag_ns = (user_stop_flag_r || s_axis_tlast) && !s_axis_tvalid;
			ft_data_ns = ft_data_r;
			ft_keep_ns = ft_keep_r;
			ft_valid_ns = ft_valid_r;
			m_axis_tdata_r = ft_data_r[C_IN_DATA_WIDTH-1 -: C_OUT_DATA_WIDTH];
			m_axis_tkeep_r = ft_keep_r[C_IN_KEEP-1 -: C_OUT_KEEP];
			m_axis_tvalid_r = (ft_valid_r[C_HALF_RATIO_WIDTH-2] || fifo_tvalid) && ft_valid_r[C_HALF_RATIO_WIDTH-1];
			m_axis_upper_half_valid_r = ft_valid_r[C_HALF_RATIO_WIDTH-1];
			if (!ft_valid_r[C_HALF_RATIO_WIDTH-1] && fifo_tvalid) begin
				fifo_tready_r = 1;
				m_axis_tdata_r = fifo_tdata;
				m_axis_tkeep_r = fifo_tkeep;
				m_axis_tvalid_r = 1;
				m_axis_upper_half_valid_r = 1;
				if (m_axis_tready) begin
					ft_data_ns = fifo_tdata << C_OUT_DATA_WIDTH;
					ft_keep_ns = fifo_tkeep << C_OUT_KEEP;
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}} << 2;
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH - 2;
				end
				else if (m_axis_upper_half_ready) begin
					ft_data_ns = fifo_tdata << (C_OUT_DATA_WIDTH / 2);
					ft_keep_ns = fifo_tkeep << (C_OUT_KEEP / 2);
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}} << 1;
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH - 1;
				end
				else begin
					ft_data_ns = fifo_tdata;
					ft_keep_ns = fifo_tkeep;
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}};
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH;
				end
			end
			else if (!ft_valid_r[C_HALF_RATIO_WIDTH-2] && fifo_tvalid) begin
				m_axis_tdata_r = {ft_data_r[C_IN_DATA_WIDTH-1 -: C_OUT_DATA_WIDTH/2], fifo_tdata[C_IN_DATA_WIDTH-1 -: C_OUT_DATA_WIDTH/2]};
				m_axis_tkeep_r = {ft_keep_r[C_IN_KEEP-1 -: C_OUT_KEEP/2], fifo_tkeep[C_IN_KEEP-1 -: C_OUT_KEEP/2]};
				if (m_axis_tready) begin
					fifo_tready_r = 1;
					ft_data_ns = fifo_tdata << (C_OUT_DATA_WIDTH / 2);
					ft_keep_ns = fifo_tkeep << (C_OUT_KEEP / 2);
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}} << 1;
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH - 1;
				end
				else if (m_axis_upper_half_ready) begin
					fifo_tready_r = 1;
					ft_data_ns = fifo_tdata;
					ft_keep_ns = fifo_tkeep;
					ft_valid_ns = {C_HALF_RATIO_WIDTH{1'b1}};
					ft_half_data_count_ns = C_HALF_RATIO_WIDTH;
				end
			end
			else if (m_axis_tready && m_axis_tvalid_r) begin
				ft_data_ns = ft_data_r << C_OUT_DATA_WIDTH;
				ft_keep_ns = ft_keep_r << C_OUT_KEEP;
				ft_valid_ns = ft_valid_r << 2;
				ft_half_data_count_ns = ft_half_data_count_r - 2;
			end
			else if (m_axis_upper_half_ready && m_axis_upper_half_valid_r) begin
				ft_data_ns = ft_data_r << (C_OUT_DATA_WIDTH / 2);
				ft_keep_ns = ft_keep_r << (C_OUT_KEEP / 2);
				ft_valid_ns = ft_valid_r << 1;
				ft_half_data_count_ns = ft_half_data_count_r - 1;
			end
		end
	end
endgenerate

always @(posedge clk) begin
	if (reset) begin
		ft_data_r <= 0;
		ft_keep_r <= 0;
		ft_valid_r <= 0;
		user_stop_flag_r <= 0;
		ft_half_data_count_r <= 0;
	end
	else begin
		ft_data_r <= ft_data_ns;
		ft_keep_r <= ft_keep_ns;
		ft_valid_r <= ft_valid_ns;
		user_stop_flag_r <= user_stop_flag_ns;
		ft_half_data_count_r <= ft_half_data_count_ns;
	end
end

assign data_count = (fifo_data_count > 0 	? fifo_data_count * C_IO_WIDTH_RATIO * 2 	:
					fifo_tvalid 			? FIFO_DEPTH * C_IO_WIDTH_RATIO * 2 		: 0) + ft_half_data_count_r;

assign programmed_stop = user_stop_flag_r && fifo_data_count == 0;
assign m_axis_tdata = m_axis_tdata_r;
assign m_axis_tkeep = m_axis_tkeep_r;
assign m_axis_tvalid = m_axis_tvalid_r;
assign m_axis_upper_half_data = m_axis_tdata_r[C_OUT_DATA_WIDTH/2 +: C_OUT_DATA_WIDTH/2];
assign m_axis_upper_half_keep = m_axis_tkeep_r[C_OUT_KEEP/2 +: C_OUT_KEEP/2];
assign m_axis_upper_half_valid = m_axis_upper_half_valid_r;

data_fifo pcie_buffer (
  .wr_rst_busy( ),      // output wire wr_rst_busy
  .rd_rst_busy( ),      // output wire rd_rst_busy
  .s_aclk(clk),                // input wire s_aclk
  .s_aresetn(~reset),          // input wire s_aresetn
  .s_axis_tvalid(s_axis_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(s_axis_tready),  // output wire s_axis_tready
  .s_axis_tdata(s_axis_tdata),    // input wire [127 : 0] s_axis_tdata
  .s_axis_tkeep(s_axis_tkeep),    // input wire [15 : 0] s_axis_tkeep
  .m_axis_tvalid(fifo_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(fifo_tready_r),  // input wire m_axis_tready
  .m_axis_tdata(fifo_tdata),    // output wire [127 : 0] m_axis_tdata
  .m_axis_tkeep(fifo_tkeep),    // output wire [15 : 0] m_axis_tkeep
  .axis_data_count(fifo_data_count)
);

endmodule