`timescale 1ns / 1ps

module trivial_rotator #(
    parameter N = 16  // Input data width
)(
    input  wire rot_sel,  // 0 = Multiply by 1, 1 = Multiply by -j
    input  wire signed [N-1:0]  i_data_re,
    input  wire signed [N-1:0]  i_data_im,
    
    output reg  signed [N-1:0]  o_data_re,
    output reg  signed [N-1:0]  o_data_im
);

    always @(*) begin
        if (rot_sel == 1'b0) begin
            // Pass-through (Multiply by 1)
            o_data_re = i_data_re;
            o_data_im = i_data_im;
        end else begin
            // Swap and Negate (Multiply by -j)
            o_data_re = i_data_im;
            o_data_im = -i_data_re; 
        end
    end

endmodule