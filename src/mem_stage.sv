import decode_pkg::*;
import pipeline_pkg::*;

module mem_stage (
    input ex_mem_reg_t  ex_mem,
    input logic [31:0]  mem_data,

    input logic         redirect_wb,

    output logic        mem_write,
    output logic [3:0]  byte_en,
    output logic [31:0] write_data,
    output logic [31:0] mem_address,
    output logic [31:0] alu_result,

    output mem_wb_reg_t mem_wb
);

    opcode_e opcode_mem;
    
    logic       exception;
    mcause_e    mcause;
    
    assign opcode_mem   = ex_mem.opcode;
    assign mem_write    = ex_mem.mem_write && ex_mem.valid && !ex_mem.exception && !redirect_wb && !exception;
    assign alu_result   = ex_mem.alu_result;
    assign mem_address  = ex_mem.alu_result;

    logic [15:0] selected_half;
    logic [7:0]  selected_byte;   

    logic [31:0] ld_byte_ext;       
    logic [31:0] ld_half_ext;        
    logic [31:0] ld_byte_unsigned_ext;   
    logic [31:0] ld_half_unsigned_ext;   

    logic [31:0] mem_data_adjusted;

    assign ld_byte_ext              = {{24{selected_byte[7]}}, selected_byte};
    assign ld_half_ext              = {{16{selected_half[15]}}, selected_half};
    assign ld_byte_unsigned_ext     = {24'd0, selected_byte};
    assign ld_half_unsigned_ext     = {16'd0, selected_half};
    assign selected_half            = (ex_mem.alu_result[1]) ? mem_data[31:16] : mem_data[15:0];

    
    always_comb begin : select_load_byte
        selected_byte       = '0;
        
        unique case (ex_mem.alu_result[1:0])
            2'b00: selected_byte = mem_data[7:0];
            2'b01: selected_byte = mem_data[15:8];
            2'b10: selected_byte = mem_data[23:16];
            2'b11: selected_byte = mem_data[31:24];
            default: ;
        endcase
    end


    always_comb begin : load_select
        mem_data_adjusted   = '0;

        unique case (ex_mem.load_op)
            LOAD_BYTE:            mem_data_adjusted = ld_byte_ext;
            LOAD_HALF:            mem_data_adjusted = ld_half_ext;
            LOAD_WORD:            mem_data_adjusted = mem_data;
            LOAD_BYTE_UNSIGNED:   mem_data_adjusted = ld_byte_unsigned_ext;
            LOAD_HALF_UNSIGNED:   mem_data_adjusted = ld_half_unsigned_ext;
            default: ;
        endcase
    end


    always_comb begin : store_format
        byte_en = '0;
        write_data = ex_mem.write_data;

        unique case (ex_mem.store_op) // TODO: Check if these shifts synthesize to wires or more complicated shifting
            STORE_BYTE: begin
                write_data = write_data << (8 * ex_mem.alu_result[1:0]);
                byte_en = 4'b0001 << (ex_mem.alu_result[1:0]);
            end

            STORE_HALF: begin
                write_data = write_data << (16 * ex_mem.alu_result[1]);
                byte_en = 4'b0011 << (2 * ex_mem.alu_result[1]);
            end

            STORE_WORD:
                byte_en = 4'b1111;

            default: ;
        endcase
    end


    always_comb begin : exception_detection
        exception    = ex_mem.exception;
        mcause       = ex_mem.mcause;

        if (!ex_mem.exception) begin
            if (ex_mem.mem_write) begin
                unique case (ex_mem.store_op)
                    STORE_WORD: begin
                        if (mem_address[1:0] != 2'd0) begin
                            exception   = 1'b1;
                            mcause      = EXCEPTION_STORE_AMO_ADDR_MISALIGNED; 
                        end
                    end

                    STORE_HALF: begin
                        if (mem_address[0]) begin
                            exception   = 1'b1;
                            mcause      = EXCEPTION_STORE_AMO_ADDR_MISALIGNED; 
                        end
                    end
                    default: ;
                endcase

            end else if (opcode_mem == OP_LOAD) begin // TODO: Use a mem_read signal instead. The opcode is just for waveform debugging.
                unique case (ex_mem.load_op)
                    LOAD_HALF, LOAD_HALF_UNSIGNED: begin
                        if (mem_address[0]) begin
                            exception   = 1'b1;
                            mcause      = EXCEPTION_LOAD_ADDR_MISALIGNED;
                        end
                    end

                    LOAD_WORD: begin
                        if (mem_address[1:0] != 2'd0) begin
                            exception   = 1'b1;
                            mcause      = EXCEPTION_LOAD_ADDR_MISALIGNED;
                        end
                    end

                    LOAD_BYTE, LOAD_BYTE_UNSIGNED: ;
                    default: ;
                endcase
            end
        end
    end // always_comb exception detection


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
        mem_wb.mem_data     = mem_data_adjusted;

        // Zicsr Extension
        mem_wb.csr_op       = ex_mem.csr_op;
        mem_wb.csr_data     = ex_mem.csr_data;
        mem_wb.csr_addr     = ex_mem.csr_addr;
    end
    
endmodule