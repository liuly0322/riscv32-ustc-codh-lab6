module top_test(
        input clk,              // clk100mhz
        input rstn,             // cpu_resetn
        output [31:0] pc,
        // for simulate io
        output [7:0] io_addr,
        output io_rd,
        input [31:0] io_din
    );

    wire [31 : 0] io_dout;
    wire io_we;
    wire [31 : 0] chk_data;
    wire [31:0] vga_data;

    cpu CPU (.clk(clk), .rstn(rstn), .vga_addr(0), .vga_data(vga_data),
             .io_addr(io_addr), .io_dout(io_dout), .io_we(io_we),
             .io_rd(io_rd), .io_din(io_din),
             .pc(pc), .chk_addr(0), .chk_data(chk_data));

endmodule
