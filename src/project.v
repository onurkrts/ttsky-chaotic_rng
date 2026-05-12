`default_nettype none

module tt_um_chaotic_rng (
    input  wire [7:0] ui_in,    // [7:4]: Lx, [3:0]: en
    output wire [7:0] uo_out,   // x[7:0]
    input  wire [7:0] uio_in,   // [7:4]: Lz, [3:3]: Ly
    output wire [7:0] uio_out,  // Debug outputs
    output wire [7:0] uio_oe,   // Direction control
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire [7:0] x, y, z;
    wire [3:0] Lx = ui_in[7:4];
    wire [3:0] Ly = uio_in[3:0];
    wire [3:0] Lz = uio_in[7:4];

    rng_chaos_scroll u_rng_chaos_scroll (
        .clk(clk),
        .rst_n(rst_n),
        .en(ui_in[3:0]),
        .Lx(Lx), .Ly(Ly), .Lz(Lz),
        .wire_x(x), .wire_y(y), .wire_z(z)
    );

    assign uo_out = x;

    assign uio_out = {z[1:0], y[2:0], x[2:0]};
    
    assign uio_oe = 8'b00000000; 

endmodule

module rng_chaos_scroll(
    input clk, rst_n,
    input [3:0] en,
    input [3:0] Lx, Ly, Lz,
    output [7:0] wire_x, wire_y, wire_z
);
    
    reg [31:0] x, y, z;
    
    assign wire_x = x[7:0];
    assign wire_y = y[7:0]; // Düzeltildi
    assign wire_z = z[7:0]; // Düzeltildi
    
    wire [31:0] Fx, Fy, Fz;
    
    func Fx_f(.F_i(x), .U_i(3'b100), .L_i(Lx), .F_o(Fx));
    func Fy_f(.F_i(y), .U_i(3'b100), .L_i(Ly), .F_o(Fy));
    func Fz_f(.F_i(z), .U_i(3'b100), .L_i(Lz), .F_o(Fz));

    wire [31:0] xo = en[1] ? Fx : x;
    wire [31:0] yo = en[2] ? Fy : y;
    wire [31:0] zo = en[3] ? Fz : z;

    wire [31:0] zd1 = xo + yo + zo;
    wire [31:0] zd  = zd1 - $signed(zd1 >>> 4);

    always @(posedge clk) begin
        if(!rst_n) begin
            x <= 32'h12345678;
            y <= 32'h87654321;
            z <= 32'hABCDEF12;
        end else if (en[0]) begin
            x <= x + $signed(yo >>> 3);
            y <= y + $signed(zo >>> 3);
            z <= z - $signed(zd >>> 3);
        end
    end
endmodule

module func(
    input  [31:0] F_i,
    input  [2:0]  U_i,
    input  [3:0]  L_i,
    output [31:0] F_o
);
    wire [5:0] Xh = F_i[31:26] - {L_i[3], L_i, 1'b1};
    wire [5:0] XU = F_i[31:26] - {U_i[2], U_i[2], U_i, 1'b1};
    
    wire [5:0] res = (Xh[5]) ? Xh : 
                     (XU[5]) ? (~{6{F_i[26]}}) : XU;

    assign F_o = {res, F_i[25:0]};
endmodule
