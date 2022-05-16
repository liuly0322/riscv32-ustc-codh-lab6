module hazard(
        input rstn,
        input pc_change_EX,
        input load_use_hazard,
        output stall_IF,
        output flush_ID
    );

    assign stall_IF = rstn & load_use_hazard;
    assign flush_ID = rstn & (pc_change_EX | load_use_hazard);

endmodule
