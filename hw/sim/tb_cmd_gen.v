`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 02/02/2026 12:44:34 PM
// Design Name:
// Module Name: tb_cmd_gen
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

`include "parameters.vh"
`include "project.vh"

module tb_cmd_gen(

    );

    reg clk, rst;

    reg [3:0]                 ddr_write;
    reg [3:0]                 ddr_read;
    reg [3:0]                 ddr_pre;
    reg [3:0]                 ddr_act;
    reg [3:0]                 ddr_ref;
    reg [3:0]                 hbm_sel_ch; // used for channel select
    reg [3:0]                 ddr_nop;
    reg [3:0]                 ddr_ap;
    reg [3:0]                 ddr_rank; // can be used to indicate PC
    reg [3:0]                 ddr_pall;
    reg [4*`HBM_CH_WIDTH-1:0] hbm_ch;
    reg [4*`BG_WIDTH-1:0]     ddr_bg;
    reg [4*`BANK_WIDTH-1:0]   ddr_bank;
    reg [4*`COL_WIDTH-1:0]    ddr_col;
    reg [4*`ROW_WIDTH-1:0]    ddr_row;
    reg [511:0]               ddr_wdata;

    // --- 300 MHz Clock Generation ---
    initial clk = 0;
    always #1.667 clk = ~clk;

    cmd_gen dut
	(
      // common signals
      .clk(clk),
      .rst(rst),

      // ddr_pipeline <-> outer module if
      .ddr_write(ddr_write),
      .ddr_read(ddr_read),
      .ddr_pre(ddr_pre),
      .ddr_act(ddr_act),
      .ddr_ref(ddr_ref),
      .hbm_sel_ch(hbm_sel_ch), // used for channel select
      .ddr_nop(ddr_nop),
      .ddr_ap(ddr_ap),
      .ddr_rank(ddr_rank), // can be used to indicate PC
      .ddr_pall(ddr_pall),
      .hbm_ch(hbm_ch),
      .ddr_bg(ddr_bg),
      .ddr_bank(ddr_bank),
      .ddr_col(ddr_col),
      .ddr_row(ddr_row),
      .ddr_wdata(ddr_wdata),

      .fifo_data(),
      .fifo_ch_sel_oh(),
      .wrdata()

    );

    // --- Simulation Control ---
    integer loop_cnt;
    integer ch_idx;

    initial begin
        // Reset and Init
        initialize_signals();

        // 10 Cycle Reset
        repeat (10) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Run the sweep for 100 cycles to see the patterns overlap
        fork
            // Thread 1: Sweep hbm_sel_ch every single cycle (1, 2, 4, 8...)
            begin
                repeat (100) begin
                    for (ch_idx = 0; ch_idx < 4; ch_idx = ch_idx + 1) begin
                        if (ch_idx == 3)
                            hbm_sel_ch = #1 (4'b0001);
                        else
                            hbm_sel_ch = #1 4'b0;
                        @(posedge clk);
                    end
                end
            end

            // Thread 2: Increment hbm_ch every 3 cycles
            begin
                for (loop_cnt = 0; loop_cnt < 200; loop_cnt = loop_cnt + 1) begin
                    hbm_ch = #1 loop_cnt; // This will naturally truncate to the bus width
                    repeat (3) @(posedge clk);
                end
            end
        join

        // Finish up
        repeat (20) @(posedge clk);
        $display("Extended Simulation Complete.");
        $finish;
    end

    // Helper task to clear inputs
    task initialize_signals;
        begin
            rst = 1;
            hbm_sel_ch = 0; hbm_ch = 0;
            ddr_write = 0; ddr_read = 0; ddr_pre = 0; ddr_act = 0;
            ddr_ref = 0; ddr_nop = 0; ddr_ap = 0; ddr_rank = 0; ddr_pall = 0;
            ddr_bg = 0; ddr_bank = 0; ddr_col = 0; ddr_row = 0; ddr_wdata = 0;
        end
    endtask


endmodule
