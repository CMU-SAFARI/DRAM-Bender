`include "parameters.vh"
`include "encoding.vh"

/*
 * This combinational logic will output
 * whether or not an instruction is a branch
 * or not, for now.
 */
module pre_decode(
  input [`INSTR_WIDTH-1:0] instruction,
  // available readback_fifo entries in terms of read count
  input [11:0]             buffer_space,
  output [11:0]            read_size,
  output                   is_branch,
  output                   is_end,
  output                   is_ddr_start,
  output                   need_flush,
  output                   is_sleep
  );

  // When an instruction is non_ddr and has 
  // is_branch flag set
  assign is_branch = instruction[`BRANCH_OFFSET]
                        && ~instruction[`DDR_OFFSET];
                        
  assign is_end    = &(~instruction);
  
  // encountered a ddr command segments
  assign is_ddr_start = instruction[`INFO_OFFSET]
                        && ~instruction[`DDR_OFFSET];
  
  assign read_size    = instruction[9:0];
  // if there are more reads than we can buffer
  assign need_flush   = is_ddr_start && (read_size > buffer_space);    
       
  assign is_sleep     = instruction[`BRANCH_OFFSET] && 
                            instruction[`FU_CODE_OFFSET +: 8] == `SLEEP;
                        
endmodule
