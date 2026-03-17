`timescale 1ns / 1ps

module tb_fft_16point;

    localparam N = 16;

    reg  clk;
    reg  rst_n;
    reg  i_valid;
    reg  signed [N-1:0] i_data_re;
    reg  signed [N-1:0] i_data_im;
    
    wire o_valid;
    wire signed [N+3:0] o_data_re; // 20 bits wide
    wire signed [N+3:0] o_data_im;

    // Instantiate Top-Level 16-Point FFT
    fft_16point #(.N(N)) dut (
        .clk(clk), .rst_n(rst_n),
        .i_valid(i_valid), .i_data_re(i_data_re), .i_data_im(i_data_im),
        .o_valid(o_valid), .o_data_re(o_data_re), .o_data_im(o_data_im)
    );

    // 100 MHz Clock
    always #5 clk = ~clk;

    // 4-Bit-reversed index array for N=16
    integer bit_rev_idx [0:15];
    reg signed [15:0] natural_input [0:15];
    
    integer frame, i, current_idx;

    initial begin
        // Setup Bit-Reversed Mapping for 16 points
        bit_rev_idx[0]  = 0;  bit_rev_idx[1]  = 8;
        bit_rev_idx[2]  = 4;  bit_rev_idx[3]  = 12;
        bit_rev_idx[4]  = 2;  bit_rev_idx[5]  = 10;
        bit_rev_idx[6]  = 6;  bit_rev_idx[7]  = 14;
        bit_rev_idx[8]  = 1;  bit_rev_idx[9]  = 9;
        bit_rev_idx[10] = 5;  bit_rev_idx[11] = 13;
        bit_rev_idx[12] = 3;  bit_rev_idx[13] = 11;
        bit_rev_idx[14] = 7;  bit_rev_idx[15] = 15;

        // Setup mathematical input signal (DC value of 10)
        // Expected FFT Output: X[0] = 160 (less minor quantization error), others = 0
        for (i = 0; i < 16; i = i + 1) begin
            natural_input[i] = 16'sd10; 
        end

        // Initialize
        clk       = 0;
        rst_n     = 0;
        i_valid   = 0;
        i_data_re = 0;
        i_data_im = 0;

        // Apply Reset
        #20;
        rst_n = 1;
        #15;

        // -------------------------------------------------------------
        // STREAM 5 CONSECUTIVE FRAMES (5 x 16 = 80 clock cycles)
        // We will NOT drop i_valid between frames!
        // -------------------------------------------------------------
        for (frame = 0; frame < 5; frame = frame + 1) begin
            for (i = 0; i < 16; i = i + 1) begin
                @(posedge clk);
                i_valid   = 1;
                current_idx = bit_rev_idx[i]; 
                i_data_re = natural_input[current_idx];
                i_data_im = 16'sd0;
            end
        end

        // Stop valid stream and let the deep pipeline flush
        @(posedge clk);
        i_valid   = 0;
        i_data_re = 16'sd0;
        i_data_im = 16'sd0;

        // Wait for pipeline to flush out the remaining data from the delay lines
        #400;
        
        $display("Simulation Complete.");
        $stop;
    end

    // Monitor output
    // To make it easy to read, we will print a spacer whenever X[0] pops out
    always @(posedge clk) begin
        if (o_valid) begin
            // X[0] is the large DC bin. We can roughly detect the start of a frame this way
            if (o_data_re > 100) begin
                $display("---------------- FRAME BOUNDARY ----------------");
            end
            $display("Time: %0t | VALID OUTPUT -> Real: %5d, Imag: %5d", 
                     $time, o_data_re, o_data_im);
        end
    end

endmodule