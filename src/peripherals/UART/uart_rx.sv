module uart_rx #(
    parameter int unsigned FIFO_DEPTH = 16
)(
    input logic         clk,
    input logic         rst_n,
    input logic         tick_16x,
    
    input logic         rx_pin,
    input logic         rx_fifo_rd_en,
    input logic         rx_fifo_flush,
    
    output logic        rx_fifo_empty,
    output logic        rx_fifo_full,

    output logic        rx_parity_error,
    output logic        rx_framing_error,
    output logic        rx_break_interrupt,
    output logic        rx_overrun_error,
    output logic [7:0]  rx_data_out,

    output logic [$clog2(FIFO_DEPTH):0] rx_fifo_count
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
    logic       stop_bit, next_stop_bit, parity_bit, next_parity_bit;

    // FIFO signals
    typedef struct packed {
        logic [7:0] data;
        logic       parity_error;
        logic       framing_error;
        logic       break_interrupt;
    } rx_fifo_entry_t;

    rx_fifo_entry_t rx_fifo_entry_in, rx_fifo_entry_out;

    //--------------------------------------------------------------------------
    // Rx Clock Enables
    //--------------------------------------------------------------------------
    
    assign tick_1x_rx = (bit_div_cnt_rx == 4'd15);
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
    
    assign start_bit_edge   = (rx_falling_edge && (rx_state == RX_IDLE || rx_state == RX_STOP));
    assign rx_frame_done    = (rx_state == RX_STOP && tick_1x_rx);

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
                if (tick_1x_rx) next_rx_state = RX_STOP;
            end
            RX_STOP:    begin
                if (tick_1x_rx) begin
                    if (start_bit_edge) next_rx_state = RX_START;
                    else                next_rx_state = RX_IDLE;
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
    // Frame Data
    //--------------------------------------------------------------------------

    assign next_rx_shift_register = ((rx_state == RX_DATA || rx_state == RX_START) && rx_mid_bit)   ?
                                    {rx_sample, rx_shift_register[7:1]}     :
                                    rx_shift_register;

    assign next_stop_bit    = ((rx_state == RX_STOP) && rx_mid_bit)     ? rx_sample : stop_bit;
    assign next_parity_bit  = ((rx_state == RX_PARITY) && rx_mid_bit)   ? rx_sample : parity_bit;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_register   <= '0;
            stop_bit            <= '0;
            parity_bit          <= '0;
        end else begin
            rx_shift_register   <= next_rx_shift_register;
            stop_bit            <= next_stop_bit;
            parity_bit          <= next_parity_bit;
        end
    end

    //--------------------------------------------------------------------------
    // Error Checking and FIFO Data
    //--------------------------------------------------------------------------

    assign rx_fifo_wr_en       = rx_frame_done;

    assign rx_data_out         = rx_fifo_entry_out.data;
    assign rx_parity_error     = rx_fifo_entry_out.parity_error;
    assign rx_framing_error    = rx_fifo_entry_out.framing_error;
    assign rx_break_interrupt  = rx_fifo_entry_out.break_interrupt;
    assign rx_overrun_error    = 1'b0; // TODO: Calculate this

    always_comb begin
        rx_fifo_entry_in = '0;

        // Data
        rx_fifo_entry_in.data = rx_shift_register;
        // Parity Error: TODO: Check the parity configuration, calculate parity
        // Framing Error
        rx_fifo_entry_in.framing_error = (stop_bit) ? 1'b0 : 1'b1;
        // Break Interrupt: TODO: Check for a full frame of zeros, including parity
    end

    //--------------------------------------------------------------------------
    // Rx FIFO
    //--------------------------------------------------------------------------

    synch_fifo # (.WIDTH($bits(rx_fifo_entry_t)), .DEPTH(FIFO_DEPTH)) synch_fifo_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .flush      (rx_fifo_flush),
        .write_en   (rx_fifo_wr_en),
        .read_en    (rx_fifo_rd_en),
        .data_in    (rx_fifo_entry_in),
        .empty      (rx_fifo_empty),
        .full       (rx_fifo_full),
        .data_out   (rx_fifo_entry_out),
        .count      (rx_fifo_count)
    );

endmodule