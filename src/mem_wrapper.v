module mem_wrapper (
        a,
        d,
        dpra,
        clk,
        en,
        we,
        funct3,
        spo,
        dpo,
        io_addr,
        io_dout,
        io_we,
        io_rd,
        io_din
    );

    input wire [31 : 0] a;
    input wire [31 : 0] d;
    input wire [9 : 0] dpra;
    input wire clk;
    input wire en;
    input wire we;
    input wire [2: 0] funct3;
    output wire [31 : 0] spo;
    output wire [31 : 0] dpo;

    // 外设地址范围： 0x00, 0x04, 0x08, 0x0c, 0x10, 0x14, 0x18...
    input [31:0]   io_din;      // 来自外设输入的数据
    output [7:0]   io_addr;	    // 外设地址
    output [31:0]  io_dout; 	// 向外设输出的数据
    output  io_we;		        // 向外设输出数据时的写使能信号
    output  io_rd;		        // 从外设输入数据时的读使能信号

    wire is_mmio = (a[31:8] == 24'h0000ff);    // 判断现在是主存还是 mmio
    reg  [31:0] mem_in;         // 写入数据寄存器的数据
    wire [31:0] mem_out;        // 数据存储器读出的 32 位数据
    reg  [31:0] mdr;            // 实际返回的数据
    assign spo = is_mmio? io_din : mdr;
    dist_mem data_mem (
                 .a(a[9:2]),
                 .d(mem_in),
                 .dpra(dpra[9:2]),
                 .clk(clk),
                 .we(we & ~is_mmio),
                 .spo(mem_out),
                 .dpo(dpo)
             );

    always @(*) begin
        case (funct3)
            3'b000: begin           // lb
                case (a[1:0])
                    2'b00:
                        mdr = {{24{mem_out[7]}}, mem_out[7:0]};
                    2'b01:
                        mdr = {{24{mem_out[15]}}, mem_out[15:8]};
                    2'b10:
                        mdr = {{24{mem_out[23]}}, mem_out[23:16]};
                    2'b11:
                        mdr = {{24{mem_out[31]}}, mem_out[31:24]};
                endcase
            end
            3'b001: begin           // lh
                case (a[1])
                    1'b0:
                        mdr = {{16{mem_out[15]}}, mem_out[15:0]};
                    1'b1:
                        mdr = {{16{mem_out[31]}}, mem_out[31:16]};
                endcase
            end
            3'b100: begin           // lbu
                case (a[1:0])
                    2'b00:
                        mdr = {24'b0, mem_out[7:0]};
                    2'b01:
                        mdr = {24'b0, mem_out[15:8]};
                    2'b10:
                        mdr = {24'b0, mem_out[23:16]};
                    2'b11:
                        mdr = {24'b0, mem_out[31:24]};
                endcase
            end
            3'b101: begin           // 1hu
                case (a[1])
                    1'b0:
                        mdr = {16'b0, mem_out[15:0]};
                    1'b1:
                        mdr = {16'b0, mem_out[31:16]};
                endcase
            end
            default:
                mdr = mem_out;
        endcase
    end

    always @(*) begin
        case (funct3)
            3'b000:             // sb
            case (a[1:0])
                2'b00:
                    mem_in = {mem_out[31:8], d[7:0]};
                2'b01:
                    mem_in = {mem_out[31:16], d[7:0], mem_out[7:0]};
                2'b10:
                    mem_in = {mem_out[31:24], d[7:0], mem_out[15:0]};
                2'b11:
                    mem_in = {d[7:0], mem_out[23:0]};
            endcase
            3'b001:             // sh
            case (a[1])
                1'b0:
                    mem_in = {mem_out[31:16], d[15:0]};
                1'b1:
                    mem_in = {d[15:0], mem_out[15:0]};
            endcase
            default:            // sw
                mem_in = d;
        endcase
    end

    assign io_addr = a[7:0];
    assign io_dout = d;
    assign io_we   = we & is_mmio;
    assign io_rd   = en & is_mmio;

endmodule
