module alu #(parameter WIDTH = 32)
    (input [WIDTH - 1: 0] a,
     input [WIDTH - 1: 0] b,      // 两操作数
     input [2:0] s,               // 功能选择
     output reg [WIDTH - 1: 0] y, // 运算结果
     output reg [2:0] f);         // 标志

    wire a_s = a[WIDTH - 1];
    wire b_s = b[WIDTH - 1];
    wire y_s = y[WIDTH - 1];

    always @(*) begin
        case (s)
            3'b000:
                y = a - b;
            3'b001:
                y = a + b;
            3'b010:
                y = a & b;
            3'b011:
                y = a | b;
            3'b100:
                y = a ^ b;
            3'b101:
                y = a >> b;
            3'b110:
                y = a << b;
            3'b111:
                y = ($signed(a)) >>> b;       // signed
        endcase
    end

    always @(*) begin
        f[0] = (y == 0 ? 1'b1 :1'b0);
        f[1] = (a_s & ~b_s) | (a_s & y_s) | (~b_s & y_s);
        f[2] = (~a_s & b_s) | (~a_s & y_s) | (b_s & y_s);
    end
endmodule
