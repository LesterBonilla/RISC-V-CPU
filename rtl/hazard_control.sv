import decode_pkg::*;
import pipeline_pkg::*;

module hazard_control (
    input logic [4:0]   rs1_id,
    input logic [4:0]   rs2_id,

    input logic [4:0]   rs1_ex,
    input logic [4:0]   rs2_ex,
    input logic [4:0]   rd_ex,
    input pc_src_e      pc_src_ex,
    input wb_src_e      wb_src_ex,

    input logic [4:0]   rd_mem,
    input logic         reg_write_mem,

    input logic         reg_write_wb,
    input logic [4:0]   rd_wb,

    output logic        stall_pc_if,
    output logic        stall_if_id,
    output logic        flush_if_id,
    output logic        flush_id_ex,
    output fwd_sel_e    fwd_sel_a,
    output fwd_sel_e    fwd_sel_b
);

    // Hazards to account for now:
    // 1. Data hazard: Load-use
    //      If ID stage is setting up a register rs1_id/rs2_id that is the destination rd_ex in the execute stage,
    //      and wb_src_ex is selecting the memory output, we need to stall the pipeline to wait for the memory.
    //      We do this by stalling the PC and IF/ID registers
    //      and by flushing the contents/valid bit of the ID/EX register to introduce a bubble
    //      So: The PC stays the same, the instruction input to the ID stage stays the same, and the next input to
    //      the EX stage is invalid (since the ID stage did not progress into it). The invalid bit travels along as the bubble.
    //      This gives the memory time to load the value (assuming 2-cycle latency). This will be expanded upon
    //      later to introduce variable latency stalling in the case of busy memory/cache misses.

    // 2. Data hazard: Forwarding from MEM or WB to EX
    //      If one of rs1_ex/rs2_ex are used as rd_mem and we are writing with reg_write_mem (and rs1_ex/rs2_ex are not 0)
    //      Then we forward mem.alu_result to the EX stage.
    //      If one of rs1_ex/rs2_ex are used as rd_wb and we are writing with reg_write_wb (and rs1_ex/rs2_ex are not 0)
    //      Then we forward wb_result to the EX stage.
    //      Note: Prioritize forwarding from MEM if MEM and WB both have relevant rd destinations. The value in MEM is
    //      the most up-to-date.

    // 3. Control hazard: Flushing when wrong instructions are processed (branch mispredict/jump)
    //      If pc_src_ex is true, that means we are branching or jumping and the last two stages have wrong data.
    //      We synchronously flush the IF/ID and ID/EX registers, so the ID and EX stages become bubbles.
    //      The branch/jump instruction continues to MEM and WB stages as normal.
    //      For clarity: On the clock after pc_src is set to target_pc, the PC register is updated and it takes one more
    //      clock cycle before the next correct instruction passes to the ID stage via the IF/ID register.

    // Hazards to account for once the core develops:
    //  1. Data hazard: Dynamic memory latency and instruction memory stalling
    //      We currently assume that data from a load takes 2 cycles to be available (address calculated in EX travels to
    //      the MEM stage, and the data then passes to the WB stage).
    //      However, this latency may increase in the future if we add a memory hierarchy via a cache and main memory.
    //      The memory interface will then include a handshaking protocol to indicate when it is busy and when a 
    //      request is served. The pipeline will need to stall PC and IF/ID and flush EX while waiting.
    //      We also assume that instructions reads are single-cycle, but if we introduce a memory hierarchy to imem,
    //      we will need to stall the PC register and flush the IF/ID register while waiting for the memory.


    always_comb begin
        fwd_sel_a = '0;
        fwd_sel_b = '0;

        // Forward rs1, prioritize MEM
        if (rs1_ex == rd_mem) && (reg_write_mem) && (rs1_ex != 5'd0) 
            fwd_sel_a = FWD_MEM;
        else if (rs1_ex == rd_wb) && (reg_write_mem) && (rs1_ex != 5'd0)
            fwd_sel_a = FWD_WB;
        else 
            fwd_sel_a = FWD_NONE;

        // Forward rs2, prioritize MEM
        if (rs2_ex == rd_mem) && (reg_write_mem) && (rs2_ex != 5'd0) 
            fwd_sel_b = FWD_MEM;
        else if (rs2_ex == rd_wb) && (reg_write_mem) && (rs2_ex != 5'd0)
            fwd_sel_b = FWD_WB;
        else 
            fwd_sel_b = FWD_NONE;


    end

endmodule