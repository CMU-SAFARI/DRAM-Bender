`include "parameters.vh"

/* 
 * An 8 read 8 write port reg file
 * satisfying ddr pipeline's needs
 */
module register_file(

  // common signals
  input           clk,
  input           rst,

  // execute stage <-> reg file if
  input                                rf_wide_wen,
  input   [3:0]                        rf_wide_offset,
  output  [511:0]                      rf_wide_data,
  output  [32*8-1:0]                   rf_rdata,
  input   [32*8-1:0]                   rf_wdata,
  input   [7:0]                        rf_wen,
  input   [4*8-1:0]                    rf_raddr,
  input   [4*8-1:0]                    rf_waddr,
  output  [`COL_WIDTH-1:0]             casr,
  output  [`BANK_WIDTH+`BG_WIDTH-1:0]  basr,
  output  [`ROW_WIDTH-1:0]             rasr,
  // update stride registers, wen is OH (3'b001 = update rasr)
  input   [31:0]                       srf_value,
  input   [2:0]                        srf_wen
  );

  // Stride registers
  reg [31:0] casr_r, basr_r, rasr_r;

  assign casr = casr_r;
  assign basr = basr_r;
  assign rasr = rasr_r;

  // Update stride registers
  always @(posedge clk) begin
    if(srf_wen[0]) begin
      casr_r <= srf_value;
    end
    if(srf_wen[1]) begin
      basr_r <= srf_value;
    end
    if(srf_wen[2]) begin
      rasr_r <= srf_value;
    end
  end

  // General purpose registers
  reg [31:0] reg_file [15:0];
  
  // split r&w data signals into human readable form
  // also drive rdata with appropriate register values
  wire [31:0] wdata [7:0];
  wire        wen   [7:0];
  wire [3:0]  waddr [7:0];
  wire [3:0]  raddr [7:0];
  genvar i;
  generate
    for(i = 0 ; i < 8 ; i = i + 1) begin: gen_ports
      assign wdata[i] = rf_wdata[32*i +: 32];
      assign wen[i]   = rf_wen[i];
      assign waddr[i] = rf_waddr[4*i +: 4];
      assign raddr[i] = rf_raddr[4*i +: 4];
      // TODO will this compile?
      assign rf_rdata[32*i +: 32] = raddr[i] == 0 ? casr_r : 
        raddr[i] == 1 ? basr_r : 
        raddr[i] == 2 ? rasr_r : reg_file[raddr[i]];
    end
  endgenerate

  integer j;
  // Write to the register file
  always @(posedge clk) begin
    for(j = 0 ; j < 8 ; j = j+1) begin: regfile_write
      if(wen[j])
        reg_file[waddr[j]] <= wdata[j];
    end
  end
  
  // DDR4 8-burst write data register
  reg [511:0] wide_reg;
  always @(posedge clk) begin
    // TODO this probably won't compile
    if(rf_wide_wen)
      wide_reg[rf_wide_offset*32 +: 32] <= wdata[0];
  end
 
  assign rf_wide_data = wide_reg; 

endmodule
