module IF(
        input clk, flush_IF, stall_IF, rstn,
        input [31: 0] pc_nxt_EX,
        input predict,
        input [31: 0] predict_pc,
        input pc_change_EX,
        output reg [31: 0] pc,
        output reg [31: 0] ir_IF,
        output reg [31: 0] pc_IF,
        output reg [31: 0] pc_4_IF,
        output reg predict_IF
    );

    wire [31: 0] ir;
    dist_ir ir_mem (.a(pc[9:2]), .d(0), .clk(clk), .we(0), .spo(ir));

    wire [31:0] pc_2 = pc + 32'h2;
    wire [31:0] pc_4 = pc + 32'h4;
    wire is_compressed = pc[1] || (ir[1:0] != 2'b11);

    always@(posedge clk) begin
        if (flush_IF | !rstn) begin
            pc_IF       <= 0;
            pc_4_IF     <= 0;
            ir_IF       <= 32'h13;
            predict_IF  <= 0;
        end
        else if (!stall_IF) begin
            pc_IF       <= pc;
            pc_4_IF     <= pc_4;
            ir_IF       <= ir;
            predict_IF  <= predict;
        end
    end

    always @(posedge clk) begin
        if (!rstn)
            pc <= 32'h3000;
        else if (pc_change_EX)
            pc <= pc_nxt_EX;
        else if (stall_IF)
            pc <= pc;
        else if (predict)
            pc <= predict_pc;
        else if (is_compressed)
            pc <= pc_2;
        else
            pc <= pc_4;
    end

endmodule
