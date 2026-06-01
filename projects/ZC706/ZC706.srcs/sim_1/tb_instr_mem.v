`timescale 1ns / 1ps

module tb_instr_mem();

localparam			FIFO_SCALE 	= 4;
localparam			DATA_WIDTH	= 64;
localparam			KEEP_WIDTH  = DATA_WIDTH / 8;

reg clk;
reg reset;

reg		[DATA_WIDTH-1:0]			 	s_axis_tdata;
reg 									s_axis_tvalid;
reg 	[KEEP_WIDTH-1:0]				s_axis_tkeep;
wire 									s_axis_tready;

wire	[DATA_WIDTH*FIFO_SCALE-1:0]		m_axis_tdata;
wire									m_axis_tvalid;
reg										m_axis_tready;

instruction_buffer #(
	.C_DATA_WIDTH(DATA_WIDTH),
	.FIFO_WIDTH(FIFO_SCALE * DATA_WIDTH)
) uut(
	.clk(clk),
	.reset(reset),
	.s_axis_tdata(s_axis_tdata),
	.s_axis_tready(s_axis_tready),
	.s_axis_tkeep(s_axis_tkeep),
	.s_axis_tvalid(s_axis_tvalid),
	.m_axis_tdata(m_axis_tdata),
	.m_axis_tready(m_axis_tready),
	.m_axis_tvalid(m_axis_tvalid)
);

always begin
	clk = 0;
	#5;
	clk = 1;
	#5;
end

localparam								TEST_LEN 	= 16;
reg		[DATA_WIDTH-1:0]				data 		[0:TEST_LEN-1];
reg		[KEEP_WIDTH-1:0]				data_keep	[0:TEST_LEN-1];

integer i;
integer j;
initial begin
	for (i = 0; i < TEST_LEN; i = i+1) begin
		for (j = 0; j < 8; j = j+1) begin
			data[i][(KEEP_WIDTH - j - 1) * 8 +: 8] = (8 * i + j) & 'hFF;
		end
		/*
		data_keep[i] = 	i % 4 == 0 	? 'h0F :
						i % 4 == 1 	? 'hF0 :
						i % 4 == 2 	? 'h0F : 'hFF ;
		*/
		data_keep[i] = 	i == 0		? 'h0F : 'hFF ;
	end
	reset = 1;
	s_axis_tdata = 0;
	s_axis_tvalid = 0;
	m_axis_tready = 0;
	repeat(10) begin @(posedge clk); end #1;
	reset = 0;
	for (i = 0; i < TEST_LEN;) begin
		s_axis_tdata = data[i];
		s_axis_tkeep = data_keep[i];
		s_axis_tvalid = 1;
		if (s_axis_tready && s_axis_tvalid) begin
			i = i+1;
		end
		@(posedge clk) #1;
	end
	s_axis_tvalid = 0;
	m_axis_tready = 1;
end

endmodule
