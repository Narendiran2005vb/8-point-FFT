module twiddle_rom #(
    parameter ADDR_WIDTH = 3,      
    parameter TWIDDLE_WIDTH = 8 )(    
    input  wire clk,
    input  wire [ADDR_WIDTH-1:0] i_addr,
    
    output reg signed [TWIDDLE_WIDTH-1:0] o_twid_re,
    output reg signed [TWIDDLE_WIDTH-1:0] o_twid_im
);

    localparam ROM_DEPTH = 1 << ADDR_WIDTH;

    reg signed [TWIDDLE_WIDTH-1:0] rom_re [0:ROM_DEPTH-1];
    reg signed [TWIDDLE_WIDTH-1:0] rom_im [0:ROM_DEPTH-1];

    initial begin
        rom_re[0] = 8'sd127;  rom_im[0] = 8'sd0;
        rom_re[1] = 8'sd90;   rom_im[1] = -8'sd90;
        rom_re[2] = 8'sd0;    rom_im[2] = -8'sd127;
        rom_re[3] = -8'sd90;  rom_im[3] = -8'sd90;
    end

    always @(posedge clk) begin
        o_twid_re <= rom_re[i_addr];
        o_twid_im <= rom_im[i_addr];
    end

endmodule

// module twiddle_rom #(
//     parameter ADDR_WIDTH = 3,       // Width of address bus (e.g., 3 bits for 8 addresses)
//     parameter TWIDDLE_WIDTH = 8     // Bit width for real and imaginary parts
// )(
//     input  wire clk,
//     input  wire [ADDR_WIDTH-1:0] i_addr,
    
//     output reg signed [TWIDDLE_WIDTH-1:0] o_twid_re,
//     output reg signed [TWIDDLE_WIDTH-1:0] o_twid_im
// );

//     // Number of elements in the ROM
//     localparam ROM_DEPTH = 1 << ADDR_WIDTH;

//     // The memory arrays for real (cosine) and imaginary (-sine) parts
//     reg signed [TWIDDLE_WIDTH-1:0] rom_re [0:ROM_DEPTH-1];
//     reg signed [TWIDDLE_WIDTH-1:0] rom_im [0:ROM_DEPTH-1];

//     // Initialize the ROM
//     // In a real project, you would use $readmemh("twiddle_re.hex", rom_re);
//     // For a small FFT, you can hardcode the initial blocks:
//     initial begin
//         // Example for N=8, Twiddle Width=8 (Scaled by 127)
//         // W_8^0 = 1 - j0
//         rom_re[0] = 8'sd127;  rom_im[0] = 8'sd0;
//         // W_8^1 = 0.707 - j0.707
//         rom_re[1] = 8'sd90;   rom_im[1] = -8'sd90;
//         // W_8^2 = 0 - j1
//         rom_re[2] = 8'sd0;    rom_im[2] = -8'sd127;
//         // W_8^3 = -0.707 - j0.707
//         rom_re[3] = -8'sd90;  rom_im[3] = -8'sd90;
//         // ... fill rest up to ROM_DEPTH
//     end

//     // Synchronous Read (Recommended for block RAM inference in FPGAs)
//     always @(posedge clk) begin
//         o_twid_re <= rom_re[i_addr];
//         o_twid_im <= rom_im[i_addr];
//     end

// endmodule