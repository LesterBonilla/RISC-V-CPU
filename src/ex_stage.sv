import decode_pkg::*;
import pipeline_pkg::*;

module ex_stage (
    input id_ex_reg_t   id_ex,
    input fwd_sel_e     fwd_sel_a,
    input fwd_sel_e     fwd_sel_b,
    input logic [31:0]  fwd_data_mem,
    input logic [31:0]  fwd_data_wb,

    output logic [31:0] pc_target,
    output pc_src_e     pc_src,
    output ex_mem_reg_t ex_mem
);

    opcode_e            opcode_ex;
    
    logic [31:0]        alu_result;
    logic [31:0]        alu_a;
    logic [31:0]        alu_b;
    logic [31:0]        rs1_data, rs2_data;
    
    logic               cmp_eq;
    logic               cmp_lt;
    logic               cmp_ltu;
    logic               branch_taken;
    
    assign opcode_ex    = id_ex.opcode;
    assign pc_src       = ((branch_taken && id_ex.branch) || id_ex.jump) ? PC_SRC_TARGET : PC_SRC_PC_PLUS4;

    assign cmp_eq       = (alu_a == alu_b);
    assign cmp_lt       = ($signed(alu_a) < $signed(alu_b));
    assign cmp_ltu      = (alu_a < alu_b);


    always_comb begin : pc_target_calc
        logic is_JALR;
        is_JALR     = (id_ex.pc_target_src == TARGET_SRC_RS1);
        pc_target   = '0;

        unique case (id_ex.pc_target_src)
            TARGET_SRC_PC:  pc_target = id_ex.pc + id_ex.imm_extended;
            TARGET_SRC_RS1: pc_target = rs1_data + id_ex.imm_extended;
            default: ;
        endcase

        if (is_JALR) 
            pc_target[0] = 1'b0;
    end


    always_comb begin : forward_mux
        rs1_data    = '0;
        rs2_data    = '0;

        unique case (fwd_sel_a) 
            FWD_NONE:   rs1_data = id_ex.rs1_data;
            FWD_MEM:    rs1_data = fwd_data_mem;
            FWD_WB:     rs1_data = fwd_data_wb;
            default:    rs1_data = 32'd0;
        endcase

        unique case (fwd_sel_b) 
            FWD_NONE:   rs2_data = id_ex.rs2_data;
            FWD_MEM:    rs2_data = fwd_data_mem;
            FWD_WB:     rs2_data = fwd_data_wb;
            default:    rs2_data = 32'd0;
        endcase
    end


    always_comb begin : alu_operand_mux
        alu_a       = '0;
        alu_b       = '0;
        
        unique case (id_ex.alu_src_a)
            ALU_SRC_A_REG:  alu_a = rs1_data;
            ALU_SRC_A_ZERO: alu_a = 32'd0;
            ALU_SRC_A_PC:   alu_a = id_ex.pc;
            default:        alu_a = 32'd0;
        endcase

        unique case (id_ex.alu_src_b)
            ALU_SRC_B_REG:  alu_b = rs2_data;
            ALU_SRC_B_IMM:  alu_b = id_ex.imm_extended;
            default:        alu_b = 32'd0;
        endcase
    end


    always_comb begin : basic_integer_alu
        alu_result = '0;

        unique case (id_ex.alu_op) 
            ALU_ADD:    alu_result = alu_a + alu_b;
            ALU_SLL:    alu_result = alu_a << alu_b[4:0];
            ALU_SLT:    alu_result = {31'd0, cmp_lt};
            ALU_SLTU:   alu_result = {31'd0, cmp_ltu};
            ALU_XOR:    alu_result = alu_a ^ alu_b;
            ALU_SRL:    alu_result = alu_a >> alu_b[4:0];
            ALU_OR:     alu_result = alu_a | alu_b;
            ALU_AND:    alu_result = alu_a & alu_b;
            ALU_SUB:    alu_result = alu_a - alu_b;
            ALU_SRA:    alu_result = $signed(alu_a) >>> alu_b[4:0];

            default: alu_result = 32'd0;
        endcase
    end


    always_comb begin : branch_resolve
        branch_taken = 1'b0;

        unique case (id_ex.branch_op)
            BEQ:    branch_taken = cmp_eq;
            BNE:    branch_taken = !cmp_eq;
            BLT:    branch_taken = cmp_lt;
            BGE:    branch_taken = !cmp_lt;
            BLTU:   branch_taken = cmp_ltu;
            BGEU:   branch_taken = !cmp_ltu;
            default: ;
        endcase
    end


//------------------------------------------------------------------------------
// Zicsr Extension
//------------------------------------------------------------------------------
    logic [31:0]        csr_data;
    logic               is_csr_imm;

    assign is_csr_imm   = id_ex.csr_op[2];
    assign csr_data     = (is_csr_imm) ? {{27{1'b0}}, id_ex.rs1_addr} : rs1_data;

    
    always_comb begin : ex_mem_reg_input
        // Prevent latches
        ex_mem = '0;

        // Values passed along
        ex_mem.valid        = id_ex.valid;
        ex_mem.reg_write    = id_ex.reg_write;
        ex_mem.mem_write    = id_ex.mem_write;
        ex_mem.wb_src       = id_ex.wb_src;
        ex_mem.load_op      = id_ex.load_op;
        ex_mem.store_op     = id_ex.store_op;
        ex_mem.rd_addr      = id_ex.rd_addr;
        ex_mem.pc_plus4     = id_ex.pc_plus4;
        ex_mem.opcode       = id_ex.opcode;
        
        // Values calculated by EX stage
        ex_mem.alu_result   = alu_result;
        ex_mem.write_data   = rs2_data;

        // Zicsr Extension
        ex_mem.csr_addr     = id_ex.imm_extended[11:0];
        ex_mem.csr_op       = id_ex.csr_op;
        ex_mem.csr_data     = csr_data;

    end
    
endmodule