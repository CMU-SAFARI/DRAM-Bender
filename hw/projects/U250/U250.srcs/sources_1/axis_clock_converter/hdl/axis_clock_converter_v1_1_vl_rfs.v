//  (c) Copyright 2011-2013 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES. 
//-----------------------------------------------------------------------------
//
// Register Slice
//   Generic single-channel AXI pipeline register on forward and/or reverse signal path
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   axic_sync_clock_converter
//
//--------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *)
module axis_clock_converter_v1_1_23_axisc_sync_clock_converter # (
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
  parameter C_FAMILY     = "virtex6",
  parameter integer C_PAYLOAD_WIDTH = 32,
  parameter integer C_S_ACLK_RATIO = 1,
  parameter integer C_M_ACLK_RATIO = 1,
  parameter integer C_MODE = 1  // 0 = light-weight (1-deep); 1 = fully-pipelined (2-deep)
  )
 (
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  input wire                         SAMPLE_CYCLE_EARLY,
  input wire                         SAMPLE_CYCLE,
  // Slave side
  input  wire                        S_ACLK,
  input  wire                        S_ARESETN,
  input  wire [C_PAYLOAD_WIDTH-1:0]  S_PAYLOAD,
  input  wire                        S_VALID,
  output wire                        S_READY,

  // Master side
  input  wire                        M_ACLK,
  input  wire                        M_ARESETN,
  output wire [C_PAYLOAD_WIDTH-1:0]  M_PAYLOAD,
  output wire                        M_VALID,
  input  wire                        M_READY
);

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////
localparam [1:0] ZERO = 2'b10;
localparam [1:0] ONE  = 2'b11;
localparam [1:0] FULL = 2'b01;
localparam [1:0] INIT = 2'b00;
localparam integer P_LIGHT_WT = 0;
localparam integer P_FULLY_REG = 1;

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
////////////////////////////////////////////////////////////////////////////////

generate
  if (C_S_ACLK_RATIO == C_M_ACLK_RATIO) begin : gen_passthru
    assign M_PAYLOAD = S_PAYLOAD;
    assign M_VALID   = S_VALID;
    assign S_READY   = M_READY;      
  end else begin : gen_sync_clock_converter
    wire s_sample_cycle;
    wire s_sample_cycle_early;
    wire m_sample_cycle;
    wire m_sample_cycle_early;

    wire slow_aclk;
    wire slow_areset;
    reg  s_areset_r;
    reg  m_areset_r;
   
    reg  s_ready_r; 
    wire s_ready_ns; 
    reg  m_valid_r; 
    wire m_valid_ns; 
    reg  [C_PAYLOAD_WIDTH-1:0] m_payload_r;
    reg  [C_PAYLOAD_WIDTH-1:0] m_storage_r;
    wire [C_PAYLOAD_WIDTH-1:0] m_payload_ns; 
    wire [C_PAYLOAD_WIDTH-1:0] m_storage_ns; 
    reg  m_ready_hold;
    wire m_ready_sample;
    wire load_payload;
    wire load_storage;
    wire load_payload_from_storage;
    reg [1:0] state;
    reg [1:0] next_state;
    
    always @(posedge S_ACLK) begin
      s_areset_r <= ~(S_ARESETN & M_ARESETN);
    end
  
    always @(posedge M_ACLK) begin
      m_areset_r <= ~(S_ARESETN & M_ARESETN);
    end

    assign slow_aclk   = (C_S_ACLK_RATIO > C_M_ACLK_RATIO) ? M_ACLK   : S_ACLK;
    assign slow_areset = (C_S_ACLK_RATIO > C_M_ACLK_RATIO) ? m_areset_r : s_areset_r;
    assign s_sample_cycle_early = (C_S_ACLK_RATIO > C_M_ACLK_RATIO) ? SAMPLE_CYCLE_EARLY : 1'b1;
    assign s_sample_cycle       = (C_S_ACLK_RATIO > C_M_ACLK_RATIO) ? SAMPLE_CYCLE : 1'b1;
    assign m_sample_cycle_early = (C_S_ACLK_RATIO > C_M_ACLK_RATIO) ? 1'b1 : SAMPLE_CYCLE_EARLY;
    assign m_sample_cycle       = (C_S_ACLK_RATIO > C_M_ACLK_RATIO) ? 1'b1 : SAMPLE_CYCLE;

    // Output flop for S_READY, value is encoded into state machine.
    assign s_ready_ns = (C_S_ACLK_RATIO > C_M_ACLK_RATIO) ? state[1] & (state != INIT) : next_state[1];

    always @(posedge S_ACLK) begin 
      if (s_areset_r) begin
        s_ready_r <= 1'b0;
      end
      else begin
        s_ready_r <= s_sample_cycle_early ? s_ready_ns : 1'b0;
      end
    end

    assign S_READY = s_ready_r;

    // Output flop for M_VALID
    assign m_valid_ns = next_state[0];

    always @(posedge M_ACLK) begin 
      if (m_areset_r) begin
        m_valid_r <= 1'b0;
      end
      else begin
        m_valid_r <= m_sample_cycle ? m_valid_ns : m_valid_r & ~M_READY;
      end
    end

    assign M_VALID = m_valid_r;

    // Hold register for M_READY when M_ACLK is fast.
    always @(posedge M_ACLK) begin 
      if (m_areset_r) begin
        m_ready_hold <= 1'b0;
      end
      else begin
        m_ready_hold <= m_sample_cycle ? 1'b0 : m_ready_sample;
      end
    end

    assign m_ready_sample = (M_READY ) | m_ready_hold;
    // Output/storage flops for PAYLOAD
    assign m_payload_ns = ~load_payload ? m_payload_r :
                           load_payload_from_storage ? m_storage_r : 
                           S_PAYLOAD;

    assign m_storage_ns = (C_MODE == P_FULLY_REG) ? (load_storage ? S_PAYLOAD : m_storage_r) : {C_PAYLOAD_WIDTH{1'b0}};

    always @(posedge slow_aclk) begin 
      m_payload_r <= m_payload_ns;
      m_storage_r <= (C_MODE == P_FULLY_REG) ? m_storage_ns : 0;
    end

    assign M_PAYLOAD = m_payload_r;

    // load logic
    assign load_storage = (C_MODE == P_FULLY_REG) && (state != FULL);
    assign load_payload = m_ready_sample || (state == ZERO);
    assign load_payload_from_storage = (C_MODE == P_FULLY_REG) && (state == FULL) && m_ready_sample;
    
    // State machine
    always @(posedge slow_aclk) begin 
      state <= next_state;
    end

    always @* begin 
      if (slow_areset) begin 
        next_state = INIT;
      end else begin
        case (state)
          INIT: begin
            next_state = ZERO;
          end
          // No transaction stored locally
          ZERO: begin
            if (S_VALID) begin
              next_state = (C_MODE == P_FULLY_REG) ? ONE : FULL; // Push from empty
            end
            else begin
              next_state = ZERO;
            end
          end

          // One transaction stored locally
          ONE: begin
            if (m_ready_sample & ~S_VALID) begin 
              next_state = ZERO; // Read out one so move to ZERO
            end
            else if (~m_ready_sample & S_VALID) begin
              next_state = FULL;  // Got another one so move to FULL
            end
            else begin
              next_state = ONE;
            end
          end

          // Storage registers full
          FULL: begin 
            if (m_ready_sample) begin
              next_state = (C_MODE == P_FULLY_REG) ? ONE : ZERO; // Pop from full
            end
            else begin
              next_state = FULL;
            end
          end
          default: begin
            next_state = ZERO;
          end
        endcase // case (state)
      end
    end
  end // gen_sync_clock_converter
  endgenerate
endmodule // axisc_sync_clock_converter

`default_nettype wire


//  (c) Copyright 2011-2013 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES. 
//-----------------------------------------------------------------------------
//
// Register Slice
//   Generic single-channel AXI pipeline register on forward and/or reverse signal path
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   axic_sync_clock_converter
//
//--------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *)
module axis_clock_converter_v1_1_23_axisc_async_clock_converter # (
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
  parameter integer C_PAYLOAD_WIDTH      = 32,
  parameter integer C_SYNCHRONIZER_STAGE = 3,
  parameter integer C_FIFO_DEPTH         = 32

  )
 (
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  // Slave side
  input  wire                        s_aclk,
  input  wire                        s_aresetn,
  input  wire [C_PAYLOAD_WIDTH-1:0]  s_payload,
  input  wire                        s_valid,
  output wire                        s_ready,

  // Master side
  input  wire                        m_aclk,
  input  wire                        m_aresetn,
  output wire [C_PAYLOAD_WIDTH-1:0]  m_payload,
  output wire                        m_valid,
  input  wire                        m_ready
);

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////
`include "axis_infrastructure_v1_1_0.vh"

////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////
localparam integer LP_COUNT_WIDTH = f_clogb2(C_FIFO_DEPTH) + 1; // Set to 1 + Depth.
localparam integer LP_PROG_FULL = C_FIFO_DEPTH - 5; // Set to valid value to avoid DRC error.

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////
wire m_areset_i;
reg s_and_m_areset_r = 1'b0;
wire s_full;

////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
////////////////////////////////////////////////////////////////////////////////
// Synchronize reset into s_aclk domain and combine with s_aresetn.
xpm_cdc_sync_rst #(
  .DEST_SYNC_FF    ( C_SYNCHRONIZER_STAGE ) 
)
inst_xpm_cdc_sync_rst (
  .src_rst  ( ~m_aresetn ) ,
  .dest_rst ( m_areset_i     ) ,
  .dest_clk ( s_aclk     ) 
);

always @(posedge s_aclk) begin 
  s_and_m_areset_r <= ~s_aresetn | m_areset_i;
end

/*
XPM_FIFO instantiation template for Asynchronous FIFO configurations
Refer to the targeted device family architecture libraries guide for XPM_FIFO documentation
=======================================================================================================================

Parameter usage table, organized as follows:
+---------------------------------------------------------------------------------------------------------------------+
| Parameter name          | Data type          | Restrictions, if applicable                                          |
|---------------------------------------------------------------------------------------------------------------------|
| Description                                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
+---------------------------------------------------------------------------------------------------------------------+
| FIFO_MEMORY_TYPE        | String             | Must be "auto", "block", or "distributed"                            |
|---------------------------------------------------------------------------------------------------------------------|
| Designate the fifo memory primitive (resource type) to use:                                                         |
|   "auto": Allow Vivado Synthesis to choose                                                                          |
|   "block": Block RAM FIFO                                                                                           |
|   "distributed": Distributed RAM FIFO                                                                               |
+---------------------------------------------------------------------------------------------------------------------+
| FIFO_WRITE_DEPTH        | Integer            | Must be between 16 and 4194304                                       |
|---------------------------------------------------------------------------------------------------------------------|
| Defines the FIFO Write Depth, must be power of two                                                                  |
| In standard READ_MODE, the effective depth = FIFO_WRITE_DEPTH-1                                                     |
| In First-Word-Fall-Through READ_MODE, the effective depth = FIFO_WRITE_DEPTH+1                                      |
+---------------------------------------------------------------------------------------------------------------------+
| RELATED_CLOCKS          | Integer            | Must be 0 or 1                                                       |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies if the wr_clk and rd_clk are related having the same source but different clock ratios                    |
+---------------------------------------------------------------------------------------------------------------------+
| WRITE_DATA_WIDTH        | Integer            | Must be between 1 and 4096                                           |
|---------------------------------------------------------------------------------------------------------------------|
| Defines the width of the write data port, din                                                                       |
+---------------------------------------------------------------------------------------------------------------------+
| WR_DATA_COUNT_WIDTH     | Integer            | Must be between 1 and log2(FIFO_WRITE_DEPTH)+1                       |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the width of wr_data_count                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| READ_MODE               | String             | Must be "std" or "fwft"                                              |
|---------------------------------------------------------------------------------------------------------------------|
|  "std": standard read mode                                                                                          |
|  "fwft": First-Word-Fall-Through read mode                                                                          |
+---------------------------------------------------------------------------------------------------------------------+
| FIFO_READ_LATENCY       | Integer            | Must be >= 0                                                         |
|---------------------------------------------------------------------------------------------------------------------|
|  Number of output register stages in the read data path                                                             |
|  If READ_MODE = "fwft", then the only applicable value is 0.                                                        |
+---------------------------------------------------------------------------------------------------------------------+
| FULL_RESET_VALUE        | Integer            | Must be 0 or 1                                                       |
|---------------------------------------------------------------------------------------------------------------------|
|---------------------------------------------------------------------------------------------------------------------|
|  Sets FULL, PROG_FULL and ALMOST_FULL to FULL_RESET_VALUE during reset                                              |
+---------------------------------------------------------------------------------------------------------------------+
| USE_ADV_FEATURES        | String             | Must be between "0000" and "1F1F"                                    |
|---------------------------------------------------------------------------------------------------------------------|
|  Enables data_valid, almost_empty, rd_data_count, prog_empty, underflow, wr_ack, almost_full, wr_data_count,        |
|  prog_full, overflow features                                                                                       |
|    Setting USE_ADV_FEATURES[0]  to 1 enables overflow flag;     Default value of this bit is 1                      |
|    Setting USE_ADV_FEATURES[1]  to 1 enables prog_full flag;    Default value of this bit is 1                      |
|    Setting USE_ADV_FEATURES[2]  to 1 enables wr_data_count;     Default value of this bit is 1                      |
|    Setting USE_ADV_FEATURES[3]  to 1 enables almost_full flag;  Default value of this bit is 0                      |
|    Setting USE_ADV_FEATURES[4]  to 1 enables wr_ack flag;       Default value of this bit is 0                      |
|    Setting USE_ADV_FEATURES[8]  to 1 enables underflow flag;    Default value of this bit is 1                      |
|    Setting USE_ADV_FEATURES[9]  to 1 enables prog_empty flag;   Default value of this bit is 1                      |
|    Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count;     Default value of this bit is 1                      |
|    Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                      |
|    Setting USE_ADV_FEATURES[12] to 1 enables data_valid flag;   Default value of this bit is 0                      |
+---------------------------------------------------------------------------------------------------------------------+
| READ_DATA_WIDTH         | Integer            | Must be between >= 1                                                 |
|---------------------------------------------------------------------------------------------------------------------|
| Defines the width of the read data port, dout                                                                       |
+---------------------------------------------------------------------------------------------------------------------+
| RD_DATA_COUNT_WIDTH     | Integer            | Must be between 1 and log2(FIFO_READ_DEPTH)+1                        |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the width of rd_data_count                                                                                |
| FIFO_READ_DEPTH = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH                                                 |
+---------------------------------------------------------------------------------------------------------------------+
| CDC_SYNC_STAGES         | Integer            | Must be between 2 to 8                                               |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the number of synchronization stages on the CDC path                                                      |
| Must be < 5 if FIFO_WRITE_DEPTH = 16                                                                                |
+---------------------------------------------------------------------------------------------------------------------+
| ECC_MODE                | String             | Must be "no_ecc" or "en_ecc"                                         |
|---------------------------------------------------------------------------------------------------------------------|
| "no_ecc" : Disables ECC                                                                                             |
| "en_ecc" : Enables both ECC Encoder and Decoder                                                                     |
+---------------------------------------------------------------------------------------------------------------------+
| PROG_FULL_THRESH        | Integer            | Must be between "Min_Value" and "Max_Value"                          |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.                    |
| Min_Value = 3 + (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))+CDC_SYNC_STAGES                                |
| Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))                             |
| If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1                                           |
+---------------------------------------------------------------------------------------------------------------------+
| PROG_EMPTY_THRESH       | Integer            | Must be between "Min_Value" and "Max_Value"                          |
|---------------------------------------------------------------------------------------------------------------------|
| Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted                     |
| Min_Value = 3 + (READ_MODE_VAL*2)                                                                                   |
| Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2)                                                                |
| If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1                                           |
+---------------------------------------------------------------------------------------------------------------------+
| DOUT_RESET_VALUE        | String             | Must be >="0". Valid hexa decimal value                              |
|---------------------------------------------------------------------------------------------------------------------|
| Reset value of read data path.                                                                                      |
+---------------------------------------------------------------------------------------------------------------------+
| WAKEUP_TIME             | Integer            | Must be 0 or 2                                                       |
|---------------------------------------------------------------------------------------------------------------------|
| 0 : Disable sleep.                                                                                                  |
| 2 : Use Sleep Pin.                                                                                                  |
+---------------------------------------------------------------------------------------------------------------------+

Port usage table, organized as follows:
+---------------------------------------------------------------------------------------------------------------------+
| Port name      | Direction | Size, in bits                         | Domain | Sense       | Handling if unused      |
|---------------------------------------------------------------------------------------------------------------------|
| Description                                                                                                         |
+---------------------------------------------------------------------------------------------------------------------+
+---------------------------------------------------------------------------------------------------------------------+
| sleep          | Input     | 1                                     |        | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.                              |
| Synchronous to the slower of wr_clk and rd_clk.                                                                     |
+---------------------------------------------------------------------------------------------------------------------+
| rst            | Input     | 1                                     | wr_clk | Active-high | Required                |
+---------------------------------------------------------------------------------------------------------------------+
| Reset: Must be synchronous to wr_clk. Must be applied only when wr_clk and rd_clk are stable and free-running.      |
| Once reset is applied to FIFO, the subsequent reset must be applied only when wr_rst_busy becomes zero from one.    |
+---------------------------------------------------------------------------------------------------------------------+
| wr_clk         | Input     | 1                                     |        | Rising edge | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Write clock: Used for write operation. wr_clk must be a free running clock.                                         |
+---------------------------------------------------------------------------------------------------------------------+
| wr_en          | Input     | 1                                     | wr_clk | Active-high | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO.        |
| Must be held active-low when rst or wr_rst_busy or rd_rst_busy is active high.                                      |
+---------------------------------------------------------------------------------------------------------------------+
| din            | Input     | WRITE_DATA_WIDTH                      | wr_clk |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Write Data: The input data bus used when writing the FIFO.                                                          |
+---------------------------------------------------------------------------------------------------------------------+
| full           | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Full Flag: When asserted, this signal indicates that the FIFO is full.                                              |
| Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive       |
| to the contents of the FIFO.                                                                                        |
+---------------------------------------------------------------------------------------------------------------------+
| overflow       | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected,              |
| because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.                      |
+---------------------------------------------------------------------------------------------------------------------+
| wr_rst_busy    | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.                   |
+---------------------------------------------------------------------------------------------------------------------+
| almost_full    | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.|
+---------------------------------------------------------------------------------------------------------------------+
| wr_ack         | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.    |
+---------------------------------------------------------------------------------------------------------------------+
| rd_clk         | Input     | 1                                     |        | Rising edge | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Read clock: Used for read operation. rd_clk must be a free running clock.                                           |
+---------------------------------------------------------------------------------------------------------------------+
| rd_en          | Input     | 1                                     | rd_clk | Active-high | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO         |
| Must be held active-low when rst or wr_rst_busy or rd_rst_busy is active high.                                      |
+---------------------------------------------------------------------------------------------------------------------+
| dout           | Output    | READ_DATA_WIDTH                       | rd_clk |             | Required                |
|---------------------------------------------------------------------------------------------------------------------|
| Read Data: The output data bus is driven when reading the FIFO.                                                     |
+---------------------------------------------------------------------------------------------------------------------+
| empty          | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Empty Flag: When asserted, this signal indicates that the FIFO is empty.                                            |
| Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.     |
+---------------------------------------------------------------------------------------------------------------------+
| underflow      | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected                     |
| because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.                                   |
+---------------------------------------------------------------------------------------------------------------------+
| rd_rst_busy    | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.                     |
+---------------------------------------------------------------------------------------------------------------------+
| prog_full      | Output    | 1                                     | wr_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal            |
| to the programmable full threshold value.                                                                           |
| It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.          |
+---------------------------------------------------------------------------------------------------------------------+
| wr_data_count  | Output    | WR_DATA_COUNT_WIDTH                   | wr_clk |             | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Write Data Count: This bus indicates the number of words written into the FIFO.                                     |
+---------------------------------------------------------------------------------------------------------------------+
| prog_empty     | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal              |
| to the programmable empty threshold value.                                                                          |
| It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.              |
+---------------------------------------------------------------------------------------------------------------------+
| rd_data_count  | Output    | RD_DATA_COUNT_WIDTH                   | rd_clk |             | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Read Data Count: This bus indicates the number of words read from the FIFO.                                         |
+---------------------------------------------------------------------------------------------------------------------+
| almost_empty   | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to|
| empty.                                                                                                              |
+---------------------------------------------------------------------------------------------------------------------+
| data_valid     | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).        |
+---------------------------------------------------------------------------------------------------------------------+
| injectsbiterr  | Intput    | 1                                     | wr_clk | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or                  |
| built-in FIFO macros.                                                                                               |
+---------------------------------------------------------------------------------------------------------------------+
| injectdbiterr  | Intput    | 1                                     | wr_clk | Active-high | Tie to 1'b0             |
|---------------------------------------------------------------------------------------------------------------------|
| Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or                  |
| built-in FIFO macros.                                                                                               |
+---------------------------------------------------------------------------------------------------------------------+
| sbiterr        | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.                             |
+---------------------------------------------------------------------------------------------------------------------+
| dbiterr        | Output    | 1                                     | rd_clk | Active-high | Leave open              |
|---------------------------------------------------------------------------------------------------------------------|
| Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
+---------------------------------------------------------------------------------------------------------------------+
*/

//  xpm_fifo_async      : In order to incorporate this function into the design, the following module instantiation
//       Verilog        : needs to be placed in the body of the design code.  The default values for the parameters
//        module        : may be changed to meet design requirements.  The instance name (xpm_fifo_async)
//     instantiation    : and/or the port declarations within the parenthesis may be changed to properly reference and
//         code         : connect this function to the design.  All inputs and outputs must be connected, unless
//                      : otherwise specified.

// xpm_fifo_async: Asynchronous FIFO
// Xilinx Parameterized Macro, Version 2018.1
xpm_fifo_async # (

  .FIFO_MEMORY_TYPE    ( "distributed"   ) , // string; "auto", "block", or "distributed";
  .ECC_MODE            ( "no_ecc"        ) , // string; "no_ecc" or "en_ecc";
  .RELATED_CLOCKS      ( 0               ) , // positive integer; 0 or 1
  .FIFO_WRITE_DEPTH    ( C_FIFO_DEPTH    ) , // positive integer
  .WRITE_DATA_WIDTH    ( C_PAYLOAD_WIDTH ) , // positive integer
  .WR_DATA_COUNT_WIDTH ( LP_COUNT_WIDTH  ) , // positive integer
  .PROG_FULL_THRESH    ( LP_PROG_FULL    ) , // positive integer
  .FULL_RESET_VALUE    ( 1               ) , // positive integer; 0 or 1 
  .USE_ADV_FEATURES    ( "1000"          ) , // string; "0000" to "1F1F"; "1000" = enable data_valid.
  .READ_MODE           ( "fwft"          ) , // string; "std" or "fwft";
  .FIFO_READ_LATENCY   ( 1               ) , // positive integer;
  .READ_DATA_WIDTH     ( C_PAYLOAD_WIDTH ) , // positive integer
  .RD_DATA_COUNT_WIDTH ( LP_COUNT_WIDTH  ) , // positive integer
  .PROG_EMPTY_THRESH   ( 10              ) , // positive integer
  .DOUT_RESET_VALUE    ( "0"             ) , // string
  .CDC_SYNC_STAGES     ( C_SYNCHRONIZER_STAGE ) , // positive integer
  .WAKEUP_TIME         ( 0               )   // positive integer; 0 or 2;

) xpm_fifo_async_inst (

  .rst           ( s_and_m_areset_r ) ,
  .wr_clk        ( s_aclk           ) ,
  .wr_en         ( s_valid          ) ,
  .din           ( s_payload        ) ,
  .full          ( s_full           ) ,
  .overflow      (                  ) ,
  .prog_full     (                  ) ,
  .wr_data_count (                  ) ,
  .almost_full   (                  ) ,
  .wr_ack        (                  ) ,
  .wr_rst_busy   (                  ) ,
  .rd_clk        ( m_aclk           ) ,
  .rd_en         ( m_ready          ) ,
  .dout          ( m_payload        ) ,
  .empty         (                  ) ,
  .underflow     (                  ) ,
  .rd_rst_busy   (                  ) ,
  .prog_empty    (                  ) ,
  .rd_data_count (                  ) ,
  .almost_empty  (                  ) ,
  .data_valid    ( m_valid          ) ,
  .sleep         ( 1'b0             ) ,
  .injectsbiterr ( 1'b0             ) ,
  .injectdbiterr ( 1'b0             ) ,
  .sbiterr       (                  ) ,
  .dbiterr       (                  ) 

);

// End of xpm_fifo_async instance declaration

assign s_ready = ~s_full;

endmodule // axisc_async_clock_converter

`default_nettype wire


//  (c) Copyright 2011-2013 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES. 
//-----------------------------------------------------------------------------
//
// Register Slice
//   Generic single-channel AXI pipeline register on forward and/or reverse signal path
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   axic_register_slice
//
//--------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *)
module axis_clock_converter_v1_1_23_axisc_sample_cycle_ratio # (
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
  parameter C_RATIO = 2 // Must be > 0
  )
 (
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
  input  wire                    SLOW_ACLK,
  input  wire                    FAST_ACLK,

  output wire                    SAMPLE_CYCLE_EARLY,
  output wire                    SAMPLE_CYCLE
);

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////
localparam P_DELAY = C_RATIO > 2 ? C_RATIO-1 : C_RATIO-1; 
////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////
reg                slow_aclk_div2 = 0;
reg                posedge_finder_first;
reg                posedge_finder_second;
wire               first_edge;
wire               second_edge;
reg  [P_DELAY-1:0] sample_cycle_d;
(* shreg_extract = "no" *) reg                sample_cycle_r;


////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
////////////////////////////////////////////////////////////////////////////////
generate
  if (C_RATIO == 1) begin : gen_always_sample
    assign SAMPLE_CYCLE_EARLY = 1'b1;
    assign SAMPLE_CYCLE = 1'b1;
  end
  else begin : gen_sample_cycle
    genvar i;
    always @(posedge SLOW_ACLK) begin 
      slow_aclk_div2 <= ~slow_aclk_div2;
    end

    // Find matching rising edges by clocking slow_aclk_div2 onto faster clock
    always @(posedge FAST_ACLK) begin 
      posedge_finder_first <= slow_aclk_div2;
    end
    always @(posedge FAST_ACLK) begin 
      posedge_finder_second <= ~slow_aclk_div2;
    end

    assign first_edge = slow_aclk_div2 & ~posedge_finder_first;
    assign second_edge = ~slow_aclk_div2 & ~posedge_finder_second;

    always @(*) begin 
      sample_cycle_d[P_DELAY-1] = first_edge | second_edge;
    end
   
    // delay the posedge alignment by C_RATIO - 1 to set the sample cycle as
    // the clock one cycle before the posedge.
    for (i = P_DELAY-1; i > 0; i = i - 1) begin : gen_delay
      always @(posedge FAST_ACLK) begin
        sample_cycle_d[i-1] <= sample_cycle_d[i];
      end
    end

    always @(posedge FAST_ACLK) begin 
      sample_cycle_r <= sample_cycle_d[0];
    end
    assign SAMPLE_CYCLE_EARLY = sample_cycle_d[0];
    assign SAMPLE_CYCLE = sample_cycle_r;
  end
endgenerate

endmodule // axisc_sample_cycle_ratio

`default_nettype wire


//  (c) Copyright 2011-2013 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES. 
//-----------------------------------------------------------------------------
//
// axis_clock_converter
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   axis_clock_converter
//     util_aclken_converter (optional)
//     fifo_generator
//       or
//     axisc_sync_clock_converter
//     util_aclken_converter (optional)
//--------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none

(* DowngradeIPIdentifiedWarnings="yes" *)
module axis_clock_converter_v1_1_23_axis_clock_converter #
(
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
  parameter         C_FAMILY           = "virtex6",
  parameter integer C_AXIS_TDATA_WIDTH = 32,
  parameter integer C_AXIS_TID_WIDTH   = 1,
  parameter integer C_AXIS_TDEST_WIDTH = 1,
  parameter integer C_AXIS_TUSER_WIDTH = 1,
  parameter [31:0]  C_AXIS_SIGNAL_SET  = 32'hFF,
  // C_AXIS_SIGNAL_SET: each bit if enabled specifies which axis optional signals are present
  //   [0] => TREADY present
  //   [1] => TDATA present
  //   [2] => TSTRB present, TDATA must be present
  //   [3] => TKEEP present, TDATA must be present
  //   [4] => TLAST present
  //   [5] => TID present
  //   [6] => TDEST present
  //   [7] => TUSER present
  parameter integer C_IS_ACLK_ASYNC     = 1,
  parameter integer C_SYNCHRONIZER_STAGE = 2,
  parameter integer C_S_AXIS_ACLK_RATIO = 1,
  parameter integer C_M_AXIS_ACLK_RATIO = 2,
  parameter integer C_ACLKEN_CONV_MODE  = 0
  // C_ACLKEN_CONV_MODE: Determines how to handle the clock enable pins during
  // clock conversion
  // 0 -- Clock enables not converted
  // 1 -- s_axis_aclken can toggle,  m_axis_aclken always high.
  // 2 -- s_axis_aclken always high, m_axis_aclken can toggle.
  // 3 -- s_axis_aclken can toggle,  m_axis_aclken can toggle.
  )
  (
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
   // System Signals
   input wire                             s_axis_aresetn,
   input wire                             m_axis_aresetn,
   input wire                             s_axis_aclken,
   input wire                             m_axis_aclken,

   // Slave side
   input  wire                            s_axis_aclk,
   input  wire                            s_axis_tvalid,
   output wire                            s_axis_tready,
   input  wire [C_AXIS_TDATA_WIDTH-1:0]   s_axis_tdata,
   input  wire [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_tstrb,
   input  wire [C_AXIS_TDATA_WIDTH/8-1:0] s_axis_tkeep,
   input  wire                            s_axis_tlast,
   input  wire [C_AXIS_TID_WIDTH-1:0]     s_axis_tid,
   input  wire [C_AXIS_TDEST_WIDTH-1:0]   s_axis_tdest,
   input  wire [C_AXIS_TUSER_WIDTH-1:0]   s_axis_tuser,

   // Master side
   input  wire                            m_axis_aclk,
   output wire                            m_axis_tvalid,
   input  wire                            m_axis_tready,
   output wire [C_AXIS_TDATA_WIDTH-1:0]   m_axis_tdata,
   output wire [C_AXIS_TDATA_WIDTH/8-1:0] m_axis_tstrb,
   output wire [C_AXIS_TDATA_WIDTH/8-1:0] m_axis_tkeep,
   output wire                            m_axis_tlast,
   output wire [C_AXIS_TID_WIDTH-1:0]     m_axis_tid,
   output wire [C_AXIS_TDEST_WIDTH-1:0]   m_axis_tdest,
   output wire [C_AXIS_TUSER_WIDTH-1:0]   m_axis_tuser

   );

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////
`include "axis_infrastructure_v1_1_0.vh"

////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////
localparam integer LP_S_ACLKEN_CAN_TOGGLE = (C_ACLKEN_CONV_MODE == 1) || (C_ACLKEN_CONV_MODE == 3);
localparam integer LP_M_ACLKEN_CAN_TOGGLE = (C_ACLKEN_CONV_MODE == 2) || (C_ACLKEN_CONV_MODE == 3);
localparam integer P_FIFO_DEPTH           = 32; // clock converter use of fifo_gen be fixed 
                                                // at 32 deep fifo.
                                          
localparam integer P_S_AXIS_ACLK_RATIO    = f_lcm(C_S_AXIS_ACLK_RATIO, C_M_AXIS_ACLK_RATIO) / C_M_AXIS_ACLK_RATIO;
localparam integer P_M_AXIS_ACLK_RATIO    = f_lcm(C_S_AXIS_ACLK_RATIO, C_M_AXIS_ACLK_RATIO) / C_S_AXIS_ACLK_RATIO;
                                          
localparam integer P_INST_ASYNC_CONV      =  C_IS_ACLK_ASYNC || (P_S_AXIS_ACLK_RATIO != 1 && P_M_AXIS_ACLK_RATIO != 1);
                                          
localparam integer P_TPAYLOAD_WIDTH       = f_payload_width(C_AXIS_TDATA_WIDTH, C_AXIS_TID_WIDTH, 
                                                 C_AXIS_TDEST_WIDTH, C_AXIS_TUSER_WIDTH, 
                                                 C_AXIS_SIGNAL_SET);
localparam integer P_SAMPLE_CYCLE_RATIO   = (C_S_AXIS_ACLK_RATIO > C_M_AXIS_ACLK_RATIO) 
                                            ? C_S_AXIS_ACLK_RATIO : C_M_AXIS_ACLK_RATIO;


////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////
wire [P_TPAYLOAD_WIDTH-1:0] s_axis_tpayload;

wire [P_TPAYLOAD_WIDTH-1:0] d1_tpayload;
wire                        d1_tvalid;
wire                        d1_tready;

wire [P_TPAYLOAD_WIDTH-1:0] d2_tpayload;
wire                        d2_tvalid;
wire                        d2_tready;

wire [P_TPAYLOAD_WIDTH-1:0] m_axis_tpayload;


////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
////////////////////////////////////////////////////////////////////////////////
axis_infrastructure_v1_1_0_util_axis2vector #(
  .C_TDATA_WIDTH    ( C_AXIS_TDATA_WIDTH ) ,
  .C_TID_WIDTH      ( C_AXIS_TID_WIDTH   ) ,
  .C_TDEST_WIDTH    ( C_AXIS_TDEST_WIDTH ) ,
  .C_TUSER_WIDTH    ( C_AXIS_TUSER_WIDTH ) ,
  .C_TPAYLOAD_WIDTH ( P_TPAYLOAD_WIDTH   ) ,
  .C_SIGNAL_SET     ( C_AXIS_SIGNAL_SET  ) 
)
util_axis2vector_0 (
  .TDATA    ( s_axis_tdata    ) ,
  .TSTRB    ( s_axis_tstrb    ) ,
  .TKEEP    ( s_axis_tkeep    ) ,
  .TLAST    ( s_axis_tlast    ) ,
  .TID      ( s_axis_tid      ) ,
  .TDEST    ( s_axis_tdest    ) ,
  .TUSER    ( s_axis_tuser    ) ,
  .TPAYLOAD ( s_axis_tpayload )
);

generate
  if (LP_S_ACLKEN_CAN_TOGGLE) begin : gen_s_aclken_converter
    axis_infrastructure_v1_1_0_util_aclken_converter #( 
      .C_PAYLOAD_WIDTH       ( P_TPAYLOAD_WIDTH       ) ,
      .C_S_ACLKEN_CAN_TOGGLE ( LP_S_ACLKEN_CAN_TOGGLE ) ,
      .C_M_ACLKEN_CAN_TOGGLE ( 0                      ) 
    )
    s_util_aclken_converter_0 ( 
      .ACLK      ( s_axis_aclk     ) ,
      .ARESETN   ( s_axis_aresetn  ) ,
      .S_ACLKEN  ( s_axis_aclken   ) ,
      .S_PAYLOAD ( s_axis_tpayload ) ,
      .S_VALID   ( s_axis_tvalid   ) ,
      .S_READY   ( s_axis_tready   ) ,
      .M_ACLKEN  ( 1'b1            ) ,
      .M_PAYLOAD ( d1_tpayload     ) ,
      .M_VALID   ( d1_tvalid       ) ,
      .M_READY   ( d1_tready       )
    );
  end
  else begin : gen_s_aclken_passthru
    assign d1_tpayload = s_axis_tpayload;
    assign d1_tvalid   = s_axis_tvalid;
    assign s_axis_tready = d1_tready;
  end

  if (P_INST_ASYNC_CONV) begin : gen_async_conv
    // Use xpm_fifo in 2018.1+ for future part support.
    axis_clock_converter_v1_1_23_axisc_async_clock_converter #( 
      .C_PAYLOAD_WIDTH      ( P_TPAYLOAD_WIDTH     ) ,
      .C_FIFO_DEPTH         ( P_FIFO_DEPTH         ) ,
      .C_SYNCHRONIZER_STAGE ( C_SYNCHRONIZER_STAGE ) 
    )
    axisc_async_clock_converter_0 (
      .s_aclk    ( s_axis_aclk    ) ,
      .s_aresetn ( s_axis_aresetn ) ,
      .s_payload ( d1_tpayload    ) ,
      .s_valid   ( d1_tvalid      ) ,
      .s_ready   ( d1_tready      ) ,
      .m_aclk    ( m_axis_aclk    ) ,
      .m_aresetn ( m_axis_aresetn ) ,
      .m_payload ( d2_tpayload    ) ,
      .m_valid   ( d2_tvalid      ) ,
      .m_ready   ( d2_tready      ) 
    );

  end
  else begin : gen_sync_ck_conv

    wire                        slow_aclk;
    wire                        fast_aclk;
    wire                        sample_cycle_early;
    wire                        sample_cycle;

    // Sample cycle used to determine when to assert a signal on a fast clock
    // to be flopped onto a slow clock.
    assign slow_aclk   = (C_S_AXIS_ACLK_RATIO > C_M_AXIS_ACLK_RATIO) ? m_axis_aclk   : s_axis_aclk;
    assign fast_aclk   = (C_S_AXIS_ACLK_RATIO < C_M_AXIS_ACLK_RATIO) ? m_axis_aclk   : s_axis_aclk;

    axis_clock_converter_v1_1_23_axisc_sample_cycle_ratio #(
      .C_RATIO ( P_SAMPLE_CYCLE_RATIO )
    ) 
    axisc_sample_cycle_ratio_m (
      .SLOW_ACLK          ( slow_aclk          ) ,
      .FAST_ACLK          ( fast_aclk          ) ,
      .SAMPLE_CYCLE_EARLY ( sample_cycle_early ) ,
      .SAMPLE_CYCLE       ( sample_cycle       ) 
    );

    axis_clock_converter_v1_1_23_axisc_sync_clock_converter #( 
      .C_FAMILY        ( C_FAMILY            ) ,
      .C_PAYLOAD_WIDTH ( P_TPAYLOAD_WIDTH    ) ,
      .C_S_ACLK_RATIO  ( P_S_AXIS_ACLK_RATIO ) ,
      .C_M_ACLK_RATIO  ( P_M_AXIS_ACLK_RATIO ) ,
      .C_MODE          ( 1 )
    )
    axisc_sync_clock_converter_0 (
      .SAMPLE_CYCLE_EARLY ( sample_cycle_early ) ,
      .SAMPLE_CYCLE       ( sample_cycle       ) ,
      .S_ACLK             ( s_axis_aclk        ) ,
      .S_ARESETN          ( s_axis_aresetn     ) ,
      .S_PAYLOAD          ( d1_tpayload        ) ,
      .S_VALID            ( d1_tvalid          ) ,
      .S_READY            ( d1_tready          ) ,
      .M_ACLK             ( m_axis_aclk        ) ,
      .M_ARESETN          ( m_axis_aresetn     ) ,
      .M_PAYLOAD          ( d2_tpayload        ) ,
      .M_VALID            ( d2_tvalid          ) ,
      .M_READY            ( d2_tready          ) 
    );
  end

  if (LP_M_ACLKEN_CAN_TOGGLE) begin : gen_m_aclken_converter
    axis_infrastructure_v1_1_0_util_aclken_converter #( 
      .C_PAYLOAD_WIDTH       ( P_TPAYLOAD_WIDTH       ) ,
      .C_S_ACLKEN_CAN_TOGGLE ( 0                      ) ,
      .C_M_ACLKEN_CAN_TOGGLE ( LP_M_ACLKEN_CAN_TOGGLE ) 
    )
    m_util_aclken_converter_0 ( 
      .ACLK      ( m_axis_aclk     ) ,
      .ARESETN   ( m_axis_aresetn  ) ,
      .S_ACLKEN  ( 1'b1            ) ,
      .S_PAYLOAD ( d2_tpayload     ) ,
      .S_VALID   ( d2_tvalid       ) ,
      .S_READY   ( d2_tready       ) ,
      .M_ACLKEN  ( m_axis_aclken   ) ,
      .M_PAYLOAD ( m_axis_tpayload ) ,
      .M_VALID   ( m_axis_tvalid   ) ,
      .M_READY   ( m_axis_tready   ) 
    );
  end
  else begin : gen_m_aclken_passthru
    assign m_axis_tpayload = d2_tpayload;
    assign m_axis_tvalid = d2_tvalid;
    assign d2_tready = m_axis_tready;
  end

endgenerate

axis_infrastructure_v1_1_0_util_vector2axis #(
  .C_TDATA_WIDTH    ( C_AXIS_TDATA_WIDTH ) ,
  .C_TID_WIDTH      ( C_AXIS_TID_WIDTH   ) ,
  .C_TDEST_WIDTH    ( C_AXIS_TDEST_WIDTH ) ,
  .C_TUSER_WIDTH    ( C_AXIS_TUSER_WIDTH ) ,
  .C_TPAYLOAD_WIDTH ( P_TPAYLOAD_WIDTH   ) ,
  .C_SIGNAL_SET     ( C_AXIS_SIGNAL_SET  ) 
)
util_vector2axis_0 (
  .TPAYLOAD ( m_axis_tpayload ) ,
  .TDATA    ( m_axis_tdata    ) ,
  .TSTRB    ( m_axis_tstrb    ) ,
  .TKEEP    ( m_axis_tkeep    ) ,
  .TLAST    ( m_axis_tlast    ) ,
  .TID      ( m_axis_tid      ) ,
  .TDEST    ( m_axis_tdest    ) ,
  .TUSER    ( m_axis_tuser    ) 
);

endmodule // axis_clock_converter

`default_nettype wire


