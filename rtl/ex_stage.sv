import decode_pkg::*;
import pipeline_pkg::*;

module ex_stage (
    input id_ex_reg_t   id_ex,

    output logic [31:0] pc_target,
    output pc_src_e     pc_src,
    output ex_mem_reg_t ex_mem
);

    logic [31:0]    alu_result;
    logic [31:0]    alu_a;
    logic [31:0]    alu_b;
    logic [31:0]    rs1_data, rs2_data;

    logic equal;
    logic less_than;
    logic less_than_unsigned;
    logic branch_taken;

    assign pc_target = (id_ex.pc_target_src ? id_ex.pc : rs1_data) + id_ex.imm_extended;

    assign pc_src = (branch_taken || id_ex.jump) ? PC_SRC_TARGET : PC_SRC_PC_PLUS4;

    assign equal                = (alu_a == alu_b);
    assign less_than            = ($signed(alu_a) < $signed(alu_b));
    assign less_than_unsigned   = (alu_a < alu_b);

    always_comb begin : data_sources
        
        unique case (id_ex.alu_src_a)
            ALU_SRC_A_REG:  alu_a = rs1_data;
            ALU_SRC_A_ZERO: alu_a = 32'd0;
            ALU_SRC_A_PC:   alu_a = id_ex.pc;
            default: ;
        endcase

        unique case (id_ex.alu_src_b)
            ALU_SRC_B_REG:  alu_b = rs2_data;
            ALU_SRC_B_IMM:  alu_b = id_ex.imm_extended;
            default: ;
        endcase

        // Place forwarded values for rs1/rs2 data here

    end

    always_comb begin : basic_integer_alu
        alu_result = '0;

        unique case (id_ex.alu_op) 
            ALU_ADD:    alu_result = alu_a + alu_b;
            ALU_SLL:    alu_result = alu_a << alu_b[4:0];
            ALU_SLT:    alu_result = {31'd0, less_than};
            ALU_SLTU:   alu_result = {31'd0, less_than_unsigned};
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
            BEQ:    branch_taken = equal;
            BNE:    branch_taken = !equal;
            BLT:    branch_taken = less_than;
            BGE:    branch_taken = !less_than;
            BLTU:   branch_taken = less_than_unsigned;
            BEGU:   branch_taken = !less_than_unsigned;
            default: ;
        endcase
    end

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
        ex_mem.write_data   = id_ex.reg_data_2; // Will be changed when hazard control is introduced
        ex_mem.rd           = id_ex.rd;
        ex_mem.pc_plus4     = id_ex.pc_plus4;

        // Values calculated by EX stage
        ex_mem.alu_result   = alu_result;

    end
    
endmodule