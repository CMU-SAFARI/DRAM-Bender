module tb_decode_stage(

  );

  reg [63:0] instr;
  reg [11:0] instr_pc;
  reg instr_valid;

  decode_stage ds(
    .instr(instr),
    .instr_pc(instr_pc),
    .instr_valid(instr_valid)
  );
 
  reg clk = 0, rst = 1;

  initial begin
    #100;
    rst = 0;
  end
 
  always begin
    #5;
    clk = ~clk;
  end
endmodule
