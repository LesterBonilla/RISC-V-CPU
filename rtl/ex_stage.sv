import decode_pkg::*;
import pipeline_pkg::*;

module ex_stage (
    input id_ex_reg_t   id_ex,

    output pc_src_e     pc_src,
    output ex_mem_reg_t ex_mem
);

    logic [31:0] alu_result;
    logic [31:0] alu_src_a;
    logic [31:0] alu_src_b;

    always_comb begin : basic_integer_alu
        alu_result = '0;
        


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