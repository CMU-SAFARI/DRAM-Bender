`timescale 1ps / 1ps

module sim_tb_top;

    // common signals
    reg c0_sys_clk_p;
    reg c0_sys_clk_n;
    reg sys_rst_l;
  
    softmc_top UUT(
      .c0_sys_clk_p(c0_sys_clk_p),
      .c0_sys_clk_n(c0_sys_clk_n),
      .sys_rst_l(sys_rst_l)
  
  );
  
  initial
    c0_sys_clk_p = 1'b0;
  always
    c0_sys_clk_p = #(10000/2.0) ~c0_sys_clk_p;
    
  initial
    c0_sys_clk_n = 1'b1;
  always
    c0_sys_clk_n = #(10000/2.0) ~c0_sys_clk_n;
    
    
  initial begin
	  sys_rst_l = 1'b0;
	  #200000;
	  sys_rst_l = 1'b0;
	  #4500000;
	  sys_rst_l = 1'b1;
  end








endmodule
