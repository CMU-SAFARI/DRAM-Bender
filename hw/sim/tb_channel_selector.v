`timescale 1ns / 1ps

// Mocking the header values - Adjust to match your project.vh
`define ROW_ADDR_WIDTH 14
`define COL_ADDR_WIDTH 10
`define BA_ADDR_WIDTH  2
`define WR_DATA_WIDTH  256
`define CMD_TYPE_WIDTH 4
`define PC_WIDTH       1
`define HBM_CH_WIDTH   4
`define RNOP           4'b0000

module tb_channel_selector();

    // ---------------------------------------------------------
    // Parameters and Signals
    // ---------------------------------------------------------
    reg dfi_clk;
    reg dfi_rst_n;

    // Command Inputs
    reg [2*`ROW_ADDR_WIDTH-1:0] row_addr;
    reg [2*`COL_ADDR_WIDTH-1:0] col_addr;
    reg [2*`BA_ADDR_WIDTH-1:0]  ba_addr;
    reg [2*`WR_DATA_WIDTH-1:0]  i_wrdata;
    reg [2*`CMD_TYPE_WIDTH-1:0] cmd_type;
    reg [2*`PC_WIDTH-1:0]       BA4;
    reg [2*`HBM_CH_WIDTH-1:0]   channel_id;
    reg [15:0]                  channel_id_oh;
    reg [15:0]                  hbm_enabled_channels;

    // Per-Channel Inputs (Arrays used for easy stimulation in loops)
    reg         ch_init_complete [0:15];
    reg [255:0] ch_rddata_p0     [0:15];
    reg [255:0] ch_rddata_p1     [0:15];
    reg [3:0]   ch_rddata_valid  [0:15];
    reg         ch_out_rst_n     [0:15];
    reg         ch_ready         [0:15];

    // Outputs
    wire        o_ch_dfi_init_complete;
    wire [255:0] o_ch_dfi_dw_rddata_p0;
    wire [255:0] o_ch_dfi_dw_rddata_p1;
    wire [3:0]  o_ch_dfi_dw_rddata_valid;
    wire        o_ch_dfi_out_rst_n;
    wire        o_ch_ready;

    wire [2*`CMD_TYPE_WIDTH-1:0] o_cmd_types [0:15];
    wire [2*`ROW_ADDR_WIDTH-1:0] o_row_addr;
    wire [2*`COL_ADDR_WIDTH-1:0] o_col_addr;
    wire [2*`BA_ADDR_WIDTH-1:0]  o_ba_addr;
    wire [2*`WR_DATA_WIDTH-1:0]  o_i_wrdata;
    wire [2*`PC_WIDTH-1:0]       o_BA4;

    // ---------------------------------------------------------
    // Clock Generation
    // ---------------------------------------------------------
    initial begin
        dfi_clk = 0;
        forever #5 dfi_clk = ~dfi_clk; // 100MHz
    end

    // ---------------------------------------------------------
    // Module Instantiation
    // ---------------------------------------------------------
    channel_selector uut (
        .dfi_clk(dfi_clk), .dfi_rst_n(dfi_rst_n),
        .row_addr(row_addr), .col_addr(col_addr), .ba_addr(ba_addr),
        .i_wrdata(i_wrdata), .cmd_type(cmd_type), .BA4(BA4),
        .channel_id(channel_id), .channel_id_oh(channel_id_oh),
        .hbm_enabled_channels(hbm_enabled_channels),

        // Map inputs to individual channel ports
        .dfi_0_init_complete(ch_init_complete[0]), .dfi_0_dw_rddata_p0(ch_rddata_p0[0]),
        .dfi_0_dw_rddata_p1(ch_rddata_p1[0]), .dfi_0_dw_rddata_valid(ch_rddata_valid[0]),
        .dfi_0_out_rst_n(ch_out_rst_n[0]), .ready_0(ch_ready[0]),

        .dfi_1_init_complete(ch_init_complete[1]), .dfi_1_dw_rddata_p0(ch_rddata_p0[1]),
        .dfi_1_dw_rddata_p1(ch_rddata_p1[1]), .dfi_1_dw_rddata_valid(ch_rddata_valid[1]),
        .dfi_1_out_rst_n(ch_out_rst_n[1]), .ready_1(ch_ready[1]),

        .dfi_2_init_complete(ch_init_complete[2]), .dfi_2_dw_rddata_p0(ch_rddata_p0[2]),
        .dfi_2_dw_rddata_p1(ch_rddata_p1[2]), .dfi_2_dw_rddata_valid(ch_rddata_valid[2]),
        .dfi_2_out_rst_n(ch_out_rst_n[2]), .ready_2(ch_ready[2]),

        .dfi_3_init_complete(ch_init_complete[3]), .dfi_3_dw_rddata_p0(ch_rddata_p0[3]),
        .dfi_3_dw_rddata_p1(ch_rddata_p1[3]), .dfi_3_dw_rddata_valid(ch_rddata_valid[3]),
        .dfi_3_out_rst_n(ch_out_rst_n[3]), .ready_3(ch_ready[3]),

        .dfi_4_init_complete(ch_init_complete[4]), .dfi_4_dw_rddata_p0(ch_rddata_p0[4]),
        .dfi_4_dw_rddata_p1(ch_rddata_p1[4]), .dfi_4_dw_rddata_valid(ch_rddata_valid[4]),
        .dfi_4_out_rst_n(ch_out_rst_n[4]), .ready_4(ch_ready[4]),

        .dfi_5_init_complete(ch_init_complete[5]), .dfi_5_dw_rddata_p0(ch_rddata_p0[5]),
        .dfi_5_dw_rddata_p1(ch_rddata_p1[5]), .dfi_5_dw_rddata_valid(ch_rddata_valid[5]),
        .dfi_5_out_rst_n(ch_out_rst_n[5]), .ready_5(ch_ready[5]),

        .dfi_6_init_complete(ch_init_complete[6]), .dfi_6_dw_rddata_p0(ch_rddata_p0[6]),
        .dfi_6_dw_rddata_p1(ch_rddata_p1[6]), .dfi_6_dw_rddata_valid(ch_rddata_valid[6]),
        .dfi_6_out_rst_n(ch_out_rst_n[6]), .ready_6(ch_ready[6]),

        .dfi_7_init_complete(ch_init_complete[7]), .dfi_7_dw_rddata_p0(ch_rddata_p0[7]),
        .dfi_7_dw_rddata_p1(ch_rddata_p1[7]), .dfi_7_dw_rddata_valid(ch_rddata_valid[7]),
        .dfi_7_out_rst_n(ch_out_rst_n[7]), .ready_7(ch_ready[7]),

        .dfi_8_init_complete(ch_init_complete[8]), .dfi_8_dw_rddata_p0(ch_rddata_p0[8]),
        .dfi_8_dw_rddata_p1(ch_rddata_p1[8]), .dfi_8_dw_rddata_valid(ch_rddata_valid[8]),
        .dfi_8_out_rst_n(ch_out_rst_n[8]), .ready_8(ch_ready[8]),

        .dfi_9_init_complete(ch_init_complete[9]), .dfi_9_dw_rddata_p0(ch_rddata_p0[9]),
        .dfi_9_dw_rddata_p1(ch_rddata_p1[9]), .dfi_9_dw_rddata_valid(ch_rddata_valid[9]),
        .dfi_9_out_rst_n(ch_out_rst_n[9]), .ready_9(ch_ready[9]),

        .dfi_10_init_complete(ch_init_complete[10]), .dfi_10_dw_rddata_p0(ch_rddata_p0[10]),
        .dfi_10_dw_rddata_p1(ch_rddata_p1[10]), .dfi_10_dw_rddata_valid(ch_rddata_valid[10]),
        .dfi_10_out_rst_n(ch_out_rst_n[10]), .ready_10(ch_ready[10]),

        .dfi_11_init_complete(ch_init_complete[11]), .dfi_11_dw_rddata_p0(ch_rddata_p0[11]),
        .dfi_11_dw_rddata_p1(ch_rddata_p1[11]), .dfi_11_dw_rddata_valid(ch_rddata_valid[11]),
        .dfi_11_out_rst_n(ch_out_rst_n[11]), .ready_11(ch_ready[11]),

        .dfi_12_init_complete(ch_init_complete[12]), .dfi_12_dw_rddata_p0(ch_rddata_p0[12]),
        .dfi_12_dw_rddata_p1(ch_rddata_p1[12]), .dfi_12_dw_rddata_valid(ch_rddata_valid[12]),
        .dfi_12_out_rst_n(ch_out_rst_n[12]), .ready_12(ch_ready[12]),

        .dfi_13_init_complete(ch_init_complete[13]), .dfi_13_dw_rddata_p0(ch_rddata_p0[13]),
        .dfi_13_dw_rddata_p1(ch_rddata_p1[13]), .dfi_13_dw_rddata_valid(ch_rddata_valid[13]),
        .dfi_13_out_rst_n(ch_out_rst_n[13]), .ready_13(ch_ready[13]),

        .dfi_14_init_complete(ch_init_complete[14]), .dfi_14_dw_rddata_p0(ch_rddata_p0[14]),
        .dfi_14_dw_rddata_p1(ch_rddata_p1[14]), .dfi_14_dw_rddata_valid(ch_rddata_valid[14]),
        .dfi_14_out_rst_n(ch_out_rst_n[14]), .ready_14(ch_ready[14]),

        .dfi_15_init_complete(ch_init_complete[15]), .dfi_15_dw_rddata_p0(ch_rddata_p0[15]),
        .dfi_15_dw_rddata_p1(ch_rddata_p1[15]), .dfi_15_dw_rddata_valid(ch_rddata_valid[15]),
        .dfi_15_out_rst_n(ch_out_rst_n[15]), .ready_15(ch_ready[15]),

        // Channel output mux
        .o_ch_dfi_init_complete(o_ch_dfi_init_complete), .o_ch_dfi_dw_rddata_p0(o_ch_dfi_dw_rddata_p0),
        .o_ch_dfi_dw_rddata_p1(o_ch_dfi_dw_rddata_p1), .o_ch_dfi_dw_rddata_valid(o_ch_dfi_dw_rddata_valid),
        .o_ch_dfi_out_rst_n(o_ch_dfi_out_rst_n), .o_ch_ready(o_ch_ready),

        // Command Type Outputs
        .o_0_cmd_type(o_cmd_types[0]),   .o_1_cmd_type(o_cmd_types[1]),
        .o_2_cmd_type(o_cmd_types[2]),   .o_3_cmd_type(o_cmd_types[3]),
        .o_4_cmd_type(o_cmd_types[4]),   .o_5_cmd_type(o_cmd_types[5]),
        .o_6_cmd_type(o_cmd_types[6]),   .o_7_cmd_type(o_cmd_types[7]),
        .o_8_cmd_type(o_cmd_types[8]),   .o_9_cmd_type(o_cmd_types[9]),
        .o_10_cmd_type(o_cmd_types[10]), .o_11_cmd_type(o_cmd_types[11]),
        .o_12_cmd_type(o_cmd_types[12]), .o_13_cmd_type(o_cmd_types[13]),
        .o_14_cmd_type(o_cmd_types[14]), .o_15_cmd_type(o_cmd_types[15]),

        .o_row_addr(o_row_addr), .o_col_addr(o_col_addr), .o_ba_addr(o_ba_addr),
        .o_i_wrdata(o_i_wrdata), .o_BA4(o_BA4)
    );

    // ---------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------
    integer i;

    initial begin
        // Initialize inputs
        dfi_rst_n = 0;
        row_addr = 0; col_addr = 0; ba_addr = 0;
        i_wrdata = 0; cmd_type = 0; BA4 = 0;
        channel_id = 0; channel_id_oh = 0;
        hbm_enabled_channels = 0;

        for (i=0; i<16; i=i+1) begin
            ch_init_complete[i] = 0;
            ch_rddata_p0[i]     = i;       // Unique pattern per channel
            ch_rddata_p1[i]     = i + 100; // Unique pattern per channel
            ch_rddata_valid[i]  = i[3:0];
            ch_out_rst_n[i]     = 1;
            ch_ready[i]         = 1;
        end

        // Reset Sequence
        #20 dfi_rst_n = 1;
        #10;

        // --- TEST CASE 1: Verify Channel Muxing (Data flow from Ch to Output) ---
        $display("Testing Channel Muxing...");
        for (i=0; i<16; i=i+1) begin
            @(posedge dfi_clk);
            channel_id    = i;
            channel_id_oh = (1 << i);

//            // Wait for 2 clock cycles pipeline delay
//            repeat(2) @(posedge dfi_clk);
//            #1; // Sample shortly after clock
//            if (o_ch_dfi_dw_rddata_p0 === ch_rddata_p0[i])
//                $display("CH %0d Mux: SUCCESS", i);
//            else
//                $display("CH %0d Mux: FAILED. Expected %h, Got %h", i, ch_rddata_p0[i], o_ch_dfi_dw_rddata_p0);
        end

        // --- TEST CASE 2: Verify Command Distribution (Broadcasting) ---
        $display("Testing Command Distribution via hbm_enabled_channels...");
        @(posedge dfi_clk);
        cmd_type = 8'hAA; // Dummy command
        hbm_enabled_channels = 16'b0000_0000_1000_0001; // Enable CH 0 and CH 7

        repeat(2) @(posedge dfi_clk);
        #1;
        if (o_cmd_types[0] === 8'hAA && o_cmd_types[7] === 8'hAA)
            $display("Command Broadcast: SUCCESS");
        else
            $display("Command Broadcast: FAILED");

        // --- TEST CASE 3: Verify Single Channel Command Selection ---
        $display("Testing Single Channel Command Selection...");
        hbm_enabled_channels = 0;
        channel_id = 4'd5;
        cmd_type = 8'h55;

        repeat(2) @(posedge dfi_clk);
        #1;
        if (o_cmd_types[5] === 8'h55)
            $display("Single Command CH 5: SUCCESS");
        else
            $display("Single Command CH 5: FAILED");

        #100;
        $display("Simulation Finished.");
        $finish;
    end

endmodule