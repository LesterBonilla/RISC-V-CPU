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

        // Control signals
        logic               reg_write;
        logic               jump;
        logic               branch;
        alu_op_e            alu_op;
        alu_src_a_e         alu_src_a;
        alu_src_b_e         alu_src_b;
        wb_src_e            wb_src;
        branch_op_e         branch_op;
        load_op_e           load_op;
        store_op_e          store_op;
        imm_src_e           imm_src;
        target_adder_src_e  target_adder_src;

        // Data lines
        logic [4:0]         rs1;
        logic [4:0]         rs2;
        logic [4:0]         rd;
        logic [31:0]        imm_extended;
        logic [31:0]        pc;
        logic [31:0]        pc_plus4;
        logic [31:0]        reg_data_1;
        logic [31:0]        reg_data_2;

    } id_ex_reg_t;

endpackage