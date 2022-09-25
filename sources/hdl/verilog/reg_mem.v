`timescale 1ns / 1ps

module reg_mem(
    input [9:0] addr,
    input clk,
    input [31:0] din,
    output [31:0] dout,
    input en,
    input we
    );
    
    reg [31:0] mem [1023:0];
    
    integer i;
    initial
    begin
        for(i=0; i<1024; i=i+1)
            mem[i]=0;
    end
        
    reg [31:0] out;
        
    assign dout=out;    
        
    always @(posedge clk)
    begin
        if(we)
            mem[addr]<=din;
        else if(en)
            out<=mem[addr];
    end
            
endmodule
