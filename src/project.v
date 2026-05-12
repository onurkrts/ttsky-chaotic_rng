```verilog
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

    wire rst;
    assign rst = ~rst_n;

    // RNG outputs
    wire [31:0] x;
    wire [31:0] y;
    wire [31:0] z;

    // enable
    wire [3:0] rng_en;
    assign rng_en = {3'b111, ena};

    // Programmable parameters
    wire [3:0] Lx; //4'b1011
    wire [3:0] Ly; //4'b1100
    wire [3:0] Lz; //4'b1011
    wire [2:0] Ux, Uy, Uz; // 3'b100

    assign Lx = ui_in[3:0];
    assign Ly = ui_in[7:4];
    assign Lz = uio_in[3:0];

    // Fixed U parameters
    assign Ux = 3'b100;
    assign Uy = 3'b100;
    assign Uz = 3'b100;

    rng_chaos_scroll u_rng_chaos_scroll (
        .clk(clk),
        .rst(rst),
        .en(rng_en),

        .x_init(32'h12345678),
        .y_init(32'h87654321),
        .z_init(32'hABCDEF12),

        .Lx(Lx),
        .Ux(Ux),

        .Ly(Ly),
        .Uy(Uy),

        .Lz(Lz),
        .Uz(Uz),

        .x(x),
        .y(y),
        .z(z)
    );

    // RNG output
    assign uo_out = x[7:0];

    // debug outputs
    assign uio_out[0] = x[0];
    assign uio_out[1] = x[1];
	assign uio_out[2] = x[2];
	assign uio_out[3] = y[0];
	assign uio_out[4] = y[1];
	assign uio_out[5] = y[2];
	assign uio_out[6] = z[0];
	assign uio_out[7] = z[1];

    // uio used as INPUTS
    assign uio_oe = 8'b11111111;

    // Unused signals
    wire _unused = &{
        uio_in[7:4],
        x[31:8],
        y[31:8],
        z[31:8],
        1'b0
    };

endmodule

module rng_chaos_scroll(
    input clk,
    input rst,
    input [3:0] en,
    input [31:0] x_init,
    input [31:0] y_init,
    input [31:0] z_init,
    input [3:0] Lx,
    input [2:0] Ux,
    input [3:0] Ly,
    input [2:0] Uy,
    input [3:0] Lz,
    input [2:0] Uz,
    output reg [31:0] x,
    output reg [31:0] y,
    output reg [31:0] z
);

// wires
wire [31:0] Fx, xn, xo;
wire [31:0] Fy, yn, yo;
wire [31:0] Fz, zn, zo, zd, zd1, zd2;

func Fx_func(
    .F_i(x),
    .U_i(Ux),
    .L_i(Lx),
    .F_o(Fx)
);

assign xo = en[1] ? Fx : x;

func Fy_func(
    .F_i(y),
    .U_i(Uy),
    .L_i(Ly),
    .F_o(Fy)
);

assign yo = en[2] ? Fy : y;

func Fz_func(
    .F_i(z),
    .U_i(Uz),
    .L_i(Lz),
    .F_o(Fz)
);

assign zo = en[3] ? Fz : z;

assign zd1 = xo + yo + zo;
assign zd2 = {{4{zd1[31]}}, zd1[31:4]};
assign zd  = zd1 - zd2;

assign xn = x + {{3{yo[31]}}, yo[31:3]};
assign yn = y + {{3{zo[31]}}, zo[31:3]};
assign zn = z - {{3{zd[31]}}, zd[31:3]};

always @(posedge clk)
begin
    if(rst) begin
        x <= x_init;
        y <= y_init;
        z <= z_init;
    end else if (en[0]) begin
        x <= xn;
        y <= yn;
        z <= zn;
    end
end

endmodule

module func(
    input   [31:0] F_i,
    input   [2:0]  U_i,
    input   [3:0]  L_i,
    output  [31:0] F_o
);

wire [5:0] Xhigh;
wire [5:0] X26_6n;
wire [5:0] Se_U;
wire [5:0] XU;
wire [5:0] XU_X26;
wire [5:0] out_6b;

assign Xhigh  = F_i[31:26] - {L_i[3], L_i, 1'b1};
assign X26_6n = ~{6{F_i[26]}};
assign Se_U   = {U_i[2], U_i[2], U_i, 1'b1};
assign XU     = F_i[31:26] - Se_U;
assign XU_X26 = (XU[5]) ? X26_6n : XU;
assign out_6b = (Xhigh[5]) ? Xhigh : XU_X26;
assign F_o    = {out_6b, F_i[25:0]};

endmodule
```
