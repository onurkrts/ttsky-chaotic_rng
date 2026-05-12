`default_nettype none

module tt_um_chaotic_rng (
    input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire [7:0] x_out;
    assign uo_out = x_out;
    assign uio_oe = 8'b00000000;
    assign uio_out = 8'b0;

    rng_chaos_scroll u_rng (
        .clk(clk), .rst_n(rst_n),
        .en(ui_in[3:0]),
        .Lx(ui_in[7:4]), .Ly(uio_in[3:0]), .Lz(uio_in[7:4]),
        .wire_x(x_out)
    );

    wire _unused = ena;
    
endmodule

module rng_chaos_scroll(
    input clk, rst_n,
    input [3:0] en,
    input [3:0] Lx, Ly, Lz,
    output [7:0] wire_x
);
    reg signed [23:0] x, y, z;

    function [23:0] chaos_f;
        input signed [23:0] val;
        input [3:0] l_p;
        reg [5:0] vh, vu;
        begin
            vh = val[23:18] - {l_p[3], l_p, 1'b1};
            vu = val[23:18] - 6'b100001; 
            chaos_f = {(vh[5] ? vh : (vu[5] ? ~{6{val[18]}} : vu)), val[17:0]};
        end
    endfunction

    wire signed [23:0] xo = en[1] ? chaos_f(x, Lx) : x;
    wire signed [23:0] yo = en[2] ? chaos_f(y, Ly) : y;
    wire signed [23:0] zo = en[3] ? chaos_f(z, Lz) : z;

    wire signed [23:0] zd_sum = xo + yo + zo;
    wire signed [23:0] zd     = zd_sum - (zd_sum >>> 4);

    always @(posedge clk) begin
        if (!rst_n) begin
            x <= 24'h123456; y <= 24'h876543; z <= 24'hABCDEF;
        end else if (en[0]) begin
            x <= x + (yo >>> 3);
            y <= y + (zo >>> 3);
            z <= z - (zd >>> 3);
        end
    end

    assign wire_x = x[7:0];

endmodule
