`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/19/2018 10:51:52 AM
// Design Name: 
// Module Name: pop_count4
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


module pop_count4(
  input [3:0] in,
  output [2:0] out
  );
    
  reg [2:0] out_r; 
    
  always @* begin
    out_r = 3'd0;
    case(in)
      4'b0000:
        out_r = 3'd0;
      4'b0001:
        out_r = 3'd1;
      4'b0010:
        out_r = 3'd1;
      4'b0011:
        out_r = 3'd2;
      4'b0100:
        out_r = 3'd1;
      4'b0101:
        out_r = 3'd2;
      4'b0110:
        out_r = 3'd2;
      4'b0111:
        out_r = 3'd3;
      4'b1000:
        out_r = 3'd1;
      4'b1001:
        out_r = 3'd2;
      4'b1010:
        out_r = 3'd2;
      4'b1011:
        out_r = 3'd3;
      4'b1100:
        out_r = 3'd2;
      4'b1101:
        out_r = 3'd3;
      4'b1111:
        out_r = 3'd4;
    endcase  
  end
  
  assign out = out_r;
  
endmodule
