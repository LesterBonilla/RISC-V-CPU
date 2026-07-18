import decode_pkg::*;
import pipeline_pkg::*;

module wb_stage (
    input mem_wb_reg_t  mem_wb,

    output logic        reg_write,
    output logic [4:0]  rd_addr,
    output logic [31:0] wb_result,

    // Zicsr Extension
    input  logic [31:0] csr_read_data,
    output logic [31:0] csr_write_data,
    output logic [11:0] csr_addr,
    output csr_op_e     csr_op,
    output logic        inst_ret
);

    opcode_e opcode_wb;

    assign opcode_wb        = mem_wb.opcode;
    assign reg_write        = mem_wb.valid && mem_wb.reg_write;
    assign rd_addr          = mem_wb.rd_addr;

    // Zicsr Extension
    assign csr_write_data   = mem_wb.csr_data;
    assign csr_addr         = mem_wb.csr_addr;
    assign csr_op           = mem_wb.csr_op;

    always_comb begin
        wb_result = '0;

        unique case (mem_wb.wb_src) 
            WB_SRC_ALU:         wb_result = mem_wb.alu_result;
            WB_SRC_MEM:         wb_result = mem_wb.mem_data;
            WB_SRC_PC_PLUS4:    wb_result = mem_wb.pc_plus4;
            WB_SRC_CSR:         wb_result = csr_read_data;
            default: ;
        endcase
    end
    
endmodule