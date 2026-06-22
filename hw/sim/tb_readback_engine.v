`timescale 1ns/1ps

// Uncomment this if you want to test the HBM_BENDER logic.
// `define HBM_BENDER

module readback_engine_tb;

  // --------------------------------------------------------------------------
  // Local parameters
  // --------------------------------------------------------------------------
  // Typically these would come from parameters.vh,
  // but for this self-contained TB, we define them here.
  localparam XDMA_AXI_DATA_WIDTH = 256;  // Must match your design setup
  // If your design uses 512 bits for XDMA, change accordingly.

  // --------------------------------------------------------------------------
  // Testbench signals
  // --------------------------------------------------------------------------
  reg                      clk;
  reg                      rst;
  reg                      flush;
  reg                      read_seq_incoming;
  reg       [11:0]         incoming_reads;
  wire      [11:0]         buffer_space;
  reg                      switch_mode;

  // DRAM -> engine
  reg       [511:0]        rd_data;
  reg                      rd_valid;

  reg                      per_rd_init;
  reg                      per_zq_init;
  reg                      per_ref_init;

  // data to compare read data against
  reg       [511:0]        ddr_wdata;

`ifdef HBM_BENDER
  // HBM signals
  reg                      hbm_temp_rd;
  reg       [6:0]          hbm0_temp;
  reg       [6:0]          hbm1_temp;
`endif

  // Engine -> XDMA
  wire [XDMA_AXI_DATA_WIDTH-1:0]   c2h_tdata_0;
  wire                             c2h_tlast_0;
  wire                             c2h_tvalid_0;
  wire                             c2h_tready_0;
  wire [XDMA_AXI_DATA_WIDTH/8-1:0] c2h_tkeep_0;

  assign c2h_tready_0 = c2h_tvalid_0;

  // --------------------------------------------------------------------------
  // Instantiate the DUT: readback_engine
  // --------------------------------------------------------------------------
  readback_engine dut (
    // Common signals
    .clk                (clk),
    .rst                (rst),

    // Control signals
    .flush              (flush),
    .read_seq_incoming  (read_seq_incoming),
    .incoming_reads     (incoming_reads),
    .buffer_space       (buffer_space),
    .switch_mode        (switch_mode),

    // DRAM <-> engine if
    .rd_data            (rd_data),
    .rd_valid           (rd_valid),

    .per_rd_init        (per_rd_init),
    .per_zq_init        (per_zq_init),
    .per_ref_init       (per_ref_init),

    // Data to compare read data against
    .ddr_wdata          (ddr_wdata),

`ifdef HBM_BENDER
    .hbm_temp_rd        (hbm_temp_rd),
    .hbm0_temp          (hbm0_temp),
    .hbm1_temp          (hbm1_temp),
`endif

    // readback <-> XDMA if
    .c2h_tdata_0        (c2h_tdata_0),
    .c2h_tlast_0        (c2h_tlast_0),
    .c2h_tvalid_0       (c2h_tvalid_0),
    .c2h_tready_0       (c2h_tready_0),
    .c2h_tkeep_0        (c2h_tkeep_0)
  );

  // --------------------------------------------------------------------------
  // Clock generation
  // --------------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz clock => period of 10 ns
  end

  // --------------------------------------------------------------------------
  // Reset logic
  // --------------------------------------------------------------------------
  initial begin
    rst = 1;
    #100;             // Hold reset for 100 ns
    rst = 0;
  end

  // --------------------------------------------------------------------------
  // Test stimulus
  // --------------------------------------------------------------------------
  initial begin
    // Initialize all signals
    flush              = 0;
    read_seq_incoming  = 0;
    incoming_reads     = 0;
    switch_mode        = 0;

    rd_data            = 512'h0;
    rd_valid           = 0;
    per_rd_init        = 0;
    per_zq_init        = 0;
    per_ref_init       = 0;
    ddr_wdata          = 512'h0;

`ifdef HBM_BENDER
    hbm_temp_rd        = 0;
    hbm0_temp          = 7'd20;
    hbm1_temp          = 7'd25;
`endif

//    c2h_tready_0       = 0;

    // Wait for reset deassert
    @(negedge rst);
    $display("[%0t] Reset deasserted...", $time);

    // Small delay before starting
    #50;

    // Let the DUT "idle" for a bit
    wait_for_cycles(10);

    $display("[%0t] Issuing flush...", $time);
    flush = 1;
    @(posedge clk);
    flush = 0;

    wait_for_cycles(500);

    // Now make the XDMA side ready to receive

    //-------------------------------------------------------------------------
    // EXAMPLE SCENARIO 1:
    // - Indicate that we have a read sequence incoming
    // - Provide some DRAM read data
    // - Observe how the DUT eventually sends data out via c2h interface
    //-------------------------------------------------------------------------
    $display("[%0t] Starting read sequence with 4 DRAM reads...", $time);
    read_seq_incoming  = 1;
    incoming_reads     = 4;   // we plan to send 4 reads
    @(posedge clk);
    read_seq_incoming  = 0;   // typically asserted for 1 cycle in the DUT

    // Provide valid read data (4 bursts)
    send_rd_burst(4);


    // Wait a bit while data flows
    wait_for_cycles(100);

    //-------------------------------------------------------------------------
    // EXAMPLE SCENARIO 2:
    // - Issue a flush to see how the DUT handles it
    //-------------------------------------------------------------------------
    $display("[%0t] Issuing flush...", $time);
    flush = 1;
    @(posedge clk);
    flush = 0;

    read_seq_incoming  = 1;
    incoming_reads     = 2;   // we plan to send 2 more reads
    @(posedge clk);
    read_seq_incoming  = 0;   // typically asserted for 1 cycle in the DUT


    // Keep driving read bursts; the flush signal was only 1-cycle
    send_rd_burst(2);

    // Wait some more cycles to observe behavior
    wait_for_cycles(100);

    //-------------------------------------------------------------------------
    // Wrap up the simulation
    //-------------------------------------------------------------------------
//    $display("[%0t] Test completed!", $time);
    #200;
//    $stop;  // End simulation
  end


  // --------------------------------------------------------------------------
  // Helper Tasks
  // --------------------------------------------------------------------------
  // Wait for 'num_cycles' clock cycles
  task wait_for_cycles(input integer num_cycles);
    integer i;
    begin
      for (i = 0; i < num_cycles; i = i + 1) begin
        @(posedge clk);
      end
    end
  endtask

  // Send 'num_bursts' of read data from DRAM
  task send_rd_burst(input integer num_bursts);
    integer i;
    begin
      for (i = 0; i < num_bursts; i = i + 1) begin
        @(posedge clk);
        rd_data  = {$random, $random};  // 512 bits of random data
        rd_valid = 1'b1;
        @(posedge clk);
        rd_valid = 1'b0;
      end
    end
  endtask

  // --------------------------------------------------------------------------
  // Optional waveform dump
  // --------------------------------------------------------------------------
  initial begin
    // Uncomment if you want a VCD dump (supported by most simulators)
    // $dumpfile("readback_engine_tb.vcd");
    // $dumpvars(0, readback_engine_tb);
  end

endmodule
