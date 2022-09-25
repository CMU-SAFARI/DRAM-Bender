`include "parameters.vh"
`include "encoding.vh"

module decode_stage(
 
  input clk,
  input rst,   

  // fetch stage <-> decode stage interface
  input  [`INSTR_WIDTH-1:0]     instr,
  input  [`IMEM_ADDR_WIDTH-1:0] instr_pc,
  input                         instr_valid,
 
  // decode stage <-> execute stage interface 
  output                        ddr_valid,
  output                        exe_valid,
  output [`DDR_UOP_WIDTH*4-1:0] ddr_uop,
  output [`EXE_UOP_WIDTH-1:0]   exe_uop,
  output [`IMEM_ADDR_WIDTH-1:0] exe_pc,
  output [32*7-1:0]             ddr_stat
  );

  reg ddr_valid_r, ddr_valid_ns;
  reg exe_valid_r, exe_valid_ns;
  reg [`IMEM_ADDR_WIDTH-1:0] exe_pc_r;

  reg [`DDR_UOP_WIDTH-1:0] ddr_uop_r [3:0], ddr_uop_ns [3:0];
  reg [`EXE_UOP_WIDTH-1:0] exe_uop_r, exe_uop_ns;
  reg[31:0] ddr_stat_r[0:6]; //WRITE, READ, PRE, ACT, ZQ, REF, CYC counts

  // split the instr into four individual insts
  localparam div = 16;
  wire [`INSTR_WIDTH/4-1:0] ddr_insts [3:0];
  assign ddr_insts[0] = instr [0     +: div];
  assign ddr_insts[1] = instr [div   +: div];
  assign ddr_insts[2] = instr [div*2 +: div];
  assign ddr_insts[3] = instr [div*3 +: div];
  // gather all ddr uops into one output (¯\_(ツ)_/¯)
  // verilog does not let us define output vectors
  genvar uops;
  generate
    for(uops = 0 ; uops < 4 ; uops = uops + 1) begin: gather_uops
      assign ddr_uop[uops*`DDR_UOP_WIDTH +: `DDR_UOP_WIDTH] =
          ddr_uop_r[uops];
    end
  endgenerate
  assign exe_uop   = exe_uop_r;
  assign exe_pc    = exe_pc_r;
  assign ddr_valid = ddr_valid_r;
  assign exe_valid = exe_valid_r;
  assign ddr_stat = {ddr_stat_r[6], ddr_stat_r[5], 
                     ddr_stat_r[4], ddr_stat_r[3], 
                     ddr_stat_r[2], ddr_stat_r[1], 
                     ddr_stat_r[0]};
  
  reg is_started = 0;
  reg[26:0] imd;
  integer i;
  
  always @* begin
    ddr_valid_ns = `LOW;
    exe_valid_ns = `LOW; 
    exe_uop_ns = {`EXE_UOP_WIDTH{`LOW}};
    for(i = 0 ; i < 4 ; i = i + 1)
      ddr_uop_ns[i] = {`DDR_UOP_WIDTH{`LOW}};
    if(instr_valid) begin
      // Decoding a DDR packet
      if(instr[`DDR_OFFSET]) begin
        ddr_valid_ns = `HIGH;
        for(i = 0 ; i < 4 ; i = i + 1) begin: gen_ddr_uops
          case(ddr_insts[i][`DDR_CODE_OFFSET +: 3])
            `WRITE: begin
              ddr_uop_ns[i][`IS_WRITE] = `HIGH;
              ddr_uop_ns[i][`INC_CAR]  = ddr_insts[i][`DEC_INC_CAR];
              ddr_uop_ns[i][`INC_BAR]  = ddr_insts[i][`DEC_INC_BAR];
              ddr_uop_ns[i][`CAR+:4]   = ddr_insts[i][`DEC_CAR+:4];
              ddr_uop_ns[i][`BAR+:4]   = ddr_insts[i][`DEC_BAR+:4];
              ddr_uop_ns[i][`DO_AP]    = ddr_insts[i][`DEC_AP];
              ddr_uop_ns[i][`IS_BL4]   = ddr_insts[i][`DEC_BL4];
            end
            `READ: begin
              ddr_uop_ns[i][`IS_READ]  = `HIGH;
              ddr_uop_ns[i][`INC_CAR]  = ddr_insts[i][`DEC_INC_CAR];
              ddr_uop_ns[i][`INC_BAR]  = ddr_insts[i][`DEC_INC_BAR];
              ddr_uop_ns[i][`CAR+:4]   = ddr_insts[i][`DEC_CAR+:4];
              ddr_uop_ns[i][`BAR+:4]   = ddr_insts[i][`DEC_BAR+:4];
              ddr_uop_ns[i][`DO_AP]    = ddr_insts[i][`DEC_AP];
              ddr_uop_ns[i][`IS_BL4]   = ddr_insts[i][`DEC_BL4];
            end
            `PRE: begin
              ddr_uop_ns[i][`IS_PRE]   = `HIGH;
              ddr_uop_ns[i][`PRE_ALL]  = ddr_insts[i][`DEC_PRE_ALL];
              ddr_uop_ns[i][`INC_BAR]  = ddr_insts[i][`DEC_INC_BAR];
              ddr_uop_ns[i][`BAR+:4]   = ddr_insts[i][`DEC_BAR+:4];
            end
            `ACT: begin
              ddr_uop_ns[i][`IS_ACT]   = `HIGH;
              ddr_uop_ns[i][`INC_RAR]  = ddr_insts[i][`DEC_INC_RAR];
              ddr_uop_ns[i][`INC_BAR]  = ddr_insts[i][`DEC_INC_BAR];
              ddr_uop_ns[i][`RAR+:4]   = ddr_insts[i][`DEC_RAR+:4];
              ddr_uop_ns[i][`BAR+:4]   = ddr_insts[i][`DEC_BAR+:4];
            end
            `ZQ: begin
              ddr_uop_ns[i][`IS_ZQ]    = `HIGH;
            end
            `REF: begin
              ddr_uop_ns[i][`IS_REF]   = `HIGH;
            end
            `NOP: begin
              ddr_uop_ns[i][`IS_NOP]   = `HIGH;
            end
          endcase
        end
      end
      else if(instr[`SR_OFFSET]) begin
        ddr_valid_ns = `HIGH;
        case(instr[`FU_CODE_OFFSET])
          `SRE: begin
            ddr_uop_ns[0][`IS_SRE] = `HIGH;
            ddr_uop_ns[1][`IS_NOP] = `HIGH;
            ddr_uop_ns[2][`IS_NOP] = `HIGH;
            ddr_uop_ns[3][`IS_NOP] = `HIGH;
          end   
          `SRX: begin
            ddr_uop_ns[0][`IS_SRX] = `HIGH;
            ddr_uop_ns[1][`IS_NOP] = `HIGH;
            ddr_uop_ns[2][`IS_NOP] = `HIGH;
            ddr_uop_ns[3][`IS_NOP] = `HIGH;
          end   
        endcase
      end
      else begin
        exe_valid_ns = `HIGH;
        // Decoding a branch instruction
        if(instr[`BRANCH_OFFSET]) begin
          case(instr[`FU_CODE_OFFSET +: 8])
            `BL: begin
              exe_uop_ns[`RS1 +: 4]    = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RS2 +: 4]    = instr[`DEC_RS2 +: 4];
              exe_uop_ns[`IMD +: 19]   = instr[`DEC_BR_TGT_OFFSET  +: 19];
              exe_uop_ns[`IS_BL]       = `HIGH;
            end
            `BEQ: begin
              exe_uop_ns[`RS1 +: 4]    = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RS2 +: 4]    = instr[`DEC_RS2 +: 4];
              exe_uop_ns[`IMD +: 19]   = instr[`DEC_BR_TGT_OFFSET  +: 19];
              exe_uop_ns[`IS_BEQ]      = `HIGH;
            end
            `JUMP: begin
              exe_uop_ns[`IMD +: 27]   = instr[`DEC_JUMP_OFFSET  +: 27];
              exe_uop_ns[`IS_JUMP]     = `HIGH;
            end
            `SLEEP: begin
              exe_uop_ns[`IS_SLEEP]    = `HIGH;
              exe_uop_ns[`IMD +: 27]   = instr[`DEC_SLEEP_OFFSET +: 27];
            end        
          endcase
        end
        else if(instr[`MEM_OFFSET]) begin
          case(instr[`FU_CODE_OFFSET +: 8])
            `LD: begin
              exe_uop_ns[`RS1 +: 4]    = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RT  +: 4]    = instr[`DEC_RT +: 4];
              exe_uop_ns[`IMD +: 16]   = instr[`DEC_IMD1  +: 16];
              exe_uop_ns[`IS_MEM]      = `HIGH;
              exe_uop_ns[`IS_LD]       = `HIGH;
              exe_uop_ns[`HAS_IMD]     = `HIGH;
            end
            `ST: begin
              exe_uop_ns[`RS1 +: 4]    = instr[`DEC_RS1 +: 4]; // The address base to write to
              exe_uop_ns[`RS2 +: 4]    = instr[`DEC_RT  +: 4]; // The value to write
              exe_uop_ns[`IMD +: 16]   = instr[`DEC_IMD1  +: 16];
              exe_uop_ns[`IS_MEM]      = `HIGH;
              exe_uop_ns[`IS_ST]       = `HIGH;
              exe_uop_ns[`HAS_IMD]     = `HIGH;
            end        
          endcase
        end
        else if(instr[`BW_OFFSET]) begin
          case(instr[`FU_CODE_OFFSET +: 8])
            `AND: begin
              exe_uop_ns[`RS1 +: 4]    = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RS2 +: 4]    = instr[`DEC_RS2 +: 4];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_AND]       = `HIGH;
            end
            `OR: begin
              exe_uop_ns[`RS1 +: 4]    = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RS2 +: 4]    = instr[`DEC_RS2 +: 4];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_OR]      = `HIGH;
            end      
            `XOR: begin
              exe_uop_ns[`RS1 +: 4]    = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RS2 +: 4]    = instr[`DEC_RS2 +: 4];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_XOR]      = `HIGH;
            end   
          endcase
        end
        // Decoding a normal instruction
        else begin
          case(instr[`FU_CODE_OFFSET +: 8])
            `ADD: begin
              exe_uop_ns[`RS1 +: 4]  = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RS2 +: 4]  = instr[`DEC_RS2 +: 4];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_ADD]    = `HIGH;
            end
            `ADDI: begin
              exe_uop_ns[`RS1 +: 4]  = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`IMD +: 16] = instr[`DEC_IMD1 +: 16];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_ADD]    = `HIGH;
              exe_uop_ns[`HAS_IMD]   = `HIGH;
            end
            `SUB: begin
              exe_uop_ns[`RS1 +: 4]  = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RS2 +: 4]  = instr[`DEC_RS2 +: 4];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_SUB]    = `HIGH;
            end
            `SUBI: begin
              exe_uop_ns[`RS1 +: 4]  = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`IMD +: 16] = instr[`DEC_IMD1 +: 16];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_SUB]    = `HIGH;
              exe_uop_ns[`HAS_IMD]   = `HIGH;
            end
            `MV: begin
              exe_uop_ns[`RS1 +: 4]  = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_MOV]    = `HIGH;
            end
            `SRC: begin
              exe_uop_ns[`RS1 +: 4]  = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_SRC]    = `HIGH;
            end
            `LI: begin
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_LI]     = `HIGH;
              exe_uop_ns[`IMD +: 16] = instr[`DEC_IMD1 +: 16];
              exe_uop_ns[`IMD2 +: 16]= instr[`DEC_IMD3 +: 16];
              exe_uop_ns[`HAS_IMD]   = `HIGH;
            end
            `LDWD: begin
              exe_uop_ns[`RS1 +: 4]  = instr[`DEC_RS1 +: 4];
              // used to select word offset in wide write data register
              exe_uop_ns[`RT +: 4]   = instr[`DEC_WO  +: 4];
              exe_uop_ns[`IS_LDWD]   = `HIGH;
            end   
            `LDPC: begin
              exe_uop_ns[`RS1 +: 4]  = instr[`DEC_RS1 +: 4];
              exe_uop_ns[`RT +: 4]   = instr[`DEC_RT  +: 4];
              exe_uop_ns[`IS_LDPC]   = `HIGH;
            end       
          endcase
        end
      end
    end
  end

  always @(posedge clk) begin
    
    if(rst) begin
      exe_pc_r <= {`IMEM_ADDR_WIDTH{`LOW}};
      exe_uop_r <= {`EXE_UOP_WIDTH{`LOW}};
      exe_valid_r <= `LOW;
      ddr_valid_r <= `LOW;
      for(i = 0 ; i < 4 ; i = i + 1)
        ddr_uop_r[i] <= {`DDR_UOP_WIDTH{`LOW}};
      is_started <= `LOW;
    end
    else begin
      exe_uop_r <= exe_uop_ns;
      exe_valid_r <= exe_valid_ns;
      ddr_valid_r <= ddr_valid_ns;
      for(i = 0 ; i < 4 ; i = i + 1)
        ddr_uop_r[i] <= ddr_uop_ns[i];
      exe_pc_r <= instr_pc;
    end
  
    if(~is_started) begin
      for(i = 0 ; i < 7 ; i = i + 1) begin
        ddr_stat_r[i] <= 0;   
      end
      if(instr_pc == 1)
        is_started <= 1;
    end
    else begin
      ddr_stat_r[6] <= ddr_stat_r[6] + 1;
      if(instr_valid) begin
        if(instr[`DDR_OFFSET]) begin
          for(i = 0 ; i < 4 ; i = i + 1) begin
            case(ddr_insts[i][`DDR_CODE_OFFSET +: 3])
              `WRITE: 
                ddr_stat_r[0] <= ddr_stat_r[0] + 1;
              `READ: 
                ddr_stat_r[1] <= ddr_stat_r[1] + 1;
              `PRE: 
                ddr_stat_r[2] <= ddr_stat_r[2] + 1;
              `ACT: 
                ddr_stat_r[3] <= ddr_stat_r[3] + 1;
              `ZQ: 
                ddr_stat_r[4] <= ddr_stat_r[4] + 1;
              `REF: 
                ddr_stat_r[5] <= ddr_stat_r[5] + 1;
            endcase
          end
        end
      end
    end
  end
  
  

endmodule
