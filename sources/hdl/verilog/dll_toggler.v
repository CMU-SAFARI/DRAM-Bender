`include "parameters.vh"

module dll_toggler #(parameter CKE_WIDTH = 1, RANK_WIDTH = 1, DQ_WIDTH = 64, DRAM_CMD_SLOTS = 4,
										DATA_BUF_ADDR_WIDTH = 5, DBUF_WIDTH = 4, DQ_BURST = 8)

(
  
  input                                             clk,
  input                                             rst,
  input                                             toggle_valid,
  output reg                                        dllt_done,  
  
  // ----------  DDR4 Signals  ----------
  output [7:0]                                      mc_ACT_n,  // DRAM ACT_n command signal for four DRAM clock cycles.
  output [`ADDR_WIDTH*8-1:0]                        mc_ADR,    // DRAM address. There are 8 bits in the fabric interface for each address bit on the DRAM bus.
  output [`BANK_WIDTH*8-1:0]                        mc_BA,     // DRAM bank address. 8 bits for each DRAM bank address.
  output [`BG_WIDTH*8-1:0]                          mc_BG,     // DRAM bank group address.
  output [`CS_WIDTH*8-1:0]                          mc_CS_n,   // DRAM CS_n
  
  // NOTE: CKE is transmitted within another clock domain that is 4x faster than fabric clock.
  output [`CKE_WIDTH*8-1:0]                         mc_CKE,
  output                                            clk_sel
  
  );
    
  wire [13:0] MR1_CONF = 14'b00001100000000;  
    
  reg [`ADDR_WIDTH*8-1:0]       ADR_ns, ADR_r;
  reg [`BANK_WIDTH*8-1:0]       BA_ns, BA_r;
  reg [`BG_WIDTH*8-1:0]         BG_ns, BG_r;
  reg [`CS_WIDTH*8-1:0]         CS_n_ns, CS_n_r;
  reg [`ODT_WIDTH*8-1:0]        ODT_ns, ODT_r;
  reg [`CKE_WIDTH*8-1:0]        CKE_ns, CKE_r;
  
  reg                           clk_sel_ns, clk_sel_r;
  
  assign mc_ACT_n   = {8{`HIGH}};
  assign mc_ADR     = ADR_r;
  assign mc_BA      = BA_r;
  assign mc_BG      = BG_r;
  assign mc_CS_n    = CS_n_r;
  assign mc_CKE     = CKE_r;
  assign clk_sel    = clk_sel_r;
  
  
  // TODO we need to implement the following routine (TO TURN DLL OFF ONLY)
  // 1 - Precharge all banks (IDLE STATE)
  // 2 - Set MR1 A0 to 1 (DISABLE DLL), wait tMOD
  // 3 - Enter self-refresh mode, wait until tCKSRE/tCKSRE_PAR
  // 4 - Change clock frequency
  // 5 - Wait at least tCKSRX (until clock signal stabilizes)
  // 6 - Exit self-refresh mode, keep CKE high from now on
  //     if any ODT feature was enabled in self-ref. mode
  //     ODT signal must be LOW.
  // 7 - Wait tXS and set mode registers to appropriate values
  //     (UG says that CL, CWL and WR may need to be updated),
  //     wait for another tMOD 
  
  localparam IDLE_S                 = 0;
  localparam IDLE_WAIT_S            = 1;
  localparam SET_MR_1_S             = 2;
  localparam WAIT_MR_1_S            = 3;
  localparam ENTER_SELF_REF_S       = 4;
  localparam WAIT_ENTER_SELF_REF_S  = 5;
  localparam CHANGE_CLK_FREQ_S      = 6;
  localparam WAIT_CHANGE_CLK_FREQ_S = 7;
  localparam EXIT_SELF_REF_S        = 8;
  localparam WAIT_EXIT_SELF_REF_S   = 9;
  
  localparam T_PRECHARGE      = 5;    // in terms of MC cycles (which is 4x less frequent than the DDR4)
  localparam T_MOD            = 24;   // Max(24CK,15ns)
  localparam T_CKSRE          = 300;  // Max(5CK,10ns)
  localparam T_CKSRX          = 300;  // Max(5CK, 10ns) + additional room for clock to stabilize;
  localparam T_XS             = 1000;
  
  
  reg[3:0] state_r, state_ns;
  
  reg[9:0] wait_r, wait_ns;
  
  integer adr_bit_i;
  
  always @* begin
    // Set bank and bank group signals
    dllt_done  = `LOW;
    ADR_ns     = {`ADDR_WIDTH*8{`HIGH}};
    BG_ns      = {`BG_WIDTH*8{`LOW}};
    BA_ns      = {`BANK_WIDTH*8{`LOW}};
    CS_n_ns    = {`CS_WIDTH*8{`HIGH}}; // by default we don't issue any commands
    CKE_ns     = CKE_r;              // register this signal because it needs to be LOW during self-ref.
    wait_ns    = wait_r;
    state_ns   = state_r;
    clk_sel_ns = clk_sel_r;
    case (state_r)
      IDLE_S: begin
        if(toggle_valid) begin
          CS_n_ns[1:0] = {2*`CS_WIDTH{`LOW}};
          ADR_ns[`ADDR_WIDTH*8-3*8 +: 2] = {2{`LOW}};  // WE
          ADR_ns[`ADDR_WIDTH*8-2*8 +: 2] = {2{`HIGH}}; // ~CAS
          ADR_ns[`ADDR_WIDTH*8-8   +: 2] = {2{`LOW}};  // RAS
          ADR_ns[10*8 +: 2]              = {2{`HIGH}}; // Pre ALL
          wait_ns                        = T_PRECHARGE;
          state_ns                       = IDLE_WAIT_S;
        end
      end
      IDLE_WAIT_S: begin
        if(wait_r > 0)
          wait_ns = wait_r - 1'b1;
        else
          state_ns = SET_MR_1_S;
      end
      SET_MR_1_S: begin
        CS_n_ns[1:0] = {2*`CS_WIDTH{`LOW}};
        ADR_ns[`ADDR_WIDTH*8-3*8 +: 2] = {2{`LOW}};  // WE
        ADR_ns[`ADDR_WIDTH*8-2*8 +: 2] = {2{`LOW}};  // CAS
        ADR_ns[`ADDR_WIDTH*8-8   +: 2] = {2{`LOW}};  // RAS
        for(adr_bit_i = 0 ; adr_bit_i < 14 ; adr_bit_i = adr_bit_i + 1) begin
            ADR_ns[adr_bit_i*8 +: 2] =
                      {2{MR1_CONF[adr_bit_i]}};
        end
        // Bank + Bank group bits indicate which register this MRS is writing to.
        BA_ns[0 +: 2]  = {2{`HIGH}}; // Select MR1
        ADR_ns[0 +: 2] = {2{`LOW}};  // Set A0 to 0
        state_ns = WAIT_MR_1_S;
        wait_ns  = T_MOD;
      end
      WAIT_MR_1_S: begin
        if(wait_r > 0)
          wait_ns = wait_r - 1'b1;
        else
          state_ns = ENTER_SELF_REF_S;
      end
      ENTER_SELF_REF_S: begin
        CKE_ns = `LOW;
        CS_n_ns[1:0] = {2*`CS_WIDTH{`LOW}};
        ADR_ns[`ADDR_WIDTH*8-3*8 +: 2] = {2{`HIGH}};  // ~WE
        ADR_ns[`ADDR_WIDTH*8-2*8 +: 2] = {2{`LOW}};  // CAS
        ADR_ns[`ADDR_WIDTH*8-8   +: 2] = {2{`LOW}};  // RAS
        state_ns = WAIT_ENTER_SELF_REF_S;
        wait_ns  = T_CKSRE;
      end
      WAIT_ENTER_SELF_REF_S: begin
        if(wait_r > 0)
          wait_ns = wait_r - 1'b1;
        else begin
          state_ns = CHANGE_CLK_FREQ_S;            
        end
      end
      CHANGE_CLK_FREQ_S: begin
        clk_sel_ns = ~clk_sel_r;
        wait_ns    = T_CKSRX;
        state_ns   = WAIT_CHANGE_CLK_FREQ_S;
      end
      WAIT_CHANGE_CLK_FREQ_S: begin
        if(wait_r > 0)
          wait_ns = wait_r - 1'b1;
        else begin
          state_ns = EXIT_SELF_REF_S;
        end
      end
      EXIT_SELF_REF_S: begin
        CKE_ns = {`CKE_WIDTH*8{`HIGH}};
        CS_n_ns[7:0] = {8*`CS_WIDTH{`HIGH}};
        ADR_ns[`ADDR_WIDTH*8-3*8 +: 2] = {2{`HIGH}};  // ~WE
        ADR_ns[`ADDR_WIDTH*8-2*8 +: 2] = {2{`HIGH}};  // CAS
        ADR_ns[`ADDR_WIDTH*8-8   +: 2] = {2{`HIGH}};  // RAS
        state_ns = WAIT_EXIT_SELF_REF_S;
        wait_ns  = T_XS;
      end
      WAIT_EXIT_SELF_REF_S: begin
        CS_n_ns[7:0] = {8*`CS_WIDTH{`HIGH}};
        if(wait_r > 0)
          wait_ns = wait_r - 1'b1;
        else begin
          state_ns  = IDLE_S;
          dllt_done = `HIGH;           
        end
      end
    endcase 
  
  end
  
  always @(posedge clk) begin
    if(rst) begin
      state_r   <= IDLE_S;
      wait_r    <= `LOW;
      clk_sel_r <= `LOW;
      CKE_r     <= {`CKE_WIDTH*8{`HIGH}};
      ADR_r      = {`ADDR_WIDTH*8{`LOW}};
      BG_r       = {`BG_WIDTH*8{`LOW}};
      BA_r       = {`BANK_WIDTH*8{`LOW}};
      CS_n_r     = {`CS_WIDTH*8{`HIGH}};
    end
    else begin
      state_r   <= state_ns;
      wait_r    <= wait_ns;
      clk_sel_r <= clk_sel_ns;
      CKE_r <= CKE_ns;
      ADR_r <= ADR_ns;
      BA_r <= BA_ns;
      BG_r <= BG_ns;
      CS_n_r <= CS_n_ns;
    end
  end
  
endmodule
