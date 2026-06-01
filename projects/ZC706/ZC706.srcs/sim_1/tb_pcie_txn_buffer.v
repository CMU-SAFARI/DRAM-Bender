`timescale 1ns / 1ps

module tb_pcie_txn_buffer();

localparam C_IN_DATA_WIDTH = 128;
localparam C_OUT_DATA_WIDTH = 64;
localparam C_IN_KEEP = C_IN_DATA_WIDTH / 8;
localparam C_OUT_KEEP = C_OUT_DATA_WIDTH / 8;
localparam DATA_COUNT_WIDTH = 32;

reg                                 clk;
reg                                 reset;
reg     [C_IN_DATA_WIDTH-1:0]       s_axis_tdata;
reg     [C_IN_KEEP-1:0]             s_axis_tkeep;
reg                                 s_axis_tvalid;
wire                                s_axis_tready;
reg								    s_axis_tlast;
wire    [C_OUT_DATA_WIDTH-1:0]	    m_axis_tdata;
wire    [C_OUT_DATA_WIDTH/2-1:0]    m_axis_upper_half_data;
wire    [C_OUT_KEEP-1:0]		    m_axis_tkeep;
wire    [C_OUT_KEEP/2-1:0]          m_axis_upper_half_keep;
wire							    m_axis_tvalid;
wire							    m_axis_upper_half_valid;
reg								    m_axis_tready;
reg								    m_axis_upper_half_ready;
wire 	[DATA_COUNT_WIDTH-1:0]	    data_count;
wire							    programmed_stop;

pcie_txn_buffer #(
    .C_IN_DATA_WIDTH(C_IN_DATA_WIDTH),
    .C_OUT_DATA_WIDTH(C_OUT_DATA_WIDTH)
) uut (
    .clk(clk),
    .reset(reset),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tkeep(s_axis_tkeep),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tlast(s_axis_tlast),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_upper_half_data(m_axis_upper_half_data),
    .m_axis_tkeep(m_axis_tkeep),
    .m_axis_upper_half_keep(m_axis_upper_half_keep),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_upper_half_valid(m_axis_upper_half_valid),
    .m_axis_tready(m_axis_tready),
    .m_axis_upper_half_ready(m_axis_upper_half_ready),
    .data_count(data_count),
    .programmed_stop(programmed_stop)
);

always begin
    clk = 0;
    #5;
    clk = 1;
    #5;
end

integer i;

localparam WRITE_LENGTH = 16;

initial begin
    s_axis_tdata = 0;
    s_axis_tkeep = 0;
    s_axis_tvalid = 0;
    s_axis_tlast = 0;
    m_axis_tready = 0;
    m_axis_upper_half_ready = 0;
    reset = 1;
    repeat (10) @(posedge clk) #1;
    reset = 0;
    for (i = 0; i < WRITE_LENGTH;) begin
        s_axis_tdata = {C_IN_KEEP{i[C_IN_KEEP-1:0]}};
        s_axis_tkeep = {C_IN_KEEP{1'b1}};
        s_axis_tvalid = 1;
        if (s_axis_tready && s_axis_tvalid) begin
            i = i + 1;
        end
        @(posedge clk) #2;
    end
    s_axis_tvalid = 0;
    m_axis_tready = 0;
    m_axis_upper_half_ready = 0;
    wait(m_axis_tvalid);
    @(posedge clk) #2;
    m_axis_tready = 0;
    m_axis_upper_half_ready = 1;
    @(posedge clk) #2;
    m_axis_tready = 1;
    m_axis_upper_half_ready = 0;
    wait(!m_axis_tvalid);
    @(posedge clk) #2;
    m_axis_tready = 1;
    m_axis_upper_half_ready = 1;
    repeat(5) @(posedge clk) #2;
    m_axis_tready = 0;
    m_axis_upper_half_ready = 0;
end

endmodule
