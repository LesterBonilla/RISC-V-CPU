import decode_pkg::*;
import pipeline_pkg::*;
import csr_pkg::*;

module csr (
    input logic             clk,
    input logic             rst_n,
    
    input logic [31:0]      data_in,
    input logic [11:0]      address,
    input csr_op_e          csr_op,

    input logic             inst_ret,

    input logic             trap,
    input logic             mret,
    input logic [31:0]      mepc_in,
    input logic [31:0]      mcause_in,
    input mip_mie_csr_t     mip_in,

    output mip_mie_csr_t    mie_out,
    output mstatus_csr_t    mstatus_out,
    output logic [31:0]     mtvec_out,
    output logic [31:0]     mepc_out,

    output logic [31:0]     data_out
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
    mstatus_csr_t   mstatus, next_mstatus;
    mstatush_csr_t  mstatus_h;
    logic           mstatus_csr_en, mstatus_hw_en;

    assign mstatus_csr_en   = (address == MSTATUS);
    assign mstatus_h        = '0;
    assign mstatus_hw_en    = trap || mret;
    assign mstatus_out      = mstatus;

    always_comb begin : mstatus_input_mux
        next_mstatus = data_in;
        next_mstatus.MPP = 2'b11;

        if (trap && mret) begin
            next_mstatus        = mstatus;
            next_mstatus.MPIE   = mstatus.MPIE;
            next_mstatus.MPP    = 2'b11; 
            next_mstatus.MIE    = 1'b0;

        end else if (trap) begin
            next_mstatus        = mstatus;
            next_mstatus.MPIE   = mstatus.MIE;
            next_mstatus.MPP    = 2'b11; // Only M-mode, written for completeness
            next_mstatus.MIE    = 1'b0;
        
        end else if (mret) begin
            // TODO: Privilege is set to mstatus.MPP
            next_mstatus        = mstatus;
            next_mstatus.MIE    = mstatus.MPIE;
            next_mstatus.MPIE   = 1'b1;
            next_mstatus.MPP    = 2'b11;
        end
    end

    csr_reg # (.RESET_VAL(MSTATUS_RESET), .WRITE_MASK(MSTATUS_WR_MASK)) mstatus_reg (
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_en         (mstatus_csr_en),
        .overwrite_en   (mstatus_hw_en),
        .csr_op         (csr_op),
        .data_in        (next_mstatus),
        .data_out       (mstatus)
    );

//------------------------------------------------------------------------------
// Machine Trap-Vector Base-Address (mtvec) Register
//------------------------------------------------------------------------------
    mtvec_csr_t mtvec;
    localparam logic [31:0] MTVEC_ADDR = 32'h00010000;
    localparam logic [29:0] MTVEC_BASE = MTVEC_ADDR[31:2];

    assign mtvec_out    = mtvec;

    csr_reg # (.RESET_VAL({MTVEC_MODE_DIRECT, MTVEC_BASE}), .WRITE_MASK(32'h7FFFFFFF)) mtvec_reg (
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_en         (address == MTVEC),
        .overwrite_en   (1'b0),
        .csr_op         (csr_op),
        .data_in        (data_in),
        .data_out       (mtvec)
    );

//------------------------------------------------------------------------------
// Machine Trap Delegation (medeleg and mideleg) Registers
//------------------------------------------------------------------------------
    // Do not exist if S-mode not implemented

//------------------------------------------------------------------------------
// Machine Interrupt (mip and mie) Registers
//------------------------------------------------------------------------------
    // MIP is read-only, bits are cleared through interfacing with
    // the relevant peripheral. Only MEI, MTI, and MSI are supported.
    // MIE is writable to MEI, MTI, and MSI. All other bits are read-only 0.
    // Interrupt priority is MEI > MSI > MTI (see wb_stage)
    mip_mie_csr_t mip, mie;

    assign mip      = mip_in;
    assign mie_out  = mie;

    csr_reg # (.WRITE_MASK(MIE_WR_MASK)) mie_reg (
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_en         (address == MIE),
        .overwrite_en   (1'b0),
        .csr_op         (csr_op),
        .data_in        (data_in),
        .data_out       (mie)
    );

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
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_en         (is_mcycle),
        .overwrite_en   (!is_mcycle),
        .csr_op         (csr_op),
        .data_in        (next_mcycle),
        .data_out       (mcycle)
    );

    csr_reg # (.WIDTH(64)) minstret_reg (
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_en         (is_minstret),
        .overwrite_en   (inc_minstret),
        .csr_op         (csr_op),
        .data_in        (next_minstret),
        .data_out       (minstret)
    );

//------------------------------------------------------------------------------
// Machine Counter-Enable (mcounteren) Register
//------------------------------------------------------------------------------
    // Does not exist if U-mode not supported

//------------------------------------------------------------------------------
// Machine Counter-Inhibit (mcountinhibit) Register
//------------------------------------------------------------------------------
    // Does not need to be implemented, will act as read-only 0.
    // TODO: This register, mcounteren, and the HPMs above can all exist
    // within their own csr_mcount module. It would be easier to implement
    // the registers directly instead of reusing csr_reg.

//------------------------------------------------------------------------------
// Machine Scratch (mscratch) Register
//------------------------------------------------------------------------------
    logic [31:0] mscratch;

    csr_reg mscratch_reg (
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_en         (address == MSCRATCH),
        .overwrite_en   (1'b0),
        .csr_op         (csr_op),
        .data_in        (data_in),
        .data_out       (mscratch)
    );

//------------------------------------------------------------------------------
// Machine Exception Program Counter (mepc) Register
//------------------------------------------------------------------------------
    logic [31:0] mepc, next_mepc;

    assign next_mepc = (trap) ? (mepc_in & ~(32'd3)) : data_in;
    assign mepc_out  = mepc;   

    csr_reg # (.WRITE_MASK(32'hFFFFFFFC)) mepc_reg ( // Lower two bits are always 0
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_en         (address == MEPC),
        .overwrite_en   (trap),
        .csr_op         (csr_op),
        .data_in        (next_mepc),
        .data_out       (mepc)
    );

//------------------------------------------------------------------------------
// Machine Cause (mcause) Register
//------------------------------------------------------------------------------
    // When a trap is taken into M-mode, mcause is written with the exception code.
    mcause_csr_t mcause, next_mcause;

    assign next_mcause = (trap) ? mcause_in : data_in;

    csr_reg mcause_reg (
        .clk            (clk),
        .rst_n          (rst_n),
        .csr_en         (address == MCAUSE),
        .overwrite_en   (trap),
        .csr_op         (csr_op),
        .data_in        (next_mcause),
        .data_out       (mcause)
    );

//------------------------------------------------------------------------------
// Machine Trap Value (mtval) Register
//------------------------------------------------------------------------------
    // On a trap, mtval is set to zero or written with exception-specific information.
    // If no exceptions set mtval to a non-zero value, mtval is read-only 0.

//------------------------------------------------------------------------------
// Machine Configuration Pointer (mconfigptr) Register
//------------------------------------------------------------------------------
    // Read-only 0 if not implemented. Points to address where a configuration
    // data structure is held. The data structure is not standardized.

//------------------------------------------------------------------------------
// Machine Environment Configuration (menvcfg) Register
//------------------------------------------------------------------------------
    // If U-mode is not supported, menvcfg/menvcfgh do not exist.

//------------------------------------------------------------------------------
// Machine Security Configuration (mseccfg) Register
//------------------------------------------------------------------------------
    // Exists if any extension adds a field to it.

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
            MSCRATCH:   data_out = mscratch;
            MEPC:       data_out = mepc;
            MCAUSE:     data_out = mcause;
            default:    data_out = 32'd0;
        endcase
    end

endmodule