module core (
    input clk,
    input rst_n
);

    if_id_reg_t     if_id, if_id_next;
    id_ex_reg_t     id_ex, id_ex_next;
    ex_mem_reg_t    ex_mem, ex_mem_next;
    mem_wb_reg_t    mem_wb, mem_wb_next;

    logic [31:0]    pc, pc_next, pc_target;
    logic [31:0]    instruction, rs1_data, rs2_data;
    logic [31:0]    mem_write_data, mem_write_addr;
    logic [31:0]    mem_read_addr, mem_read_data;
    logic [31:0]    alu_result_mem, wb_result;
    logic [4:0]     rs1_addr, rs2_addr, reg_dest_addr;
    logic [4:0]     write_mask;
    
    logic           mem_write, reg_write;
    logic           stall_pc_if, stall_if_id, flush_if_id, flush_id_ex;
    pc_src_e        pc_src_ex;
    fwd_sel_e       fwd_sel_a, fwd_sel_b;

// PC
    pipeline_register # (T = logic [31:0]) pc_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .en_n           (stall_pc_if),
        .flush          (1'b0),
        .data_in        (pc_next),
        .data_out       (pc)
    )

// Memories

    instruction_memory # (.SIZE(1024), .XLEN(32)) imem_inst (
        .read_address   (pc),
        .data_out       (instruction)
    );

    data_memory # (.SIZE(1024), .XLEN(32)) dmem_inst (
        .clk            (clk),
        .write_en       (mem_write),
        .read_address   (mem_read_addr),
        .write_address  (mem_write_addr),
        .write_data     (mem_write_data),
        .write_mask     (write_mask),

        .data_out       (mem_read_data)
    );

    register_file regfile_inst (
        .clk            (clk),
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .dest_addr      (reg_dest_addr),
        .dest_write_en  (reg_write),
        .dest_write_data(wb_result),

        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data)
    );

// Stage Modules

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
        .fwd_data_mem   (alu_result_mem),
        .fwd_data_wb    (wb_result),

        .pc_target      (pc_target),
        .pc_src         (pc_src_ex),
        .ex_mem         (ex_mem_next)
    );

    mem_stage mem_inst (
        .ex_mem         (ex_mem),
        .mem_data       (mem_read_data),

        .mem_write      (mem_write),
        .write_mask     (write_mask),
        .write_data     (mem_write_data),
        .mem_address    (mem_write_addr),
        .alu_result     (alu_result_mem),
        .mem_wb         (mem_wb_next)
    );

    wb_stage wb_inst (
        .mem_wb         (mem_wb),

        .reg_write      (reg_write),
        .reg_write_addr (reg_dest_addr),
        .wb_result      (wb_result)
    );

// Stage registers

    pipeline_register # (parameter T = if_id_reg_t) if_id_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .en_n           (stall_if_id),
        .flush          (flush_if_id),
        .data_in        (if_id_next),

        .data_out       (if_id)
    );

    pipeline_register # (parameter T = id_ex_reg_t) id_ex_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .en_n           (1'b0),
        .flush          (flush_id_ex),
        .data_in        (id_ex_next),

        .data_out       (id_ex)
    );

    pipeline_register # (parameter T = ex_mem_reg_t) ex_mem_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .en_n           (1'b0),
        .flush          (1'b0),
        .data_in        (ex_mem_next),

        .data_out       (ex_mem)
    );

    pipeline_register # (parameter T = mem_wb_reg_t) mem_wb_reg_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .en_n           (1'b0),
        .flush          (1'b0),
        .data_in        (mem_wb_next),

        .data_out       (mem_wb)
    );

// Hazard Control
    
    hazard_control hazard_inst (
        .rs1_id         (id_ex_next.rs1),
        .rs2_id         (id_ex_next.rs2),

        .rs1_ex         (id_ex.rs1),
        .rs2_ex         (id_ex.rs2),
        .rd_ex          (id_ex.rd),
        .pc_src_ex      (pc_src_ex),
        .wb_src_ex      (id_ex.wb_src),

        .rd_mem         (ex_mem.rd),
        .reg_write_mem  (ex_mem.reg_write),

        .reg_write_wb   (mem_wb.reg_write),
        .rd_wb          (mem_wb.rd),

        .stall_pc_if    (stall_pc_if),
        .stall_if_id    (stall_if_id),
        .flush_if_id    (flush_if_id),
        .flush_id_ex    (flush_id_ex),
        .fwd_sel_a      (fwd_sel_a),
        .fwd_sel_b      (fwd_sel_b)
    );

endmodule