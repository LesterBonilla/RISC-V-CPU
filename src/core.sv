import decode_pkg::*;
import pipeline_pkg::*;
import csr_pkg::*;

module core # (
    parameter int MEM_SIZE_WORDS = 1024
)(
    input logic clk,
    input logic rst_n,
    input logic rx_pin,
    output logic tx_pin
);

    // Pipeline structs
    if_id_reg_t     if_id, if_id_next;
    id_ex_reg_t     id_ex, id_ex_next;
    ex_mem_reg_t    ex_mem, ex_mem_next;
    mem_wb_reg_t    mem_wb, mem_wb_next;

    // PC
    logic [31:0]    pc, pc_next, pc_target_ex, pc_target_wb;
    logic [31:0]    instruction_direct, instruction_stalled, instruction;
    pc_src_e        pc_src_ex;

    // Register file
    logic [31:0]    rs1_data, rs2_data;
    logic [4:0]     rs1_addr, rs2_addr, rd_addr;
    logic           reg_write;

    // Data memory
    logic [31:0]    mem_write_data, dmem_addr, mem_read_data;
    logic [3:0]     byte_en;
    logic           mem_write, mem_read;

    // Hazard control
    logic [31:0]    fwd_data_mem, wb_result;
    logic           stall_pc_if, stall_if_id, stall_id_ex;
    logic           flush_if_id, flush_id_ex, flush_ex_mem, flush_mem_wb;
    fwd_sel_e       fwd_sel_a, fwd_sel_b;

    // CSR
    logic [31:0]    csr_read_data, csr_write_data;
    logic [11:0]    csr_addr;
    logic           inst_ret;
    csr_op_e        csr_op;

    // Traps/Exceptions/Interrupts
    logic           trap_wb, mret_wb, redirect_wb;
    logic [31:0]    mie_csr, mepc_csr, mstatus_csr, mtvec_csr;
    logic [31:0]    mcause_wb, mepc_wb, mip;
    mip_mie_csr_t   irq_p;

//------------------------------------------------------------------------------
// Program Counter
//------------------------------------------------------------------------------

    pipeline_register # (.WIDTH($bits(pc)), .INITIAL_VALUE(32'hFFFFF000)) pc_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (stall_pc_if),
        .flush          (1'b0),
        .data_in        (pc_next),
        .data_out       (pc)
    );

    logic use_stalled;

    assign instruction = use_stalled ? instruction_stalled : instruction_direct;

    always_ff @(posedge clk) begin
        if (stall_if_id) begin
            instruction_stalled <= instruction_direct;
            use_stalled <= 1'b1;
        end else if (flush_if_id) begin
            instruction_stalled <= '0;
            use_stalled <= 1'b1;
        end else begin
            use_stalled <= 1'b0;
        end
    end

//------------------------------------------------------------------------------
// Memories
//------------------------------------------------------------------------------

    bus # (.NUM_WORDS(MEM_SIZE_WORDS)) bus_inst (
        .clk            (clk),
        .rst_n          (rst_n),

        .imem_address   (pc),
        .imem_data      (instruction_direct),
        .imem_read      (!stall_if_id && !flush_if_id),
        .address        (dmem_addr),
        .data_in        (mem_write_data),
        .byte_en        (byte_en),
        .write_en       (mem_write),
        .data_out       (mem_read_data),
        .irq_p          (irq_p),
        .read_en        (mem_read),
        .rx_pin         (rx_pin),
        .tx_pin         (tx_pin)
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
// CSR
//------------------------------------------------------------------------------

    csr csr_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (csr_write_data),
        .address        (csr_addr),
        .csr_op         (csr_op),
        .inst_ret       (inst_ret),

        .trap           (trap_wb),
        .mret           (mret_wb),
        .mip_in         (irq_p),
        .mepc_in        (mepc_wb),
        .mcause_in      (mcause_wb),

        .mie_out        (mie_csr),
        .mepc_out       (mepc_csr),
        .mstatus_out    (mstatus_csr),
        .mtvec_out      (mtvec_csr),

        .data_out       (csr_read_data)
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

        .redirect_wb    (redirect_wb),

        .stall_pc_if    (stall_pc_if),
        .stall_if_id    (stall_if_id),
        .flush_if_id    (flush_if_id),
        .flush_id_ex    (flush_id_ex),
        .flush_ex_mem   (flush_ex_mem),
        .flush_mem_wb   (flush_mem_wb),
        .fwd_sel_a      (fwd_sel_a),
        .fwd_sel_b      (fwd_sel_b)
    );

//------------------------------------------------------------------------------
// Pipeline stages
//------------------------------------------------------------------------------

    if_stage if_inst (
        .pc             (pc),
        .pc_target_ex   (pc_target_ex),
        .pc_src_ex      (pc_src_ex),

        .redirect_wb    (redirect_wb),
        .pc_target_wb   (pc_target_wb),

        .pc_next        (pc_next),
        .if_id          (if_id_next)
    );

    id_stage id_inst (
        .if_id          (if_id),
        .instruction    (instruction),
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

        .pc_target      (pc_target_ex),
        .pc_src         (pc_src_ex),
        .ex_mem         (ex_mem_next)
    );

    mem_stage mem_inst (
        .ex_mem         (ex_mem),

        .redirect_wb    (redirect_wb),

        .mem_write      (mem_write),
        .mem_read       (mem_read),
        .byte_en        (byte_en),
        .write_data     (mem_write_data),
        .mem_address    (dmem_addr),
        .alu_result     (fwd_data_mem),
        .mem_wb         (mem_wb_next)
    );

    wb_stage wb_inst (
        .mem_wb         (mem_wb),
        .mem_read_data  (mem_read_data),

        .reg_write      (reg_write),
        .rd_addr        (rd_addr),
        .wb_result      (wb_result),

        .csr_read_data  (csr_read_data),
        .csr_write_data (csr_write_data),
        .csr_op         (csr_op),
        .csr_addr       (csr_addr),
        .inst_ret       (inst_ret),

        .mip            (irq_p),
        .mie            (mie_csr),
        .mstatus        (mstatus_csr),
        .mtvec          (mtvec_csr),
        .mepc_in        (mepc_csr),
        .trap           (trap_wb),
        .mret           (mret_wb),
        .redirect       (redirect_wb),
        .mcause         (mcause_wb),
        .mepc_out       (mepc_wb),
        .pc_target      (pc_target_wb)
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
        .flush          (flush_ex_mem),
        .data_in        (ex_mem_next),

        .data_out       (ex_mem)
    );

    pipeline_register # (.WIDTH($bits(mem_wb))) mem_wb_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .stall          (1'b0),
        .flush          (flush_mem_wb),
        .data_in        (mem_wb_next),

        .data_out       (mem_wb)
    );

endmodule