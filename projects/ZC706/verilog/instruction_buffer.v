`timescale 1ns / 1ps

module instruction_buffer #(
	parameter							C_DATA_WIDTH 	= 64,
	parameter							FIFO_WIDTH		= 256,
	localparam							KEEP_WIDTH		= C_DATA_WIDTH/8
)(
	input								clk,
	input								reset,
	
	input	[C_DATA_WIDTH-1:0]			s_axis_tdata,
	input								s_axis_tvalid,
	input	[KEEP_WIDTH-1:0]			s_axis_tkeep,
	output								s_axis_tready,
	input								s_axis_tlast,
		
	output	[FIFO_WIDTH-1:0]			m_axis_tdata,
	output								m_axis_tvalid,
	input								m_axis_tready,
	output								m_axis_tlast
);

localparam								FIFO_SCALE		= FIFO_WIDTH / C_DATA_WIDTH;
localparam								FIFO_BYTES		= FIFO_WIDTH / 8;
localparam								DATA_BYTES		= C_DATA_WIDTH / 8;

wire wr_rst_busy;
wire rd_rst_busy;

reg		[FIFO_WIDTH-1:0]				fifo_tdata_r;
reg										fifo_tvalid_r;
reg										fifo_tlast_r;
reg		[$clog2(FIFO_BYTES):0]			byte_counter_r;
reg 	[(C_DATA_WIDTH/2)-1:0]			overflow_buffer_r;
reg										overflow_flag_r;
reg										s_axis_tready_r;
	
reg		[FIFO_WIDTH-1:0]				fifo_tdata_ns;
reg										fifo_tvalid_ns;
reg										fifo_tlast_ns;
reg		[$clog2(FIFO_BYTES):0]			byte_counter_ns;
reg 	[(C_DATA_WIDTH/2)-1:0]			overflow_buffer_ns;
reg										overflow_flag_ns;
reg										s_axis_tready_ns;
	
wire									fifo_tready;

initial begin
	fifo_tdata_r <= 0;
	fifo_tvalid_r <= 0;
	fifo_tlast_r <= 0;
	byte_counter_r <= 0;
	s_axis_tready_r <= 0;
	overflow_buffer_r <= 0;
	overflow_flag_r <= 0;
end

integer i;
always @(*) begin
	fifo_tdata_ns = fifo_tdata_r;
	fifo_tvalid_ns = fifo_tvalid_r;
	byte_counter_ns = byte_counter_r;
	fifo_tlast_ns = fifo_tlast_r || s_axis_tlast;
	s_axis_tready_ns = !(fifo_tvalid_r && !fifo_tready);
	overflow_buffer_ns = overflow_buffer_r;
	overflow_flag_ns = overflow_flag_r;
	if (fifo_tvalid_r && fifo_tready) begin
		fifo_tvalid_ns = 0;
		fifo_tlast_ns = 0;
	end
	if (s_axis_tvalid && s_axis_tready_r && !(fifo_tvalid_r && !fifo_tready)) begin
		if (overflow_flag_r) begin
			fifo_tdata_ns[(FIFO_BYTES - 4) * 8 +: 32] = overflow_buffer_r;
			overflow_flag_ns = 0;
		end
		case(s_axis_tkeep)
		'h0F: begin
			fifo_tdata_ns[(FIFO_BYTES - byte_counter_r - 4) * 8 +: 32] = s_axis_tdata[31:0];
			byte_counter_ns = byte_counter_r + 'd4;
			if (byte_counter_r == FIFO_BYTES - 'd4) begin
				fifo_tvalid_ns = 1;
				byte_counter_ns = 0;
				s_axis_tready_ns = fifo_tready;
			end
		end
		'hF0: begin
			fifo_tdata_ns[(FIFO_BYTES - byte_counter_r - 4) * 8 +: 32] = s_axis_tdata[63:32];
			byte_counter_ns = byte_counter_r + 'd4;
			if (byte_counter_r == FIFO_BYTES - 'd4) begin
				fifo_tvalid_ns = 1;
				byte_counter_ns = 0;
				s_axis_tready_ns = fifo_tready;
			end
		end
		'hFF: begin
			if (byte_counter_r == FIFO_BYTES - 'd4) begin
				fifo_tdata_ns[(FIFO_BYTES - byte_counter_r - 4) * 8 +: 32] = s_axis_tdata[63:32];
				overflow_buffer_ns = s_axis_tdata[31:0];
				fifo_tvalid_ns = 1;
				overflow_flag_ns = 1;
				byte_counter_ns = 'd4;
				s_axis_tready_ns = fifo_tready;
			end
			else if (byte_counter_r == FIFO_BYTES - 'd8) begin
				fifo_tdata_ns[(FIFO_BYTES - byte_counter_r - 8) * 8 +: 64] = s_axis_tdata;
				fifo_tvalid_ns = 1;
				byte_counter_ns = 'd0;
				s_axis_tready_ns = fifo_tready;
			end
			else begin
				fifo_tdata_ns[(FIFO_BYTES - byte_counter_r - 8) * 8 +: 64] = s_axis_tdata;
				byte_counter_ns = byte_counter_r + 'd8;
				fifo_tvalid_ns = 0;
			end
		end
		default: begin
			fifo_tdata_ns = fifo_tdata_r;
			byte_counter_ns = byte_counter_r;
		end
		endcase
	end
end

always @(posedge clk) begin
	if (reset) begin
		fifo_tdata_r <= 0;
		fifo_tvalid_r <= 0;
		fifo_tlast_r <= 0;
		byte_counter_r <= 0;
		overflow_buffer_r <= 0;
		overflow_flag_r <= 0;
		s_axis_tready_r <= 0;
	end
	else begin
		fifo_tdata_r <= fifo_tdata_ns;
		fifo_tvalid_r <= fifo_tvalid_ns;
		fifo_tlast_r <= fifo_tlast_ns;
		byte_counter_r <= byte_counter_ns;
		overflow_buffer_r <= overflow_buffer_ns;
		overflow_flag_r <= overflow_flag_ns;
		s_axis_tready_r <= s_axis_tready_ns;
	end
end

instr_fifo instr_fifo_i (
  .s_aclk(clk),                		// input wire s_aclk
  .s_aresetn(~reset),          		// input wire s_aresetn
  .wr_rst_busy(wr_rst_busy),      	// output wire wr_rst_busy
  .rd_rst_busy(rd_rst_busy),      	// output wire rd_rst_busy
  .s_axis_tvalid(fifo_tvalid_r),  	// input wire s_axis_tvalid
  .s_axis_tready(fifo_tready),  	// output wire s_axis_tready
  .s_axis_tdata(fifo_tdata_r),    	// input wire [255 : 0] s_axis_tdata
  .s_axis_tlast(fifo_tlast_r),		// input wire s_axis_tlast
  .m_axis_tvalid(m_axis_tvalid),  	// output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready),  	// input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata),    	// output wire [255 : 0] m_axis_tdata
  .m_axis_tlast(m_axis_tlast)    	// output wire m_axis_tlast
);

assign s_axis_tready = s_axis_tready_r;

wire unused = wr_rst_busy & rd_rst_busy;

endmodule