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
  
  // readback <-> XDMA if
  output [`XDMA_AXI_DATA_WIDTH-1:0]   c2h_tdata_0,  
  output                              c2h_tlast_0,
  output                              c2h_tvalid_0,
  input                               c2h_tready_0,
  output [`XDMA_AXI_DATA_WIDTH/8-1:0] c2h_tkeep_0
  
  );
  
  
  localparam READ_MODE = 0;
  localparam DIFF_MODE = 1;
  reg mode_r, mode_ns; // Switch between diff count and read modes
  
  reg rd_valid_r;
  reg ignore_read_r, ignore_read_ns;
  reg ignore_flush_r, ignore_flush_ns;

  // Popcount computation part
  reg[511:0] read_diff;
  reg        diff_valid;
  always @(posedge clk) begin
    if(rst) begin
      read_diff <= 512'bX;
      diff_valid <= `LOW;
    end
    read_diff <= rd_valid ? rd_data ^ ddr_wdata : read_diff;
    diff_valid <= rd_valid && ~ignore_read_r && mode_r == DIFF_MODE ? `HIGH : `LOW;
  end

  genvar pcs; // popcount modules

  wire[2:0] pc_out [127:0];
  reg[3:0] pc_out_l2 [63:0];
  reg[4:0] pc_out_l3 [31:0];
  reg[5:0] pc_out_l4 [15:0];
  reg[6:0] pc_out_l5 [7:0];
  reg[7:0] pc_out_l6 [3:0];
  reg[8:0] pc_out_l7 [1:0];
  reg[15:0] pop_count_value;
  reg       pop_count_valid;
  
  generate
    for(pcs = 0 ; pcs < 128 ; pcs = pcs + 1) begin: gen_pcs
      pop_count4 pci
      (
        .in(read_diff[pcs*4 +: 4]),
        .out(pc_out[pcs])
      );
    end
  endgenerate

  integer l1, l2, l3, l4, l5, l6;
  always @* begin
    for(l1 = 0 ; l1 < 64 ; l1 = l1+1)
      pc_out_l2[l1] = pc_out[2*l1] + pc_out[2*l1+1];
    for(l2 = 0 ; l2 < 32 ; l2 = l2+1)
      pc_out_l3[l2] = pc_out_l2[2*l2] + pc_out_l2[2*l2+1];
    for(l3 = 0 ; l3 < 16 ; l3 = l3+1)
      pc_out_l4[l3] = pc_out_l3[2*l3] + pc_out_l3[2*l3+1];
    for(l4 = 0 ; l4 < 8 ; l4 = l4+1)
      pc_out_l5[l4] = pc_out_l4[2*l4] + pc_out_l4[2*l4+1];
    for(l5 = 0 ; l5 < 4 ; l5 = l5+1)
      pc_out_l6[l5] = pc_out_l5[2*l5] + pc_out_l5[2*l5+1];
    for(l6 = 0 ; l6 < 2 ; l6 = l6+1)
      pc_out_l7[l6] = pc_out_l6[2*l6] + pc_out_l6[2*l6+1];
  end
  
  always @(posedge clk) begin
    if(rst) begin
      pop_count_value <= 16'bX;
      pop_count_valid <= `LOW;
    end
    else begin
      pop_count_value <= diff_valid ? pc_out_l7[0] + pc_out_l7[1] : pop_count_value;
      pop_count_valid <= diff_valid ? `HIGH : `LOW;
    end
  end
  
  wire[511:0] dsr_out;
  wire        dsr_valid;
  // We put popcounted data into a shift register
  // to fill up 512 bit I/O fifo.
  diff_shift_reg dsr(
    .clk(clk),
    .rst(rst),
    
    .in(pop_count_value),
    .in_valid(pop_count_valid),
  
    .flush(flush&~ignore_flush_r),
  
    .out(dsr_out),
    .out_valid(dsr_valid)
  );
  // End popcount computation part
  
  // Count up to 1024 32-byte transfers  
  reg[9:0] xctr_r;

  reg tlast; // indicating c2h's last transfer
  
  // We read DQ_WIDTH*DQ_BURST (512 as of now) bits
  // from DRAM, and have to pipe 256 bit partitions of
  // it to the PCI. We may read data each cycle from 
  // DRAM and have to buffer some of those. 
  wire rbf_empty, rbf_rd_valid, fifo_almost_full, fifo_valid;
  (*KEEP = "TRUE"*) wire rbf_full;
  (*KEEP = "TRUE"*) reg [19:0] dbg_rd_ctr;
  rdback_fifo rbf(
    .full(rbf_full),
    .prog_full(fifo_almost_full),
    .empty(rbf_empty),
    .wr_en(mode_r == READ_MODE ? rd_valid && ~ignore_read_r: dsr_valid),
    // shuffle data because fifo outputs them on wrong order
    .din(mode_r == READ_MODE ? {rd_data[255:0],rd_data[511:256]} : {dsr_out[255:0],dsr_out[511:256]}),
    .rd_en(c2h_tready_0),
    .dout(c2h_tdata_0),
    .valid(fifo_valid),
    .clk(clk),
    .srst(rst)
  );
  
  reg proc_flush_ns, proc_flush_r;
  // we count the remaining space in terms of 
  // AXI transactions
  // e.g. 1024 reads will take up 2048 
  reg [11:0] buffer_space_ns, buffer_space_r;
  
  always @* begin
    tlast = `LOW;
    ignore_read_ns = ignore_read_r;
    ignore_flush_ns = ignore_flush_r;
    buffer_space_ns = buffer_space_r;
    if(per_rd_init || per_zq_init || per_ref_init) begin
      ignore_read_ns = per_rd_init;
      ignore_flush_ns = `HIGH;
    end
    if(rd_valid_r)
      ignore_read_ns = `LOW;
    proc_flush_ns = proc_flush_r;
    if(flush) begin
      if(ignore_flush_r)
        ignore_flush_ns = `LOW;
      else
        proc_flush_ns = `HIGH;
    end
    mode_ns = mode_r;
    if(switch_mode)
      mode_ns = ~mode_r;
    if(&xctr_r && (c2h_tready_0 && c2h_tvalid_0)) begin
      tlast = `HIGH;
    end
    // Send what's remaining in the fifo
    // to host with a random length transfer
    // (tlast is not based on the counter value)
    if(proc_flush_r) begin
      if(c2h_tready_0 && rbf_empty && ~dsr_valid) begin
        tlast = `HIGH;
        proc_flush_ns = `LOW;
      end
      else
        proc_flush_ns = `HIGH; 
    end
    if(read_seq_incoming) begin
      if(c2h_tvalid_0 && c2h_tready_0) begin
        buffer_space_ns = (buffer_space_r - (incoming_reads << 1)) + 1;
      end
      else begin
        buffer_space_ns = (buffer_space_r - (incoming_reads << 1));
      end
    end
    else begin
      if(c2h_tvalid_0 && c2h_tready_0) begin
        if(~(proc_flush_r && rbf_empty && ~dsr_valid))
          buffer_space_ns = buffer_space_r + 1;
      end
    end  
  end
  
  always @(posedge clk) begin
    if(rst) begin
      dbg_rd_ctr <= 20'b0;
      xctr_r <= 15'b0;
      proc_flush_r <= `LOW;
      mode_r <= READ_MODE;
      ignore_read_r <= 1'b0;
      ignore_flush_r <= 1'b0;
      rd_valid_r <= 1'b0;
      buffer_space_r <= 12'd2048;
    end
    else begin
      if(rd_valid && ~ignore_read_r && ~rbf_full)
        dbg_rd_ctr <= dbg_rd_ctr + 1'b1;
      else
        dbg_rd_ctr <= dbg_rd_ctr;
      buffer_space_r <= buffer_space_ns;
      mode_r <= mode_ns;
      rd_valid_r <= rd_valid;
      ignore_read_r <= ignore_read_ns;
      ignore_flush_r <= ignore_flush_ns;
      if(proc_flush_r && tlast)
        xctr_r <= 15'b0;
      else if(c2h_tready_0 && c2h_tvalid_0) begin
        xctr_r <= xctr_r + 1;
      end
      proc_flush_r <= proc_flush_ns;
    end
  end
  
  assign c2h_tkeep_0  = {(`XDMA_AXI_DATA_WIDTH/8){1'b1}};
  assign c2h_tlast_0  = tlast;
  assign c2h_tvalid_0 = proc_flush_r && rbf_empty && ~dsr_valid ? `HIGH : fifo_valid; 
  
  assign buffer_space = buffer_space_r >> 1;
  
endmodule
