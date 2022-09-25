`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/06/2018 05:43:09 PM
// Design Name: 
// Module Name: tb_softmc_top
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


module tb_only_softmc(

  );
  
  reg clk = 0, rst = 1;
  softmc_top smct(
    .clk(clk),
    .rst(rst)
  );
  
  initial begin
    #50;
    rst = 0;
  end
  
  always begin
    #5;
    clk = ~clk;
  end
endmodule
