package pipeline_pkg;   
   
    import decode_pkg::*;

    typedef enum logic [1:0] { 
        FWD_NONE,
        FWD_MEM,
        FWD_WB
    } fwd_sel_e;

    typedef struct packed {
        logic               valid;

        // Data lines
        logic [31:0]        instruction;
        logic [31:0]        pc;
        logic [31:0]        pc_plus4;

    } if_id_reg_t;

    typedef struct packed {
        logic               valid;
        opcode_e            opcode;

        // Control signals
        logic               reg_write;
        logic               mem_write;
        logic               jump;
        logic               branch;
        alu_op_e            alu_op;
        alu_src_a_e         alu_src_a;
        alu_src_b_e         alu_src_b;
        wb_src_e            wb_src;
        branch_op_e         branch_op;
        load_op_e           load_op;
        store_op_e          store_op;
        pc_target_src_e     pc_target_src;

        // Data lines
        logic [4:0]         rs1_addr;
        logic [4:0]         rs2_addr;
        logic [4:0]         rd_addr;
        logic [31:0]        imm_extended;
        logic [31:0]        pc;
        logic [31:0]        pc_plus4;
        logic [31:0]        rs1_data;
        logic [31:0]        rs2_data;

    } id_ex_reg_t;

    typedef struct packed {
        logic               valid;
        opcode_e            opcode;

        // Control signals
        logic               reg_write;
        wb_src_e            wb_src;
        logic               mem_write;
        load_op_e           load_op;
        store_op_e          store_op;

        // Data lines
        logic [31:0]        alu_result;
        logic [31:0]        write_data;
        logic [31:0]        pc_plus4;
        logic [4:0]         rd_addr;

    } ex_mem_reg_t;

    typedef struct packed {
        logic               valid;
        opcode_e            opcode;
        
        // Control signals
        logic               reg_write;
        wb_src_e            wb_src;

        // Data lines
        logic [31:0]        alu_result;
        logic [31:0]        mem_data;
        logic [31:0]        pc_plus4;
        logic [4:0]         rd_addr;

    } mem_wb_reg_t;

endpackage