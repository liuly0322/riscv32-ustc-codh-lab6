module hazard(
        input rstn,
        input pc_change_EX,
        input load_use_hazard,
        output stall_IF,
        output flush_IF,
        output flush_ID
    );

//     assign stall_IF = load_use_hazard;
//     assign flush_IF = rstn & pc_change_EX;
//     assign flush_ID = rstn & (pc_change_EX | load_use_hazard);
        assign stall_IF = 0;
        assign flush_IF = 0;
        assign flush_ID = 0;

endmodule
