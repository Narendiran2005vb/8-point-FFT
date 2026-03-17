module fft_stage4 #(
    parameter N = 20,             // Input width
    parameter TWID_W = 8,         // Twiddle factor bit width
    parameter SHIFT_VAL = 7       // Divide by 128 (2^7)
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 i_valid,
    input  wire signed [N-1:0]  i_data_re,
    input  wire signed [N-1:0]  i_data_im,

    output reg                  o_valid,
    output reg  signed [N:0]    o_data_re,  // N+1 bits (1 bit growth)
    output reg  signed [N:0]    o_data_im
);


    reg [3:0] count;           // 4-bit counter for L=8 (0 to 15)
    reg [3:0] flush_count;    

    wire is_compute = count[3];       // MSB controls Phase (0=Fill, 1=Compute)
    wire [2:0] twid_addr = count[2:0]; // Lower 3 bits control ROM Address

    // The L=8 Shift Register (Width N+1 to hold Butterfly Diff)
    reg signed [N:0] delay_re [0:7];
    reg signed [N:0] delay_im [0:7];
    reg signed [TWID_W-1:0] twid_re, twid_im;
    
    always @(*) begin
        case(twid_addr)
            3'd0: begin twid_re =  8'sd127; twid_im =  8'sd0;   end // W^0
            3'd1: begin twid_re =  8'sd113; twid_im = -8'sd50;  end // W^1
            3'd2: begin twid_re =  8'sd90;  twid_im = -8'sd90;  end // W^2
            3'd3: begin twid_re =  8'sd50;  twid_im = -8'sd113; end // W^3
            3'd4: begin twid_re =  8'sd0;   twid_im = -8'sd127; end // W^4
            3'd5: begin twid_re = -8'sd50;  twid_im = -8'sd113; end // W^5
            3'd6: begin twid_re = -8'sd90;  twid_im = -8'sd90;  end // W^6
            3'd7: begin twid_re = -8'sd113; twid_im = -8'sd50;  end // W^7
        endcase
    end

    wire signed [N+TWID_W-1:0] mult_re = (i_data_re * twid_re) - (i_data_im * twid_im);
    wire signed [N+TWID_W-1:0] mult_im = (i_data_re * twid_im) + (i_data_im * twid_re); 

    wire signed [N-1:0] trunc_re = mult_re[N + SHIFT_VAL - 1 : SHIFT_VAL];
    wire signed [N-1:0] trunc_im = mult_im[N + SHIFT_VAL - 1 : SHIFT_VAL];

    wire signed [N:0] sum_re, sum_im;
    wire signed [N:0] diff_re, diff_im;
    
    // A comes from the END of the delay line (delay[7])
    // B comes from the Truncated Multiplier output
    butterfly #(.N(N)) butterfly_inst (
        .A_re(delay_re[7][N-1:0]), 
        .A_im(delay_im[7][N-1:0]), 
        .B_re(trunc_re),             
        .B_im(trunc_im),
        .Sum_re(sum_re), 
        .Sum_im(sum_im),
        .Diff_re(diff_re), 
        .Diff_im(diff_im)
    );

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count       <= 4'b0;
            flush_count <= 4'b0;
            o_valid     <= 1'b0;
            o_data_re   <= 0; o_data_im <= 0;
            delay_re[0] <= 0; delay_im[0] <= 0;
            delay_re[1] <= 0; delay_im[1] <= 0;
            delay_re[2] <= 0; delay_im[2] <= 0;
            delay_re[3] <= 0; delay_im[3] <= 0;
            delay_re[4] <= 0; delay_im[4] <= 0;
            delay_re[5] <= 0; delay_im[5] <= 0;
            delay_re[6] <= 0; delay_im[6] <= 0;
            delay_re[7] <= 0; delay_im[7] <= 0;
        end else begin
            
            o_valid <= 1'b0; 
            // --- Flush Logic ---
            if (!i_valid && flush_count > 0) begin
                o_data_re <= delay_re[7]; 
                o_data_im <= delay_im[7];
                o_valid   <= 1'b1; 

                // Shift the delay line forward
                delay_re[7] <= delay_re[6]; delay_im[7] <= delay_im[6];
                delay_re[6] <= delay_re[5]; delay_im[6] <= delay_im[5]; 
                delay_re[5] <= delay_re[4]; delay_im[5] <= delay_im[4];
                delay_re[4] <= delay_re[3]; delay_im[4] <= delay_im[3];
                delay_re[3] <= delay_re[2]; delay_im[3] <= delay_im[2];
                delay_re[2] <= delay_re[1]; delay_im[2] <= delay_im[1];
                delay_re[1] <= delay_re[0]; delay_im[1] <= delay_im[0];
                
                flush_count <= flush_count - 1;
            end

            // --- Streaming Logic ---
            if (i_valid) begin
                count <= count + 1;

                // Shift the delay line forward
                delay_re[7] <= delay_re[6]; delay_im[7] <= delay_im[6];
                delay_re[6] <= delay_re[5]; delay_im[6] <= delay_im[5];
                delay_re[5] <= delay_re[4]; delay_im[5] <= delay_im[4];
                delay_re[4] <= delay_re[3]; delay_im[4] <= delay_im[3];
                delay_re[3] <= delay_re[2]; delay_im[3] <= delay_im[2]; 
                delay_re[2] <= delay_re[1]; delay_im[2] <= delay_im[1];
                delay_re[1] <= delay_re[0]; delay_im[1] <= delay_im[0]; 

                if (!is_compute) begin
                    // FILL PHASE: Store raw incoming data in the front of the delay line
                    delay_re[0] <= {i_data_re[N-1], i_data_re}; 
                    delay_im[0] <= {i_data_im[N-1], i_data_im};

                    // Output old data if flushing between continuous frames
                    if (flush_count > 0) begin
                        o_data_re <= delay_re[7];
                        o_data_im <= delay_im[7];
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

                    // 3. Queue up 8 flush cycles for later
                    flush_count <= 4'd8; 
                end
            end
        end
    end
endmodule