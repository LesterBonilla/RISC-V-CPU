import decode_pkg::*;
import pipeline_pkg::*;

module mem_stage (
    input ex_mem_reg_t  ex_mem,
    input logic [31:0]  mem_data,

    output logic        mem_write,
    output logic [3:0]  write_mask,
    output logic [31:0] write_data,
    output logic [31:0] mem_address,
    output logic [31:0] alu_result,

    output mem_wb_reg_t mem_wb
);

    assign mem_write    = ex_mem.mem_write && ex_mem.valid;
    assign alu_result   = ex_mem.alu_result;
    assign mem_address  = {ex_mem.alu_result[31:2], 2'b0};

    logic [15:0] selected_half;
    logic [7:0]  selected_byte;   

    logic [31:0] ld_byte_ext            = {{24{selected_byte[7]}}, selected_byte};
    logic [31:0] ld_half_ext            = {{16{selected_half[15]}}, selected_half};
    logic [31:0] ld_byte_unsigned_ext   = {24'd0, selected_byte};
    logic [31:0] ld_half_unsigned_ext   = {16'd0, selected_half};

    logic [31:0] mem_data_adjusted;


    always_comb begin : load_select
        selected_half       = '0;
        selected_byte       = '0;
        mem_data_adjusted   = '0;
        
        unique case (ex_mem.alu_result[1:0])
            2'b00: selected_byte = mem_data[7:0];
            2'b01: selected_byte = mem_data[15:8];
            2'b10: selected_byte = mem_data[23:16];
            2'b11: selected_byte = mem_data[31:24];
            default: ;
        endcase

        unique case (ex_mem.alu_result[1])
            1'b0: selected_half = mem_data[15:0];
            1'b1: selected_half = mem_data[31:16];
            default: ;
        endcase

        unique case (ex_mem.load_op)
            LD_BYTE:            mem_data_adjusted = ld_byte_ext;
            LD_HALF:            mem_data_adjusted = ld_half_ext;
            LD_WORD:            mem_data_adjusted = mem_data;
            LD_BYTE_UNSIGNED:   mem_data_adjusted = ld_byte_unsigned_ext;
            LD_HALF_UNSIGNED:   mem_data_adjusted = ld_half_unsigned_ext;
            default: ;
        endcase
    end


    always_comb begin : store_format
        write_mask = '0;
        write_data = ex_mem.write_data;

        unique case (ex_mem.store_op)
            STORE_BYTE: begin
                write_data = write_data << (8 * ex_mem.alu_result[1:0]);
                write_mask = 4'b0001 << (ex_mem.alu_result[1:0]);
            end

            STORE_HALF: begin
                write_data = write_data << (16 * ex_mem.alu_result[1]);
                write_mask = 4'b0011 << (2 * ex_mem.alu_result[1]);
            end

            STORE_WORD:
                write_mask = 4'b1111;

            default: ;
        endcase
    end


    always_comb begin : mem_wb_reg_input
        mem_wb = '0;

        mem_wb.valid        = ex_mem.valid;
        mem_wb.reg_write    = ex_mem.reg_write;
        mem_wb.wb_src       = ex_mem.wb_src;
        mem_wb.alu_result   = ex_mem.alu_result;
        mem_wb.pc_plus4     = ex_mem.pc_plus4;
        mem_wb.rd           = ex_mem.rd;
        mem_wb.mem_data     = mem_data_adjusted;
    end
    
endmodule