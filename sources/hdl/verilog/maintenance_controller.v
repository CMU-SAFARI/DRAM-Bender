`include "parameters.vh"

module maintenance_controller#(parameter tCK = 1500)(
  
  input clk,
  input rst,
  
  input init_calib_complete,
  input softmc_fin,
  
  input aref_en,
  input aref_en_valid,
  
  input       maint_ack,
  output      maint_req,
  output      per_rd_init,
  output      per_zq_init,
  output      per_ref_init,
  output      maint_process,
  input       program_process,
  
  input [`IMEM_ADDR_WIDTH-1:0]  in_addr,
  input                         in_valid,
  
  output [`INSTR_WIDTH-1:0]     out_data,
  output reg                    out_valid,
  output [`IMEM_ADDR_WIDTH-1:0] out_addr
  );
  
  wire zq_ack, per_rd_ack, ref_ack;
  reg zq_request, zq_process;
  reg per_rd_request, per_rd_process;
  reg pr_ref_request, pr_ref_process;
 
  wire [`INSTR_WIDTH-1 : 0] pr_read_out, pr_zq_out, pr_ref_out;
  
  assign maint_req      = per_rd_request | zq_request | pr_ref_request;
  assign out_addr       = {`IMEM_ADDR_WIDTH{`HIGH}};
  assign out_data       = zq_process ? pr_zq_out : per_rd_process ? pr_read_out : pr_ref_out;
  assign per_ref_init   = maint_ack && pr_ref_request && ~per_rd_request && ~zq_request;
  assign per_rd_init    = maint_ack && per_rd_request && ~zq_request;
  assign per_zq_init    = maint_ack && zq_request;
  assign maint_process  = zq_process || per_rd_process || pr_ref_process;
 
  assign zq_ack         = softmc_fin && zq_process;
  assign per_rd_ack     = softmc_fin && per_rd_process;
  assign ref_ack        = softmc_fin && pr_ref_process;
 
  pr_read_mem prm
  (
    .addra(in_addr[3:0]),
    .clka(clk),
    .douta(pr_read_out),
    .dina(64'bX),
    .wea(`LOW),
    .ena(in_valid && per_rd_process)
  );
  
  zq_calib_mem pzm
  (
    .addra(in_addr[5:0]),
    .clka(clk),
    .douta(pr_zq_out),
    .dina(64'bX),
    .wea(`LOW),
    .ena(in_valid && zq_process)
  );
  
  pr_ref_mem prefm
  (
    .addra(in_addr[6:0]),
    .clka(clk),
    .douta(pr_ref_out),
    .dina(64'bX),
    .wea(`LOW),
    .ena(in_valid && pr_ref_process)
  );
  
  always @(posedge clk) begin
    if(rst) begin
      zq_process <= `LOW;
      per_rd_process <= `LOW;
      out_valid <= `LOW;
      pr_ref_process <= `LOW; 
    end
    else begin
      if(softmc_fin) begin
        if(zq_process)
          zq_process <= `LOW;
        if(per_rd_process)
          per_rd_process <= `LOW;
        if(pr_ref_process)
          pr_ref_process <= `LOW;
        out_valid <= `LOW;
      end
      else if(maint_ack) begin
        if(zq_request)
          zq_process <= `HIGH;
        else if(per_rd_request) 
          per_rd_process <= `HIGH;
        else if(pr_ref_request)
          pr_ref_process <= `HIGH;
        out_valid <= `LOW;  
      end
      else begin
        zq_process <= zq_process;
        per_rd_process <= per_rd_process;
        pr_ref_process <= pr_ref_process;
        if(maint_process)
          out_valid <= in_valid;
        else
          out_valid <= `LOW;
      end
    end
  end
  
  // Maintenance control logic
  // Set request bits according to timers
  
  localparam MAINT_PRESCALER_PERIOD = 500_000; // .5 us
  
  function integer clogb2 (input integer size); // ceiling logb2
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
  endfunction // clogb2
  
  localparam MAINT_PRESCALER_DIV = MAINT_PRESCALER_PERIOD/(tCK * 4); // softmc is clocked 4 times slower than the memory interface
  localparam MAINT_PRESCALER_WIDTH = clogb2(MAINT_PRESCALER_DIV + 1);
  localparam ONE = 1;
  
  reg maint_prescaler_tick_r_lcl;
  reg [MAINT_PRESCALER_WIDTH-1:0] maint_prescaler_r;
  reg [MAINT_PRESCALER_WIDTH-1:0] maint_prescaler_ns;

  wire maint_prescaler_tick_ns = (maint_prescaler_r == ONE[MAINT_PRESCALER_WIDTH-1:0]);
  
  always @(/*AS*/init_calib_complete or maint_prescaler_r
        or maint_prescaler_tick_ns) begin
    maint_prescaler_ns = maint_prescaler_r;
    if (~init_calib_complete || maint_prescaler_tick_ns)
      maint_prescaler_ns = MAINT_PRESCALER_DIV[MAINT_PRESCALER_WIDTH-1:0];
    else if (|maint_prescaler_r)
      maint_prescaler_ns = maint_prescaler_r - ONE[MAINT_PRESCALER_WIDTH-1:0];
  end

  always @(posedge clk) maint_prescaler_r <= maint_prescaler_ns;

  always @(posedge clk) maint_prescaler_tick_r_lcl <= maint_prescaler_tick_ns;
  
  localparam tPRDI = 1_000_000;
  localparam PERIODIC_RD_TIMER_DIV = tPRDI/MAINT_PRESCALER_PERIOD;
  localparam PERIODIC_RD_TIMER_WIDTH = clogb2(PERIODIC_RD_TIMER_DIV + /*idle state*/ 1);

  reg [PERIODIC_RD_TIMER_WIDTH-1:0] periodic_rd_timer_r, periodic_rd_timer;
  
  always @* begin
    periodic_rd_timer = periodic_rd_timer_r;

    if(~init_calib_complete) begin
      periodic_rd_timer = {PERIODIC_RD_TIMER_WIDTH{1'b0}};
    end
    else if (per_rd_ack || program_process) begin
      periodic_rd_timer = PERIODIC_RD_TIMER_DIV[0+:PERIODIC_RD_TIMER_WIDTH];
    end
    else if (|periodic_rd_timer_r && maint_prescaler_tick_r_lcl) begin
      periodic_rd_timer = periodic_rd_timer_r - ONE[0+:PERIODIC_RD_TIMER_WIDTH];
    end
  end //always

  wire periodic_rd_timer_one = maint_prescaler_tick_r_lcl && (periodic_rd_timer_r == ONE[0+:PERIODIC_RD_TIMER_WIDTH]);

  wire periodic_rd_request = ~rst && (/*((PERIODIC_RD_TIMER_DIV != 0) && ~dfi_init_complete) ||*/
                      (~per_rd_ack && (per_rd_request || periodic_rd_timer_one)));

  always @(posedge clk) begin
    if(~init_calib_complete)
      periodic_rd_timer_r <= PERIODIC_RD_TIMER_DIV[0+:PERIODIC_RD_TIMER_WIDTH];
    else
      periodic_rd_timer_r <= periodic_rd_timer;
    per_rd_request <= periodic_rd_request;
  end //always

  // ZQ timebase.  Nominally 128 mS
  localparam MAINT_PRESCALER_PERIOD_NS = MAINT_PRESCALER_PERIOD / 1000;
  localparam tZQI = 128_000_000;
  localparam ZQ_TIMER_DIV = tZQI/MAINT_PRESCALER_PERIOD_NS;
  localparam ZQ_TIMER_WIDTH = clogb2(ZQ_TIMER_DIV + 1);

  generate
    begin : zq_cntrl
      reg zq_tick = 1'b0;

      if (ZQ_TIMER_DIV !=0) begin : zq_timer
        reg [ZQ_TIMER_WIDTH-1:0] zq_timer_r;
        reg [ZQ_TIMER_WIDTH-1:0] zq_timer_ns;

        always @(/*AS*/init_calib_complete or maint_prescaler_tick_r_lcl or zq_tick or zq_timer_r or program_process) begin
          zq_timer_ns = zq_timer_r;
          if (~init_calib_complete || zq_tick || program_process)
            zq_timer_ns = ZQ_TIMER_DIV[ZQ_TIMER_WIDTH-1:0];
          else if (|zq_timer_r && maint_prescaler_tick_r_lcl)
            zq_timer_ns = zq_timer_r - ONE[ZQ_TIMER_WIDTH-1:0];
        end

        always @(posedge clk) zq_timer_r <= zq_timer_ns;

        always @(/*AS*/maint_prescaler_tick_r_lcl or zq_timer_r)
          zq_tick = (zq_timer_r == ONE[ZQ_TIMER_WIDTH-1:0] && maint_prescaler_tick_r_lcl);
      end // zq_timer

      // ZQ request. Set request with timer tick, and when exiting PHY init.  Never
      // request if ZQ_TIMER_DIV == 0.
      begin : zq_request_logic
        wire zq_clear = zq_ack;
        reg zq_request_r;
        wire zq_request_ns = ~rst && ((~init_calib_complete && (ZQ_TIMER_DIV != 0)) ||
          (zq_request_r && ~zq_clear) || zq_tick);

        always @(posedge clk) zq_request_r <= zq_request_ns;

        always @(/*AS*/init_calib_complete or zq_request_r)
          zq_request = init_calib_complete && zq_request_r;
      end // zq_request_logic
    end
  endgenerate
  
  localparam tAREF = 7_800;
  localparam PERIODIC_REF_TIMER_DIV = tAREF/MAINT_PRESCALER_PERIOD_NS;
  localparam PERIODIC_REF_TIMER_WIDTH = clogb2(PERIODIC_REF_TIMER_DIV + /*idle state*/ 1);

  reg [PERIODIC_REF_TIMER_WIDTH-1:0] autoref_timer_r, autoref_timer;
  reg aref_switch_ns, aref_switch_r;
  
  always @* begin
    aref_switch_ns = aref_en_valid ? aref_en : aref_switch_r;
    pr_ref_request = `LOW;
    autoref_timer = autoref_timer_r;
    if(~aref_switch_r || ~init_calib_complete)
      autoref_timer = PERIODIC_REF_TIMER_DIV[PERIODIC_REF_TIMER_WIDTH-1:0];
    else begin
      if(autoref_timer_r > 1 && maint_prescaler_tick_r_lcl) // you were here
        autoref_timer  = autoref_timer_r - ONE[PERIODIC_REF_TIMER_WIDTH-1:0];
      else if(autoref_timer_r == 1) begin
        pr_ref_request = `HIGH;
        if(ref_ack)
          autoref_timer = PERIODIC_REF_TIMER_DIV[PERIODIC_REF_TIMER_WIDTH-1:0];
      end
    end
  end
  
  always @(posedge clk) begin
    if(rst) begin
      aref_switch_r <= `LOW;
      autoref_timer_r = PERIODIC_REF_TIMER_DIV[PERIODIC_REF_TIMER_WIDTH-1:0];
    end
    else begin
      aref_switch_r   <= aref_switch_ns;
      autoref_timer_r <= autoref_timer;
    end
  end

endmodule
