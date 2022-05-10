module alu #(parameter WIDTH = 32)
    (input [WIDTH - 1: 0] a,
     input [WIDTH - 1: 0] b,      // 两操作数
     input [3:0] s,               // 功能选择
     output reg [WIDTH - 1: 0] y, // 运算结果
     output reg [2:0] f);         // 标志

    wire a_s = a[WIDTH - 1];
    wire b_s = b[WIDTH - 1];
    wire y_s = y[WIDTH - 1];

    always @(*) begin
        case (s)
            4'b000:
                y = a - b;
            4'b001:
                y = a + b;
            4'b010:
                y = a & b;
            4'b011:
                y = a | b;
            4'b100:
                y = a ^ b;
            4'b101:
                y = $signed(a) >> b;
            4'b110:
                y = $signed(a) << b;
            4'b111:
                y = ($signed(a)) >>> b;       // signed
            4'b1000:
                y = ( $signed(a) < $signed(b) )? 1 : 0;
            4'b1001:
                y = (a < b)? 1 : 0;
            default:
                y = a + b;
        endcase
    end

    always @(*) begin
        f[0] = (y == 0 ? 1'b1 :1'b0);
        f[1] = (a_s & ~b_s) | (a_s & y_s) | (~b_s & y_s);
        f[2] = (~a_s & b_s) | (~a_s & y_s) | (b_s & y_s);
    end
endmodule
