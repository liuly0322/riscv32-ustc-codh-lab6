module branch_predict(
        input clk,
        input rstn,

        // 记录
        input record_we,                // 是否记录分支历史
        input [9:2] record_pc,          // 记录的 pc
        input record_data,              // 记录是否跳转
        input [31:0] record_pc_result,  // 记录跳转后 pc
        // 查询
        input [9:1] chk_branch_pc,
        output predict,                 // 预测结果
        output [31:0] predict_pc        // 预测的 pc
    );

    reg [31:0] btb[0:255];      // BTB 表
    reg [1:0]  record[0:255];   // (hash 后) 饱和计数器
    reg [2:0]  history[0:31];   // (hash 后) 分支历史

    wire [4: 0] chk_pc_hash    = chk_branch_pc[6:2];
    wire [4: 0] record_pc_hash = record_pc[6:2];

    assign predict_pc = btb[chk_branch_pc[9:2]];
    assign predict    = !chk_branch_pc[1] & rstn & record[{chk_pc_hash, history[chk_pc_hash]}][1] & (predict_pc != 0);

    always @(posedge clk) begin
        if (record_we) begin
            if (record_data) begin
                btb[record_pc] <= record_pc_result;
            end
            history[record_pc_hash] <= {history[record_pc_hash][1:0], record_data};
            if (record_data && record[{record_pc_hash, history[record_pc_hash]}] != 2'b11)
                record[{record_pc_hash, history[record_pc_hash]}] <= record[{record_pc_hash, history[record_pc_hash]}] + 1;
            else if (!record_data && record[{record_pc_hash, history[record_pc_hash]}] != 2'b00)
                record[{record_pc_hash, history[record_pc_hash]}] <= record[{record_pc_hash, history[record_pc_hash]}] - 1;
        end
    end

endmodule
