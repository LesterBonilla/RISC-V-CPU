import decode_pkg::*;
import pipeline_pkg::*;

module ex_stage (
    input id_ex_reg_t   id_ex,

    output pc_src_e     pc_src,
    output ex_mem_reg_t ex_mem
);

    logic [31:0]    alu_result;
    logic [31:0]    alu_a;
    logic [31:0]    alu_b;

    // TODO: Branch flags
    logic           zero_flag;
    logic           overflow_flag;

    always_comb begin : basic_integer_alu
        alu_result = '0;

        unique case (id_ex.alu_op) 
            ALU_ADD:
                alu_result = alu_a + alu_b;

            ALU_SLL:
                alu_result = alu_a << alu_b[4:0];

            ALU_SLT:
                alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'd1 : 32'd0;
            
            ALU_SLTU:
                alu_result = (alu_a < alu_b) ? 32'd1 : 32'd0;

            ALU_XOR:
                alu_result = alu_a ^ alu_b;

            ALU_SRL:
                alu_result = alu_a >> alu_b[4:0];

            ALU_OR:
                alu_result = alu_a | alu_b;

            ALU_AND:
                alu_result = alu_a & alu_b;

            ALU_SUB:
                alu_result = alu_a - alu_b;
            
            ALU_SRA:
                alu_result = $signed(alu_a) >>> alu_b[4:0];
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