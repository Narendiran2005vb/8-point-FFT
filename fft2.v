`timescale 1ns / 1ps
`include "trivial_rotor.v"

module fft_stage2 #(
    parameter N = 16
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 i_valid,
    input  wire signed [N-1:0]  i_data_re,
    input  wire signed [N-1:0]  i_data_im,
    
    output reg                  o_valid,
    output reg  signed [N:0]    o_data_re,
    output reg  signed [N:0]    o_data_im
);

    reg [1:0] count;
    reg [1:0] flush_count;

    reg signed [N:0] delay_re [0:1];
    reg signed [N:0] delay_im [0:1];

    wire signed [N-1:0] rot_re, rot_im;
    wire signed [N:0]   sum_re, sum_im;
    wire signed [N:0]   diff_re, diff_im;

    wire is_compute = count[1];
    wire rot_sel    = count[0];

    trivial_rotator #(.N(N)) rotator_inst (
        .rot_sel(rot_sel),
        .i_data_re(i_data_re),
        .i_data_im(i_data_im),
        .o_data_re(rot_re),
        .o_data_im(rot_im)
    );

    butterfly #(.N(N)) bfly_inst (
        .A_re(delay_re[1][N-1:0]),
        .A_im(delay_im[1][N-1:0]), 
        .B_re(rot_re),
        .B_im(rot_im),
        .Sum_re(sum_re),
        .Sum_im(sum_im),
        .Diff_re(diff_re),
        .Diff_im(diff_im)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count        <= 2'b00;
            flush_count  <= 2'b00;
            o_valid      <= 1'b0;
            o_data_re    <= 0; o_data_im <= 0;
            delay_re[0]  <= 0; delay_im[0] <= 0;
            delay_re[1]  <= 0; delay_im[1] <= 0;
        end else begin
            
            o_valid <= 1'b0;

            if (!i_valid && flush_count > 0) begin
                o_data_re   <= delay_re[1];
                o_data_im   <= delay_im[1];
                o_valid     <= 1'b1;
                
                delay_re[1] <= delay_re[0];
                delay_im[1] <= delay_im[0];
                
                flush_count <= flush_count - 1;
            end

            if (i_valid) begin
                if(i_valid) begin
                    count <= count + 1;
                end
                else begin
                   count <= 0;
                end
                delay_re[1] <= delay_re[0];
                delay_im[1] <= delay_im[0];

                if (!is_compute) begin
                    delay_re[0] <= {i_data_re[N-1], i_data_re}; 
                    delay_im[0] <= {i_data_im[N-1], i_data_im};

                    if (flush_count > 0) begin
                        o_data_re <= delay_re[1];
                        o_data_im <= delay_im[1];
                        o_valid   <= 1'b1;
                        flush_count <= flush_count - 1;
                    end

                end else begin
                    o_data_re <= sum_re;
                    o_data_im <= sum_im;
                    o_valid   <= 1'b1;

                    delay_re[0] <= diff_re;
                    delay_im[0] <= diff_im;

                    flush_count <= 2'b10; 
                end
            end
        end
    end

endmodule






module fft_stage2_sample #(
    parameter N = 16  // Input bit width (Should match output of Stage 1)
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 i_valid,
    input  wire signed [N-1:0]  i_data_re,
    input  wire signed [N-1:0]  i_data_im,
    
    output reg                  o_valid,
    output reg  signed [N:0]    o_data_re,  // N+1 bits for bit growth
    output reg  signed [N:0]    o_data_im
);

    // =========================================================================
    // Internal Signals & State
    // =========================================================================
    reg [1:0] count;           // 2-bit counter for L=2
    reg [1:0] flush_count;     // To track flushing when i_valid drops

    // The L=2 Shift Register (Depth of 2)
    // We size this to N+1 bits so it can hold the 'Diff' from the butterfly!
    reg signed [N:0] delay_re [0:1];
    reg signed [N:0] delay_im [0:1];

    // Interconnect Wires
    wire signed [N-1:0] rot_re, rot_im;
    wire signed [N:0]   sum_re, sum_im;
    wire signed [N:0]   diff_re, diff_im;

    wire is_compute = count[1]; // 1 = Compute Phase, 0 = Fill Phase
    wire rot_sel    = count[0]; // 0 = Mult by 1, 1 = Mult by -j

    // =========================================================================
    // Instantiations
    // =========================================================================
    
    // 1. Trivial Rotator (Sits on the incoming B path)
    trivial_rotator #(.N(N)) rotator_inst (
        .rot_sel(rot_sel),
        .i_data_re(i_data_re),
        .i_data_im(i_data_im),
        .o_data_re(rot_re),
        .o_data_im(rot_im)
    );

    // 2. The Butterfly (A comes from delay line, B comes from rotator)
    butterfly #(.N(N)) bfly_inst (
        .A_re(delay_re[1][N-1:0]), // Read from the end of the shift register
        .A_im(delay_im[1][N-1:0]), 
        .B_re(rot_re),
        .B_im(rot_im),
        .Sum_re(sum_re),
        .Sum_im(sum_im),
        .Diff_re(diff_re),
        .Diff_im(diff_im)
    );

    // =========================================================================
    // Control & Shift Register Logic
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count        <= 2'b00;
            flush_count  <= 2'b00;
            o_valid      <= 1'b0;
            o_data_re    <= 0; o_data_im <= 0;
            delay_re[0]  <= 0; delay_im[0] <= 0;
            delay_re[1]  <= 0; delay_im[1] <= 0;
        end else begin
            
            o_valid <= 1'b0; // Default clear

            // --- 1. Flush Logic (When stream pauses) ---
            if (!i_valid && flush_count > 0) begin
                o_data_re   <= delay_re[1];
                o_data_im   <= delay_im[1];
                o_valid     <= 1'b1;
                
                // Shift the delay line to push out the last value
                delay_re[1] <= delay_re[0];
                delay_im[1] <= delay_im[0];
                
                flush_count <= flush_count - 1;
            end

            // --- 2. Standard Streaming Logic ---
            if (i_valid) begin
                count <= count + 1;

                // The delay line ALWAYS shifts forward every valid cycle!
                delay_re[1] <= delay_re[0];
                delay_im[1] <= delay_im[0];

                if (!is_compute) begin
                    // FILL PHASE: 
                    // 1. Put incoming data into the start of the delay line (sign-extended to N+1 bits)
                    delay_re[0] <= {i_data_re[N-1], i_data_re}; 
                    delay_im[0] <= {i_data_im[N-1], i_data_im};

                    // 2. Output whatever was at the end of the delay line (from previous frame)
                    if (flush_count > 0) begin
                        o_data_re <= delay_re[1];
                        o_data_im <= delay_im[1];
                        o_valid   <= 1'b1;
                        flush_count <= flush_count - 1;
                    end

                end else begin
                    // COMPUTE PHASE: 
                    // 1. Output the Sum immediately
                    o_data_re <= sum_re;
                    o_data_im <= sum_im;
                    o_valid   <= 1'b1;

                    // 2. Store the Difference in the start of the delay line
                    delay_re[0] <= diff_re;
                    delay_im[0] <= diff_im;

                    // 3. Queue up 2 flush cycles to output these differences later
                    flush_count <= 2'b10; 
                end
            end
        end
    end

endmodule