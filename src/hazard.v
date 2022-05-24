module hazard(
        input rstn,
        input miss,
        input pc_change_EX,
        input load_use_hazard,
        output stall_IF,
        output stall_ID,
        output stall_EX,
        output flush_IF,
        output flush_ID
    );

    assign stall_IF = load_use_hazard | miss;
    assign stall_ID = miss;
    assign stall_EX = miss;
    assign flush_IF = rstn & pc_change_EX;
    assign flush_ID = rstn & (pc_change_EX | load_use_hazard);

endmodule
