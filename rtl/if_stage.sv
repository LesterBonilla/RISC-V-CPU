import decode_pkg::*;
import pipeline_pkg::*;

module if_stage (
    input logic [31:0]  pc,
    input logic [31:0]  pc_target,
    input logic [31:0]  instruction,
    input pc_src_e      pc_src,

    output logic [31:0] pc_next,
    output if_id_reg_t  if_id
);

    logic [31:0] pc_plus4;

    assign pc_plus4 = pc + 4;

    always_comb begin : pc_next_mux

        pc_next = '0;

        unique case (pc_src)
            PC_SRC_PC_PLUS4:    pc_next = pc_plus4;
            PC_SRC_TARGET:      pc_next = pc_target;
            default: ;
        endcase

    end

    always_comb begin : if_id_reg_input
        
        if_id       = '0;

        if_id.valid         = 1'b1;
        if_id.pc            = pc;
        if_id.instruction   = instruction;
        if_id.pc_plus4      = pc_plus4;

    end
    
endmodule