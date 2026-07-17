import decode_pkg::*;
import pipeline_pkg::*;
import csr_pkg::*;

module csr (
    input logic         clk,
    input logic         rst_n,
    
    input logic [31:0]  data_in,
    input logic [11:0]  address,
    input csr_op_e      csr_op,

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

    csr_reg # (.RESET_VAL = MSTATUS_RESET, .WRITE_MASK = MSTATUS_WR_MASK) mstatus_reg (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (mstatus_en),
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
            default:    data_out = 32'd0;
        endcase
    end

endmodule