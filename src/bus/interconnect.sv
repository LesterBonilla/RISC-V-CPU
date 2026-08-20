import interconnect_pkg::*; 
import map_pkg::*;
module interconnect (
    input   logic               clk,
    input   logic               rst_n,
    input   axi_manager_t       manager_request[NUM_MANAGERS],
    input   axi_subordinate_t   subordinate_response[NUM_SUBORDINATES],
    output  axi_manager_t       subordinate_request[NUM_SUBORDINATES],
    output  axi_subordinate_t   manager_response[NUM_MANAGERS]
);

    owner_e ram_owner, boot_owner;
    subordinates_e  aw_req[NUM_MANAGERS], ar_req[NUM_MANAGERS];
    managers_e      aw_grant[NUM_SUBORDINATES], ar_grant[NUM_SUBORDINATES];
    managers_e      b_owner_r[NUM_SUBORDINATES], r_owner_r[NUM_SUBORDINATES];
    managers_e      next_b_owner[NUM_SUBORDINATES], next_r_owner[NUM_SUBORDINATES];

//------------------------------------------------------------------------------
// Address Decode
//------------------------------------------------------------------------------
    always_comb begin
        for (int m = 0; m < NUM_MANAGERS; ++m) begin
            aw_req[m] = decode_address(manager_request[m].AW.AWADDR);
            ar_req[m] = decode_address(manager_request[m].AR.ARADDR);
        end
    end
//------------------------------------------------------------------------------
// Shared Resource Arbitration
//------------------------------------------------------------------------------
    always_comb begin
        // Fixed priority arbiter for now, will update to round robin once this is working
        // For each subordinate, check if a manager is requesting access.
        // The first manager to request access gets the grant, the loop breaks and the
        // next subordinate is checked.
        // Check ar and aw separately. Separate managers can access the same channel of
        // different subordinates or different channels of the same subordinate.
        // Use subordinates_e'(s+1) to skip SEL_NONE and MANAGER_NONE
        ar_grant = '{default:'0};
        aw_grant = '{default:'0};

        for (int s = 0; s < NUM_SUBORDINATES; s++) begin
            for (int m = 0; m < NUM_MANAGERS; m++) begin
                if (ar_req[m] == subordinates_e'(s+1)) begin
                    ar_grant[s] = managers_e'(m+1);
                    break;
                end
            end
        end

        for (int s = 0; s < NUM_SUBORDINATES; s++) begin
            for (int m = 0; m < NUM_MANAGERS; m++) begin
                if (aw_req[m] == subordinates_e'(s+1)) begin
                    aw_grant[s] = managers_e'(m+1);
                    break;
                end
            end
        end
    end

//------------------------------------------------------------------------------
// Request Muxing
//------------------------------------------------------------------------------   
    always_comb begin
        subordinate_request = '{default:'0};

        for (int s = 0; s < NUM_SUBORDINATES; s++) begin
            if (aw_grant[s] != MANAGER_NONE) begin
                subordinate_request[s].AW   = manager_request[aw_grant[s]].AW;
                subordinate_request[s].W    = manager_request[aw_grant[s]].W;
            end
            if (ar_grant[s] != MANAGER_NONE) begin
                subordinate_request[s].AR   = manager_request[ar_grant[s]].AR;
            end
        end
    end

//------------------------------------------------------------------------------
// Handshakes and Assigning Response Grants
//------------------------------------------------------------------------------  
    always_comb begin
        next_b_owner = b_owner_r;
        next_r_owner = r_owner_r;

        // Each manager only does one read/write transaction at a time.
        // If AWVALID or ARVALID are set, the manager received the previous response it was
        // waiting for and is ready to start another transaction.
        // Later, support will be added for multiple transactions on each of read/write.
        // This will let the manager start a read from RAM and start a read from UART and get them
        // out of order. This will require IDs and keeping track of which ID routes back to which manager.
        // The simple case here is that IMEM only needs RAM access. DMEM is the only manager that
        // accesses peripherals. I'll try to generalize it so I can add a second master and not need to
        // redo anything. For now, DMEM will need to wait for a RAM completion before starting a UART transaciton.
        // A table can be kept that matches IDs to managers. When a subordinate asserts RVALID/BVALID, the ID
        // is used to connect the response channels. The table would be iterated, and the first match would be
        // connected to the manager and poped when RREADY/BREADY accepts the response.
        // For now W and AW are tightly coupled.
        for (int s = 0; s < NUM_SUBORDINATES; s++) begin
            for (int m = 0; m < NUM_MANAGERS; m++) begin
                // Clear response_owner when response is handshaked. In that same cycle, a response handshake
                // can occur, so it will update the next_x_owner.
                if (b_owner_r[s] == managers_e'(m+1)) begin
                    if (handshake(.ch(AXI_CH_B), .m(m), .s(s))) begin
                        next_b_owner[s] = MANAGER_NONE;
                    end
                    if (handshake(.ch(AXI_CH_AW), .m(m), .s(s))) begin
                        if (handshake(.ch(AXI_CH_W), .m(m), .s(s))) begin
                            next_b_owner[s] = managers_e'(m+1);
                        end
                    end
                end

                if (r_owner_r[s] == managers_e'(m+1)) begin
                    if (handshake(.ch(AXI_CH_R), .m(m), .s(s))) begin
                        next_r_owner[s] = MANAGER_NONE;
                    end
                    if (handshake(.ch(AXI_CH_AR), .m(m), .s(s))) begin
                        next_r_owner[s] = managers_e'(m+1);
                end
                end
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b_owner_r <= '{default:'0};
            r_owner_r <= '{default:'0};
        end else begin
            b_owner_r <= next_b_owner;
            r_owner_r <= next_r_owner;
        end
    end

//------------------------------------------------------------------------------
// Response Muxing
//------------------------------------------------------------------------------  
    always_comb begin
        manager_response = '{default:'0};

        for (int s = 0; s < NUM_SUBORDINATES; s++) begin
            if (b_owner_r[s] != MANAGER_NONE) begin
                manager_response[b_owner_r[s]].B = subordinate_response[s].B;
            end
            if (r_owner_r[s] != MANAGER_NONE) begin
                manager_response[r_owner_r[s]].R = subordinate_response[s].R;
            end
        end
    end

//------------------------------------------------------------------------------
// Functions
//------------------------------------------------------------------------------  
    function automatic logic handshake(axi_ch_e ch, int unsigned m, int unsigned s);
        case (ch)
            AXI_CH_AW:  return manager_request[m].AW.AWVALID & subordinate_response[s].AW.AWREADY;
            AXI_CH_W:   return manager_request[m].W.WVALID   & subordinate_response[s].W.WREADY;
            AXI_CH_B:   return manager_request[m].B.BREADY   & subordinate_response[s].B.BVALID;
            AXI_CH_AR:  return manager_request[m].AR.ARVALID & subordinate_response[s].AR.ARREADY;
            AXI_CH_R:   return manager_request[m].R.RREADY   & subordinate_response[s].R.RVALID;
            default:    return 1'b0;
        endcase
    endfunction

endmodule