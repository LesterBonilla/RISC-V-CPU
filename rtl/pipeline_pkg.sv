package pipeline_pkg;   
   
    import decode_pkg::*;

    typedef enum logic [1:0] { 
        FWD_NONE,
        FWD_MEM,
        FWD_WB
    } fwd_sel_e;

    typedef struct packed {
        
    } id_ex_ctrl_t;

    typedef struct packed {
        
    } id_ex_data_t;

endpackage