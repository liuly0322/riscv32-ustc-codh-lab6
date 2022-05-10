module EX(
        input clk,
        input              predict_ID,
        input [3: 0]       ctrl_alu_op_ID,
        input              ctrl_alu_src1_ID,
        input              ctrl_alu_src2_ID,
        input              ctrl_jalr_ID,
        input [2: 0]       ctrl_branch_ID,
        input [4: 0]       reg_wb_addr_ID,
        input [31: 0]      imm_ID,
        input [31: 0]      rd1_ID,
        input [31: 0]      pc_ID,
        input [31: 0]      pc_4_ID,
        input [31: 0]      rd2_ID,
        input              ctrl_reg_write_ID,
        input [1: 0]       ctrl_wb_reg_src_ID,
        input              ctrl_mem_r_ID,
        input              ctrl_mem_w_ID,
        output             record_we,           // 是否记录分支历史
        output [4: 0]      record_pc,           // 记录的 pc[6:2]
        output             record_data,         // 是否跳转
        output reg         ctrl_reg_write_EX,
        output reg [1: 0]  ctrl_wb_reg_src_EX,
        output reg         ctrl_mem_r_EX,
        output [31: 0]     alu_out,
        output reg [31: 0] alu_out_EX,
        output             pc_change_EX,
        output [31:0]      pc_nxt_EX,
        output reg [31: 0] rd2_EX,
        output reg [31: 0] pc_4_EX,
        output reg [4: 0]  reg_wb_addr_EX,
        output reg         ctrl_mem_w_EX
    );

    // alu 模块及 alu 模块的端口连接
    wire [31: 0] alu_in1 = ctrl_alu_src1_ID ? pc_ID : rd1_ID;
    wire [31: 0] alu_in2 = ctrl_alu_src2_ID ? imm_ID : rd2_ID;
    wire [2:  0] alu_f;
    alu alu32 (.a(alu_in1), .b(alu_in2), .s(ctrl_alu_op_ID), .y(alu_out), .f(alu_f));

    // ctrl_branch 信号三位含义见 control 模块
    // is_branch:     当前指令是否是跳转指令
    wire is_branch     = ctrl_branch_ID[2];
    // should_branch: 当前跳转指令是否需要跳转
    wire should_branch = ((ctrl_branch_ID[1] == 1)? alu_f[1] : alu_f[0]) ^ ctrl_branch_ID[0];
    wire pc_branch_EX = (is_branch & (should_branch ^ predict_ID));       // 当且仅当预测失败
    wire pc_jump_EX   = ctrl_jalr_ID;
    assign pc_change_EX = pc_branch_EX | pc_jump_EX;
    always @(*) begin
        if (predict_ID && !should_branch)
            pc_nxt_EX = pc_4_ID;
        else
            pc_nxt_EX = (ctrl_jalr_ID? rd1_ID: pc_ID) + imm_ID;
    end

    assign record_pc   = pc_ID[6:2];
    assign record_we   = is_branch;
    assign record_data = should_branch;

    always @(posedge clk) begin
        alu_out_EX         <= alu_out;
        rd2_EX             <= rd2_ID;
        ctrl_reg_write_EX  <= ctrl_reg_write_ID;
        ctrl_wb_reg_src_EX <= ctrl_wb_reg_src_ID;
        ctrl_mem_r_EX      <= ctrl_mem_r_ID;
        ctrl_mem_w_EX      <= ctrl_mem_w_ID;
        pc_4_EX            <= pc_4_ID;
        reg_wb_addr_EX     <= reg_wb_addr_ID;
    end

endmodule
