import uart_pkg::*;

module uart_rx #(
    parameter int unsigned FIFO_DEPTH = 16
)(
    input logic         clk,
    input logic         rst_n,
    input logic         tick_16x,
    
    input logic         rx_pin,
    input logic         rx_fifo_rd_en,
    input logic         rx_fifo_flush,

    input uart_config_t rx_config,
    
    output logic        rx_fifo_empty,
    output logic        rx_fifo_full,

    output logic        rx_parity_error,
    output logic        rx_framing_error,
    output logic        rx_break_interrupt,
    output logic        rx_overrun_error,
    output logic        rx_error_in_fifo,
    output logic [7:0]  rx_data_out,

    output logic [$clog2(FIFO_DEPTH):0] rx_fifo_count
);
//------------------------------------------------------------------------------
// Receiver
//------------------------------------------------------------------------------
    // Rx States:
    //  IDLE:       The line is high and no data is being received
    //  START:      Start bit detected (falling edge of synchronized rx_pin)
    //  DATA:       Sample data bits at each bit's midpoint
    //  PARITY:     If parity is enabled, read parity bit
    //  STOP:       Read stop bit
    //  FRAME END:  Package data for FIFO and compute errors. If a start bit
    //              is detected, go to DATA. If break condition, go to BREAK.
    //              Else, go to IDLE.
    //  BREAK:      When the line is held low for longer than one configured frame
    //              (i.e. Start, Data, Parity, Stop, + 1 bit are all zeros), a 
    //              break interrupt occurs (stored in FIFO with its received char)
    //              and the line idles low until the next start bit condition
    //              occurs (a falling edge of rx_pin)
    //
    //  Notes:
    //      start_bit is sampled in START and FRAME END states, and holds otherwise.
    //      stop_bit is sampled in STOP, and holds otherwise.
    //      break_cond reuses the sampled start_bit from FRAME END.
    //
    // The rx_pin is synchronized through a 2-flop synchronizer. This makes sure
    // the value read is stable before acting on it. A falling rx_pin is detected by
    // comparing the previous synchronized value to the current synchronized value.
    //

    // State machine
    uart_state_e    rx_state, next_rx_state;
    logic [3:0]     rx_bit_idx, next_rx_bit_idx;
    logic           start_bit_edge, rx_frame_done, rx_data_done, start_bit, next_start_bit;
    logic           stop_bit, next_stop_bit, break_cond;

    // Clock enables
    logic [3:0]     bit_div_cnt_rx, next_bit_div_cnt_rx;
    logic           tick_1x_rx, rx_mid_bit;

    // Synchronizing
    logic           rx_sync1, rx_sync2, rx_sync2_prev, rx_falling_edge, rx_sample;

    // Frame data
    logic [7:0]     rx_shift_register, next_rx_shift_register, formatted_data;
    logic           parity_bit, next_parity_bit, calculated_parity, break_int, parity_error;
    logic           rx_error_in_fifo_entry_in, rx_error_in_fifo_entry_out;
    logic [$clog2(FIFO_DEPTH):0] rx_fifo_error_count;

    // FIFO signals
    logic rx_fifo_wr_en;
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

    // The line idles at (rx_pin == 1) for normal operation and (rx_pin == 0) for break
    // Valid start bit == 0
    // Valid stop bit == 1
    
    assign start_bit_edge   = ((rx_state == UART_IDLE || rx_state == UART_BREAK) && rx_falling_edge);
    assign break_cond       = ((rx_state == UART_FRAME_END) && !stop_bit && !start_bit && (formatted_data == 8'd0));

    always_comb begin
        next_rx_state = rx_state;
        unique case (rx_state)
            UART_IDLE:      if (start_bit_edge)                         next_rx_state = UART_START;
            UART_START:     if (tick_1x_rx && !start_bit)               next_rx_state = UART_DATA;
                            else if (tick_1x_rx)                        next_rx_state = UART_IDLE;
            UART_DATA:      if (tick_1x_rx && rx_data_done)             next_rx_state = UART_STOP;
            UART_PARITY:    if (tick_1x_rx)                             next_rx_state = UART_STOP; 
            UART_STOP:      if (tick_1x_rx)                             next_rx_state = UART_FRAME_END;
            UART_FRAME_END: if (tick_1x_rx && stop_bit && !start_bit)   next_rx_state = UART_DATA;
                            else if (tick_1x_rx && break_cond)          next_rx_state = UART_BREAK;
                            else if (tick_1x_rx)                        next_rx_state = UART_IDLE;
            UART_BREAK:     if (start_bit_edge)                         next_rx_state = UART_START;
            default:                                                    next_rx_state = UART_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_state <= UART_IDLE;
        else        rx_state <= next_rx_state;
    end

    //--------------------------------------------------------------------------
    // Received Bit Counter
    //--------------------------------------------------------------------------
    
    always_comb begin
        unique case (rx_config.char_length)
            LENGTH_5: rx_data_done = (rx_bit_idx == 4'd4);
            LENGTH_6: rx_data_done = (rx_bit_idx == 4'd5);
            LENGTH_7: rx_data_done = (rx_bit_idx == 4'd6);
            LENGTH_8: rx_data_done = (rx_bit_idx == 4'd7);
            default:  rx_data_done = '0;
        endcase
    end

    always_comb begin
        next_rx_bit_idx = rx_bit_idx;

        if (tick_1x_rx) begin
            if (next_rx_state == UART_DATA) next_rx_bit_idx = '0;
            else if (rx_state == UART_DATA) next_rx_bit_idx = rx_bit_idx + 1'b1;
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_bit_idx <= '0;
        else        rx_bit_idx <= next_rx_bit_idx;
    end

    //--------------------------------------------------------------------------
    // Frame Data
    //--------------------------------------------------------------------------

    assign next_rx_shift_register = ((rx_state == UART_DATA || rx_state == UART_START) && rx_mid_bit) ?
                                    {rx_sample, rx_shift_register[7:1]} :
                                    (rx_shift_register);

    assign next_start_bit   = ((rx_state == UART_START || rx_state == UART_FRAME_END) && rx_mid_bit) ? rx_sample : start_bit;
    assign next_stop_bit    = ((rx_state == UART_STOP) && rx_mid_bit)     ? rx_sample : stop_bit;
    assign next_parity_bit  = ((rx_state == UART_PARITY) && rx_mid_bit)   ? rx_sample : parity_bit;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_shift_register   <= '0;
            stop_bit            <= '0;
            parity_bit          <= '0;
            start_bit           <= '0;
        end else begin
            rx_shift_register   <= next_rx_shift_register;
            stop_bit            <= next_stop_bit;
            parity_bit          <= next_parity_bit;
            start_bit           <= next_start_bit;
        end
    end

    always_comb begin
        unique case (rx_config.char_length)
            LENGTH_5: formatted_data = {3'b0, rx_shift_register[7:3]};
            LENGTH_6: formatted_data = {2'b0, rx_shift_register[7:2]};
            LENGTH_7: formatted_data = {1'b0, rx_shift_register[7:1]};
            LENGTH_8: formatted_data = (rx_shift_register);
            default:  formatted_data = '0;
        endcase
    end

    //--------------------------------------------------------------------------
    // Error Checking and FIFO Data
    //--------------------------------------------------------------------------

    assign rx_frame_done        = (rx_state == UART_FRAME_END && tick_1x_rx);
    assign rx_fifo_wr_en        = (rx_frame_done);

    assign rx_data_out          = rx_fifo_entry_out.data;
    assign rx_parity_error      = rx_fifo_entry_out.parity_error;
    assign rx_framing_error     = rx_fifo_entry_out.framing_error;
    assign rx_break_interrupt   = rx_fifo_entry_out.break_interrupt;
    assign rx_overrun_error     = (rx_frame_done && rx_fifo_full && !rx_fifo_rd_en);
    assign rx_error_in_fifo     = (rx_fifo_error_count != '0);

    assign rx_fifo_entry_in.data            = formatted_data;
    assign rx_fifo_entry_in.parity_error    = parity_error;
    assign rx_fifo_entry_in.framing_error   = !stop_bit;
    assign rx_fifo_entry_in.break_interrupt = break_cond;
    assign rx_error_in_fifo_entry_in        = (rx_fifo_wr_en && !rx_fifo_full) && (parity_error || !stop_bit || break_cond);
    assign rx_error_in_fifo_entry_out       = (rx_fifo_rd_en && !rx_fifo_empty) && 
                                              (rx_fifo_entry_out.parity_error || rx_fifo_entry_out.framing_error ||rx_fifo_entry_out.break_interrupt);

    always_comb begin
        parity_error        = 1'b0;
        calculated_parity   = ^{formatted_data, parity_bit};

        if (rx_config.parity_en) begin
            unique case (rx_config.parity_type)
                PARITY_ODD:     parity_error = (calculated_parity != 1'b1);
                PARITY_EVEN:    parity_error = (calculated_parity != 1'b0);
                PARITY_STICK_1: parity_error = (parity_bit != 1'b1);
                PARITY_STICK_0: parity_error = (parity_bit != 1'b0);
                default:        parity_error = (1'b0);
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            rx_fifo_error_count <= '0;
        else if (rx_fifo_flush) 
            rx_fifo_error_count <= '0;
        else 
            rx_fifo_error_count <= rx_fifo_error_count 
                                   + rx_error_in_fifo_entry_in
                                   - rx_error_in_fifo_entry_out;    
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