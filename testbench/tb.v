`timescale 1ns / 1ps

module tb_fft_16point_impulse;

    localparam N = 16;

    reg  clk;
    reg  rst_n;
    reg  i_valid;
    reg  signed [N-1:0] i_data_re;
    reg  signed [N-1:0] i_data_im;
    
    wire o_valid;
    wire signed [N+3:0] o_data_re; // 20 bits wide
    wire signed [N+3:0] o_data_im;

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


        natural_input[0] = 16'sd1000; 
        for (i = 1; i < 16; i = i + 1) begin
            natural_input[i] = 16'sd0; 
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


        for (frame = 0; frame < 2; frame = frame + 1) begin
            for (i = 0; i < 16; i = i + 1) begin
                @(posedge clk);
                i_valid   = 1;
                current_idx = bit_rev_idx[i]; 
                i_data_re = natural_input[current_idx];
                i_data_im = 16'sd0;
            end
        end

        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            i_valid   = 1;
            i_data_re = 16'sd0;
            i_data_im = 16'sd0;
        end

        // Safely drop valid
        @(posedge clk);
        i_valid   = 0;

        #200;
        $display("Simulation Complete.");
        $stop;
    end

    // Monitor output
    always @(posedge clk) begin
        if (o_valid) begin
            if (o_data_re > 900 && o_data_im == 0) begin
                $display("--- NEW FRAME ---");
            end
            $display("Time: %0t | VALID OUTPUT -> Real: %5d, Imag: %5d", 
                     $time, o_data_re, o_data_im);
        end
    end

endmodule