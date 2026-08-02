module uart (
    input logic     clk,
    input logic     rst_n
);

//------------------------------------------------------------------------------
// Registers and Address Map
//------------------------------------------------------------------------------
    localparam RX_BUFFER            = 3'b000; // Read only, DLAB = 0
    localparam TX_HOLDING           = 3'b000; // Write only, DLAB = 0
    localparam INTERRUPT_ENABLE     = 3'b001; // DLAB = 0
    localparam INTERRUPT_IDENT      = 3'b010; // Read only
    localparam FIFO_CONTROL         = 3'b010; // Write only
    localparam LINE_CONTROL         = 3'b011;
    localparam MODEM_CONTROL        = 3'b100;
    localparam LINE_STATUS          = 3'b101;
    localparam MODEM_STATUS         = 3'b110;
    localparam SCRATCH              = 3'b111;
    localparam DIVISOR_LATCH_LOW    = 3'b000; // DLAB = 1
    localparam DIVISOR_LATCH_HIGH   = 3'b001; // DLAB = 1

    logic [7:0]     rx_buffer_r, tx_holding_r, interrupt_en_r, interrupt_ident_r,
                    fifo_control_r, line_control_r, modem_control_r, line_status_r,
                    modem_status_r, scratch_r;
    logic [15:0]    divisor_r;

//------------------------------------------------------------------------------
// Baud Rate
//------------------------------------------------------------------------------
    // baud_rate = clk_freq / (16 x divisor)
    // divisor = clk_freq / (baud_rate x 16)
    // 16 is the oversampling factor. For each bit period, the clock is pulsed 
    // 16 times and data is sampled halfway through to maximize accuracy.
    // Every time div_cnt wraps is 1/16th of a bit period
    // tick_16x is enabled on div_cnt wrap
    // tick_1x_(rx/tx) is enabled every 16 tick_16x enables (start of next bit period)
    // bit_div_cnt_(rx/tx) counts tick_16x enables from 0 to 15

    logic [15:0]    div_cnt, next_div_cnt;
    logic           tick_16x;
    
    assign next_div_cnt = (div_cnt == divisor_r - 1'b1) ? '0 : div_cnt + 1'b1;
    assign tick_16x     = (div_cnt == '0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) div_cnt <= '0;
        else        div_cnt <= next_div_cnt;
    end

//------------------------------------------------------------------------------
// Receiver
//------------------------------------------------------------------------------
    logic [3:0] bit_div_cnt_rx, next_bit_div_cnt_rx;
    logic       tick_1x_rx;




//------------------------------------------------------------------------------
// Transmitter
//------------------------------------------------------------------------------
    logic [3:0] bit_div_cnt_tx, next_bit_div_cnt_tx;
    logic       tick_1x_tx;

    

endmodule