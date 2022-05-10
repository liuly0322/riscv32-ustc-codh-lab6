module  cpu (
        input clk,
        input rstn,

        // IO_BUS
        output [7:0]  io_addr,	// 外设地址
        output [31:0]  io_dout,	// 向外设输出的数据
        output  io_we,		    // 向外设输出数据时的写使能信号
        output  io_rd,		    // 从外设输入数据时的读使能信号
        input [31:0]  io_din,	    // 来自外设输入的数据

        // Debug_BUS
        output [31:0] pc,      	// 当前执行指令地址
        input [15:0] chk_addr,	// 数据通路状态的编码地址
        output [31:0] chk_data  // 数据通路状态的数据
    );

    // 变量命名约定：对于段间寄存器，统一取前一段作为命名后缀
    // 对于段内寄存器，取所在段作为命名后缀

    // if 段
    wire          stall_IF;             // if 段停顿，目前是由于 load-use hazard
    wire [31:0]	  pc_IF;                // if/id 段的 pc，可以认为是正在执行的指令
    wire [31:0]	  ir_IF;                // if/id 段正在执行的指令
    wire [31:0]	  pc_4_IF;              // if/id 段正在执行的指令 pc + 4

    // id 段
    wire          flush_ID;             // 清空 id，目前是由于 load-use hazard 或者 pc 变动（与预测的 pc 不符）
    wire [31: 0]  reg_data_debug;       // pdu 使用的读寄存器
    wire [31: 0]  pc_ID;                // id/mem 段 pc
    wire [31: 0]  pc_4_ID;              // id/mem 段 pc+4
    wire          predict;              // id 段，如果正在执行的指令是分支指令，预测是否跳转
    wire [31: 0]  pc_nxt;               // id 段，结合 predict 和 pc_4_IF 得出下一条发射的 pc，交给 if
    wire          predict_ID;           // id/mem 段 predict
    wire [31: 0]  rd1_ID;               // id/mem 段 rd1，已经过 forward 处理
    wire [31: 0]  rd2_ID;               // id/mem 段 rd2，已经过 forward 处理
    wire [31: 0]  imm_ID;               // id/mem 段 imm
    wire [2: 0]   ctrl_branch_ID;
    wire          ctrl_mem_r_ID;
    wire          ctrl_mem_w_ID;
    wire [1:0]    ctrl_wb_reg_src_ID;
    wire [4: 0]   reg_wb_addr_ID;
    wire [3:0]    ctrl_alu_op_ID;
    wire          ctrl_jalr_ID;
    wire          ctrl_alu_src1_ID;
    wire          ctrl_alu_src2_ID;
    wire          ctrl_reg_write_ID;
    wire          load_use_hazard;      // 检测当前指令是否与前一条 ld 指令产生相关，如果是，stall if 并 flush id

    // ex 段
    wire          ctrl_reg_write_EX;
    wire [1: 0]   ctrl_wb_reg_src_EX;
    wire [4: 0]   reg_wb_addr_EX;
    wire          ctrl_mem_r_EX;
    wire [31: 0]  alu_out;              // 直接连接 alu 输出（forward 用）
    wire [31: 0]  alu_out_EX;
    wire          pc_change_EX;         // pc 是否需要更改（预测失败或者 jalr）
    wire [31: 0]  pc_nxt_EX;            // 更改后的 pc
    wire          record_we;            // 是否记录分支历史，即当前 ex 段是否是分支指令
    wire [4: 0]   record_pc;            // 记录的 pc[6:2]
    wire          record_data;          // 当前分支指令是否跳转
    wire [31: 0]  rd2_EX;
    wire [31: 0]  pc_4_EX;
    wire          ctrl_mem_w_EX;

    // mem 段
    wire [31: 0]  mem_data_debug;
    wire [31: 0]  pc_4_MEM;
    wire [31: 0]  alu_out_MEM;
    wire [31: 0]  mdr;                  // 直接连接内存读出数据端口（forward 用）
    wire [31: 0]  mdr_MEM;
    wire [1: 0]   ctrl_wb_reg_src_MEM;
    wire [4: 0]   reg_wb_addr_MEM;

    // wb 段（写回 id 段，这里都是 mem/wb 的段间寄存器）
    wire          reg_wb_en;
    wire [31: 0]  reg_wb_data;

    branch_predict u_branch_predict(
                       .clk           		( clk           		),
                       .record_chk_pc 		( pc_IF[6:2]     		),
                       .record_we     		( record_we     		),
                       .record_pc     		( record_pc     		),
                       .record_data   		( record_data   		),
                       .predict       		( predict       		)
                   );


    hazard u_hazard(
               .rstn               ( rstn              ),
               .load_use_hazard    ( load_use_hazard   ),
               .pc_change_EX       ( pc_change_EX      ),
               .stall_IF           ( stall_IF          ),
               .flush_ID           ( flush_ID          )
           );

    IF u_IF(
           .clk          		( clk          		),
           .stall_IF           ( stall_IF          ),
           .pc_nxt             ( pc_nxt            ),
           .pc_nxt_EX    		( pc_nxt_EX    		),
           .pc_change_EX 		( pc_change_EX 		),
           .ir_IF        		( ir_IF        		),
           .pc_IF        		( pc_IF        		),
           .pc_4_IF      		( pc_4_IF      		)
       );

    wire [4:0] reg_addr_debug = chk_addr[4: 0];

    ID u_ID(
           .clk                ( clk               ),
           .predict            ( predict           ),
           .predict_ID         ( predict_ID        ),
           .pc_nxt             ( pc_nxt            ),
           .flush_ID           ( flush_ID          ),
           .ctrl_reg_write_EX  ( ctrl_reg_write_EX ),
           .ctrl_wb_reg_src_EX ( ctrl_wb_reg_src_EX),
           .alu_out_EX         ( alu_out_EX        ),
           .pc_4_EX            ( pc_4_EX           ),
           .reg_wb_addr_EX     ( reg_wb_addr_EX    ),
           .reg_addr_debug     ( reg_addr_debug    ),
           .reg_data_debug     ( reg_data_debug    ),
           .reg_wb_en          ( reg_wb_en         ),
           .reg_wb_addr_MEM    ( reg_wb_addr_MEM   ),
           .reg_wb_data        ( reg_wb_data       ),
           .alu_out            ( alu_out           ),
           .load_use_hazard    ( load_use_hazard   ),
           .mdr                ( mdr               ),
           .pc_IF              ( pc_IF             ),
           .pc_4_IF            ( pc_4_IF           ),
           .ir_IF              ( ir_IF             ),
           .pc_ID              ( pc_ID             ),
           .pc_4_ID            ( pc_4_ID           ),
           .rd1_ID             ( rd1_ID            ),
           .rd2_ID             ( rd2_ID            ),
           .imm_ID             ( imm_ID            ),
           .reg_wb_addr_ID     ( reg_wb_addr_ID    ),
           .ctrl_branch_ID     ( ctrl_branch_ID    ),
           .ctrl_mem_r_ID      ( ctrl_mem_r_ID     ),
           .ctrl_mem_w_ID      ( ctrl_mem_w_ID     ),
           .ctrl_wb_reg_src_ID ( ctrl_wb_reg_src_ID),
           .ctrl_alu_op_ID     ( ctrl_alu_op_ID    ),
           .ctrl_jalr_ID       ( ctrl_jalr_ID      ),
           .ctrl_alu_src1_ID   ( ctrl_alu_src1_ID  ),
           .ctrl_alu_src2_ID   ( ctrl_alu_src2_ID  ),
           .ctrl_reg_write_ID  ( ctrl_reg_write_ID )
       );

    EX u_EX(
           .clk                ( clk               ),
           .predict_ID         ( predict_ID        ),
           .record_we          ( record_we         ),
           .record_pc          ( record_pc         ),
           .record_data        ( record_data       ),
           .alu_out            ( alu_out           ),
           .ctrl_alu_op_ID     ( ctrl_alu_op_ID    ),
           .ctrl_alu_src1_ID   ( ctrl_alu_src1_ID  ),
           .ctrl_alu_src2_ID   ( ctrl_alu_src2_ID  ),
           .ctrl_jalr_ID       ( ctrl_jalr_ID      ),
           .ctrl_branch_ID     ( ctrl_branch_ID    ),
           .imm_ID             ( imm_ID            ),
           .rd1_ID             ( rd1_ID            ),
           .pc_ID              ( pc_ID             ),
           .pc_4_ID            ( pc_4_ID           ),
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
           .ctrl_mem_w_EX      ( ctrl_mem_w_EX     )
       );

    wire [9: 0] mem_addr_debug = chk_addr[9:0];

    MEM u_MEM(
            .mem_addr_debug     ( mem_addr_debug    ),
            .io_din             ( io_din            ),
            .mem_data_debug     ( mem_data_debug    ),
            .io_addr            ( io_addr           ),
            .io_dout            ( io_dout           ),
            .io_we              ( io_we             ),
            .io_rd              ( io_rd             ),
            .clk                ( clk               ),
            .pc_4_EX            ( pc_4_EX           ),
            .alu_out_EX         ( alu_out_EX        ),
            .rd2_EX             ( rd2_EX            ),
            .ctrl_mem_r_EX      ( ctrl_mem_r_EX     ),
            .ctrl_mem_w_EX      ( ctrl_mem_w_EX     ),
            .ctrl_reg_write_EX  ( ctrl_reg_write_EX ),
            .ctrl_wb_reg_src_EX ( ctrl_wb_reg_src_EX),
            .pc_4_MEM           ( pc_4_MEM          ),
            .alu_out_MEM        ( alu_out_MEM       ),
            .mdr                ( mdr               ),
            .mdr_MEM            ( mdr_MEM           ),
            .reg_wb_addr_EX     ( reg_wb_addr_EX    ),
            .reg_wb_en          ( reg_wb_en         ),
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
    assign pc       = pc_4_IF;
    always @(*) begin
        if (chk_addr[15:12] == 1) begin        // 查看寄存器值
            debug_data = reg_data_debug;
        end
        else if (chk_addr[15:12] == 2) begin   // 数据主存
            debug_data = mem_data_debug;
        end
        else begin                             // 查看 pcs
            case (chk_addr[3:0])
                4'h1:
                    debug_data = pc_IF;
                4'h2:
                    debug_data = pc_ID;
                4'h3:
                    debug_data = ir_IF;
                4'h4:
                    debug_data = {12'h0, ctrl_alu_op_ID, ctrl_alu_src1_ID, ctrl_alu_src2_ID,
                                  ctrl_branch_ID, ctrl_jalr_ID, ctrl_mem_r_EX, ctrl_mem_w_EX,
                                  ctrl_reg_write_EX, ctrl_reg_write_ID, ctrl_wb_reg_src_EX,
                                  ctrl_wb_reg_src_ID, ctrl_wb_reg_src_MEM};
                4'h5:
                    debug_data = pc_4_EX;
                4'h6:
                    debug_data = alu_out_EX;
                4'h7:
                    debug_data = rd2_EX;
                4'h8:
                    debug_data = imm_ID;
                4'ha:
                    debug_data = alu_out_MEM;
                4'hb:
                    debug_data = mdr_MEM;
                4'hc:
                    debug_data = {31'h0, reg_wb_en};
                4'hd:
                    debug_data = reg_wb_data;
                default:
                    debug_data = pc_nxt_EX;
            endcase
        end
    end

endmodule
