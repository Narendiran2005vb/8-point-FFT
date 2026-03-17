module complex_multiplier #(
    parameter DATA_WIDTH = 8,
    parameter TWIDDLE_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire i_valid,
    
    input  wire signed [DATA_WIDTH-1:0]    i_data_re,
    input  wire signed [DATA_WIDTH-1:0]    i_data_im,
    input  wire signed [TWIDDLE_WIDTH-1:0] i_twid_re,
    input  wire signed [TWIDDLE_WIDTH-1:0] i_twid_im,
    
    output reg                                  o_valid,
    // Note: Output width is DATA + TWIDDLE + 1 to prevent overflow during add/sub
    output reg  signed [DATA_WIDTH+TWIDDLE_WIDTH:0] o_result_re,
    output reg  signed [DATA_WIDTH+TWIDDLE_WIDTH:0] o_result_im
);

    localparam PROD_W = DATA_WIDTH + TWIDDLE_WIDTH;

    reg signed [PROD_W-1:0] mult_re_re;
    reg signed [PROD_W-1:0] mult_re_im;
    reg signed [PROD_W-1:0] mult_im_re;
    reg signed [PROD_W-1:0] mult_im_im;

    reg valid_d1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mult_re_re  <= 0;
            mult_re_im  <= 0;
            mult_im_re  <= 0;
            mult_im_im  <= 0;
            o_result_re <= 0;
            o_result_im <= 0;
            
            valid_d1    <= 0;
            o_valid     <= 0;
        end else begin

            mult_re_re <= i_data_re * i_twid_re;
            mult_re_im <= i_data_re * i_twid_im;
            mult_im_re <= i_data_im * i_twid_re;
            mult_im_im <= i_data_im * i_twid_im;
            
            valid_d1   <= i_valid;

            // Computing: Real = (Dr*Wr) - (Di*Wi) | Imag = (Dr*Wi) + (Di*Wr)  
            o_result_re <= mult_re_re - mult_im_im; 
            o_result_im <= mult_re_im + mult_im_re;
            
            o_valid <= valid_d1;
        end
    end

endmodule