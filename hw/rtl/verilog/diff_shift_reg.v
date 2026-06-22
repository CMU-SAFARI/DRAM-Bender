`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/19/2018 01:07:06 PM
// Design Name: 
// Module Name: diff_shift_reg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module diff_shift_reg(
  input         clk,
  input         rst,
  
  input         flush,
  
  input [15:0]  in,
  input         in_valid,

  output[511:0] out,
  output        out_valid
  );
  
  reg [4:0]   ctr_r;
  reg [511:0] shift_r;
  reg         valid_r;
  
  always @(posedge clk) begin
    if(rst) begin
      shift_r <= 512'bX;
      ctr_r   <= 5'b0;
      valid_r <= 1'b0;
    end
    else begin
      if(flush) begin
        valid_r <= `HIGH;
        ctr_r   <= 5'b0;
      end
      else begin
        if(in_valid) begin
          shift_r[16 +: 16*31] <= shift_r[0 +: 16*31];
          shift_r[0  +: 16]    <= in;
          ctr_r                <= ctr_r + 1;
        end
        else begin 
          ctr_r   <= ctr_r;
          shift_r <= shift_r;
        end
        valid_r <= (|ctr_r) && in_valid;
      end
    end
  end
  
  assign out_valid = valid_r;
  assign out       = shift_r;
  
endmodule
