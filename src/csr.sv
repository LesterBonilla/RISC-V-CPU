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
            default:    data_out = 32'd0;
        endcase
    end

//------------------------------------------------------------------------------
// Writing
//------------------------------------------------------------------------------

    // always_ff @(posedge clk) begin
    //     if (address == EXAMPLE_ADDRESS) begin
    //         unique case (csr_op)
    //             CSR_NOP: ;
    //             CSR_RW, CSR_RWI: example_reg <= data_in;
    //             CSR_RS, CSR_RSI: example_reg <= example_reg & data_in;
    //             CSR_RC, CSR_RCI: example_reg <= example_reg & ~data_in;
    //         endcase
    //     end
    // end


endmodule