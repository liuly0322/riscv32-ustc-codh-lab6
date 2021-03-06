module control (
        input [31:0] ir,
        output [2:0] funct3,
        output control_branch,
        output control_jal,
        output control_jalr,
        output control_mem_read,
        output control_mem_write,
        output [1:0] control_wb_reg_src,
        output [3:0] control_alu_op,
        output control_alu_src1,
        output control_alu_src2,
        output control_reg_write);

    wire [6:0] opcd = ir[6:0];
    assign funct3 = ir[14:12];

    wire is_load    = (opcd == 7'b0000011);
    wire is_branch  = (opcd == 7'b1100011);
    wire is_store   = (opcd == 7'b0100011);
    wire is_jal     = (opcd == 7'b1101111);
    wire is_jalr    = (opcd == 7'b1100111);
    wire is_lui     = (opcd == 7'b0110111);
    wire is_auipc   = (opcd == 7'b0010111);
    wire is_arith   = (opcd == 7'b0110011);
    wire is_arith_i = (opcd == 7'b0010011);

    assign control_branch     = is_branch;
    assign control_jal        = is_jal;
    assign control_jalr       = is_jalr;
    assign control_mem_read   = is_load;
    assign control_mem_write  = is_store;
    assign control_alu_src1   = is_auipc | is_jal;
    assign control_alu_src2   = is_auipc | is_jal | is_jalr | is_arith_i | is_load | is_store | is_lui;
    assign control_reg_write  = ~(is_branch | is_store);

    // 写回寄存器的数据来源：
    // 2'b00: 来源于 alu
    // 2'b01: 来源于 mdr
    // 2'b10: 来源于 pc+4
    // 2'b11: 暂无
    reg [1:0] wb_signal;
    assign control_wb_reg_src = wb_signal;
    always@(*) begin
        wb_signal = 0;                    // 默认 0, 用 alu 运算结果
        if (is_load)
            wb_signal = 2'b01;            // 使用 mdr
        else if (is_jal | is_jalr) begin
            wb_signal = 2'b10;            // 用下一个 pc
        end
    end

    // R、I 型指令
    reg [3: 0] ctrl_alu_op;
    always @(*) begin
        ctrl_alu_op = 4'b0000;
        if (is_branch)
            ctrl_alu_op = 4'b0001;
        else if (is_lui)
            ctrl_alu_op = 4'b1010;
        else if (is_arith || is_arith_i) begin
            case (funct3)
                3'b000: begin           // add(i), sub(i)
                    if(is_arith & ir[30])
                        ctrl_alu_op = 4'b0001;
                end
                3'b001: begin           // sll
                    ctrl_alu_op = 4'b0110;
                end
                3'b010: begin           // slt(i)
                    ctrl_alu_op = 4'b1000;
                end
                3'b011: begin           // sltu(i)
                    ctrl_alu_op = 4'b1001;
                end
                3'b100: begin           // xor(i)
                    ctrl_alu_op = 4'b0100;
                end
                3'b101: begin           // srl(i) ,sra(i)
                    if(ir[30])
                        ctrl_alu_op = 4'b0111;
                    else
                        ctrl_alu_op = 4'b0101;
                end
                3'b110: begin           // or
                    ctrl_alu_op = 4'b0011;
                end
                3'b111: begin           // and
                    ctrl_alu_op = 4'b0010;
                end
            endcase
        end
    end
    assign control_alu_op = ctrl_alu_op;

endmodule
