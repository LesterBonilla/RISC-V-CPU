import decode_pkg::*;
import pipeline_pkg::*;

module id_stage (
    input   if_id_reg_t     if_id,

    input   logic [31:0]    reg_data_1,
    input   logic [31:0]    reg_data_2,

    output  id_ex_reg_t     id_ex
); 

    logic [6:0] funct7  = if_id.instruction[31:25];
    logic [2:0] funct3  = if_id.instruction[14:12];

    logic [31:0] imm_I  = {{20{if_id.instruction[31]}}, if_id.instruction[31:20]};
    logic [31:0] imm_S  = {{20{if_id.instruction[31]}}, if_id.instruction[31:25], if_id.instruction[11:7]};
    logic [31:0] imm_U  = {if_id.instruction[31:12], {12{1'b0}}};
    logic [31:0] imm_B  = {{20{if_id.instruction[12]}}, if_id.instruction[7], if_id.instruction[30:25], if_id.instruction[11:8], 1'b0}
    logic [31:0] imm_J  = {{12{if_id.instruction[31]}, if_id.instruction[19:12]}, if_id.instruction[20], if_id.instruction[30:25], if_id.instruction[24:21], 1'b0};

    opcode_e opcode     = opcode_t'(if_id.instruction[6:0]);

    assign rs2          = if_id.instruction[24:20];
    assign rs1          = if_id.instruction[19:15];
    assign rd           = if_id.instruction[11:7];


    always_comb begin

        // Default value to prevent latches
        id_ex = '0;

        // Values that aren't used this stage
        id_ex.valid     = if_id.valid;
        id_ex.pc        = if_id.pc;
        id_ex.pc_plus4  = if_id.pc_plus;


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