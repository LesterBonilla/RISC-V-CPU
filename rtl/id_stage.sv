import decode_pkg::*;
import pipeline_pkg::*;

module id_stage (
    input   if_id_reg_t     if_id,

    input   logic [31:0]    reg_data_1,
    input   logic [31:0]    reg_data_2,

    output  id_ex_reg_t     id_ex
); 

    opcode_e opcode     = opcode_t'(if_id.instruction[6:0]);

    logic [4:0] rs1     = if_id.instruction[19:15];
    logic [4:0] rs2     = if_id.instruction[24:20];
    logic [4:0] rd      = if_id.instruction[11:7];
    logic [6:0] funct7  = if_id.instruction[31:25];
    logic [2:0] funct3  = if_id.instruction[14:12];

    logic [31:0] imm_I  = {{20{if_id.instruction[31]}}, if_id.instruction[31:20]};
    logic [31:0] imm_S  = {{20{if_id.instruction[31]}}, if_id.instruction[31:25], if_id.instruction[11:7]};
    logic [31:0] imm_U  = {if_id.instruction[31:12], {12{1'b0}}};
    logic [31:0] imm_B  = {{20{if_id.instruction[12]}}, if_id.instruction[7], if_id.instruction[30:25], if_id.instruction[11:8], 1'b0}
    logic [31:0] imm_J  = {{12{if_id.instruction[31]}, if_id.instruction[19:12]}, if_id.instruction[20], if_id.instruction[30:25], if_id.instruction[24:21], 1'b0};


    always_comb begin

        // Default value to prevent latches
        id_ex = '0;

        // Values that aren't used this stage
        id_ex.valid         = if_id.valid;
        id_ex.pc            = if_id.pc;
        id_ex.pc_plus4      = if_id.pc_plus;

        // Pass these along independent of instruction
        id_ex.rs1           = rs1;
        id_ex.rs2           = rs2;
        id_ex.rd            = rd;
        id_ex.reg_data_1    = reg_data_1;
        id_ex.reg_data_2    = reg_data_2;

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
            // Ex stage
                id_ex.alu_op    = alu_op_e'({funct7[5], funct3});
                id_ex.alu_src_a = ALU_SRC_A_REG;
                id_ex.alu_src_b = ALU_SRC_B_REG;

            // WB stage
                id_ex.wb_src    = WB_SRC_ALU;
                id_ex.reg_write = 1'b1;

            OP_REG_IMM:
            // Ex stage:
                // Set ALU op
                // Set ALU sources to rs1 and immediate
                // Set immediate_out to imm_S
                // Consider shift amount:
                // Shift amount is encoded in imm_S and 0 extended. The ALU can extract the shift amount from this value.
            // Mem access:
                // No write
            // Write back
                // Reg write true
                // RegDest = Rd
                // Write back source is ALU result
            // EX Stage
                if (funct3 == ALU_SLL || funct3 == ALU_SRL) begin
                    id_ex.alu_op = alu_op_e'({funct7[5], funct3});
                end else begin
                    id_ex.alu_op = alu_op_e'({1'b0, funct3});
                end
    
                id_ex.alu_src_a     = ALU_SRC_A_REG;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;
                id_ex.imm_extended  = imm_I;
            
            // WB Stage
                id_ex.wb_src        = WB_SRC_ALU;
                id_ex.reg_write     = 1'b1;


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
                id_ex.alu_src_a     = ALU_SRC_A_ZERO;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;
                id_ex.imm_extended  = imm_U;
                id_ex.alu_op        = ALU_ADD;

                id_ex.wb_src        = WB_SRC_ALU;
                id_ex.reg_write     = 1'b1;

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
                id_ex.alu_src_a     = ALU_SRC_A_PC;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;
                id_ex.imm_extended  = imm_U;
                id_ex.alu_op        = ALU_ADD;

                id_ex.reg_write     = 1'b1;
                id_ex.wb_src        = WB_SRC_ALU;

            OP_JAL:
            // Ex stage:
                // Jump is true
                // ALU does nothing
                // PC source is set to target pc (by ex stage)
                // Hazard unit flushes previous stages
            // Mem stage:
                // Nothing
            // WB stage:
                // RegDest = Rd
                // Reg write true
                // Write back source is PC_PLUS4
                id_ex.imm_extended  = imm_J;

                id_ex.jump          = 1'b1;
                id_ex.pc_target_src = TARGET_SRC_PC;

                id_ex.reg_write     = 1'b1;
                id_ex.wb_src        = WB_SRC_PC_PLUS4; 
                

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
                id_ex.imm_extended  = imm_B;

                id_ex.branch        = 1'b1;
                id_ex.alu_src_a     = ALU_SRC_A_REG;
                id_ex.alu_src_b     = ALU_SRC_B_REG;
                id_ex.alu_op        = ALU_SUB;
                id_ex.branch_op     = branch_op_e'(funct3);
                id_ex.pc_target_src = TARGET_SRC_PC;

            OP_JALR:
            // Ex stage:
                // Use PC target adder
                // ALU does nothing
                // PC target adder source set to rs1 (post-forward value)
                // PC source is set to target pc
                // Hazard unit flushes previous stages
                // Imm source is imm_J
            // Mem stage:
                // Nothing
            // WB stage:
                // RegDest = Rd
                // Reg write true
                // Write back source is PC_PLUS4
                id_ex.imm_extended  = imm_I;

                id_ex.pc_target_src = TARGET_SRC_RS1;

                id_ex.reg_write     = 1'b1;
                id_ex.wb_src        = WB_SRC_PC_PLUS4;

            OP_LOAD:
            // Ex stage:
                // ALU op is add
                // ALU source A = rs1
                // ALU source B = immediate
                // Load op is set based on funct3
                // IMM source is imm_I
            // Mem stage:
                // Sign extend output of data memory based on load type
            // WB stage:
                // RegDest = Rd
                // Reg write true
                // Write back source is data memory
                id_ex.imm_extended  = imm_I;

                id_ex.alu_op        = ALU_ADD;
                id_ex.alu_src_a     = ALU_SRC_A_REG;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;
                
                id_ex.load_op       = load_op_e'(funct3);

                id_ex.reg_write     = 1'b1;
                id_ex.wb_src        = WB_SRC_MEM;

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
                id_ex.imm_extended  = imm_S;

                id_ex.alu_op        = ALU_ADD;
                id_ex.alu_src_a     = ALU_SRC_A_REG;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;

                id_ex.mem_write     = 1'b1;
                id_ex.store_op      = store_op_e'(funct3[1:0]);

            

            default: ;
        endcase
    end


endmodule