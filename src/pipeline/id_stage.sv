import decode_pkg::*;
import pipeline_pkg::*;
import csr_pkg::*;

module id_stage (
    input   if_id_reg_t     if_id,

    input   logic [31:0]    instruction,
    input   logic [31:0]    rs1_data,
    input   logic [31:0]    rs2_data,

    output  logic [4:0]     rs1_addr,
    output  logic [4:0]     rs2_addr,
    output  id_ex_reg_t     id_ex
); 

    opcode_e        opcode;
    logic [4:0]     rd_addr;
    logic [6:0]     funct7;
    logic [2:0]     funct3;
    logic [11:0]    funct12;
    logic [31:0]    imm_I, imm_S, imm_U, imm_B, imm_J;
    logic           exception, is_shift;
    mcause_e        mcause;
    csr_op_e        csr_op;
    priv_op_e       priv_op;

    assign opcode   = (if_id.valid) ? opcode_e'(instruction[6:0]) : OP_BUBBLE;
    assign csr_op   = csr_op_e'(funct3);
    assign priv_op  = priv_op_e'(funct12);
    assign is_shift = (funct3 == 3'b001) || (funct3 == 3'b101);

    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr  = instruction[11:7];
    assign funct7   = instruction[31:25];
    assign funct3   = instruction[14:12];
    assign funct12  = instruction[31:20];

    assign imm_I    = {{20{instruction[31]}}, instruction[31:20]};
    assign imm_S    = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    assign imm_U    = {instruction[31:12], {12{1'b0}}};
    assign imm_B    = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
    assign imm_J    = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:25], instruction[24:21], 1'b0};

    always_comb begin

        // Default value to prevent latches
        id_ex = '0;

        // Exceptions
        id_ex.exception     = exception;
        id_ex.mcause        = mcause;

        // Values that aren't used this stage
        id_ex.valid         = if_id.valid;
        id_ex.pc            = if_id.pc;
        id_ex.pc_plus4      = if_id.pc_plus4;

        // Pass these along independent of instruction
        id_ex.rs1_addr      = rs1_addr;
        id_ex.rs2_addr      = rs2_addr;
        id_ex.rd_addr       = rd_addr;
        id_ex.rs1_data      = rs1_data;
        id_ex.rs2_data      = rs2_data;
        id_ex.opcode        = opcode;

        unique case (opcode)
            OP_REG_REG: begin
                id_ex.alu_op        = alu_op_e'({funct7[5], funct3});
                id_ex.alu_src_a     = ALU_SRC_A_REG;
                id_ex.alu_src_b     = ALU_SRC_B_REG;

                id_ex.wb_src        = WB_SRC_ALU;
                id_ex.reg_write     = 1'b1;
            end

            OP_REG_IMM: begin
                id_ex.alu_op        = alu_op_e'({is_shift ? funct7[5] : 1'b0, funct3});
                id_ex.imm_extended  = imm_I;
                id_ex.alu_src_a     = ALU_SRC_A_REG;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;
            
                id_ex.wb_src        = WB_SRC_ALU;
                id_ex.reg_write     = 1'b1;
            end

            OP_LUI: begin
                id_ex.alu_src_a     = ALU_SRC_A_ZERO;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;
                id_ex.imm_extended  = imm_U;
                id_ex.alu_op        = ALU_ADD;

                id_ex.wb_src        = WB_SRC_ALU;
                id_ex.reg_write     = 1'b1;
            end

            OP_AUIPC: begin
                id_ex.alu_src_a     = ALU_SRC_A_PC;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;
                id_ex.imm_extended  = imm_U;
                id_ex.alu_op        = ALU_ADD;

                id_ex.reg_write     = 1'b1;
                id_ex.wb_src        = WB_SRC_ALU;
            end

            OP_JAL: begin
                id_ex.imm_extended  = imm_J;

                id_ex.jump          = 1'b1;
                id_ex.pc_target_src = TARGET_SRC_PC;

                id_ex.reg_write     = 1'b1;
                id_ex.wb_src        = WB_SRC_PC_PLUS4; 
            end

            OP_BRANCH: begin
                id_ex.imm_extended  = imm_B;

                id_ex.branch        = 1'b1;
                id_ex.alu_src_a     = ALU_SRC_A_REG;
                id_ex.alu_src_b     = ALU_SRC_B_REG;
                id_ex.alu_op        = ALU_SUB;
                id_ex.branch_op     = branch_op_e'(funct3);
                id_ex.pc_target_src = TARGET_SRC_PC;
            end

            OP_JALR: begin
                id_ex.imm_extended  = imm_I;

                id_ex.jump          = 1'b1;
                id_ex.pc_target_src = TARGET_SRC_RS1;

                id_ex.reg_write     = 1'b1;
                id_ex.wb_src        = WB_SRC_PC_PLUS4;
            end

            OP_LOAD: begin
                id_ex.imm_extended  = imm_I;

                id_ex.alu_op        = ALU_ADD;
                id_ex.alu_src_a     = ALU_SRC_A_REG;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;
                
                id_ex.load_op       = load_op_e'(funct3);

                id_ex.reg_write     = 1'b1;
                id_ex.wb_src        = WB_SRC_MEM;
            end

            OP_STORE: begin
                id_ex.imm_extended  = imm_S;

                id_ex.alu_op        = ALU_ADD;
                id_ex.alu_src_a     = ALU_SRC_A_REG;
                id_ex.alu_src_b     = ALU_SRC_B_IMM;

                id_ex.mem_write     = 1'b1;
                id_ex.store_op      = store_op_e'(funct3[1:0]);
            end

            OP_SYSTEM: begin
                if (csr_op != CSR_NOP) begin
                    id_ex.reg_write     = 1'b1;
                    id_ex.wb_src        = WB_SRC_CSR;
                    id_ex.csr_op        = csr_op;
                    id_ex.imm_extended  = imm_I;
                
                end else if (priv_op == SYSTEM_MRET) begin
                    id_ex.mret          = 1'b1;
                end
            end

            OP_FENCE: ; // Treated as NOP

            default: ;
        endcase // Opcode control signals
    end // always_comb 

//------------------------------------------------------------------------------
// Exception Detection
//------------------------------------------------------------------------------
    always_comb begin
        exception   = if_id.exception;
        mcause      = if_id.mcause;

        if (!exception && id_ex.valid) begin
            unique case (opcode)
                OP_SYSTEM: begin
                    if (csr_op == CSR_NOP) begin
                        unique case (priv_op)
                            SYSTEM_ECALL:   begin 
                                exception = 1'b1;
                                mcause    = EXCEPTION_ENV_CALL_FROM_M;
                            end

                            SYSTEM_EBREAK:  begin 
                                exception = 1'b1;
                                mcause    = EXCEPTION_BREAKPOINT;
                            end

                            SYSTEM_MRET:    ; // May except if S-mode is supported 
                            SYSTEM_WFI:     ; // Currently implemented as NOP

                            default: begin
                                exception = 1'b1;
                                mcause    = EXCEPTION_ILLEGAL_INSTRUCTION;
                            end
                        endcase
                    end 
                    else begin // Illegal CSR
                        logic seed;
                        seed = (funct12 == 12'h015);
                        
                        if (seed) begin
                            exception = 1'b1;
                            mcause    = EXCEPTION_ILLEGAL_INSTRUCTION;
                        end
                    end
                end

                // Currently no exceptions for these opcodes
                OP_LUI, OP_AUIPC, OP_JAL, OP_JALR, OP_BRANCH, OP_LOAD, OP_REG_IMM, OP_STORE, OP_REG_REG, OP_FENCE: ;

                default: begin
                    exception = 1'b1;
                    mcause    = EXCEPTION_ILLEGAL_INSTRUCTION;
                end

            endcase // Instruction exception detection
        end // If !exception && id_ex.valid
    end // always_comb exceptions

endmodule