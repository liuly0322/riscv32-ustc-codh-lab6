module alu #(
        parameter AW = 5,
        parameter DW = 32)
    (input [DW - 1: 0] a,
     input [DW - 1: 0] b,      // 两操作数
     input [3: 0] s,            // 功能选择
     output reg [DW - 1: 0] y, // 运算结果
     output reg [2:0] f);      // 标志

    // 大小判断
    wire [DW - 1: 0] a_minus_b = a - b;
    wire a_s = a[DW - 1];
    wire b_s = b[DW - 1];
    wire y_s = a_minus_b[DW - 1];

    // 移位
    wire [AW - 1: 0] b_shift = b[AW - 1: 0];

    // 大小比较信号
    wire less_signed   = (a_s & ~b_s) | (a_s & y_s) | (~b_s & y_s);
    wire less_unsigned = (~a_s & b_s) | (~a_s & y_s) | (b_s & y_s);
    assign f = {less_unsigned, less_signed, (a_minus_b == 0)};

    always @(*) begin
        case (s)
            4'b0001:
                y = a + b;
            4'b0010:
                y = a & b;
            4'b0011:
                y = a | b;
            4'b0100:
                y = a ^ b;
            4'b0101:
                y = a >> b_shift;
            4'b0110:
                y = a << b_shift;
            4'b0111:
                y = ($signed(a)) >>> b_shift;       // signed
            4'b1000:
                y = {31'b0, f[1]};
            4'b1001:
                y = {31'b0, f[2]};
            default:
                y = a_minus_b;
        endcase
    end

endmodule
