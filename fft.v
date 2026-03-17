`timescale 1ns / 1ps
`include "fft1.v"
`include "fft2.v"
`include "fft3.v"
`include "fft4.v"
//`include "round_off.v"
`include "complex_multiplier.v"
`include "Twiddle_rom.v"
module fft_16point #(
    parameter N = 16  // Base Input Bit Width
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 i_valid,
    input  wire signed [N-1:0]  i_data_re,
    input  wire signed [N-1:0]  i_data_im,
    
    output wire                 o_valid,
    // Final output grows by 4 bits total across 4 stages (16 -> 17 -> 18 -> 19 -> 20)
    output wire signed [N+3:0]  o_data_re,  
    output wire signed [N+3:0]  o_data_im
);

    // =========================================================================
    // Interconnect Wires
    // =========================================================================
    wire                 stage1_valid;
    wire signed [N:0]    stage1_re, stage1_im;  // 17 bits

    wire                 stage2_valid;
    wire signed [N+1:0]  stage2_re, stage2_im;  // 18 bits

    wire                 stage3_valid;
    wire signed [N+2:0]  stage3_re, stage3_im;  // 19 bits

    // =========================================================================
    // Stage 1: 2-Point Core (L=1)
    // =========================================================================
    fft_2point #(.N(N)) stage1_inst (
        .clk(clk), .rst_n(rst_n),
        .i_valid(i_valid), .i_data_re(i_data_re), .i_data_im(i_data_im),
        .o_valid(stage1_valid), .o_data_re(stage1_re), .o_data_im(stage1_im)
    );

    // =========================================================================
    // Stage 2: 4-Point Combiner (L=2)
    // =========================================================================
    fft_stage2 #(.N(N + 1)) stage2_inst (
        .clk(clk), .rst_n(rst_n),
        .i_valid(stage1_valid), .i_data_re(stage1_re), .i_data_im(stage1_im),
        .o_valid(stage2_valid), .o_data_re(stage2_re), .o_data_im(stage2_im)
    );

    // =========================================================================
    // Stage 3: 8-Point Combiner (L=4)
    // =========================================================================
    fft_stage3 #(.N(N + 2)) stage3_inst (
        .clk(clk), .rst_n(rst_n),
        .i_valid(stage2_valid), .i_data_re(stage2_re), .i_data_im(stage2_im),
        .o_valid(stage3_valid), .o_data_re(stage3_re), .o_data_im(stage3_im)
    );

    // =========================================================================
    // Stage 4: 16-Point Combiner (L=8)
    // =========================================================================
    fft_stage4 #(.N(N + 3)) stage4_inst (
        .clk(clk), .rst_n(rst_n),
        .i_valid(stage3_valid), .i_data_re(stage3_re), .i_data_im(stage3_im),
        .o_valid(o_valid), .o_data_re(o_data_re), .o_data_im(o_data_im)
    );

endmodule