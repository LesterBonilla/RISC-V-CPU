import uart_pkg::*;

module uart_tx #(
    parameter int unsigned FIFO_DEPTH = 16
)(
    input logic         clk,
    input logic         rst_n,
    input logic         baud_16x_ce,

    input logic         tx_fifo_wr_en,
    input logic         tx_fifo_flush,
    input logic [7:0]   tx_data_in,

    input uart_config_t tx_config,

    output logic        tx_pin,
    output logic        tx_fifo_empty,
    output logic        tx_fifo_full,

    output logic [$clog2(FIFO_DEPTH):0] tx_fifo_count
);
//------------------------------------------------------------------------------
// Transmitter
//------------------------------------------------------------------------------
    // Tx States:
    //  IDLE:   Nothing to send, keeps line high. When data available, go to START
    //  START:  Send start bit, low. Go to DATA
    //  DATA:   Send as many data bits as configured. Go to PARITY or STOP
    //  PARITY: If enabled, send parity bit
    //  STOP:   Send stop bit, high. Optionally two stop bits.
    //          If more data to send, go to START, else go to IDLE.
    //
    //  The states transition on baud_ce. 


    // Clock enables
    logic [3:0]     over_sample_cnt, next_oversample_cnt;
    logic           baud_ce;

    // State machine
    uart_state_e    tx_state, next_tx_state;
    logic           data_available, data_done;

    // Bit idx counter
    logic [2:0]     bit_idx, next_bit_idx;

    // Stop and Parity
    logic           two_stops, next_two_stops, parity_bit, next_parity_bit;

    // Data transmission and data shift register
    logic [7:0]     data_shift_reg, next_data_shift_reg;
    logic           next_tx_pin;

    // FIFO
    logic [7:0]     tx_fifo_data_out;
    logic           tx_fifo_rd_en;

    //--------------------------------------------------------------------------
    // Tx Clock Enables
    //--------------------------------------------------------------------------
    // baud_16x_ce: Enabled every divisor clks to implement 16 x baud_rate
    // baud_ce:     Enabled every 16 baud_16x_ce to implement baud_rate

    assign baud_ce              = (over_sample_cnt == 4'd15);
    assign next_oversample_cnt  = (baud_16x_ce) ? 
                                  (over_sample_cnt == 4'd15) ? '0 : over_sample_cnt + 4'd1 :
                                  (over_sample_cnt);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) over_sample_cnt <= '0;
        else        over_sample_cnt <= next_oversample_cnt;
    end

    //--------------------------------------------------------------------------
    // State Machine
    //--------------------------------------------------------------------------
    // data_available:  There is data in the FIFO to be sent
    // data_done:       Character_Length bits have been sent
    // two_stops:       True if tx_config.stop_bit is true and first bit is being sent

    assign data_available = !tx_fifo_empty;

    always_comb begin
        next_tx_state = tx_state;
        unique case (tx_state)
            UART_IDLE:      if (data_available)                     next_tx_state = UART_START;
            UART_START:                                             next_tx_state = UART_DATA;
            UART_DATA:      if (data_done && tx_config.parity_en)   next_tx_state = UART_PARITY;
                            else if (data_done)                     next_tx_state = UART_STOP;
            UART_PARITY:                                            next_tx_state = UART_STOP;
            UART_STOP:      if (two_stops)                          next_tx_state = UART_STOP;
                            else if (data_available)                next_tx_state = UART_START;
                            else                                    next_tx_state = UART_IDLE;
            default:                                                next_tx_state = UART_IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         tx_state <= UART_IDLE;
        else if (baud_ce)   tx_state <= next_tx_state;
    end

    //--------------------------------------------------------------------------
    // Bit IDX Counter
    //--------------------------------------------------------------------------
    // bit_idx:     Counts the index of data bits shifted out
    
    always_comb begin
        unique case (tx_config.char_length)
            LENGTH_5: data_done = (bit_idx == 4'd4);
            LENGTH_6: data_done = (bit_idx == 4'd5);
            LENGTH_7: data_done = (bit_idx == 4'd6);
            LENGTH_8: data_done = (bit_idx == 4'd7);
            default:  data_done = '0;
        endcase
    end

    always_comb begin
        if (tx_state == UART_DATA)          next_bit_idx = bit_idx + 1'b1;
        else if (tx_state == UART_START)    next_bit_idx = '0;
        else                                next_bit_idx = bit_idx;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         bit_idx <= '0;
        else if (baud_ce)   bit_idx <= next_bit_idx;
    end

    //--------------------------------------------------------------------------
    // Stop and Parity
    //--------------------------------------------------------------------------
    // Set parity bit and two_stops at start of frame transmission

    always_comb begin
        next_two_stops = two_stops;

        if (baud_ce) begin
            if (tx_state == UART_STOP && two_stops) next_two_stops = 1'b0;
            else if (tx_state == UART_START)        next_two_stops = tx_config.stop_bit;
        end
    end

    always_comb begin
        next_parity_bit = parity_bit;

        if (baud_ce && (tx_state == UART_START) && tx_config.parity_en) begin
            unique case (tx_config.parity_type)
                PARITY_ODD:     next_parity_bit = ^data_shift_reg;
                PARITY_EVEN:    next_parity_bit = ~(^data_shift_reg);
                PARITY_STICK_1: next_parity_bit = 1'b1;
                PARITY_STICK_0: next_parity_bit = 1'b1;
                default:        next_parity_bit = '0;
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            two_stops   <= '0;
            parity_bit  <= '0;
        end else begin    
            two_stops   <= next_two_stops;
            parity_bit  <= next_parity_bit;
        end
    end

    //--------------------------------------------------------------------------
    // Shift Register
    //--------------------------------------------------------------------------
    // Load data_shift_reg when next state is START
    // Shift next bit into LSB, until data_done is true

    assign tx_fifo_rd_en = (next_tx_state == UART_START);

    always_comb begin
        next_data_shift_reg = data_shift_reg;

        if (baud_ce) begin
            if (next_tx_state == UART_START) 
                next_data_shift_reg = tx_fifo_data_out;
            else if (tx_state == UART_DATA || tx_state == UART_START) 
                next_data_shift_reg = {1'b0, data_shift_reg[7:1]};
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) data_shift_reg <= '0;
        else        data_shift_reg <= next_data_shift_reg;
    end

    //--------------------------------------------------------------------------
    // Transmission
    //--------------------------------------------------------------------------
    localparam logic STOP_BIT_VALUE = 1'b1;
    localparam logic START_BIT_VALUE = 1'b0;
    localparam logic IDLE_BIT_VALUE = 1'b1;

    always_comb begin
        next_tx_pin = 1'b1;

        if (baud_ce) begin
            unique case (tx_state)
                UART_IDLE:      if (next_tx_state == UART_START)        next_tx_pin = START_BIT_VALUE;
                                else                                    next_tx_pin = IDLE_BIT_VALUE;
                UART_START:                                             next_tx_pin = data_shift_reg[0];
                UART_DATA:      if (next_tx_state == UART_PARITY)       next_tx_pin = parity_bit;
                                else if (data_done)                     next_tx_pin = STOP_BIT_VALUE;
                                else                                    next_tx_pin = data_shift_reg[0];
                UART_PARITY:                                            next_tx_pin = STOP_BIT_VALUE;
                UART_STOP:      if (next_tx_state == UART_STOP)         next_tx_pin = STOP_BIT_VALUE;
                                else if (next_tx_state == UART_START)   next_tx_pin = START_BIT_VALUE;
                                else                                    next_tx_pin = IDLE_BIT_VALUE;
                default:                                                next_tx_pin = IDLE_BIT_VALUE;
            endcase
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) tx_pin = 1'b1;
        else        tx_pin = next_tx_pin;
    end

    //--------------------------------------------------------------------------
    // FIFO
    //--------------------------------------------------------------------------
    
    synch_fifo # (.WIDTH(8), .DEPTH(FIFO_DEPTH)) synch_fifo_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .flush      (tx_fifo_flush),
        .write_en   (tx_fifo_wr_en),
        .read_en    (tx_fifo_rd_en),
        .data_in    (tx_data_in),
        .empty      (tx_fifo_empty),
        .full       (tx_fifo_full),
        .data_out   (tx_fifo_data_out),
        .count      (tx_fifo_count)
    );

endmodule