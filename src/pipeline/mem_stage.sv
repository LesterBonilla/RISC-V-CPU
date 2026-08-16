import decode_pkg::*;
import pipeline_pkg::*;

module mem_stage (
    input ex_mem_reg_t  ex_mem,

    input logic         redirect_wb,

    output logic        mem_write,
    output logic        mem_read,
    output logic [3:0]  byte_en,
    output logic [31:0] write_data,
    output logic [31:0] mem_address,
    output logic [31:0] alu_result,

    output mem_wb_reg_t mem_wb
);

    opcode_e opcode_mem;
    
    logic       exception, read_en;
    mcause_e    mcause;
    
    assign opcode_mem   = ex_mem.opcode;
    assign mem_write    = ex_mem.mem_write && ex_mem.valid && !ex_mem.exception && !redirect_wb && !exception;
    assign alu_result   = ex_mem.alu_result;
    assign mem_address  = ex_mem.alu_result;
    assign read_en      = (ex_mem.wb_src == WB_SRC_MEM) && (ex_mem.reg_write);
    assign mem_read     = read_en && ex_mem.valid && !ex_mem.exception && !redirect_wb && !exception;

//------------------------------------------------------------------------------
// Store Formatting
//------------------------------------------------------------------------------
    logic [3:0] byte_mask;

    assign byte_en      = byte_mask << alu_result[1:0];
    assign write_data   = ex_mem.write_data << (8 * ex_mem.alu_result[1:0]);

    always_comb begin : store_format
        unique case (ex_mem.store_op)
            STORE_BYTE: byte_mask = 4'b0001;
            STORE_HALF: byte_mask = 4'b0011;
            STORE_WORD: byte_mask = 4'b1111;
            default:    byte_mask = 4'b0000;
        endcase
    end

//------------------------------------------------------------------------------
// Exceptions
//------------------------------------------------------------------------------
    logic [1:0] misalign_mask;

    always_comb begin : calculate_misalign_mask
        misalign_mask = '0;

        if (ex_mem.mem_write)
            unique case (ex_mem.store_op)
                STORE_BYTE: misalign_mask = 2'b00;
                STORE_HALF: misalign_mask = 2'b01;
                STORE_WORD: misalign_mask = 2'b11;
                default:    misalign_mask = 2'b00;
            endcase
        else if (read_en)
            unique case (ex_mem.load_op)
                LOAD_BYTE, LOAD_BYTE_UNSIGNED:  misalign_mask = 2'b00;
                LOAD_HALF, LOAD_HALF_UNSIGNED:  misalign_mask = 2'b01;
                LOAD_WORD:                      misalign_mask = 2'b11;
                default:                        misalign_mask = 2'b00;
        endcase
    end

    always_comb begin : exception_detection
        logic misaligned;

        exception   = ex_mem.exception;
        mcause      = ex_mem.mcause;
        misaligned  = |(ex_mem.alu_result[1:0] & misalign_mask);

        if (!ex_mem.exception && (ex_mem.mem_write || read_en) && misaligned) begin
            exception   = 1'b1;
            mcause      = ex_mem.mem_write ? EXCEPTION_STORE_AMO_ADDR_MISALIGNED
                                           : EXCEPTION_LOAD_ADDR_MISALIGNED;
        end
    end

//------------------------------------------------------------------------------
// Output to writeback stage
//------------------------------------------------------------------------------
    always_comb begin : mem_wb_reg_input
        mem_wb = '0;

        // Exceptions
        mem_wb.exception    = exception;
        mem_wb.mcause       = mcause;
        mem_wb.pc           = ex_mem.pc;
        mem_wb.mret         = ex_mem.mret;

        mem_wb.valid        = ex_mem.valid;
        mem_wb.reg_write    = ex_mem.reg_write;
        mem_wb.wb_src       = ex_mem.wb_src;
        mem_wb.alu_result   = ex_mem.alu_result;
        mem_wb.pc_plus4     = ex_mem.pc_plus4;
        mem_wb.rd_addr      = ex_mem.rd_addr;
        mem_wb.opcode       = ex_mem.opcode;
        mem_wb.load_op      = ex_mem.load_op;

        // Zicsr Extension
        mem_wb.csr_op       = ex_mem.csr_op;
        mem_wb.csr_data     = ex_mem.csr_data;
        mem_wb.csr_addr     = ex_mem.csr_addr;
    end
    
endmodule