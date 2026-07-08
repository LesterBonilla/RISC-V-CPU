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
    logic [4:0]     rs1_addr, rs2_addr, reg_dest_addr;

// Memories

    instruction_memory # (.SIZE(1024), .XLEN(32)) imem_inst (
        .read_address   (pc),
        .data_out       (instruction)
    );

    data_memory # (.SIZE(1024), .XLEN(32)) dmem_inst (
        .clk            (clk),
        .write_en       (),
        .write_address  (),
        .read_address   (),
        .write_data     (),

        .data_out       ()
    );

    register_file regfile_inst (
        .clk            (clk),
        .rs1_addr       (rs1_addr),
        .rs2_addr       (rs2_addr),
        .dest_addr      (reg_dest_addr),
        .dest_write_en  (),
        .dest_write_data(),

        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data)
    );

// Stage Modules

    if_stage if_inst (
        .pc             (pc),
        .pc_target      (pc_target),
        .instruction    (instruction),
        .pc_src         (),

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
// Ex  Stage
// Mem Stage
// WB  Stage

// Pipeline Registers
// IF/ID  register
// ID/EX  register
// EX/MEM  register
// MEM/WB register

// Hazard Control unit

endmodule