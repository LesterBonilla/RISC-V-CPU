import decode_pkg::*;
import pipeline_pkg::*;

module if_stage (
    input logic [31:0]  pc,
    input logic [31:0]  pc_target_ex,
    input logic [31:0]  instruction,
    input pc_src_e      pc_src_ex,

    input logic         redirect_wb,
    input logic [31:0]  pc_target_wb,

    output logic [31:0] pc_next,
    output if_id_reg_t  if_id
);

    logic [31:0]    pc_plus4; 
    opcode_e        opcode_if;
    logic           exception;
    mcause_e        mcause;

    assign pc_plus4     = pc + 4;
    assign opcode_if    = (exception) ? OP_EXCEPT : opcode_e'(instruction[6:0]);

    always_comb begin : pc_next_mux
        pc_next = '0;

        if (redirect_wb) pc_next = pc_target_wb;
        else if (pc_src_ex == PC_SRC_TARGET) pc_next = pc_target_ex;
        else pc_next = pc_plus4;
        
    end

    always_comb begin : detect_misalign
        exception   = 1'b0;
        mcause      = EXCEPTION_NONE;
        
        if (pc[1:0] != 2'b00) begin
            exception   = 1'b1;
            mcause      = EXCEPTION_INSTRUCTION_ADDR_MISALIGNED;
        end
    end

    always_comb begin : if_id_reg_input
        if_id               = '0;

        if_id.exception     = exception;
        if_id.mcause        = mcause;

        if_id.valid         = 1'b1;
        if_id.pc            = pc;
        if_id.instruction   = instruction;
        if_id.pc_plus4      = pc_plus4;
    end
    
endmodule