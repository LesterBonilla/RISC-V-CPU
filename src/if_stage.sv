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
    opcode_e     opcode_if;

    assign pc_plus4         = pc + 4;
    assign opcode_if        = opcode_e'(instruction[6:0]);
    assign pc_next          = (pc_src == PC_SRC_PC_PLUS4) ? pc_plus4 : pc_target;

    always_comb begin : if_id_reg_input
        if_id               = '0;

        if_id.valid         = 1'b1;
        if_id.pc            = pc;
        if_id.instruction   = instruction;
        if_id.pc_plus4      = pc_plus4;
    end
    
endmodule