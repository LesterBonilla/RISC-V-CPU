import decode_pkg::*;
import pipeline_pkg::*;
import csr_pkg::*;

module csr (
    input logic         clk,
    input logic         rst_n,
    
    input logic [31:0]  data_in,
    input logic [11:0]  address,
    input csr_op_e      csr_op,

    input logic         inst_ret,

    output logic [31:0] data_out
);

//------------------------------------------------------------------------------
// Read-Only Hardcoded Values
//------------------------------------------------------------------------------
    logic [31:0] misa, mvendorid, marchid, mimpid, mhartid;

    assign misa         = {2'b01, 4'b0, 26'b00000000000000000100000000}; // XLEN=32, Only support I extension
    assign mvendorid    = 32'd0; // Required, non-commercial implementation
    assign marchid      = 32'd0; // Required, not implemented
    assign mimpid       = 32'd0; // Required, not implemented
    assign mhartid      = 32'd0; // Required, not implemented

//------------------------------------------------------------------------------
// Machine Status (mstatus and mstatush) Registers
//------------------------------------------------------------------------------
    mstatus_csr_t   mstatus;
    mstatush_csr_t  mstatus_h;
    logic           mstatus_en;

    assign mstatus_en   = (address == MSTATUS);
    assign mstatus_h    = '0;

    csr_reg # (.RESET_VAL(MSTATUS_RESET), .WRITE_MASK(MSTATUS_WR_MASK)) mstatus_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (mstatus_en),
        .direct_ld  (1'b0),
        .csr_op     (csr_op),
        .data_in    (data_in),
        .data_out   (data_out)
    );

//------------------------------------------------------------------------------
// Machine Trap-Vector Base-Address (mtvec) Register
//------------------------------------------------------------------------------
    mtvec_csr_t mtvec;
    localparam logic [31:0] MTVEC_ADDR = 32'h00010000;
    localparam logic [29:0] MTVEC_BASE = MTVEC_ADDR[31:2];

    assign mtvec.base = MTVEC_BASE;
    assign mtvec.mode = MTVEC_MODE_DIRECT;

//------------------------------------------------------------------------------
// Machine Trap Delegation (medeleg and mideleg) Registers
//------------------------------------------------------------------------------
    // Do not exist if S-mode not implemented

//------------------------------------------------------------------------------
// Machine Interrupt (mip and mie) Registers
//------------------------------------------------------------------------------
    // Only MTI: Machine-level machine timer interrupts will be supported, but
    // will be implemented later when traps/interrupts are implemented.
    // TODO: Update csr_reg module to have an override signal to distinguish
    // between software CSR access and trap handling access. Consider alternatives.
    mip_mie_csr_t mip, mie;

    assign mip = '0;
    assign mie = '0;

//------------------------------------------------------------------------------
// Hardware Performance Monitor
//------------------------------------------------------------------------------
    // mhpcounter3-31 and mhpevent3-31 must be implemented, but can return
    // read-only 0. Default case in data_out mux handles read-only 0s.
    // TODO: These will likely go in their own module to keep this module simple.
    logic [63:0]    mcycle, minstret;
    logic [31:0]    mcycle_H, mcycle_L, minstret_H, minstret_L;
    logic [63:0]    next_mcycle, next_minstret;
    logic           is_mcycle_l, is_mcycle_h, is_mcycle; 
    logic           is_minstret, is_minstret_l, is_minstret_h, inc_minstret;

    assign is_mcycle_l      = (address == MCYCLE);
    assign is_mcycle_h      = (address == MCYCLEH);
    assign is_mcycle        = (is_mcycle_l || is_mcycle_h);
    assign is_minstret_l    = (address == MINSTRET);
    assign is_minstret_h    = (address == MINSTRETH);
    assign is_minstret      = ((is_minstret_h || is_minstret_l));
    assign inc_minstret     = (!is_minstret && inst_ret);

    assign mcycle_H         = mcycle[63:32];
    assign mcycle_L         = mcycle[31:0];
    assign minstret_H       = minstret[63:32];
    assign minstret_L       = minstret[31:0];

    always_comb begin
        next_mcycle = mcycle;

        if      (is_mcycle_h)   next_mcycle[63:32]  = data_in;
        else if (is_mcycle_l)   next_mcycle[31:0]   = data_in;  
        else                    next_mcycle         = mcycle + 1'b1;        
    end

    always_comb begin
        next_minstret = minstret;

        if      (is_minstret_h) next_minstret[63:32]    = data_in;
        else if (is_minstret_l) next_minstret[31:0]     = data_in;  
        else if (inst_ret)      next_minstret           = minstret + 1'b1;   
    end

    csr_reg # (.WIDTH(64)) mcycle_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (is_mcycle),
        .direct_ld  (!is_mcycle),
        .csr_op     (csr_op),
        .data_in    (next_mcycle),
        .data_out   (mcycle)
    );

    csr_reg # (.WIDTH(64)) minstret_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (is_minstret),
        .direct_ld  (inc_minstret),
        .csr_op     (csr_op),
        .data_in    (next_minstret),
        .data_out   (minstret)
    );

//------------------------------------------------------------------------------
// Address decoding for reading
//------------------------------------------------------------------------------
    
    always_comb begin
        data_out = 32'd0;

        unique case (address)
            MISA:       data_out = misa;
            MVENDORID:  data_out = mvendorid;
            MARCHID:    data_out = marchid;
            MIMPID:     data_out = mimpid;
            MHARTID:    data_out = mhartid;
            MSTATUS:    data_out = mstatus;
            MSTATUSH:   data_out = mstatus_h;
            MTVEC:      data_out = mtvec;
            MIP:        data_out = mip;
            MIE:        data_out = mie;
            MCYCLE:     data_out = mcycle_L;
            MCYCLEH:    data_out = mcycle_H;
            MINSTRET:   data_out = minstret_L;
            MINSTRETH:  data_out = minstret_H;
            default:    data_out = 32'd0;
        endcase
    end

endmodule