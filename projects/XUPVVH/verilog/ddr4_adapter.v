`include "parameters.vh"
`include "project.vh"
// Convert MC emitted DFI signals to a specific DDR4 PHY interface (mem_clock = 4xfab_clk)
// Note that this is a bit hardcoded, but it could be made more flexible to satisfy
// wider (can issue more than 4 commands each fab cycle) PHY interfaces.
// DBUF_WIDTH specifies how many bursts of data will be buffered
// before being issued to DRAM.

`define ADDR_WIDTH 17

module ddr4_adapter #(parameter CKE_WIDTH = 1, RANK_WIDTH = 1, DQ_WIDTH = 64, DRAM_CMD_SLOTS = 4,
										DATA_BUF_ADDR_WIDTH = 5, DBUF_WIDTH = 4, DQ_BURST = 8)

(
  // common signals
  input                                             clk,
  input                                             rst,
  
  //other control signals
  input                                             init_calib_complete,
  //input                                             process_iseq,
  
  // ddr_pipeline <-> outer module if
  input [3:0]                ddr_write,
  input [3:0]                ddr_read,
  input [3:0]                ddr_pre,
  input [3:0]                ddr_act,
  input [3:0]                ddr_ref,
  input [3:0]                ddr_zq,
  input [3:0]                ddr_nop,
  input [3:0]                ddr_ap,
  input [3:0]                ddr_half_bl,
  input [3:0]                ddr_pall,
  input [4*`BG_WIDTH-1:0]    ddr_bg, 
  input [4*`BANK_WIDTH-1:0]  ddr_bank,
  input [4*`COL_WIDTH-1:0]   ddr_col,
  input [4*`ROW_WIDTH-1:0]   ddr_row,
  input [511:0]              ddr_wdata,
  
  // periodic maintenance signals
  input                      ddr_maint_read, // next read will be a maintenance read
  
  // DDR4-PHY signals
  output [DATA_BUF_ADDR_WIDTH-1:0]                  dBufAdr,   // Reserved. Should be tied low.
  output [DQ_WIDTH*8-1:0]                           wrData,    // DRAM write data. There are 8 bits for each DQ lane on the DRAM bus.
  output [DQ_WIDTH-1:0]                             wrDataMask,// DRAM write DM/DBI port.There is one bit for each byte of the wrData port.
  input                                             wrDataEn,  // Write data Enable. The Phy will assert this port for one cycle for each write CAS command.
  output [7:0]                                      mc_ACT_n,  // DRAM ACT_n command signal for four DRAM clock cycles.
  output [`ADDR_WIDTH*8-1:0]                        mc_ADR,    // DRAM address. There are 8 bits in the fabric interface for each address bit on the DRAM bus.
  output [`BANK_WIDTH*8-1:0]                        mc_BA,     // DRAM bank address. 8 bits for each DRAM bank address.
  output [`BG_WIDTH*8-1:0]                          mc_BG,     // DRAM bank group address.
  output [`CS_WIDTH*8-1:0]                          mc_CS_n,   // DRAM CS_n
  //output [`ODT_WIDTH*8-1:0]                         mc_ODT,    // DRAM ODT
  output                                            mcRdCAS,   // Read CAS command issued.
  output                                            mcWrCAS,   // Write CAS command issued.
  output [1:0]                                      winRank,   // Target rank for CAS commands. This value indicates which rank a CAS command is issued to.
  output [4:0]                                      winBuf,    // Optional control signal. When either mcRdCAS or mcWrCAS is asserted, the Phy will store the value on the winBuf signal.
  // input  [DQ_WIDTH*8-1:0]                           rdData,    // DRAM read data.
  input                                             rdDataEn,  // Read data valid. This signal asserts for one fabric cycle for each completed read operation.
  input                                             rdDataEnd,  // Unused.  Tied high.
  output [1:0]                                      mcCasSlot,
  output                                            mcCasSlot2,
  output                                            gt_data_ready,
  
  output                                            iss_dummy_read
  );

  assign winRank  = 2'b0; // single rank -> tie to 0
  assign winBuf   = 4'b0; // TODO don't know how this could be used
  assign dBufAdr = {DATA_BUF_ADDR_WIDTH{1'b0}};

  reg [DQ_BURST*DQ_WIDTH-1:0] ddr_wdata_r;
  
  reg [2*DQ_BURST*DQ_WIDTH-1:0] wrDataBuf, wrDataBuf_ns;
  reg slot1_full, slot1_full_ns;
  reg slot2_full, slot2_full_ns;
   
  assign wrData                 = wrDataBuf[0+:DQ_BURST*DQ_WIDTH];

  reg iss_dummy_read_r, iss_dummy_read_ns;
  reg read_will_be_dummy_r, read_will_be_dummy_ns;
  
  assign iss_dummy_read = iss_dummy_read_r;

  reg init_calib_complete_r; // can't issue any commands until this signal is asserted

  reg                           wrDataEn_r; // to delay wrDataEn by one clock cycle
  reg [7:0]                     ACT_n_ns, ACT_n_r;
  reg [`ADDR_WIDTH*8-1:0]       ADR_ns, ADR_r;
  reg [`BANK_WIDTH*8-1:0]       BA_ns, BA_r;
  reg [`BG_WIDTH*8-1:0]         BG_ns, BG_r;
  reg [`CS_WIDTH*8-1:0]         CS_n_ns, CS_n_r;
  reg [`ODT_WIDTH*8-1:0]        ODT_ns, ODT_r;
  reg                           RdCAS_ns, RdCAS_r;
  reg                           WrCAS_ns, WrCAS_r;

  reg [1:0]                     mcCasSlot_r, mcCasSlot_ns;
  reg                           gt_data_ready_r, gt_data_ready_ns;
  
  // TODO - PG 150 - page 180
  // Specifically, the PHY requires the following after calDone asserts:
  // 1. At least one read command every 1 μs. For a multi-rank system any rank is acceptable.
  // 2. The gt_data_ready signal is asserted for one system clock cycle after rdDataEn or
  // per_rd_done signal asserts at least once within each 1 μs interval.
  // 3. There is a three contiguous system clock cycle period with no read CAS commands
  // asserted at the PHY interface every 1 μs.
  // Somehow enforce above requirements to our PHY command stream, if it is not implicitly
  // handled by the controller's maintenance handler modules.
  // To drive gt_data_ready
  assign gt_data_ready        = gt_data_ready_r;

  assign mcCasSlot  = mcCasSlot_r;
  assign mcCasSlot2 = mcCasSlot[1];

  assign wrDataMask = {DQ_WIDTH{1'b0}};
  assign mc_ACT_n   = ACT_n_r;
  assign mc_ADR     = ADR_r;
  assign mc_BA      = BA_r;
  assign mc_BG      = BG_r;
  assign mc_CS_n    = CS_n_r;
  assign mcRdCAS    = RdCAS_r;
  assign mcWrCAS    = WrCAS_r;

  integer mc_cmd_i; // iterate over softmc dfi commands
  integer adr_bit_i; // iterate over dfi address bits
  integer bank_bit_i; // iterate over bank number bits
  integer bg_bit_i; // iterate over bank group bits
  always@* begin
    wrDataBuf_ns = wrDataBuf;
    slot1_full_ns = slot1_full;
		slot2_full_ns = slot2_full;
    ACT_n_ns = {8{`HIGH}};
    ADR_ns = {`ROW_WIDTH*8{1'bx}};
    BA_ns = {`BANK_WIDTH*8{1'bx}};
    BG_ns = {`BG_WIDTH*8{1'bx}};
    CS_n_ns = {`CS_WIDTH*8{1'b1}}; // NOP
    ODT_ns = {`ODT_WIDTH*8{1'bx}};
    RdCAS_ns = 1'b0;
    WrCAS_ns = 1'b0;
    mcCasSlot_ns = 2'b0;
    iss_dummy_read_ns = iss_dummy_read_r;
    read_will_be_dummy_ns = ddr_maint_read || read_will_be_dummy_r;

    // assign DDR4 PHY address signals
    // each pair of bits in a byte corresponds
    // to each slot's command address bit
    // e.g. ADR[1:0] is slot0's command address bit 0
    // ADR[3:2] is slot1's command address bit 0
    // ADR[9:8] is slot0's command address bit 1...

    // Assume that every command works with column addresses
    // ACTs will overwrite LSBs later
    for(mc_cmd_i = 0 ; mc_cmd_i < DRAM_CMD_SLOTS ; mc_cmd_i = mc_cmd_i + 1) begin
      for(adr_bit_i = 0 ; adr_bit_i < `COL_WIDTH ; adr_bit_i = adr_bit_i + 1) begin
          ADR_ns[adr_bit_i*8 + mc_cmd_i*2 +: 2] =
                    {2{ddr_col[mc_cmd_i*`COL_WIDTH + adr_bit_i]}};
      end
    end

    // ACTs overwriting LSBs here
    for(mc_cmd_i = 0 ; mc_cmd_i < DRAM_CMD_SLOTS ; mc_cmd_i = mc_cmd_i + 1) begin
      for(adr_bit_i = 0 ; adr_bit_i < `ROW_WIDTH ; adr_bit_i = adr_bit_i + 1) begin
        if(ddr_act[mc_cmd_i])
          ADR_ns[adr_bit_i*8 + mc_cmd_i*2 +: 2] =
                    {2{ddr_row[mc_cmd_i*`ROW_WIDTH + adr_bit_i]}};
      end
    end

    // Set bank and bank group signals
    for(mc_cmd_i = 0 ; mc_cmd_i < DRAM_CMD_SLOTS ; mc_cmd_i = mc_cmd_i + 1) begin
      for(bank_bit_i = 0 ; bank_bit_i < `BANK_WIDTH ; bank_bit_i = bank_bit_i + 1) begin
        BA_ns[bank_bit_i*8 + mc_cmd_i*2 +: 2] =
            {2{ddr_bank[mc_cmd_i*`BANK_WIDTH + bank_bit_i]}};
      end
    end
    for(mc_cmd_i = 0 ; mc_cmd_i < DRAM_CMD_SLOTS ; mc_cmd_i = mc_cmd_i + 1) begin
      for(bg_bit_i = 0 ; bg_bit_i < `BG_WIDTH ; bg_bit_i = bg_bit_i + 1) begin
        BG_ns[bg_bit_i*8 + mc_cmd_i*2 +: 2] =
            {2{ddr_bg[mc_cmd_i*`BG_WIDTH + bg_bit_i]}};
      end
    end

    // Set misc. signals (ap, bl4, precharge all)
    for(mc_cmd_i = 0 ; mc_cmd_i < DRAM_CMD_SLOTS ; mc_cmd_i = mc_cmd_i + 1) begin
      if(ddr_ap[mc_cmd_i])
        ADR_ns[10*8 + mc_cmd_i*2 +: 2] = {2{`HIGH}};
      else if(ddr_write[mc_cmd_i] | ddr_read[mc_cmd_i])
        ADR_ns[10*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};
      if(ddr_half_bl[mc_cmd_i])
        ADR_ns[12*8 + mc_cmd_i*2 +: 2] = {2{`HIGH}};
      else if(ddr_write[mc_cmd_i] | ddr_read[mc_cmd_i])
        ADR_ns[12*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};
      if(ddr_pall[mc_cmd_i])
        ADR_ns[10*8 + mc_cmd_i*2 +: 2] = {2{`HIGH}};
      else if(ddr_pre[mc_cmd_i])
        ADR_ns[10*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};
      if(ddr_zq[mc_cmd_i]) // ZQ short
        ADR_ns[10*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};
    end

    // For each command slot, decode the commands
    // and hopefully convert those to Xilinx PHY
    // compatible commands.
    for(mc_cmd_i = 0 ; mc_cmd_i < DRAM_CMD_SLOTS ; mc_cmd_i = mc_cmd_i + 1) begin
      if(ddr_nop[mc_cmd_i]) begin // NOP
         // set chip select to HI
        CS_n_ns[mc_cmd_i*1*2 +: 1*2] = {1*2{`HIGH}};
      end
      else if(ddr_act[mc_cmd_i]) begin // Activate ROW
        // There seems to be something wrong with the dfi_cs signal widths
        // coming from the mc. Consider LSBs as valid CS signals for now
        CS_n_ns[mc_cmd_i*1*2 +: 1*2] = {2*1{`LOW}};
        ACT_n_ns[mc_cmd_i*2 +: 2] = {2{`LOW}};
      end // Activate
      else if(ddr_read[mc_cmd_i] || ddr_write[mc_cmd_i]) begin // DDR Read or Write
        mcCasSlot_ns = mc_cmd_i[0 +: 2];
        CS_n_ns[mc_cmd_i*1*2 +: 1*2] = {2*1{`LOW}};
        if(ddr_write[mc_cmd_i]) begin // Write burst
          ADR_ns[`ADDR_WIDTH*8-3*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};  // WE
          ADR_ns[`ADDR_WIDTH*8-2*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};  // CAS
          ADR_ns[`ADDR_WIDTH*8-8   + mc_cmd_i*2 +: 2] = {2{`HIGH}}; // ~RAS
          //fifo_wr_en = HIGH;
          WrCAS_ns = `HIGH;
        end
        else begin // Read burst
          ADR_ns[`ADDR_WIDTH*8-3*8 + mc_cmd_i*2 +: 2] = {2{`HIGH}}; // ~WE
          ADR_ns[`ADDR_WIDTH*8-2*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};  // CAS
          ADR_ns[`ADDR_WIDTH*8-8   + mc_cmd_i*2 +: 2] = {2{`HIGH}}; // ~RAS
          RdCAS_ns = `HIGH;
          iss_dummy_read_ns = read_will_be_dummy_r;
          read_will_be_dummy_ns = `LOW;
        end
      end // DDR Read-Write
      else if(ddr_pre[mc_cmd_i]) begin // Precharge
          CS_n_ns[mc_cmd_i*1*2 +: 1*2] = {2*1{`LOW}};
          ADR_ns[`ADDR_WIDTH*8-3*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};  // WE
          ADR_ns[`ADDR_WIDTH*8-2*8 + mc_cmd_i*2 +: 2] = {2{`HIGH}}; // ~CAS
          ADR_ns[`ADDR_WIDTH*8-8   + mc_cmd_i*2 +: 2] = {2{`LOW}};  // RAS
      end // Precharge
      else if(ddr_ref[mc_cmd_i]) begin // Refresh
          CS_n_ns[mc_cmd_i*1*2 +: 1*2] = {2*1{`LOW}};
          ADR_ns[`ADDR_WIDTH*8-3*8 + mc_cmd_i*2 +: 2] = {2{`HIGH}}; // ~WE
          ADR_ns[`ADDR_WIDTH*8-2*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};  // CAS
          ADR_ns[`ADDR_WIDTH*8-8   + mc_cmd_i*2 +: 2] = {2{`LOW}};  // RAS
      end
      else if(ddr_zq[mc_cmd_i]) begin // ZQ Calib
          CS_n_ns[mc_cmd_i*1*2 +: 1*2] = {2*1{`LOW}};
          ADR_ns[`ADDR_WIDTH*8-3*8 + mc_cmd_i*2 +: 2] = {2{`LOW}};   // WE
          ADR_ns[`ADDR_WIDTH*8-2*8 + mc_cmd_i*2 +: 2] = {2{`HIGH}};  // ~CAS
          ADR_ns[`ADDR_WIDTH*8-8   + mc_cmd_i*2 +: 2] = {2{`HIGH}};  // ~RAS
      end
    end // decode block end

    if(WrCAS_r) begin
        if(slot1_full && slot2_full && wrDataEn_r) begin
            wrDataBuf_ns[0+:DQ_BURST*DQ_WIDTH] = wrDataBuf[DQ_BURST*DQ_WIDTH +: DQ_BURST*DQ_WIDTH];
            wrDataBuf_ns[DQ_BURST*DQ_WIDTH+:DQ_BURST*DQ_WIDTH] = ddr_wdata_r;
        end
        else if (slot1_full && wrDataEn_r) begin
            wrDataBuf_ns[0+:DQ_BURST*DQ_WIDTH] = ddr_wdata_r;
        end
        else if (slot1_full) begin
            wrDataBuf_ns[DQ_BURST*DQ_WIDTH+:DQ_BURST*DQ_WIDTH] = ddr_wdata_r;
            slot2_full_ns = `HIGH;
        end
        else begin
            wrDataBuf_ns[0+:DQ_BURST*DQ_WIDTH] = ddr_wdata_r;
            slot1_full_ns = `HIGH;
        end
    end

		// We handle the cases where a wrDataEn and dfi CAS commands
		// arrive at the same time
    if(wrDataEn_r && ~WrCAS_r) begin
			if(slot1_full && slot2_full) begin
				wrDataBuf_ns[0+:DQ_BURST*DQ_WIDTH] = wrDataBuf[DQ_BURST*DQ_WIDTH +: DQ_BURST*DQ_WIDTH];
				slot2_full_ns = `LOW;
			end
			else if (slot1_full) begin
				slot1_full_ns = `LOW;
			end
    end

    if(rdDataEn) begin
      if(RdCAS_r) // issued another CAS read this cycle
        iss_dummy_read_ns = ddr_maint_read;
      else
        iss_dummy_read_ns = `LOW;
    end
    
    gt_data_ready_ns = iss_dummy_read_r & rdDataEn;
    // this assumes CAS_rw_ctr is either 0, 1 or 2
    //mcCasSlot_ns[1] = CAS_rw_ctr[DRAM_CMD_SLOTS-1][1];
    //mcCasSlot_ns[0] = CAS_rw_ctr[DRAM_CMD_SLOTS-1][0];
  end

  always@(posedge clk) begin
    if(rst) begin
      wrDataBuf <= {DQ_WIDTH*DQ_BURST{1'b0}};
      init_calib_complete_r <= 1'b0;
      iss_dummy_read_r <= 1'b0;
      read_will_be_dummy_r <= 1'b0;
      wrDataEn_r <= 1'b0;
      ACT_n_r <= {8{`HIGH}};
      ADR_r <= {`ADDR_WIDTH*8{1'bx}};
      BA_r <= {`BANK_WIDTH*8{1'bx}};
      BG_r <= {`BG_WIDTH*8{1'bx}};
      CS_n_r <= {`CS_WIDTH*8{1'b1}}; //NOP
      ODT_r <= {`ODT_WIDTH*8{1'bx}};
      //fifo_wr_en_r <= 1'b0;
      WrCAS_r <= 1'b0;
      RdCAS_r <= 1'b0;
      mcCasSlot_r <= 2'b0;
      slot1_full <= `LOW;
      slot2_full <= `LOW;
      gt_data_ready_r <= 1'b0;
    end
    else begin
      if(init_calib_complete_r) begin
        ddr_wdata_r <= ddr_wdata;
        slot1_full <= slot1_full_ns;
        slot2_full <= slot2_full_ns;
        wrDataBuf <= wrDataBuf_ns;
        iss_dummy_read_r <= iss_dummy_read_ns;
        read_will_be_dummy_r <= read_will_be_dummy_ns;
        wrDataEn_r <= wrDataEn;
        ACT_n_r <= ACT_n_ns;
        ADR_r <= ADR_ns;
        BA_r <= BA_ns;
        BG_r <= BG_ns;
        CS_n_r <= CS_n_ns;
        ODT_r <= ODT_ns;
        WrCAS_r <= WrCAS_ns;
        RdCAS_r <= RdCAS_ns;
        //fifo_wr_en_r <= fifo_wr_en_ns;
        mcCasSlot_r <= mcCasSlot_ns;
        gt_data_ready_r <= gt_data_ready_ns;
      end
      else begin
        slot1_full <= `LOW;
        slot2_full <= `LOW;
        wrDataBuf <= {DQ_WIDTH*DQ_BURST{1'b0}};
        init_calib_complete_r <= init_calib_complete_r | init_calib_complete;
        iss_dummy_read_r <= `LOW;
        read_will_be_dummy_r <= `LOW;
        ACT_n_r <= {8{`HIGH}};
        ADR_r <= {`ADDR_WIDTH*8{1'b1}};
        BA_r <= {`BANK_WIDTH*8{1'b1}};
        BG_r <= {`BG_WIDTH*8{1'b1}};
        CS_n_r <= {`CS_WIDTH*8{1'b1}};
        WrCAS_r <= 1'b0;
        RdCAS_r <= 1'b0;
        //fifo_wr_en_r <= 1'b0;
        mcCasSlot_r <= 2'b0;
        gt_data_ready_r <= 1'b0;
      end
    end
  end
endmodule