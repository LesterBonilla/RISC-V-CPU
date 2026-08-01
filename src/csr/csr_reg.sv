import decode_pkg::*;

module csr_reg # (
    parameter int WIDTH                     = 32,
    parameter logic [WIDTH-1:0] RESET_VAL   = '0,
    parameter logic [WIDTH-1:0] WRITE_MASK  = '1
)(
    input logic                 clk,
    input logic                 rst_n,
    input logic                 csr_en,
    input logic                 overwrite_en,
    input csr_op_e              csr_op,
    input logic [WIDTH-1:0]     data_in,

    output logic [WIDTH-1:0]    data_out
);

    logic [WIDTH-1:0] data_r;

    assign data_out = data_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_r <= RESET_VAL;

        end else if (overwrite_en) begin
            data_r <= data_in;

        end else if (csr_en) begin
            unique case (csr_op)
                CSR_NOP: ;
                CSR_RW, CSR_RWI: data_r <= (data_in & WRITE_MASK);
                CSR_RS, CSR_RSI: data_r <= data_r | (data_in & WRITE_MASK);
                CSR_RC, CSR_RCI: data_r <= data_r & ~(data_in & WRITE_MASK);
            endcase
        end
    end

endmodule