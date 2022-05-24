module MEM(
        input  [9: 0]       mem_addr_debug,
        input  [31: 0]      io_din,
        output [31: 0]      mem_data_debug,
        output [7:0]        io_addr,	    // 外设地址
        output [31:0]       io_dout,	    // 向外设输出的数据
        output              io_we,		    // 向外设输出数据时的写使能信号
        output              io_rd,		    // 从外设输入数据时的读使能信号
        input               clk,
        input               rstn,
        input [31: 0]       pc_4_EX,
        input [31: 0]       alu_out_EX,
        input [31: 0]       rd2_EX,
        input [4: 0]        reg_wb_addr_EX,
        input               ctrl_mem_r_EX,
        input               ctrl_mem_w_EX,
        input [2: 0]        funct3_EX,
        input               ctrl_reg_write_EX,
        input [1: 0]        ctrl_wb_reg_src_EX,
        output reg [31: 0]  pc_4_MEM,
        output reg [31: 0]  alu_out_MEM,
        output reg [31: 0]  mdr_MEM,
        output reg          ctrl_reg_write_MEM,
        output reg [1: 0]   ctrl_wb_reg_src_MEM,
        output reg [4: 0]   reg_wb_addr_MEM,
        output miss
    );

    // 对数据寄存器的一个包装。在数据寄存器的基础上增加了 mmio
    wire [31:0] mdr;
    mem_wrapper data_mem (
                    .a(alu_out_EX),
                    .d(rd2_EX),
                    .dpra(mem_addr_debug),
                    .clk(clk),
                    .en(ctrl_mem_r_EX),
                    .we(ctrl_mem_w_EX),
                    .funct3(funct3_EX),
                    .spo(mdr),
                    .dpo(mem_data_debug),
                    .io_addr(io_addr),
                    .io_din(io_din),
                    .io_dout(io_dout),
                    .io_rd(io_rd),
                    .io_we(io_we),
                    .miss(miss)
                );


    always@(posedge clk) begin
        if (!miss) begin
            pc_4_MEM            <= ~rstn? 0: pc_4_EX;
            alu_out_MEM         <= ~rstn? 0: alu_out_EX;
            ctrl_reg_write_MEM  <= ~rstn? 0: ctrl_reg_write_EX;
            ctrl_wb_reg_src_MEM <= ~rstn? 0: ctrl_wb_reg_src_EX;
            mdr_MEM             <= ~rstn? 0: mdr;
            reg_wb_addr_MEM     <= ~rstn? 0: reg_wb_addr_EX;
        end
    end
endmodule
