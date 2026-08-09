module de10lite_top(
    input logic clk50MHz,
    input logic rst_n,
    input logic rx_pin,
    output logic tx_pin,
    output logic [31:0] instruction_out,
    output logic done,
    output logic done_type
);

//------------------------------------------------------------------------------
// PLL
//------------------------------------------------------------------------------
    // logic core_clk, locked;

    // pll pll_inst(
    //     .areset(!rst_n),
    //     .inclk0(clk50MHz),
    //     .c0(core_clk),
    //     .locked(locked)
    // );

//------------------------------------------------------------------------------
// Core
//------------------------------------------------------------------------------
    core #(.MEM_SIZE_WORDS(1024*32)) core_inst (
        .clk    (clk50MHz),
        .rst_n  (rst_n),
        .rx_pin (rx_pin),
        .tx_pin (tx_pin),
        .instruction_out(instruction_out),
        .done   (done),
        .done_type (done_type)
    );

endmodule