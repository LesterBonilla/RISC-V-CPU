import decode_pkg::*;
import pipeline_pkg::*;

module core # (
    parameter int IMEM_SIZE_WORDS = 1024,
    parameter int DMEM_SIZE_WORDS = 1024
)(
    input logic clk,
    input logic rst_n
);

    // Pipeline structs
    if_id_reg_t     if_id, if_id_next;
    id_ex_reg_t     id_ex, id_ex_next;
    ex_mem_reg_t    ex_mem, ex_mem_next;
    mem_wb_reg_t    mem_wb, mem_wb_next;

    // PC
    logic [31:0]    pc, pc_next, pc_target;
    logic [31:0]    instruction;
    pc_src_e        pc_src_ex;

    // Register file
    logic [31:0]    rs1_data, rs2_data;
    logic [4:0]     rs1_addr, rs2_addr, rd_addr;
    logic           reg_write;

    // Data memory
    logic [31:0]    mem_write_data, dmem_addr, mem_read_data;
    logic [3:0]     byte_en;
    logic           mem_write;

    // Hazard control
    logic [31:0]    fwd_data_mem, wb_result;
    logic           stall_pc_if, stall_if_id, flush_if_id, flush_id_ex;
    fwd_sel_e       fwd_sel_a, fwd_sel_b;

//------------------------------------------------------------------------------
// Program Counter
//------------------------------------------------------------------------------

    pipeline_register # (.WIDTH($bits(pc))) pc_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (stall_pc_if),
        .flush          (1'b0),
        .data_in        (pc_next),
        .data_out       (pc)
    );

//------------------------------------------------------------------------------
// Memories
//------------------------------------------------------------------------------

    instruction_memory # (.SIZE_WORDS(IMEM_SIZE_WORDS)) imem_inst (
        .address        (pc),
        .data_out       (instruction)
    );

    data_memory # (.SIZE_WORDS(DMEM_SIZE_WORDS)) dmem_inst (
        .clk            (clk),
        .write_en       (mem_write),
        .address        (dmem_addr),
        .data_in        (mem_write_data),
        .byte_en        (byte_en),

        .data_out       (mem_read_data)
    );

    register_file regfile_inst (
        .clk            (clk),
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .rd_addr        (rd_addr),
        .reg_write      (reg_write),
        .rd_write_data  (wb_result),

        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data)
    );

//------------------------------------------------------------------------------
// Hazard control
//------------------------------------------------------------------------------
    
    hazard_control hazard_inst (
        .rs1_id         (id_ex_next.rs1_addr),
        .rs2_id         (id_ex_next.rs2_addr),

        .rs1_ex         (id_ex.rs1_addr),
        .rs2_ex         (id_ex.rs2_addr),
        .rd_ex          (id_ex.rd_addr),
        .pc_src_ex      (pc_src_ex),
        .wb_src_ex      (id_ex.wb_src),

        .rd_mem         (ex_mem.rd_addr),
        .reg_write_mem  (ex_mem.reg_write),

        .rd_wb          (mem_wb.rd_addr),
        .reg_write_wb   (mem_wb.reg_write),

        .stall_pc_if    (stall_pc_if),
        .stall_if_id    (stall_if_id),
        .flush_if_id    (flush_if_id),
        .flush_id_ex    (flush_id_ex),
        .fwd_sel_a      (fwd_sel_a),
        .fwd_sel_b      (fwd_sel_b)
    );

//------------------------------------------------------------------------------
// Pipeline stages
//------------------------------------------------------------------------------

    if_stage if_inst (
        .pc             (pc),
        .pc_target      (pc_target),
        .instruction    (instruction),
        .pc_src         (pc_src_ex),

        .pc_next        (pc_next),
        .if_id          (if_id_next)
    );

    id_stage id_inst (
        .if_id          (if_id),
        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data),

        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .id_ex          (id_ex_next)
    );

    ex_stage ex_inst (
        .id_ex          (id_ex),
        .fwd_sel_a      (fwd_sel_a),
        .fwd_sel_b      (fwd_sel_b),
        .fwd_data_mem   (fwd_data_mem),
        .fwd_data_wb    (wb_result),

        .pc_target      (pc_target),
        .pc_src         (pc_src_ex),
        .ex_mem         (ex_mem_next)
    );

    mem_stage mem_inst (
        .ex_mem         (ex_mem),
        .mem_data       (mem_read_data),

        .mem_write      (mem_write),
        .byte_en        (byte_en),
        .write_data     (mem_write_data),
        .mem_address    (dmem_addr),
        .alu_result     (fwd_data_mem),
        .mem_wb         (mem_wb_next)
    );

    wb_stage wb_inst (
        .mem_wb         (mem_wb),

        .reg_write      (reg_write),
        .rd_addr        (rd_addr),
        .wb_result      (wb_result)
    );

//------------------------------------------------------------------------------
// Pipeline registers
//------------------------------------------------------------------------------

    pipeline_register # (.WIDTH($bits(if_id))) if_id_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (stall_if_id),
        .flush          (flush_if_id),
        .data_in        (if_id_next),

        .data_out       (if_id)
    );

    pipeline_register # (.WIDTH($bits(id_ex))) id_ex_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (1'b0),
        .flush          (flush_id_ex),
        .data_in        (id_ex_next),

        .data_out       (id_ex)
    );

    pipeline_register # (.WIDTH($bits(ex_mem))) ex_mem_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (1'b0),
        .flush          (1'b0),
        .data_in        (ex_mem_next),

        .data_out       (ex_mem)
    );

    pipeline_register # (.WIDTH($bits(mem_wb))) mem_wb_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (1'b0),
        .flush          (1'b0),
        .data_in        (mem_wb_next),

        .data_out       (mem_wb)
    );



endmodule