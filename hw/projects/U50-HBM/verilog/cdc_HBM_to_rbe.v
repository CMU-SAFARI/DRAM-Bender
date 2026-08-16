// Since we are moving from a fast to slow clock domain, 
// We need to implement this circuitry that will essentially "stretch" the signals coming from the fast clock domain
// This will make sure that a pulse (in the worst case) will always be captured by the circuitry in the slow clock domain

module cdc_HBM_to_rbe(
        input dfi_clk,
        input dfi_rst_n,
        input fab_clk,
        
        // HBM TO DRAM BENDER INTERFACE
        //input dfi_0_init_complete,
        input [255 : 0] dfi_0_dw_rddata_p0,
        input [255 : 0] dfi_0_dw_rddata_p1,
        input [3:0] dfi_0_dw_rddata_valid,

        output [255 : 0] o_dfi_0_dw_rddata_p0,
        output [255 : 0] o_dfi_0_dw_rddata_p1,
        output o_dfi_0_dw_rddata_valid
        
    );
    
    reg [255 : 0] dfi_0_dw_rddata_p0_r;
    reg [255 : 0] dfi_0_dw_rddata_p1_r;
    reg wr_en_r;

    wire [255:0] w_dfi_0_dw_rddata_p0;
    wire [255:0] w_dfi_0_dw_rddata_p1;
    wire [511:0] w_dfi_0_dw_rddata;
    wire w_wr_en;
    
    wire fifo_full;
    wire fifo_empty;
    wire fifo_valid;
    
    always @ (posedge dfi_clk)
    begin
        if (~dfi_rst_n) begin
            dfi_0_dw_rddata_p0_r <= 0;
            dfi_0_dw_rddata_p1_r <= 0;
        end else begin
            // for now I am assuming if rdvalid = 1111 we ignore the read
            // But in this circuit, there will still be a chance a 1111 will be captured, fix this issue
            // the thing is i don't know what 1111 is. It should be reading from both PC at the same time.
            // But in the testbench I have seperated from DRAM Bender I cant replicate this
            if ((dfi_0_dw_rddata_valid[1:0] == 2'b11) ^ (dfi_0_dw_rddata_valid[3:2] == 2'b11)) begin
                if ((dfi_0_dw_rddata_valid == 4'b0011)) begin
                    dfi_0_dw_rddata_p0_r <= {dfi_0_dw_rddata_p1[191:128], dfi_0_dw_rddata_p1[63:0], dfi_0_dw_rddata_p0[191:128], dfi_0_dw_rddata_p0[63:0]};
                    dfi_0_dw_rddata_p1_r <= 0;
                end else if ((dfi_0_dw_rddata_valid == 4'b1100)) begin
                    dfi_0_dw_rddata_p0_r <= 0;
                    dfi_0_dw_rddata_p1_r <= {dfi_0_dw_rddata_p1[255:192], dfi_0_dw_rddata_p1[127:64], dfi_0_dw_rddata_p0[255:192], dfi_0_dw_rddata_p0[127:64]};
                end
                wr_en_r <= 1'b1;
            end else begin
                dfi_0_dw_rddata_p0_r <= dfi_0_dw_rddata_p0_r;
                dfi_0_dw_rddata_p1_r <= dfi_0_dw_rddata_p1_r;
                wr_en_r <= 0;
            end
        end
    end

    assign w_dfi_0_dw_rddata_p0     = dfi_0_dw_rddata_p0_r;
    assign w_dfi_0_dw_rddata_p1     = dfi_0_dw_rddata_p1_r;
    assign w_wr_en                  = wr_en_r;
    
    assign o_dfi_0_dw_rddata_p0     = w_dfi_0_dw_rddata[255:0];
    assign o_dfi_0_dw_rddata_p1     = w_dfi_0_dw_rddata[511:256];
    assign o_dfi_0_dw_rddata_valid  = fifo_valid;
    
    
    cdc_fifo cdc_fifo0 (
        .srst(~dfi_rst_n),
        .wr_clk(dfi_clk),
        .rd_clk(fab_clk),
        .din({w_dfi_0_dw_rddata_p1, w_dfi_0_dw_rddata_p0}),
        .wr_en(w_wr_en),
        .rd_en(1'b1), // not sure what to set this to
        .dout(w_dfi_0_dw_rddata), // this is sent to the readback engine
        .full(fifo_full),
        .empty(fifo_empty),
        .valid(fifo_valid)
        //.wr_rst_busy(), // not needed
        //.rd_rst_busy()
    );
    
       
        
endmodule
