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

    // Control Signals
    alu_op_e alu_op;
    alu_src_a_e alu_src_a;
    alu_src_b_e alu_src_b;
    wb_src_e wb_src;
    branch_op_e branch_op;
    target_adder_src_e target_adder_src;
    load_op_e load_op;
    store_op_e store_op;
    imm_src_e imm_src;

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
                // ALU OP = Addition
            // Mem access:
                // Nothing
            // Write back:
                // RegDest = Rd
                // Reg write true
                // Write back source is ALU result

            OP_AUIPC:
            // Ex stage:
                // ALU source A = PC
                // ALU source B = immediate
                // ALU OP = Addition
            // Mem stage:
                // Nothing
            // Write back:
                // RegDest = Rd
                // Reg write true
                // Write back source is ALU result

            OP_JAL:
            // Ex stage:
                // Jump is true
                // ALU does nothing
                // PC source is set to target pc
                // Hazard unit flushes previous stages
            // Mem stage:
                // Nothing
            // WB stage:
                // RegDest = Rd
                // Reg write true
                // Write back source is PC_PLUS4

            OP_BRANCH:
            // Ex stage:
                // ALU source A = rs1
                // ALU source B = rs2
                // Branch is true
                // ALU OP = Subtraction
                // If taken, a signal from EX direct to IF selects PC
                // If taken, flushes previous stages
            // Mem stage:
                // Nothing
            // WB Stage:
                // Nothing

            OP_JALR:
            // Ex stage:
                // Use PC target adder
                // ALU does nothing
                // PC target adder source set to rs1 (post-forward value)
                // PC source is set to target pc
                // Hazard unit flushes previous stages
            // Mem stage:
                // Nothing
            // WB stage:
                // RegDest = Rd
                // Reg write true
                // Write back source is PC_PLUS4

            OP_LOAD:
            // Ex stage:
                // ALU op is add
                // ALU source A = rs1
                // ALU source B = immediate
                // Load op is set based on funct3
            // Mem stage:
                // Sign extend output of data memory based on load type
            // WB stage:
                // RegDest = Rd
                // Reg write true
                // Write back source is data memory

            OP_STORE:
            // Ex stage:
                // Write data comes from rs2 post-forward value
                // ALU OP is addition
                // ALU source A = rs1 (post forward)
                // ALU source B = immediate
                // Store op is set based on funct3 (write mask)
            // Mem stage:
                // MemWrite is true
                // Set write mask based on store op
            // WB stage:
                // Nothing

            

            default: ;
        endcase
    end


endmodule