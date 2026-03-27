module butterfly #(
    parameter N = 16  // Input bit width
)(
    input  signed [N-1:0] A_re,
    input  signed [N-1:0] A_im,
    input  signed [N-1:0] B_re,
    input  signed [N-1:0] B_im,
    
    output signed [N:0] Sum_re,
    output signed [N:0] Sum_im,
    output signed [N:0] Diff_re,
    output signed [N:0] Diff_im
);

    // Combinational logic for butterfly
    assign Sum_re  = A_re + B_re;
    assign Sum_im  = A_im + B_im;
    assign Diff_re = A_re - B_re;
    assign Diff_im = A_im - B_im;

endmodule