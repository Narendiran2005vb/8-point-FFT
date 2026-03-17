`include "butterfly.v"

`timescale 1ns/1ps

module fft_2point #(
    parameter N = 16  // Input bit width
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire                 i_valid,
    input  wire signed [N-1:0]  i_data_re,
    input  wire signed [N-1:0]  i_data_im,
    
    output reg                  o_valid,
    output reg  signed [N:0]    o_data_re,  // N+1 bits to accommodate bit growth
    output reg  signed [N:0]    o_data_im
);

    // Control state: 0 = Fill (waiting for 2nd sample), 1 = Compute & Flush
    reg sel; 

    // Registers to hold the delayed input and the computed difference
    reg signed [N-1:0] input_delay_re, input_delay_im;
    reg signed [N:0]   diff_store_re,  diff_store_im;

    // Wires from the instantiated Butterfly
    wire signed [N:0] sum_re, sum_im;
    wire signed [N:0] diff_re, diff_im;

    // -------------------------------------------------------------------------
    // Instantiate the Combinational Butterfly (Your math engine)
    // -------------------------------------------------------------------------
    butterfly #(
        .N(N)
    ) bfly_inst (
        .A_re(input_delay_re),
        .A_im(input_delay_im),
        .B_re(i_data_re),
        .B_im(i_data_im),
        .Sum_re(sum_re),
        .Sum_im(sum_im),
        .Diff_re(diff_re),
        .Diff_im(diff_im)
    );

    // Add this to your variable declarations at the top
    reg flush_pending;

    // -------------------------------------------------------------------------
    // SDF Control and Data Routing (UPDATED)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sel            <= 1'b0;
            flush_pending  <= 1'b0;
            o_valid        <= 1'b0;
            o_data_re      <= {(N+1){1'b0}};
            o_data_im      <= {(N+1){1'b0}};
            input_delay_re <= {N{1'b0}};
            input_delay_im <= {N{1'b0}};
            diff_store_re  <= {(N+1){1'b0}};
            diff_store_im  <= {(N+1){1'b0}};
        end else begin
            
            // Default: clear valid flag unless we explicitly set it below
            o_valid <= 1'b0; 

            // 1. Output the stored difference from the previous computation
            // (This handles the flush independently of the i_valid signal)
            if (flush_pending) begin
                o_data_re     <= diff_store_re;
                o_data_im     <= diff_store_im;
                o_valid       <= 1'b1;
                flush_pending <= 1'b0; // Clear the flag after flushing
            end

            // 2. Handle incoming streaming data
            if (i_valid) begin
                sel <= ~sel; // Toggle state
                
                if (sel == 1'b0) begin
                    // FILL PHASE: Store sample 0. 
                    input_delay_re <= i_data_re;
                    input_delay_im <= i_data_im;
                    
                end else begin
                    // COMPUTE PHASE: Butterfly computes Sample 0 and Sample 1
                    
                    // Output the Sum immediately
                    o_data_re <= sum_re;
                    o_data_im <= sum_im;
                    o_valid   <= 1'b1;
                    
                    // Store the Difference to output on the next clock cycle
                    diff_store_re <= diff_re;
                    diff_store_im <= diff_im;
                    
                    // Set flag to trigger the flush on the next cycle!
                    flush_pending <= 1'b1; 
                end
            end
        end
    end

endmodule

// module fft_2point #(parameter N=16)(
//     input clk,
//     input rst_n,
//     input i_valid,
//     input signed [N-1:0] i_data_re,
//     input signed [N-1:0] i_data_im,

//     output reg o_valid,
//     output reg signed [N:0] o_data_re,
//     output reg signed [N:0] o_data_im
// );

// localparam S_IDLE  = 2'd0;
// localparam S_COMP  = 2'd1;
// localparam S_DIFF  = 2'd2;

// reg [1:0] state;

// reg signed [N-1:0] x0_re, x0_im;
// reg signed [N:0] diff_re, diff_im;

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         state <= S_IDLE;
//         o_valid <= 0;
//     end
//     else begin
//         o_valid <= 0;

//         case(state)

//         S_IDLE:
//         if(i_valid) begin
//             x0_re <= i_data_re;
//             x0_im <= i_data_im;
//             state <= S_COMP;
//         end

//         S_COMP:
//         if(i_valid) begin
//             o_data_re <= x0_re + i_data_re;
//             o_data_im <= x0_im + i_data_im;
//             o_valid   <= 1;

//             diff_re <= x0_re - i_data_re;
//             diff_im <= x0_im - i_data_im;

//             state <= S_DIFF;
//         end

//         S_DIFF:
//         begin
//             o_data_re <= diff_re;
//             o_data_im <= diff_im;
//             o_valid   <= 1;

//             state <= S_IDLE;
//         end

//         endcase
//     end
// end

// endmodule

// `timescale 1ns/1ps

// module fft_2point #(parameter N=16)(
//     input  wire clk,
//     input  wire rst_n,
//     input  wire i_valid,
//     input  wire signed [N-1:0] i_data_re,
//     input  wire signed [N-1:0] i_data_im,

//     output reg  o_valid,
//     output reg  signed [N:0] o_data_re,
//     output reg  signed [N:0] o_data_im
// );

// reg state;  // 0 = store first sample, 1 = output diff
// reg signed [N-1:0] x0_re, x0_im;
// reg signed [N:0] diff_re, diff_im;

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         state   <= 0;
//         o_valid <= 0;
//     end
//     else begin
//         o_valid <= 0;

//         if(state == 0) begin
//             if(i_valid) begin
//                 x0_re <= i_data_re;
//                 x0_im <= i_data_im;
//                 state <= 1;
//             end
//         end
//         else begin
//             if(i_valid) begin
//                 // output SUM
//                 o_data_re <= x0_re + i_data_re;
//                 o_data_im <= x0_im + i_data_im;
//                 o_valid   <= 1;

//                 // store DIFF
//                 diff_re <= x0_re - i_data_re;
//                 diff_im <= x0_im - i_data_im;
//             end
//             else begin
//                 // output stored DIFF
//                 o_data_re <= diff_re;
//                 o_data_im <= diff_im;
//                 o_valid   <= 1;
//                 state     <= 0;
//             end
//         end
//     end
// end

// endmodule