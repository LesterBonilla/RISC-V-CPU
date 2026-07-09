import decode_pkg::*;
import pipeline_pkg::*;

module wb_stage (
    input mem_wb_reg_t  mem_wb,

    output logic        reg_write,
    output logic [4:0]  reg_write_addr,
    output logic [31:0] wb_result

);

    opcode_e opcode_wb;

    assign opcode_wb        = mem_wb.opcode;
    assign reg_write        = mem_wb.valid && mem_wb.reg_write;
    assign reg_write_addr   = mem_wb.rd;

    always_comb begin
        wb_result = '0;

        unique case (mem_wb.wb_src) 
            WB_SRC_ALU:         wb_result = mem_wb.alu_result;
            WB_SRC_MEM:         wb_result = mem_wb.mem_data;
            WB_SRC_PC_PLUS4:    wb_result = mem_wb.pc_plus4;
            default: ;
        endcase
    end
    
endmodule