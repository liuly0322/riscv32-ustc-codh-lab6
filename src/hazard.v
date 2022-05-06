module hazard(
           input rstn,
           input pc_change_EX,
           input load_use_hazard,
           output stall_IF,
           output flush_ID
       );

assign stall_IF = load_use_hazard;
assign flush_ID = pc_change_EX | load_use_hazard;

endmodule
