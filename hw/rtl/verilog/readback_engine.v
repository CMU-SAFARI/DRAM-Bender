`include "parameters.vh"

// Process data coming from DRAM before sending it to the host.
module readback_engine(

  // common signals
  input     clk,
  input     rst,

  // other control signals
  input         flush,
  input         read_seq_incoming, // next few instructions will read from DRAM
  input [11:0]  incoming_reads,    // how many reads next few instructions will issue
  output[11:0]  buffer_space,      // remaining buffer size
  input         switch_mode,

  // DRAM <-> engine if
  input [511:0] rd_data,
  input         rd_valid,

  input         per_rd_init,
  input         per_zq_init,
  input         per_ref_init,

  // engine <-> regfile if
  input [511:0] ddr_wdata, // to compare read data against

  `ifdef HBM_BENDER
  input hbm_temp_rd,
  input [6:0] hbm0_temp,
  input [6:0] hbm1_temp,
  input hbm_discard_readback_data,
  `endif

  // readback <-> XDMA if
  output [`XDMA_AXI_DATA_WIDTH-1:0]   c2h_tdata_0,
  output                              c2h_tlast_0,
  output                              c2h_tvalid_0,
  input                               c2h_tready_0,
  output [`XDMA_AXI_DATA_WIDTH/8-1:0] c2h_tkeep_0

  );

  `ifdef HBM_BENDER
  wire [15:0] hbm_temp_all = {1'b0, hbm1_temp, 1'b0, hbm0_temp};
  wire [511:0] fifo_wr_data= hbm_temp_rd ? hbm_temp_all : {rd_data[0+:128], rd_data[128+:128], rd_data[256+:128], rd_data[384+:128]};
  wire fifo_wr_en = (rd_valid | hbm_temp_rd) & (~hbm_discard_readback_data);
  `else
  wire [511:0] fifo_wr_data= {rd_data[255:0],rd_data[511:256]};
  wire fifo_wr_en = rd_valid;
  `endif

  wire fifo_rd_en;
  wire [255:0] fifo_rd_data;
  wire fifo_rd_valid;

  rdback_fifo rbf(
    .full(),
    .prog_full(),
    .empty(),
    .wr_en(fifo_wr_en),
    // shuffle data because fifo outputs them on wrong order
    .din(fifo_wr_data),
    .rd_en(fifo_rd_en),
    .dout(fifo_rd_data),
    .valid(fifo_rd_valid),
    .clk(clk),
    .srst(rst)
  );

  // try to send whatever data we have every 300 cycles
  (*dont_touch = "yes"*) reg               [9:0]           cycle_counter_r;
  (*dont_touch = "yes"*) reg               [9:0]           cycle_counter_ns;
  localparam                        CYCLE_THRESHOLD     = 10'd300;

  // AXI sender state machine
  (*dont_touch = "yes"*) reg               [1:0]           sender_state_r;
  (*dont_touch = "yes"*) reg               [1:0]           sender_state_ns;
  localparam                        IDLE_S              = 2'b00;
  localparam                        SEND_META_S         = 2'b01;
  localparam                        SEND_DATA_S         = 2'b10;
  localparam                        SEND_DATA_FLUSH_S   = 2'b11;

  // how many axi transactions to conduct before moving back to IDLE_S
  (*dont_touch = "yes"*) reg               [11:0]          axi_expected_trans_ns;
  (*dont_touch = "yes"*) reg               [11:0]          axi_expected_trans_r;
  // current axi transaction number
  (*dont_touch = "yes"*) reg               [11:0]          axi_trans_count_r;
  (*dont_touch = "yes"*) reg               [11:0]          axi_trans_count_ns;

  // how many reads is the frontend allowed to pass
  (*dont_touch = "yes"*) reg               [10:0]          allowed_nreads_r;
  (*dont_touch = "yes"*) reg               [10:0]          allowed_nreads_ns;

  // how many transactions worth of data is in the FIFO
  (*dont_touch = "yes"*) reg               [11:0]          fifo_size_r;
  (*dont_touch = "yes"*) reg               [11:0]          fifo_size_ns;

  // how many transactions worth of data will the FIFO store in due time
  (*dont_touch = "yes"*) reg               [11:0]          expected_fifo_size_r;
  (*dont_touch = "yes"*) reg               [11:0]          expected_fifo_size_ns;

  // We need to let the host know dram bender finished executing the program
  (*dont_touch = "yes"*) reg                               process_flush_ns;
  (*dont_touch = "yes"*) reg                               process_flush_r;

  wire c2h_fire = c2h_tvalid_0 & c2h_tready_0;

  assign buffer_space = allowed_nreads_r;

  assign fifo_rd_en = ((sender_state_r == SEND_DATA_S) | (sender_state_r == SEND_DATA_FLUSH_S)) & (axi_trans_count_r != axi_expected_trans_r) & (c2h_tready_0);

  assign c2h_tkeep_0  = {(`XDMA_AXI_DATA_WIDTH/8){1'b1}};
  assign c2h_tlast_0  = (sender_state_r == SEND_META_S) |
  (((sender_state_r == SEND_DATA_S) | (sender_state_r == SEND_DATA_FLUSH_S)) & axi_trans_count_r == (axi_expected_trans_r - 12'b1));
  assign c2h_tvalid_0 = (sender_state_r == SEND_META_S) |
  (((sender_state_r == SEND_DATA_S) | (sender_state_r == SEND_DATA_FLUSH_S)) & (axi_trans_count_r != axi_expected_trans_r) & (fifo_rd_valid));

  assign c2h_tdata_0  = (sender_state_r == SEND_META_S) ? {process_flush_r, 243'b0, fifo_size_r} : fifo_rd_data;


  always @* begin
    fifo_size_ns = fifo_size_r;
    expected_fifo_size_ns = expected_fifo_size_r;
    axi_expected_trans_ns = axi_expected_trans_r;
    axi_trans_count_ns = axi_trans_count_r;

    sender_state_ns = sender_state_r;

    process_flush_ns = process_flush_r;

    if (flush) // ASSUME THIS IS SET ONLY FOR ONE CYCLE
      process_flush_ns = 1'b1;

    // every write to FIFO increments FIFO size by two due to async I/O width
    if (fifo_wr_en) begin
      fifo_size_ns = fifo_size_r + 12'd2;
      if ((axi_trans_count_r == axi_expected_trans_r) & ((sender_state_r == SEND_DATA_S) | (sender_state_r == SEND_DATA_FLUSH_S)))
        fifo_size_ns = fifo_size_r + 12'd2 - axi_expected_trans_r;
    end
    else
      if ((axi_trans_count_r == axi_expected_trans_r) & ((sender_state_r == SEND_DATA_S) | (sender_state_r == SEND_DATA_FLUSH_S)))
        fifo_size_ns = fifo_size_r - axi_expected_trans_r;

    // the most complex single unit of information to maintain
`ifdef HBM_BENDER
    if (read_seq_incoming & ~hbm_discard_readback_data) begin
`else
    if (read_seq_incoming) begin
`endif
      // read seq incoming, but also finished sending a chunk of data
      if ((axi_trans_count_r == axi_expected_trans_r) & ((sender_state_r == SEND_DATA_S) | (sender_state_r == SEND_DATA_FLUSH_S)))
        expected_fifo_size_ns = expected_fifo_size_r + (incoming_reads << 1'b1) - axi_expected_trans_r;
      else
        expected_fifo_size_ns = expected_fifo_size_r + (incoming_reads << 1'b1);
    end
    else begin
      if ((axi_trans_count_r == axi_expected_trans_r) & ((sender_state_r == SEND_DATA_S) | (sender_state_r == SEND_DATA_FLUSH_S)))
        expected_fifo_size_ns = expected_fifo_size_r - axi_expected_trans_r;
    end

    // lazily set the number of allowed reads to fifo capacity - half fifo size
    allowed_nreads_ns = 11'd1024 - (expected_fifo_size_ns >> 1'b1);

    // advance the counter while sender is idle
    if ((cycle_counter_r == CYCLE_THRESHOLD - 10'd1) || (sender_state_r != IDLE_S))
      cycle_counter_ns = 10'b0;
    else
      cycle_counter_ns = cycle_counter_r + 10'b1;

    case(sender_state_r)
    IDLE_S: begin
      if (cycle_counter_r == CYCLE_THRESHOLD - 10'd1)
        if ((fifo_size_r != 12'b0) || process_flush_r)
          sender_state_ns = SEND_META_S;
    end
    SEND_META_S: begin
      if (c2h_fire) begin
        sender_state_ns = SEND_DATA_S;
        axi_expected_trans_ns = fifo_size_r;
        axi_trans_count_ns = 12'b0;
        if (process_flush_r && fifo_size_r == 12'b0) begin
          sender_state_ns = IDLE_S;
          process_flush_ns = 1'b0;
        end
        else if (process_flush_r) begin
          sender_state_ns = SEND_DATA_FLUSH_S;
        end
      end
    end
    SEND_DATA_S: begin
      if (c2h_fire) begin
        axi_trans_count_ns = axi_trans_count_r + 12'b1;
      end
      if (axi_trans_count_r == axi_expected_trans_r) begin
        sender_state_ns = IDLE_S;
      end
    end
    SEND_DATA_FLUSH_S: begin
      if (c2h_fire) begin
        axi_trans_count_ns = axi_trans_count_r + 12'b1;
      end
      if (axi_trans_count_r == axi_expected_trans_r) begin
        sender_state_ns = IDLE_S;
        process_flush_ns = 1'b0;
      end
    end
    endcase
  end

  always @(posedge clk) begin
    if(rst) begin
      cycle_counter_r               <=          10'b0;
      fifo_size_r                   <=          12'b0;
      expected_fifo_size_r          <=          12'b0;
      axi_expected_trans_r          <=          12'b0;
      axi_trans_count_r             <=          12'b0;
      sender_state_r                <=          IDLE_S;
      allowed_nreads_r              <=          12'b0;
      process_flush_r               <=          1'b0;
    end
    else begin
      cycle_counter_r               <=          cycle_counter_ns;
      fifo_size_r                   <=          fifo_size_ns;
      expected_fifo_size_r          <=          expected_fifo_size_ns;
      axi_expected_trans_r          <=          axi_expected_trans_ns;
      axi_trans_count_r             <=          axi_trans_count_ns;
      sender_state_r                <=          sender_state_ns;
      allowed_nreads_r              <=          allowed_nreads_ns;
      process_flush_r               <=          process_flush_ns;
    end
  end

endmodule
