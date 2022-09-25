`include "parameters.vh"
/*
 * This module is responsible for the interface
 * between XDMA IP and the fetch stage.
 * This module encapsulates a X KiB BRAM which
 * is used as an instruction memory.
 */
module frontend#(parameter SIM_MEM = "false")(
  // common signals
  input                         clk,
  input                         rst,

  // other control signals
  input                         softmc_fin,
  output                        user_rst,
  input                         init_calib_complete,
  output reg                    rbe_switch_mode,
  output reg                    dllt_begin,
  output                        frontend_ready,
 
  // frontend <-> fetch stage interface
  input  [`IMEM_ADDR_WIDTH-1:0] addr_in,
  input                         valid_in,
  output [`INSTR_WIDTH-1:0]     data_out,
  output                        valid_out,
  output [`IMEM_ADDR_WIDTH-1:0] addr_out,
  output                        ready_in,  

  // frontend <-> xdma interface
  input  [`XDMA_AXI_DATA_WIDTH-1:0]   h2c_tdata_0,
  input                               h2c_tlast_0,
  input                               h2c_tvalid_0,
  output                              h2c_tready_0,
  input  [`XDMA_AXI_DATA_WIDTH/8-1:0] h2c_tkeep_0,
  
  // maintenance signals
  output                              per_rd_init,
  output                              per_zq_init,
  output                              per_ref_init
  );

  reg[31:0] delay_fin;

  always @(posedge clk) begin
    if(rst || user_rst)
      delay_fin <= 32'b0;
    else
      delay_fin[1+:31] <= delay_fin[0+:31];
      delay_fin[0]    <= softmc_fin;
  end

  assign frontend_ready = delay_fin[31];

  wire                        imem_wr_en, imem_rd_en;
  wire [`IMEM_ADDR_WIDTH-1:0] imem_addr;
  wire [`INSTR_WIDTH-1:0]     imem_wr_data, imem_rd_data;

  generate
    if(SIM_MEM == "true") begin
      instr_blk_mem_sim imem(
      .addra(imem_addr),
      .clka(clk),
      .dina(imem_wr_data),
      .douta(imem_rd_data),
      .ena(imem_rd_en || imem_wr_en),
      .wea(imem_wr_en)
    );
    end
    else begin
      instr_blk_mem imem(
      .addra(imem_addr),
      .clka(clk),
      .dina(imem_wr_data),
      .douta(imem_rd_data),
      .ena(imem_rd_en || imem_wr_en),
      .wea(imem_wr_en)
    );
    end
  endgenerate

  wire [`INSTR_WIDTH-1:0]     maint_inst;
  wire                        maint_valid;
  wire [`IMEM_ADDR_WIDTH-1:0] maint_addr;
  wire                        maint_req;
  reg                         maint_ack;
  wire                        maint_process;
  wire                        program_process;
  reg                         aref_en;
  reg                         aref_en_valid;

  maintenance_controller maint_ctrl
  (
    .clk(clk),
    .rst(rst | user_rst),
    
    .init_calib_complete(init_calib_complete),
    .softmc_fin(softmc_fin),
    
    .aref_en(aref_en),
    .aref_en_valid(aref_en_valid),
    .maint_req(maint_req),
    .maint_ack(maint_ack),
    .per_rd_init(per_rd_init),
    .per_zq_init(per_zq_init),
    .per_ref_init(per_ref_init),
    .maint_process(maint_process),
    .program_process(program_process),
    
    .in_addr(addr_in),
    .in_valid(valid_in),
    
    .out_data(maint_inst),
    .out_valid(maint_valid),
    .out_addr(maint_addr)
  );

  localparam IDLE_S     = 2'd0;
  localparam INIT_MEM_S = 2'd1;
  localparam EXECUTE_S  = 2'd2;

  reg [1:0] state_r, state_ns;

  reg [4:0]                  rst_ctr_ns, rst_ctr_r;
  reg [`IMEM_ADDR_WIDTH-1:0] xfer_ctr_r, xfer_ctr_ns;
  reg [`IMEM_RD_LATENCY-1:0] valid_out_sr;
  reg [(`IMEM_RD_LATENCY * `IMEM_ADDR_WIDTH)-1:0] addr_out_sr;

  assign user_rst     = (|rst_ctr_r);

  // imem <-> xdma interface
  // TODO do we need tkeep?
  assign h2c_tready_0 = state_r == INIT_MEM_S;
  assign imem_wr_en   = h2c_tvalid_0 && (state_r == INIT_MEM_S);
  assign imem_wr_data = h2c_tdata_0[`INSTR_WIDTH-1:0];
  assign imem_addr    = state_r == INIT_MEM_S ? xfer_ctr_r : addr_in;
  // imem <-> pipeline interface 
  assign imem_rd_en   = valid_in && (program_process);
  assign data_out     = program_process ? imem_rd_data : maint_inst;
  assign valid_out    = program_process ? valid_out_sr[0] : maint_valid;
  assign addr_out     = program_process ? addr_out_sr[`IMEM_ADDR_WIDTH-1:0] : maint_addr;
  
  generate
  if(SIM_MEM=="false")
    assign ready_in     = state_r == EXECUTE_S;
  else
    assign ready_in     = state_r == EXECUTE_S && ~rst;
  endgenerate
  assign program_process = (state_r == EXECUTE_S) && ~maint_process;

  always @* begin
    aref_en_valid   = `LOW;
    aref_en         = `LOW;
    state_ns        = state_r;
    xfer_ctr_ns     = xfer_ctr_r;
    rst_ctr_ns      = {5{`LOW}};
    maint_ack       = `LOW;
    rbe_switch_mode = `LOW;
    dllt_begin      = `LOW;
    case (state_r)
      IDLE_S: begin
        if(~((|delay_fin) || softmc_fin)) begin
            if(h2c_tvalid_0)
              state_ns = INIT_MEM_S;
            else begin
              if(maint_req) begin
                maint_ack = `HIGH;
                state_ns = EXECUTE_S;
              end
            end
        end
      end
      INIT_MEM_S: begin
        if(h2c_tvalid_0) begin
          if(h2c_tdata_0[`INSTR_WIDTH]) //indicates a reset
            rst_ctr_ns = {5{1'b1}};
          else if(h2c_tdata_0[`INSTR_WIDTH+1]) // indicate switch between readback modes
            rbe_switch_mode = `HIGH;
          else if(h2c_tdata_0[`INSTR_WIDTH+2]) // indicate dll toggle off WIP
            dllt_begin = `HIGH;
          else if(h2c_tdata_0[`INSTR_WIDTH+3]) begin // enable-disable autoref
            aref_en_valid = `HIGH;
            aref_en       = h2c_tdata_0[0];
            state_ns      = IDLE_S;
          end
          else begin
            xfer_ctr_ns = xfer_ctr_r + 1;
            if(h2c_tlast_0) begin
              state_ns    = EXECUTE_S;
              xfer_ctr_ns = {`IMEM_ADDR_WIDTH{`LOW}}; 
            end
          end
        end
      end
      EXECUTE_S: begin        
        if(h2c_tvalid_0) begin
          if(h2c_tdata_0[`INSTR_WIDTH]) //indicates a reset
            rst_ctr_ns = {5{1'b1}};
        end
        if(softmc_fin)
          state_ns = IDLE_S;
      end
    endcase
    
  end

  always @(posedge clk) begin
    if(rst || (|rst_ctr_r)) begin
      if(SIM_MEM == "false")
        state_r      <= IDLE_S;
      else
        state_r      <= EXECUTE_S;
      xfer_ctr_r   <= {`IMEM_ADDR_WIDTH{`LOW}};
      valid_out_sr <= {`IMEM_RD_LATENCY{`LOW}};
      addr_out_sr  <= 0;
      if(rst_ctr_r > 0)
        rst_ctr_r <= rst_ctr_r - 1;
      else
        rst_ctr_r <= 0;
    end
    else begin
      state_r      <= state_ns;
      xfer_ctr_r   <= xfer_ctr_ns;
      rst_ctr_r    <= rst_ctr_ns;
      // compute when we should assert valid data to
      // fetch stage.
      valid_out_sr[`IMEM_RD_LATENCY-1] <= valid_in && (state_r == EXECUTE_S);
      addr_out_sr[`IMEM_RD_LATENCY*`IMEM_ADDR_WIDTH-1 : 
          (`IMEM_RD_LATENCY-1)*`IMEM_ADDR_WIDTH] <= addr_in;
      `ifdef IMEM_SR
        valid_out_sr[`IMEM_RD_LATENCY-1:0] <= valid_out_sr >> 1;
        addr_out_sr[(`IMEM_RD_LATENCY-1)*`IMEM_ADDR_WIDTH-1:0] 
                         <= addr_out_sr >> `IMEM_ADDR_WIDTH; 
      `endif
    end
  end
endmodule

