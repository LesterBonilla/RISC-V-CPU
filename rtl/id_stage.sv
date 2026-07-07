import decode_pkg::*;

module id_stage (
    input logic [31:0] instruction,

    output logic [4:0] rs2,
    output logic [4:0] rs1,
    output logic [4:0] rd,
    output logic [31:0] imm_extended,

); 

    logic [6:0] funct7  = instruction[31:25];
    logic [2:0] funct3  = instruction[14:12];

    logic [31:0] imm_I  = {{20{instruction[31]}}, instruction[31:20]};
    logic [31:0] imm_S  = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    logic [31:0] imm_U  = {instruction[31:12], {12{1'b0}}};
    logic [31:0] imm_B  = {{20{instruction[12]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0}
    logic [31:0] imm_J  = {{12{instruction[31]}, instruction[19:12]}, instruction[20], instruction[30:25], instruction[24:21], 1'b0};

    opcode_e opcode;

    assign opcode = opcode_t'(instruction[6:0]);
    assign rs2 = instruction[24:20];
    assign rs1 = instruction[19:15];
    assign rd  = instruction[11:7];


    always_comb begin
        unique case (opcode)
            OP_REG_REG:   
            // Ex stage:
                // Set ALU op
                // Set ALU sources to rs1 and rs2
            // Mem access:
                // No write
            // Write back:
                // Reg write true
                // RegDest = Rd
                // Set write back source to ALU result

            OP_REG_IMM:
            // Ex stage:
                // Set ALU op
                // Set ALU sources to rs1 and immediate
                // Set immediate_out to imm_S
                // Consider shift amount
            // Mem access:
                // No write
            // Write back
                // Reg write true
                // RegDest = Rd
                // Write back source is ALU result

            OP_LUI:
            // Ex stage:
                // ALU source A = 0
                // ALU source B = immediate
            // Mem access:
                // Nothing
            // Write back:
                // RegDest = Rd
                // Reg write true
                // Write back source is ALU result


            default: ;
        endcase
    end


endmodule