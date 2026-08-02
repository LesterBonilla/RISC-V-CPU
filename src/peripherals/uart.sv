module uart (
    input logic     clk,
    input logic     rst_n,

    input logic     rx_pin
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
    assign tick_16x     = (next_div_cnt == '0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) div_cnt <= '0;
        else        div_cnt <= next_div_cnt;
    end

//------------------------------------------------------------------------------
// Receiver
//------------------------------------------------------------------------------
    // Rx States:
    //  IDLE:   The line is high and no data is being received
    //  START:  Start bit detected (falling edge of synchronized rx_pin)
    //  DATA:   Sample data bits at each bit's midpoint
    //  PARITY: If parity is enabled, read parity bit
    //  STOP:   Read one or two stop bits, return to idle
    //
    // The rx_pin is synchronized through a 2-flop synchronizer. This makes sure
    // the value read is stable before acting on it. A falling rx_pin is detected by
    // comparing the previous synchronized value to the current synchronized value.

    // State machine
    rx_state_e  rx_state, next_rx_state;
    logic       start_bit_edge;

    // Clock Enables
    logic [3:0] bit_div_cnt_rx, next_bit_div_cnt_rx;
    logic       tick_1x_rx, rx_mid_bit;

    // Synchronizing
    logic       rx_sync1, rx_sync2, rx_sync2_prev, rx_falling_edge;

    //--------------------------------------------------------------------------
    // Rx Clock Enables
    //--------------------------------------------------------------------------
    
    assign tick_1x_rx = (next_bit_div_cnt_rx == '0);
    assign rx_mid_bit = (bit_div_cnt_rx == 4'd7);

    always_comb begin
        next_bit_div_cnt_rx = bit_div_cnt_rx;

        if (start_bit_edge) next_bit_div_cnt_rx = '0;
        else if (tick_16x)  next_bit_div_cnt_rx = (bit_div_cnt_rx == 4'd15) ? '0 : next_bit_div_cnt_rx + 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) bit_div_cnt_rx <= '0;
        else        bit_div_cnt_rx <= next_bit_div_cnt_rx;
    end

    //--------------------------------------------------------------------------
    // Rx_pin Synchronization and Falling Edge Detection
    //--------------------------------------------------------------------------

    assign rx_falling_edge = (!rx_sync2 && rx_sync2_prev);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1        <= '0;
            rx_sync2        <= '0;
            rx_sync2_prev   <= '0;
        end else begin
            rx_sync1        <= rx_pin;
            rx_sync2        <= rx_sync1;
            rx_sync2_prev   <= rx_sync2;
        end
    end

    //--------------------------------------------------------------------------
    // Rx State Machine
    //--------------------------------------------------------------------------

    typedef enum logic [2:0] { 
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_PARITY,
        RX_STOP
    } rx_state_e;
    
    assign start_bit_edge = (rx_falling_edge && (rx_state == RX_IDLE));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_state <= RX_IDLE;
        else        rx_state <= next_rx_state;
    end

    always_comb begin
        next_rx_state = RX_IDLE;

        unique case (rx_state)
            RX_IDLE:    begin
                if (start_bit_edge) next_rx_state = RX_START;
            end
            RX_START:   begin
                ;
            end
            RX_DATA:    begin
                ;
            end
            RX_PARITY:  begin
                ;
            end
            RX_STOP:    begin
                ;
            end
            default: ;
        endcase
    end

//------------------------------------------------------------------------------
// Transmitter
//------------------------------------------------------------------------------
    logic [3:0] bit_div_cnt_tx, next_bit_div_cnt_tx;
    logic       tick_1x_tx;

    assign next_bit_div_cnt_tx  = (bit_div_cnt_tx == 4'd15) ? '0 : bit_div_cnt_tx + 1'b1;
    assign tick_1x_tx           = (next_bit_div_cnt_tx == '0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) bit_div_cnt_tx <= '0;
        else        bit_div_cnt_tx <= next_bit_div_cnt_tx;
    end

endmodule