module de10lite_top(
    input logic clk50MHz,
    input logic rst_n,
    input logic rx_pin,
    output logic tx_pin
);

//------------------------------------------------------------------------------
// PLL
//------------------------------------------------------------------------------
    logic core_clk, locked;

    pll pll_inst(
        .areset(!rst_n),
        .inclk0(clk50MHz),
        .c0(core_clk),
        .locked(locked)
    );

//------------------------------------------------------------------------------
// Core
//------------------------------------------------------------------------------
    core #(.MEM_SIZE_WORDS(1024*32)) core_inst (
        .clk    (core_clk),
        .rst_n  (rst_n && locked),
        .rx_pin (rx_pin),
        .tx_pin (tx_pin)
    );

endmodule