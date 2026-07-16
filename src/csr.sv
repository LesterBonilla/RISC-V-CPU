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


logic [31:0] misa, mvendorid, marchid, mimpid, mhartid,
             mstatus, mstatush, mtvec, mdeleg, mdelegh, mideleg,
             mip, mie;

assign misa         = {2'b01, 4'b0, 26'b00000000000000000100000000}; // XLEN=32, Only support I extension
assign mvendorid    = 32'd0; // Required, non-commercial implementation
assign marchid      = 32'd0; // Required, not implemented
assign mimpid       = 32'd0; // Required, not implemented
assign mhartid      = 32'd0; // Required, not implemented

    
endmodule