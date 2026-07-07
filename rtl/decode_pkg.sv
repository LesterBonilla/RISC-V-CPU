package decode_pkg;

    typedef enum logic [6:0] { 
        OP_LUI      = 7'b0110111;
        OP_AUIPC    = 7'b0010111;
        OP_JAL      = 7'b1101111;
        OP_BRANCH   = 7'b1100011;
        OP_JALR     = 7'b1100111;
        OP_LOAD     = 7'b0000011;
        OP_REG_IMM  = 7'b0010011;
        OP_STORE    = 7'b0100011;
        OP_REG_REG  = 7'b0110011;
        OP_FENCE    = 7'b0001111;
        OP_E_OP     = 7'b1110011;

    } opcode_e;

    typedef enum logic [3:0] { 
        ALU_ADD,
        ALU_SUB,
        ALU_SLL,
        ALU_SLT,
        ALU_SLTU,
        ALU_XOR,
        ALU_SRL,
        ALU_SRA,
        ALU_OR,
        ALU_AND
    } alu_op_e;

    typedef enum logic [1:0] {
        ALU_SRC_A_REG,
        ALU_SRC_A_ZERO,
        ALU_SRC_A_PC
    } alu_src_a_e;

    typedef enum logic {
        ALU_SRC_B_REG,
        ALU_SRC_B_IMM
    } alu_src_b_e;

    typedef enum logic [1:0] { 
        WB_SRC_ALU,
        WB_SRC_PC_PLUS4,
        WB_SRC_MEM
    } wb_src_e;

    typedef enum logic { 
        PC_SRC_PC_PLUS4,
        PC_SRC_TARGET
    } pc_src_e;

    typedef enum logic [2:0] { 
        BEQ,
        BNE,
        BLT,
        BGE,
        BLTU,
        BGEU    
    } branch_op_e;

endpackage