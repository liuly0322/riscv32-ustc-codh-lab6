module branch_predict(
    input clk,
    input [4: 0] record_chk_pc,     // 采用 5 位用于哈希，对应 pc[6:2]
    input record_we,                // 是否记录分支历史
    input [4: 0] record_pc,         // 记录的 pc[6:2]
    input record_data,              // 是否跳转
    output predict                  // 预测结果
);

// 饱和计数器
reg [1:0] record[0: 31];
assign predict = record[record_chk_pc][1];

always @(posedge clk) begin
    if (record_we) begin
        if (record_data && record[record_pc] != 2'b11)
            record[record_pc] <= record[record_pc] + 1;
        else if (!record_data && record[record_pc] != 2'b00)
            record[record_pc] <= record[record_pc] - 1;
    end
end

endmodule
