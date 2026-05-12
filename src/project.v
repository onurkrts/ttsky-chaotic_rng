`default_nettype none

module tt_um_chaotic_rng (
    input  wire [7:0] ui_in,    // [7:4]: Lx, [3:0]: en
    output wire [7:0] uo_out,   // x[7:0]
    input  wire [7:0] uio_in,   // [7:4]: Lz, [3:0]: Ly
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire [7:0] x, y, z;
    
    assign uio_oe = 8'b00000000; 

    rng_chaos_scroll u_rng (
        .clk(clk), .rst_n(rst_n),
        .en(ui_in[3:0]),
        .Lx(ui_in[7:4]), .Ly(uio_in[3:0]), .Lz(uio_in[7:4]),
        .wire_x(x), .wire_y(y), .wire_z(z)
    );

    assign uo_out = x;
    assign uio_out = {z[1:0], y[2:0], x[2:0]};

endmodule

module rng_chaos_scroll(
    input clk, rst_n,
    input [3:0] en,
    input [3:0] Lx, Ly, Lz,
    output [7:0] wire_x, wire_y, wire_z
);
    reg [31:0] x, y, z;

    function [31:0] chaos_func;
        input [31:0] f_in;
        input [3:0]  l_param;
        reg [5:0] xh, xu;
        begin
            xh = f_in[31:26] - {l_param[3], l_param, 1'b1};
            xu = f_in[31:26] - 6'b100001; // U_i=3'b100 sabitlendi
            chaos_func = {(xh[5] ? xh : (xu[5] ? ~{6{f_in[26]}} : xu)), f_in[25:0]};
        end
    endfunction

    wire [31:0] xo = en[1] ? chaos_func(x, Lx) : x;
    wire [31:0] yo = en[2] ? chaos_func(y, Ly) : y;
    wire [31:0] zo = en[3] ? chaos_func(z, Lz) : z;

    wire [31:0] zd_sum = xo + yo + zo;
    wire [31:0] zd     = zd_sum - $signed(zd_sum >>> 4);

    always @(posedge clk) begin
        if (!rst_n) begin
            x <= 32'h12345678; y <= 32'h87654321; z <= 32'hABCDEF12;
        end else if (en[0]) begin
            x <= x + $signed(yo >>> 3);
            y <= y + $signed(zo >>> 3);
            z <= z - $signed(zd >>> 3);
        end
    end

    assign wire_x = x[7:0];
    assign wire_y = y[7:0];
    assign wire_z = z[7:0];

endmodule
