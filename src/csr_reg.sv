import csr_pkg::*;

module csr_reg # (
    parameter logic [31:0] RESET_VAL    = 32'd0,
    parameter logic [31:0] WRITE_MASK   = 32'hFFFFFFFF
)(
    input logic         clk,
    input logic         rst_n,
    input logic         en,
    input csr_op_e      csr_op,
    input logic [31:0]  data_in,

    output logic [32:0] data_out
);

    logic [31:0] data_r;

    assign data_out = data_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= RESET_VAL;

        end else if (en) begin
            unique case (csr_op)
                CSR_NOP: ;
                CSR_RW, CSR_RWI: data_out <= (data_in & WRITE_MASK);
                CSR_RS, CSR_RSI: data_out <= data_r | (data_in & WRITE_MASK);
                CSR_RC, CSR_RCI: data_out <= data_r & ~(data_in & WRITE_MASK);
            endcase
        end
    end

endmodule