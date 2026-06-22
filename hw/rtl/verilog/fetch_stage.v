`include "parameters.vh"

module fetch_stage(
  // common signals
  input                          clk,
  input                          rst,

  // other control signals
  output                         softmc_end,
  output  [11:0]                 read_size,
  output reg                     read_seq_incoming,
  input  [11:0]                  buffer_space,

  // branch unit <-> fetch stage interface
  input                          br_resolve,
  input   [`IMEM_ADDR_WIDTH-1:0] br_target,

  // fetch stage <-> frontend interface
  output  [`IMEM_ADDR_WIDTH-1:0] addr_out,
  output                         valid_out,
  input   [`INSTR_WIDTH-1:0]     data_in,
  input                          valid_in,
  input   [`IMEM_ADDR_WIDTH-1:0] addr_in,
  input                          ready_out, // frontend is ready for a valid request

  // fetch stage <-> decode stage interface
  output  [`INSTR_WIDTH-1:0]     instr,
  output  [`IMEM_ADDR_WIDTH-1:0] instr_pc,
  output                         instr_valid
  );

  wire inst_is_br, is_end, is_ddr_start, need_flush, is_sleep;

  reg [31:0] sleep_ctr_r, sleep_ctr_ns;

  localparam WAIT_RESOLVE_S      = 0;
  localparam FETCH_NEXT_LINE_S   = 1;
  localparam WAIT_BUFFER_SPACE_S = 2;
  localparam WAIT_SLEEP_S        = 3;

  reg [2:0] state_r, state_ns;

  // kind of confusing but these PCs map to
  // an instruction instead of to a byte.
  // i.e. each PC addresses an instruction.
  reg [`IMEM_ADDR_WIDTH-1:0] pc_r, pc_ns;

  // register outputs, decode will receive
  // stuff we've received with one cycle latency
  // i.e. marks the end of fetch_stage cycle
  reg [`IMEM_ADDR_WIDTH-1:0] instr_pc_r, instr_pc_ns;
  reg [`INSTR_WIDTH-1:0]     instr_r, instr_ns;
  reg                        instr_valid_r, instr_valid_ns;
  
  pre_decode pdec(
    .buffer_space(buffer_space),
    .read_size(read_size),
    .instruction(state_r == WAIT_BUFFER_SPACE_S ? instr_r : data_in),
    .is_branch(inst_is_br),
    .is_end(is_end),
    .is_ddr_start(is_ddr_start),
    .need_flush(need_flush),
    .is_sleep(is_sleep)
  );

  assign instr       = instr_r;
  assign instr_valid = instr_valid_r;
  assign instr_pc    = instr_pc_r;

  // request instr @ pc from frontend
  assign valid_out   = ready_out && (state_r == FETCH_NEXT_LINE_S) && ~need_flush && ~(valid_in && is_sleep);
  assign addr_out    = pc_r;

  assign softmc_end  = is_end && valid_in && (state_r == FETCH_NEXT_LINE_S);

  always @* begin
    sleep_ctr_ns   = sleep_ctr_r;
    state_ns       = state_r;
    pc_ns          = pc_r;
    instr_ns       = instr_r;
    instr_pc_ns    = instr_pc_r;
    instr_valid_ns = ~is_end && valid_in && (state_r == FETCH_NEXT_LINE_S) 
        && ~is_ddr_start;
    read_seq_incoming = `LOW;
    case(state_r)
      WAIT_RESOLVE_S: begin
        if(br_resolve) begin
          state_ns = FETCH_NEXT_LINE_S;
          pc_ns    = br_target;
        end
      end
      FETCH_NEXT_LINE_S: begin
        if(ready_out && valid_out)
          pc_ns = pc_r + 1;
        if(valid_in) begin
          instr_ns = data_in;
          instr_pc_ns = addr_in;
          if(is_sleep) begin
            sleep_ctr_ns = data_in[31:0];
            state_ns = WAIT_SLEEP_S;
          end
          if(is_ddr_start && ~need_flush && (|data_in[9:0]))
            read_seq_incoming = `HIGH;
          if(inst_is_br && ~is_sleep) // we don't have the ability to perform well
            state_ns = WAIT_RESOLVE_S;
          else if(is_end)
            pc_ns    = {`IMEM_ADDR_WIDTH{`LOW}};
          else if(need_flush) begin
            state_ns = WAIT_BUFFER_SPACE_S;
            pc_ns    = addr_in;     // register the info packet
                                    // as the next instruction to fetch
          end
        end  
      end
      WAIT_BUFFER_SPACE_S: begin
        if(~need_flush) begin
          state_ns = FETCH_NEXT_LINE_S;
        end
      end
      WAIT_SLEEP_S: begin
        sleep_ctr_ns = sleep_ctr_r - 1;
        if(sleep_ctr_r == 32'b1)
          state_ns = FETCH_NEXT_LINE_S;
      end
    endcase
  end

  always @(posedge clk) begin
    if (rst) begin
      pc_r          <= {`IMEM_ADDR_WIDTH{`LOW}};
      state_r       <= FETCH_NEXT_LINE_S;
      instr_valid_r <= `LOW;
      instr_r       <= {`INSTR_WIDTH{`LOW}};
      instr_pc_r    <= {`IMEM_ADDR_WIDTH{`LOW}};
      sleep_ctr_r   <= {32{`LOW}};
    end
    else begin
      state_r       <= state_ns;
      pc_r          <= pc_ns;
      instr_r       <= instr_ns;
      instr_pc_r    <= instr_pc_ns;
      instr_valid_r <= instr_valid_ns;
      sleep_ctr_r   <= sleep_ctr_ns;
    end
  end

endmodule
