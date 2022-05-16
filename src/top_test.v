module top_test(
        input clk,              // clk100mhz
        input rstn,             // cpu_resetn
        input [9:0] vga_addr
    );

    // IO_BUS
    wire [7 : 0] io_addr;
    wire [31 : 0] io_dout;
    wire io_we;
    wire io_rd;

    // Debug_BUS
    wire [31 : 0] pc;
    wire [31 : 0] chk_data;

    // VGA
    wire [31:0] vga_data;

    cpu CPU (.clk(clk), .rstn(rstn), .vga_addr(vga_addr), .vga_data(vga_data),
             .io_addr(io_addr), .io_dout(io_dout), .io_we(io_we), .io_rd(io_rd), .io_din(0),
             .pc(pc), .chk_addr(0), .chk_data(chk_data));

endmodule
