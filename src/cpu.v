module  cpu (
        input clk,
        input rstn,

        // IO_BUS
        output [7:0]  io_addr,	// 外设地址
        output [31:0]  io_dout,	// 向外设输出的数据
        output  io_we,		    // 向外设输出数据时的写使能信号
        output  io_rd,		    // 从外设输入数据时的读使能信号
        input [31:0]  io_din,	// 来自外设输入的数据

        // Debug_BUS
        output [31:0] pc,      	// 当前执行指令地址
        input  [15:0] chk_addr,	// 寄存器地址
        output [31:0] chk_data, // 读取寄存器数据

        // VGA_BUS
        input  [9:0]  vga_addr, // vga 访问的数据存储器地址
        output [31:0] vga_data  // vga 得到的值
    );

    // 变量命名约定：对于段间寄存器，统一取前一段作为命名后缀
    // 对于段内寄存器，取所在段作为命名后缀

    // if 段
    wire [31:0]   predict_pc;           // 预测的下一个 pc
    wire          predict_IF;           // if/id 段的指令是否被预测跳转
    wire          flush_IF;             // if/id 段清空（因为 pc 改变）
    wire          stall_IF;             // if 段停顿，目前是由于 load-use hazard
    wire [31:0]	  pc_IF;                // if/id 段的 pc，可以认为是正在执行的指令
    wire [31:0]	  ir_IF;                // if/id 段正在执行的指令
    wire [31:0]	  pc_4_IF;              // if/id 段正在执行的指令 pc + 4

    // id 段
    wire          flush_ID;             // 清空 id，目前是由于 load-use hazard 或者 pc 变动（与预测的 pc 不符）
    wire          stall_ID;             // cache miss
    wire [31:0]   reg_data_debug;       // pdu 使用的读寄存器
    wire [31:0]   pc_ID;                // id/ex 段 pc
    wire [31:0]   pc_4_ID;              // id/ex 段 pc+4
    wire          predict;              // id 段，如果正在执行的指令是分支指令，预测是否跳转
    wire          predict_ID;           // id/ex 段 predict
    wire [4:0]    rs1_ID;               // id/ex 段 rs1, 用于 ex 段判断是否需要 forward
    wire [4:0]    rs2_ID;               // id/ex 段 rs2, 用于 ex 段判断是否需要 forward
    wire [31:0]   rd1_ID;               // id/ex 段 rd1
    wire [31:0]   rd2_ID;               // id/ex 段 rd2
    wire [31:0]   imm_ID;               // id/ex 段 imm
    wire [2:0]    funct3_ID;
    wire          ctrl_branch_ID;
    wire          ctrl_mem_r_ID;
    wire          ctrl_mem_w_ID;
    wire [1:0]    ctrl_wb_reg_src_ID;
    wire [4:0]    reg_wb_addr_ID;
    wire [3:0]    ctrl_alu_op_ID;
    wire          ctrl_jal_ID;
    wire          ctrl_jalr_ID;
    wire          ctrl_alu_src1_ID;
    wire          ctrl_alu_src2_ID;
    wire          ctrl_reg_write_ID;
    wire          load_use_hazard;      // 检测当前指令是否与前一条 ld 指令产生相关，如果是，stall if 并 flush id

    // ex 段
    wire          stall_EX;             // cache miss
    wire          ctrl_reg_write_EX;
    wire [1: 0]   ctrl_wb_reg_src_EX;
    wire [4: 0]   reg_wb_addr_EX;
    wire          ctrl_mem_r_EX;
    wire [31: 0]  alu_out_EX;
    wire          pc_change_EX;         // pc 是否需要更改（预测失败或者 jalr）
    wire [31: 0]  pc_nxt_EX;            // 更改后的 pc
    wire          record_we;            // 是否记录分支历史，即当前 ex 段是否是分支指令
    wire [31: 0]  record_pc_result;     // 记录的跳转后地址
    wire          record_data;          // 当前分支指令是否跳转
    wire [31: 0]  rd2_EX;
    wire [31: 0]  pc_4_EX;
    wire          ctrl_mem_w_EX;
    wire [2: 0]   funct3_EX;

    // mem 段
    wire miss;
    wire [31: 0]  pc_4_MEM;
    wire [31: 0]  alu_out_MEM;
    wire [31: 0]  mdr_MEM;
    wire [1: 0]   ctrl_wb_reg_src_MEM;
    wire [4: 0]   reg_wb_addr_MEM;

    // wb 段（写回 id 段，这里都是 mem/wb 的段间寄存器）
    wire          ctrl_reg_write_MEM;
    wire [31: 0]  reg_wb_data;

    branch_predict u_branch_predict(
                       .clk           		( clk           		),
                       .rstn                ( rstn                  ),
                       .chk_branch_pc       ( pc[9:1]        		),
                       .record_we     		( record_we     		),
                       .record_pc     		( pc_ID[9:2]     		),
                       .record_pc_result    ( record_pc_result      ),
                       .record_data   		( record_data   		),
                       .predict       		( predict       		),
                       .predict_pc          ( predict_pc            )
                   );


    hazard u_hazard(
               .rstn               ( rstn              ),
               .miss               ( miss              ),
               .load_use_hazard    ( load_use_hazard   ),
               .pc_change_EX       ( pc_change_EX      ),
               .flush_IF           ( flush_IF          ),
               .stall_IF           ( stall_IF          ),
               .flush_ID           ( flush_ID          ),
               .stall_ID           ( stall_ID          ),
               .stall_EX           ( stall_EX          )
           );

    IF u_IF(
           .clk          		( clk          		),
           .rstn                ( rstn              ),
           .pc                  ( pc                ),
           .flush_IF            ( flush_IF          ),
           .stall_IF            ( stall_IF          ),
           .predict             ( predict           ),
           .predict_pc          ( predict_pc        ),
           .pc_nxt_EX    		( pc_nxt_EX    		),
           .ir_IF        		( ir_IF        		),
           .pc_IF        		( pc_IF        		),
           .pc_4_IF      		( pc_4_IF      		),
           .predict_IF          ( predict_IF        )
       );

    wire [4:0] reg_addr_debug = chk_addr[4: 0];

    ID u_ID(
           .clk                ( clk               ),
           .predict_IF         ( predict_IF        ),
           .predict_ID         ( predict_ID        ),
           .funct3_ID          ( funct3_ID         ),
           .flush_ID           ( flush_ID | ~rstn  ),
           .stall_ID           ( stall_ID          ),
           .reg_addr_debug     ( reg_addr_debug    ),
           .reg_data_debug     ( reg_data_debug    ),
           .ctrl_reg_write_MEM ( ctrl_reg_write_MEM),
           .reg_wb_addr_MEM    ( reg_wb_addr_MEM   ),
           .reg_wb_data        ( reg_wb_data       ),
           .load_use_hazard    ( load_use_hazard   ),
           .pc_IF              ( pc_IF             ),
           .pc_4_IF            ( pc_4_IF           ),
           .ir_IF              ( ir_IF             ),
           .pc_ID              ( pc_ID             ),
           .pc_4_ID            ( pc_4_ID           ),
           .rs1_ID             ( rs1_ID            ),
           .rs2_ID             ( rs2_ID            ),
           .rd1_ID             ( rd1_ID            ),
           .rd2_ID             ( rd2_ID            ),
           .imm_ID             ( imm_ID            ),
           .reg_wb_addr_ID     ( reg_wb_addr_ID    ),
           .ctrl_branch_ID     ( ctrl_branch_ID    ),
           .ctrl_mem_r_ID      ( ctrl_mem_r_ID     ),
           .ctrl_mem_w_ID      ( ctrl_mem_w_ID     ),
           .ctrl_wb_reg_src_ID ( ctrl_wb_reg_src_ID),
           .ctrl_alu_op_ID     ( ctrl_alu_op_ID    ),
           .ctrl_jal_ID        ( ctrl_jal_ID       ),
           .ctrl_jalr_ID       ( ctrl_jalr_ID      ),
           .ctrl_alu_src1_ID   ( ctrl_alu_src1_ID  ),
           .ctrl_alu_src2_ID   ( ctrl_alu_src2_ID  ),
           .ctrl_reg_write_ID  ( ctrl_reg_write_ID )
       );

    EX u_EX(
           .clk                ( clk               ),
           .rstn               ( rstn              ),
           .stall_EX           ( stall_EX          ),
           .funct3_ID          ( funct3_ID         ),
           .predict_ID         ( predict_ID        ),
           .record_we          ( record_we         ),
           .record_data        ( record_data       ),
           .record_pc_result   ( record_pc_result  ),
           .ctrl_alu_op_ID     ( ctrl_alu_op_ID    ),
           .ctrl_alu_src1_ID   ( ctrl_alu_src1_ID  ),
           .ctrl_alu_src2_ID   ( ctrl_alu_src2_ID  ),
           .ctrl_jal_ID        ( ctrl_jal_ID       ),
           .ctrl_jalr_ID       ( ctrl_jalr_ID      ),
           .ctrl_branch_ID     ( ctrl_branch_ID    ),
           .imm_ID             ( imm_ID            ),
           .rs1_ID             ( rs1_ID            ),
           .rd1_ID             ( rd1_ID            ),
           .pc_ID              ( pc_ID             ),
           .pc_4_ID            ( pc_4_ID           ),
           .rs2_ID             ( rs2_ID            ),
           .rd2_ID             ( rd2_ID            ),
           .ctrl_reg_write_ID  ( ctrl_reg_write_ID ),
           .reg_wb_addr_ID     ( reg_wb_addr_ID    ),
           .reg_wb_addr_EX     ( reg_wb_addr_EX    ),
           .ctrl_wb_reg_src_ID ( ctrl_wb_reg_src_ID),
           .ctrl_mem_r_ID      ( ctrl_mem_r_ID     ),
           .ctrl_mem_w_ID      ( ctrl_mem_w_ID     ),
           .ctrl_reg_write_EX  ( ctrl_reg_write_EX ),
           .ctrl_wb_reg_src_EX ( ctrl_wb_reg_src_EX),
           .ctrl_mem_r_EX      ( ctrl_mem_r_EX     ),
           .alu_out_EX         ( alu_out_EX        ),
           .pc_change_EX       ( pc_change_EX      ),
           .pc_nxt_EX          ( pc_nxt_EX         ),
           .rd2_EX             ( rd2_EX            ),
           .pc_4_EX            ( pc_4_EX           ),
           .ctrl_mem_w_EX      ( ctrl_mem_w_EX     ),
           .funct3_EX          ( funct3_EX         ),
           .ctrl_reg_write_MEM ( ctrl_reg_write_MEM),
           .reg_wb_addr_MEM    ( reg_wb_addr_MEM   ),
           .reg_wb_data        ( reg_wb_data       )
       );

    MEM u_MEM(
            .miss               ( miss              ),
            .mem_addr_debug     ( vga_addr          ),
            .io_din             ( io_din            ),
            .mem_data_debug     ( vga_data          ),
            .io_addr            ( io_addr           ),
            .io_dout            ( io_dout           ),
            .io_we              ( io_we             ),
            .io_rd              ( io_rd             ),
            .clk                ( clk               ),
            .rstn               ( rstn              ),
            .pc_4_EX            ( pc_4_EX           ),
            .alu_out_EX         ( alu_out_EX        ),
            .rd2_EX             ( rd2_EX            ),
            .ctrl_mem_r_EX      ( ctrl_mem_r_EX     ),
            .ctrl_mem_w_EX      ( ctrl_mem_w_EX     ),
            .funct3_EX          ( funct3_EX         ),
            .ctrl_reg_write_EX  ( ctrl_reg_write_EX ),
            .ctrl_wb_reg_src_EX ( ctrl_wb_reg_src_EX),
            .pc_4_MEM           ( pc_4_MEM          ),
            .alu_out_MEM        ( alu_out_MEM       ),
            .mdr_MEM            ( mdr_MEM           ),
            .reg_wb_addr_EX     ( reg_wb_addr_EX    ),
            .ctrl_reg_write_MEM ( ctrl_reg_write_MEM),
            .reg_wb_addr_MEM    ( reg_wb_addr_MEM   ),
            .ctrl_wb_reg_src_MEM( ctrl_wb_reg_src_MEM)
        );

    WB u_WB(
           .pc_4_MEM           ( pc_4_MEM          ),
           .alu_out_MEM        ( alu_out_MEM       ),
           .mdr_MEM            ( mdr_MEM           ),
           .ctrl_wb_reg_src_MEM( ctrl_wb_reg_src_MEM),
           .reg_wb_data        ( reg_wb_data       )
       );

    reg [31:0] debug_data;
    assign chk_data = debug_data;
    always @(*) begin
        if
        (chk_addr[15:12] == 1) begin        // 查看寄存器值
            debug_data = reg_data_debug;
        end
        else begin
            debug_data = 0;
        end
    end

endmodule
