`timescale 1ns / 1ps

module tb_fft_16point_simple;

    parameter N = 16;

    reg  clk;
    reg  rst_n;
    reg  i_valid;
    reg  signed [N-1:0] i_data_re;
    reg  signed [N-1:0] i_data_im;
    
    wire o_valid;
    wire signed [N+3:0] o_data_re; 
    wire signed [N+3:0] o_data_im;

    fft_16point #(.N(N)) dut (
        .clk(clk), .rst_n(rst_n),
        .i_valid(i_valid), .i_data_re(i_data_re), .i_data_im(i_data_im),
        .o_valid(o_valid), .o_data_re(o_data_re), .o_data_im(o_data_im)
    );

    //  Generate 100 MHz Clock
    always #5 clk = ~clk;

    integer i;

    initial begin
        // Initialize Signals
        clk       = 0;
        rst_n     = 0;
        i_valid   = 0;
        i_data_re = 0;
        i_data_im = 0;

        // Apply Reset
        #20 rst_n = 1; #15;

  
        $display("--- Pushing Data Frame ---");
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            i_valid   = 1;
            i_data_re = 16'sd100; // Constant DC value
            i_data_im = 16'sd0;
        end

        // =========================================================
        // FLUSH: Send 16 dummy zeros to push the data out
        // =========================================================
        $display("--- Pushing Dummy Zeros (Flush) ---");
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            i_valid   = 1;
            i_data_re = 16'sd0;
            i_data_im = 16'sd0;
        end

        // Stop valid stream
        @(posedge clk);
        i_valid = 0;

        // Wait for pipeline to drain completely
        #200;
        
        $display("--- Simulation Complete ---");
        $stop;
    end

    // 3. Monitor the Valid Outputs
    always @(posedge clk) begin
        if (o_valid) begin
            $display("Time: %0t | VALID OUTPUT -> Real: %5d, Imag: %5d", 
                     $time, o_data_re, o_data_im);
        end
    end

endmodule