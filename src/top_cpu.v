module top_cpu(
        input clk,              // clk100mhz
        input rstn,             // cpu_resetn

        input step,             // btnu
        input cont,             // btnd
        input chk,              // btnr
        input data,             // btnc
        input del,              // btnl
        input [15 : 0] x,       // sw15-0

        output [3:0]	VGA_R,
        output [3:0]	VGA_G,
        output [3:0]	VGA_B,
        output 	        VGA_HS,
        output 	        VGA_VS,

        output          stop,    // led16r
        output [15 : 0] led,     // led15-0
        output [7 : 0]  an,      // an7-0
        output [6 : 0]  seg,     // ca-cg
        output [2 : 0]  seg_sel  // led17
    );
    wire clk_cpu;       // cpu's clk
    wire rst_cpu;       // cpu's rst

    // IO_BUS
    wire [7 : 0]    io_addr;
    wire [31 : 0]   io_dout;
    wire            io_we;
    wire            io_rd;
    wire [31 : 0]   io_din;

    // Debug_BUS
    wire [31 : 0] pc;
    wire [15 : 0] chk_addr;
    wire [31 : 0] chk_data;

    // VGA
    wire        clk_vga;
    wire [9:0]	vga_addr;
    wire [31:0] vga_data;

    pdu PDU (.clk(clk), .rstn(rstn),
             .step(step), .cont(cont), .chk(chk), .data(data), .del(del), .x(x),
             .stop(stop), .led(led), .an(an), .seg(seg), .seg_sel(seg_sel),
             .clk_cpu(clk_cpu), .rst_cpu(rst_cpu), .clk_vga(clk_vga),
             .io_addr(io_addr), .io_dout(io_dout), .io_we(io_we), .io_rd(io_rd), .io_din(io_din),
             .pc(pc), .chk_addr(chk_addr), .chk_data(chk_data));

    cpu CPU (.clk(clk_cpu), .rstn(~rst_cpu), .vga_addr(vga_addr), .vga_data(vga_data),
             .io_addr(io_addr), .io_dout(io_dout), .io_we(io_we), .io_rd(io_rd), .io_din(io_din),
             .pc(pc), .chk_addr(chk_addr), .chk_data(chk_data));

    vga_driver u_vga_driver(
                   .clk      		( clk_vga   	),
                   .rstn     		( rstn     		),
                   .VGA_R    		( VGA_R    		),
                   .VGA_G    		( VGA_G    		),
                   .VGA_B    		( VGA_B    		),
                   .VGA_HS   		( VGA_HS   		),
                   .VGA_VS   		( VGA_VS   		),
                   .vga_addr 		( vga_addr 		),
                   .vga_data 		( vga_data 		)
               );

endmodule
