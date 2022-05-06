module hazard(
           input rstn,
           input pc_branch_EX,
           input pc_jump_EX,
           input load_use_hazard,
           output stall_IF,
           output flush_ID
       );

assign stall_IF = load_use_hazard;
assign flush_ID = pc_branch_EX | pc_jump_EX | load_use_hazard;

endmodule
