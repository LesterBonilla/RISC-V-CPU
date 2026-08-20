module interconnect 
import interconnect_pkg::*; 
import map_pkg::*;
(
    input   logic               clk,
    input   logic               rst_n,
    input   axi_manager_t       manager_request[NUM_MANAGERS],
    input   axi_subordinate_t   subordinate_response[NUM_SUBORDINATES],
    output  axi_manager_t       subordinate_request[NUM_SUBORDINATES],
    output  axi_subordinate_t   manager_response[NUM_MANAGERS]
);

    owner_e ram_owner, boot_owner;
    subordinates_e aw_req[NUM_MANAGERS], ar_req[NUM_MANAGERS];
    subordinates_e imem_B_sel_r, imem_R_sel_r, dmem_B_sel_r, dmem_R_sel_r;
    subordinates_e imem_B_sel_next, imem_R_sel_next, dmem_B_sel_next, dmem_R_sel_next;

//------------------------------------------------------------------------------
// Address Decode
//------------------------------------------------------------------------------
    assign imem_AW_sel = decode_address(manager_request[MANAGER_IMEM].AW.AWADDR);
    assign imem_AR_sel = decode_address(manager_request[MANAGER_IMEM].AR.ARADDR);
    assign dmem_AW_sel = decode_address(manager_request[MANAGER_DMEM].AW.AWADDR);
    assign dmem_AR_sel = decode_address(manager_request[MANAGER_DMEM].AR.ARADDR);

//------------------------------------------------------------------------------
// Shared Resource Arbitration
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Connection Muxing
//------------------------------------------------------------------------------   
    always_comb begin
        subordinate_request = '0;

        subordinate_request[imem_AW_sel].AW = manager_request[MANAGER_IMEM].AW;
        subordinate_request[imem_AR_sel].AR = manager_request[MANAGER_IMEM].AR;
    end

//------------------------------------------------------------------------------
// Check Handshakes
//------------------------------------------------------------------------------  
    assign imem_R_sel_next = (check_ar_handshake(.manager(MANAGER_IMEM), .subordinate(imem_AR_sel))) ?
                             imem_AR_sel : SEL_NONE;

    assign imem_B_sel_next = (check_aw_handshake(.manager(MANAGER_IMEM), .subordinate(imem_AW_sel))) ?
                             imem_AW_sel : SEL_NONE;

    always_ff @(posedge clk or negedge rst_n) begin
        if !(rst_n) begin
            imem_B_sel_r <= SEL_NONE;
            imem_R_sel_r <= SEL_NONE;
        end else begin
            imem_B_sel_r <= imem_B_sel_next;
            imem_R_sel_r <= imem_R_sel_next;
        end
    end

    function automatic logic check_aw_handshake(managers_e manager, subordinates_e subordinate);
        return (manager_request[manager].AW.AWVALID && subordinate_response[subordinate].AW.AWREADY);
    endfunction

    function automatic logic check_ar_handshake(managers_e manager, subordinates_e subordinate);
        return (manager_request[manager].AR.ARVALID && subordinate_response[subordinate].AR.ARREADY);
    endfunction
endmodule