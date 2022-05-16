module IF(
        input clk, stall_IF, rstn,
        input [31: 0] pc_nxt,
        input [31: 0] pc_nxt_EX,
        input pc_change_EX,
        output reg [31: 0] ir_IF,
        output reg [31: 0] pc_IF,
        output [31: 0] pc_4_IF
    );

    reg [31: 0] pc;
    wire [31: 0] ir;
    dist_ir ir_mem (.a(pc[9:2]), .d(0), .clk(clk), .we(0), .spo(ir));

    assign pc_4_IF = pc_IF + 32'h4;

    always@(posedge clk) begin
        if (!rstn) begin
            pc_IF   <= 32'h2ffc;
            ir_IF   <= 0;
        end
        else if (!stall_IF) begin
            pc_IF <= pc;
            ir_IF <= ir;
        end
    end

    // pc(下一条被发射的指令) 应该是关于 pc_IF(当前流水线中发射出的指令) 的组合逻辑输出
    always @(*) begin
        if (pc_change_EX)
            pc = pc_nxt_EX;
        else
            pc = pc_nxt;
    end

endmodule
