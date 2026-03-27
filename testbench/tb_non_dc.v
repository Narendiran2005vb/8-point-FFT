`timescale 1ns / 1ps

module tb_fft_16point_nonzero;

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

    // Generate 100 MHz Clock
    always #5 clk = ~clk;

    integer i;

    reg signed [15:0] sample_re [0:15];
    reg signed [15:0] sample_im [0:15];

    initial begin
        // Initialize Sample Data (16-point Sine Wave)
        sample_re[0]  = 0;
        sample_re[1]  = 38;
        sample_re[2]  = 71;
        sample_re[3]  = 92;
        sample_re[4]  = 100;
        sample_re[5]  = 92;
        sample_re[6]  = 71;
        sample_re[7]  = 38;
        sample_re[8]  = 0;
        sample_re[9]  = -38;
        sample_re[10] = -71;
        sample_re[11] = -92;
        sample_re[12] = -100;
        sample_re[13] = -92;
        sample_re[14] = -71;
        sample_re[15] = -38;

        for (i = 0; i < 16; i = i + 1)
            sample_im[i] = 0;
    end

    initial begin
        // Initialize Signals
        clk       = 0;
        rst_n     = 0;
        i_valid   = 0;
        i_data_re = 0;
        i_data_im = 0;

        #20 rst_n = 1; #15;

        $display("--- Pushing Non-Zero Input Frame ---");
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            i_valid   = 1;
            i_data_re = sample_re[i];
            i_data_im = sample_im[i];
        end

        $display("--- Pushing Dummy Zeros (Flush) ---");
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge clk);
            i_valid   = 1;
            i_data_re = 0;
            i_data_im = 0;
        end

        @(posedge clk);
        i_valid = 0;

        #200;

        $display("--- Simulation Complete ---");
        $stop;
    end

    // Monitor outputs
    always @(posedge clk) begin
        if (o_valid) begin
            $display("Time: %0t | VALID OUTPUT -> Real: %5d, Imag: %5d", 
                     $time, o_data_re, o_data_im);
        end
    end

endmodule