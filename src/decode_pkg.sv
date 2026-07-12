package decode_pkg;

    typedef enum logic [6:0] { 
        OP_LUI      = 7'b0110111,
        OP_AUIPC    = 7'b0010111,
        OP_JAL      = 7'b1101111,
        OP_BRANCH   = 7'b1100011,
        OP_JALR     = 7'b1100111,
        OP_LOAD     = 7'b0000011,
        OP_REG_IMM  = 7'b0010011,
        OP_STORE    = 7'b0100011,
        OP_REG_REG  = 7'b0110011,
        OP_FENCE    = 7'b0001111,
        OP_SYSTEM   = 7'b1110011
    } opcode_e;

    // This matches with {funct7[5], funct3} to account for funct3 overlap between
    // ADD/SUB and SRL/SRA
    typedef enum logic [3:0] { 
        ALU_ADD     = 4'b0000, 
        ALU_SLL     = 4'b0001,
        ALU_SLT     = 4'b0010,
        ALU_SLTU    = 4'b0011,
        ALU_XOR     = 4'b0100,
        ALU_SRL     = 4'b0101, 
        ALU_OR      = 4'b0110,
        ALU_AND     = 4'b0111,
        ALU_SUB     = 4'b1000,
        ALU_SRA     = 4'b1101
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
        BEQ     = 3'b000,
        BNE     = 3'b001,
        BLT     = 3'b100,
        BGE     = 3'b101,
        BLTU    = 3'b110,
        BGEU    = 3'b111
    } branch_op_e;

    typedef enum logic { 
        TARGET_SRC_PC,
        TARGET_SRC_RS1
    } pc_target_src_e;

    typedef enum logic [2:0] { 
        LOAD_BYTE             = 3'b000,
        LOAD_HALF             = 3'b001,
        LOAD_WORD             = 3'b010,
        LOAD_BYTE_UNSIGNED    = 3'b100,
        LOAD_HALF_UNSIGNED    = 3'b101
    } load_op_e;

    typedef enum logic [1:0] { 
        STORE_BYTE          = 2'b00,
        STORE_HALF          = 2'b01, 
        STORE_WORD          = 2'b10
    } store_op_e;

endpackage