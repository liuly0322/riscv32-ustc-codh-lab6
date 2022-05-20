module EX(
        input clk,
        input rstn,
        input [2: 0]       funct3_ID,
        input              predict_ID,
        input [3: 0]       ctrl_alu_op_ID,
        input              ctrl_alu_src1_ID,
        input              ctrl_alu_src2_ID,
        input              ctrl_jal_ID,
        input              ctrl_jalr_ID,
        input              ctrl_branch_ID,
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
        input  [4: 0]      rs1_ID,
        input  [4: 0]      rs2_ID,
        input              ctrl_reg_write_MEM,
        input  [4: 0]      reg_wb_addr_MEM,
        input  [31: 0]     reg_wb_data,
        output             record_we,           // 是否记录分支历史
        output             record_data,         // 是否跳转
        output reg         ctrl_reg_write_EX,
        output reg [1: 0]  ctrl_wb_reg_src_EX,
        output reg         ctrl_mem_r_EX,
        output reg [31: 0] alu_out_EX,
        output             pc_change_EX,
        output reg [31: 0] pc_nxt_EX,
        output [31: 0]     record_pc_result,
        output reg [31: 0] rd2_EX,
        output reg [31: 0] pc_4_EX,
        output reg [4: 0]  reg_wb_addr_EX,
        output reg         ctrl_mem_w_EX,
        output reg [2: 0]  funct3_EX
    );

    // rd1 和 rd2 需要 forward
    reg [31:0] rd1_forward;
    always @(*) begin
        rd1_forward = rd1_ID;
        if (ctrl_reg_write_MEM && reg_wb_addr_MEM == rs1_ID) begin
            rd1_forward = reg_wb_data;
        end
        if (ctrl_reg_write_EX && reg_wb_addr_EX == rs1_ID) begin
            if (ctrl_wb_reg_src_EX == 2'b00)
                rd1_forward = alu_out_EX;
            else if (ctrl_wb_reg_src_EX == 2'b10)
                rd1_forward = pc_4_EX;
        end
        if (rs1_ID == 0)
            rd1_forward = 0;
    end
    reg [31:0] rd2_forward;
    always @(*) begin
        rd2_forward = rd2_ID;
        if (ctrl_reg_write_MEM && reg_wb_addr_MEM == rs2_ID) begin
            rd2_forward = reg_wb_data;
        end
        if (ctrl_reg_write_EX && reg_wb_addr_EX == rs2_ID) begin
            if (ctrl_wb_reg_src_EX == 2'b00)
                rd2_forward = alu_out_EX;
            else if (ctrl_wb_reg_src_EX == 2'b10)
                rd2_forward = pc_4_EX;
        end
        if (rs2_ID == 0)
            rd2_forward = 0;
    end

    // alu 模块及 alu 模块的端口连接
    wire [31: 0] alu_in1 = ctrl_alu_src1_ID ? pc_ID : rd1_forward;
    wire [31: 0] alu_in2 = ctrl_alu_src2_ID ? imm_ID : rd2_forward;
    wire [2:  0] alu_f;
    wire [31: 0] alu_out;
    alu alu32 (.a(alu_in1), .b(alu_in2), .s(ctrl_alu_op_ID), .y(alu_out), .f(alu_f));

    // 改变 pc 的指令分为三类：
    // branch: 需要考虑当前是否应该跳转，下一条指令是否已经跳转
    // jal:    同上，但是必然应该跳转，下一条指令可能没有跳转
    // jalr:   同上，但是这里只需要反馈给 pc, jalr 的目的地址无法记录

    wire should_branch = ((funct3_ID[2] == 1)? ((funct3_ID[1] == 1)? alu_f[2]: alu_f[1]) : alu_f[0]) ^ funct3_ID[0];
    wire jal_fail      = (ctrl_jal_ID & ~predict_ID);
    wire pc_branch_EX  = (ctrl_branch_ID & (should_branch ^ predict_ID));       // 预测失败, branch 引发 pc 更改
    assign pc_change_EX = pc_branch_EX | ctrl_jalr_ID | jal_fail;               // 下一条 pc 是否应该改变（不再是 pc+4）
    always @(*) begin
        if (ctrl_jal_ID | ctrl_jalr_ID)
            pc_nxt_EX = alu_out;
        else if (pc_branch_EX && predict_ID && !should_branch)   // 预测跳转但没有跳转
            pc_nxt_EX = pc_4_ID;
        else                                                     // 预测不跳转但跳转
            pc_nxt_EX = pc_ID + imm_ID;
    end

    assign record_we        = ctrl_branch_ID | jal_fail;
    assign record_data      = ctrl_jal_ID? 1: should_branch;
    assign record_pc_result = pc_nxt_EX;

    always @(posedge clk) begin
        alu_out_EX         <= ~rstn? 0: alu_out;
        rd2_EX             <= ~rstn? 0: rd2_forward;
        ctrl_reg_write_EX  <= ~rstn? 0: ctrl_reg_write_ID;
        ctrl_wb_reg_src_EX <= ~rstn? 0: ctrl_wb_reg_src_ID;
        ctrl_mem_r_EX      <= ~rstn? 0: ctrl_mem_r_ID;
        ctrl_mem_w_EX      <= ~rstn? 0: ctrl_mem_w_ID;
        pc_4_EX            <= ~rstn? 0: pc_4_ID;
        reg_wb_addr_EX     <= ~rstn? 0: reg_wb_addr_ID;
        funct3_EX          <= ~rstn? 0: funct3_ID;
    end

endmodule
