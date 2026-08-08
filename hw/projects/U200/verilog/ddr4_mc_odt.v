// Auto-generated, DDR4 SDRAM Example Design source
// small modifications to issue writes from all command slots
module ddr4_mc_odt #(parameter
        ODTWR     = 16'h8421
       ,ODTWRDEL  = 5'd9
       ,ODTWRDUR  = 4'd6
       ,ODTWRODEL = 5'd9
       ,ODTWRODUR = 4'd6
    
       ,ODTRD     = 16'h8421
       ,ODTRDDEL  = 5'd9
       ,ODTRDDUR  = 4'd6
       ,ODTRDODEL = 5'd9
       ,ODTRDODUR = 4'd6
    
       ,ODTBITS   = 4
       ,ODTNOP    = 4'b0000
       ,TCQ       = 0.1
    )(
        input clk
       ,input rst
    
       ,output [ODTBITS*8-1:0] mc_ODT
    
       ,input       casSlot2
       ,input [1:0] casSlot
       ,input [1:0] rank
       ,input       winRead
       ,input       winWrite
       ,input       tranSentC 
    );
    
    // ==========================================================================================
    // ODT is a multi-fabric-cycle waveform that needs to assert on the same cycle as write CAS,
    // and also on the same cycle as read CAS when tCL=tCWL.  This block generates the full
    // multi-cycle ODT waveform in the same cycle that rdCAS or wrCAS is generated, bypassing
    // the first 8 bits per ODT pin to mc_ODT combinationally, and flopping the remaining bits
    // in a shift register which are then sent to the XiPhy 8 bits per pin per cycle.  If CAS
    // commands are issued so that the current ODT waveform overlaps with the waveform from
    // previous commands, the waveforms will be OR'd together.
    // Note:  The original Olympus ODT block had separate timing for the selected rank and
    // non-target ranks.  This version of the code does not support this.
    // ==========================================================================================
    
    
    // ==========================================================================================
    // Signal Declarations
    // ==========================================================================================
    
    // Structures holding multi-fabric-cycle ODT pin waveforms for current CAS transaction
    wire [31:0] odt_array    [ ODTBITS-1:0 ];
    wire [31:0] odt_transent [ ODTBITS-1:0 ];
    
    // Shift register holding ODT pin waveforms for previous CAS transactions
    reg  [23:0] odt_shift    [ ODTBITS-1:0 ];
    wire [23:0] odt_shift_nxt[ ODTBITS-1:0 ];
    
    // ODT pin waveform for current fabric cycle, with time going from msb to lsb, reverse for XiPhy order
    wire [ 7:0] odt_reverse  [ ODTBITS-1:0 ];
    
    
    // ==========================================================================================
    // Module Code
    // ==========================================================================================
    
    // Set up basic write ODT timing waveform.  Note that time increases moving from msb to lsb.
    wire [31:0] odt_pulse_wr_slot0 = 32'hff_ff_ff_ff << (32 - 2*ODTWRDUR);
    wire [31:0] odt_pulse_wr_slot1 = odt_pulse_wr_slot0 >> 2;
    wire [31:0] odt_pulse_wr_slot2 = odt_pulse_wr_slot0 >> 4;
    wire [31:0] odt_pulse_wr_slot3 = odt_pulse_wr_slot0 >> 6;
    
    // Set up basic read ODT timing waveform.  Note that time increases moving from msb to lsb.
    wire [31:0] odt_pulse_rd_slot0 = ( 32'hff_ff_ff_ff << (32 - 2*ODTRDDUR) ) >> ( 2*( ODTRDDEL - ODTWRDEL ) );
    wire [31:0] odt_pulse_rd_slot1 = odt_pulse_rd_slot0 >> 2;
    wire [31:0] odt_pulse_rd_slot2 = odt_pulse_rd_slot0 >> 4;
    wire [31:0] odt_pulse_rd_slot3 = odt_pulse_rd_slot0 >> 6;
    
    // Select ODT timing waveform based on winning command type and slot position
    wire [31:0] win_odt_pulse_slot0 = winRead ? odt_pulse_rd_slot0 : odt_pulse_wr_slot0;
    wire [31:0] win_odt_pulse_slot1 = winRead ? odt_pulse_rd_slot1: odt_pulse_wr_slot1;
    wire [31:0] win_odt_pulse_slot2 = winRead ? odt_pulse_rd_slot2 : odt_pulse_wr_slot2;
    wire [31:0] win_odt_pulse_slot3 = winRead ? odt_pulse_rd_slot3 : odt_pulse_wr_slot3;
    wire [31:0] win_odt_pulse       = casSlot2 ? (casSlot[0] ? win_odt_pulse_slot3 : win_odt_pulse_slot2) 
                    : (casSlot[0] ? win_odt_pulse_slot1 : win_odt_pulse_slot0);
    
    // Select ODT pin pattern based on winning command type and rank
    wire [15:0] win_odt_cmd_pat = winRead ? ODTRD : ODTWR;
    wire [ 3:0] win_odt_pat     = { 4 { winRead | winWrite } } & win_odt_cmd_pat[ 4*rank +:4 ]; // spyglass disable W498
    
    genvar odt_pin;
    generate
       for (odt_pin = 0; odt_pin < ODTBITS; odt_pin = odt_pin + 1) begin
          // Combine selected waveform and pattern to generate full ODT output for the current winning CAS command
          assign odt_array[odt_pin]    = { 32 { win_odt_pat[ odt_pin ] } } & win_odt_pulse;
    
          // Qualify with tranSendC
          assign odt_transent[odt_pin] = { 32 { tranSentC } } & odt_array[ odt_pin ];
    
          // Parallel load lower 24 bits of qualified ODT output into shift register
          assign odt_shift_nxt[odt_pin] = odt_transent[odt_pin][23:0] | { odt_shift[odt_pin][15:0], 8'b0 };
    
          // Combine the upper 8 bits of the odt output for the new transaction (bypass path) with
          // the upper 8 bits of the shift register output to generate the odt block's output
          assign odt_reverse[odt_pin] = odt_transent[odt_pin][31:24] | odt_shift[odt_pin][23:16];
    
          // Reverse the msb/lsb order.  XiPhy wants increasing time going from lsb to msb
          assign mc_ODT[odt_pin*8+:8] = { odt_reverse[odt_pin][0], odt_reverse[odt_pin][1], odt_reverse[odt_pin][2], odt_reverse[odt_pin][3],
                                          odt_reverse[odt_pin][4], odt_reverse[odt_pin][5], odt_reverse[odt_pin][6], odt_reverse[odt_pin][7] };
       end
    endgenerate
    
    
    // ==========================================================================================
    // Reset flops
    // ==========================================================================================
    
    integer i;
    always @(posedge clk) begin
      if (rst) begin
        for (i = 0; i < ODTBITS; i = i + 1) begin
          odt_shift[i] <= #TCQ 28'b0;
        end
      end else begin
        for (i = 0; i < ODTBITS; i = i + 1) begin
          odt_shift[i] <= #TCQ odt_shift_nxt[i];
        end
      end
    end
    
endmodule