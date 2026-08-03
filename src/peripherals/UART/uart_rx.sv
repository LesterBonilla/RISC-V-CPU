module uart_rx #(
    parameter int unsigned FIFO_WIDTH   = 8,
    parameter int unsigned FIFO_DEPTH   = 16
)(
    input logic     clk,
    input logic     rst_n,
    input logic     tick_16x,
    
    input logic     rx_pin,
    input logic     rx_fifo_rd_en,
    input logic     rx_fifo_flush,
    
    output logic    rx_fifo_empty,
    output logic    rx_fifo_full,

    output logic [$clog2(FIFO_DEPTH):0]     rx_fifo_count,
    output logic [$clog2(FIFO_WIDTH)-1:0]   rx_fifo_data_out
);
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
    //
    // When the stop state is done, push the data to the FIFO. TODO: Check for errors.

    // State machine
    typedef enum logic [2:0] { 
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_PARITY,
        RX_STOP
    } rx_state_e;

    rx_state_e  rx_state, next_rx_state;
    logic [3:0] rx_bit_count, next_rx_bit_count;
    logic       start_bit_edge, start_valid, rx_frame_done, rx_data_done;

    // Clock enables
    logic [3:0] bit_div_cnt_rx, next_bit_div_cnt_rx;
    logic       tick_1x_rx, rx_mid_bit;

    // Synchronizing
    logic       rx_sync1, rx_sync2, rx_sync2_prev, rx_falling_edge, rx_sample;

    // Shift register
    logic [7:0] rx_shift_register, next_rx_shift_register;

    // FIFO signals
    logic [FIFO_WIDTH-1:0]  rx_fifo_data_in;

    //--------------------------------------------------------------------------
    // Rx Clock Enables
    //--------------------------------------------------------------------------
    
    assign tick_1x_rx = (next_bit_div_cnt_rx == '0);
    assign rx_mid_bit = (bit_div_cnt_rx == 4'd7);

    always_comb begin
        next_bit_div_cnt_rx = bit_div_cnt_rx;

        if (start_bit_edge) next_bit_div_cnt_rx = '0;
        else if (tick_16x)  next_bit_div_cnt_rx = (bit_div_cnt_rx == 4'd15) ? '0 : bit_div_cnt_rx + 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) bit_div_cnt_rx <= '0;
        else        bit_div_cnt_rx <= next_bit_div_cnt_rx;
    end

    //--------------------------------------------------------------------------
    // Rx_pin Synchronization and Falling Edge Detection
    //--------------------------------------------------------------------------

    assign rx_falling_edge  = (!rx_sync2 && rx_sync2_prev);
    assign rx_sample        = rx_sync2;

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

    localparam STOP_BIT_VALUE   = 1'b1;
    localparam START_BIT_VALUE  = 1'b0;
    
    assign start_bit_edge   = (rx_falling_edge && (rx_state == RX_IDLE));
    // TODO: rx_frame_done will likely need some error detection
    assign rx_frame_done    = (rx_state == RX_STOP && next_rx_state == RX_IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_state <= RX_IDLE;
        else        rx_state <= next_rx_state;
    end

    always_comb begin
        next_rx_state = rx_state;

        unique case (rx_state)
            RX_IDLE:    begin
                if (start_bit_edge) next_rx_state = RX_START;
            end
            RX_START:   begin
                if (tick_1x_rx) begin
                    if (rx_shift_register[7] == START_BIT_VALUE)
                        next_rx_state = RX_DATA;
                    else 
                        next_rx_state = RX_IDLE;
                end
            end
            RX_DATA:    begin
                if (tick_1x_rx) begin
                    if (rx_data_done) next_rx_state = RX_STOP;
                end                
            end
            RX_PARITY:  begin
                ; // Skipped for now
            end
            RX_STOP:    begin
                // Only one stop bit for now
                // TODO: Add failure condition to go back to IDLE
                if (tick_1x_rx) begin
                    if (rx_sample == STOP_BIT_VALUE)
                        next_rx_state = RX_IDLE;
                end
            end
            default: ;
        endcase
    end

    //--------------------------------------------------------------------------
    // Received Bit Counter
    //--------------------------------------------------------------------------
    
    assign rx_data_done = (rx_bit_count == 4'd7); // TODO: Make this configurable, hard coded for development

    always_comb begin
        next_rx_bit_count = rx_bit_count;

        if ((rx_state == RX_START) && tick_1x_rx)
            next_rx_bit_count = '0;
        else if ((rx_state == RX_DATA) && tick_1x_rx)
            next_rx_bit_count = rx_bit_count + 1'b1;
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_bit_count <= '0;
        else        rx_bit_count <= next_rx_bit_count;
    end

    //--------------------------------------------------------------------------
    // Rx Shift Register
    //--------------------------------------------------------------------------

    assign next_rx_shift_register = ((rx_state == RX_DATA || rx_state == RX_START) && rx_mid_bit)   ?
                                    {rx_sample, rx_shift_register[7:1]}     :
                                    rx_shift_register;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_register <= '0;
        end else begin
            rx_shift_register <= next_rx_shift_register;
        end
    end

    //--------------------------------------------------------------------------
    // Rx FIFO
    //--------------------------------------------------------------------------

    synch_fifo # (.WIDTH(FIFO_WIDTH), .DEPTH(FIFO_DEPTH)) synch_fifo_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .flush      (rx_fifo_flush),
        .write_en   (rx_fifo_wr_en),
        .read_en    (rx_fifo_rd_en),
        .data_in    (rx_fifo_data_in),
        .empty      (rx_fifo_empty),
        .full       (rx_fifo_full),
        .data_out   (rx_fifo_data_out),
        .count      (rx_fifo_count)
    );

    // TODO: Check when FIFO is full. Is result discarded? What error signal is set?
    assign rx_fifo_data_in  = rx_shift_register;
    assign rx_fifo_wr_en    = rx_frame_done;

endmodule