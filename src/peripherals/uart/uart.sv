import uart_pkg::*;

module uart # (
    parameter int unsigned RX_FIFO_DEPTH = 16,
    parameter int unsigned TX_FIFO_DEPTH = 16
)(
    input logic         clk,
    input logic         rst_n,

    input logic         rx_pin,
    input logic         read_en,
    input logic         write_en,
    input logic [7:0]   data_in,
    input logic [31:0]  address,

    output logic        tx_pin,
    output logic        interrupt,
    output logic [31:0] data_out
);

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
    // Registers
    line_control_t      line_control;
    line_status_t       line_status;
    interrupt_enable_t  interrupt_enable;
    interrupt_ident_t   interrupt_ident;
    fifo_control_t      fifo_control;
    logic [7:0]         rx_buffer, scratch;
    logic [15:0]        divisor;
    logic               div_latch_en, fifo_control_write, line_status_read;

    // Rx
    logic  rx_fifo_rd_en, rx_fifo_flush, rx_fifo_empty, rx_fifo_full, rx_parity_error;
    logic  rx_framing_error, rx_break_interrupt, rx_overrun_error, rx_error_in_fifo;
    logic [7:0] rx_data_out;
    logic [$clog2(RX_FIFO_DEPTH):0] rx_fifo_count, rx_fifo_trigger;

    // Tx
    logic tx_fifo_wr_en, tx_fifo_flush, tx_fifo_empty, tx_fifo_full, tx_pin_tx;
    logic tx_empty;
    logic [7:0] tx_data_in;
    logic [$clog2(TX_FIFO_DEPTH):0] tx_fifo_count;

    // Interrupts
    logic rx_line_status_intr, rx_data_available_intr, tx_holding_empty_intr;

//------------------------------------------------------------------------------
// Read/Write
//------------------------------------------------------------------------------
    assign rx_buffer            = rx_data_out;
    assign fifo_control_write   = (write_en && (address == FIFO_CONTROL)); 
    assign div_latch_en         = line_control.divisor_latch;

    always_comb begin
        data_out = '0;
        unique case (address)
            RX_BUFF_DIV_LOW:    if (div_latch_en)   data_out[7:0] = divisor[7:0];
                                else                data_out[7:0] = rx_buffer;
            INT_EN_DIV_HIGH:    if (div_latch_en)   data_out[7:0] = divisor[15:8];
                                else                data_out[7:0] = interrupt_enable;
            INTERRUPT_IDENT:                        data_out[7:0] = interrupt_ident & 8'hCF; // Always FIFO mode
            LINE_CONTROL:                           data_out[7:0] = line_control;
            LINE_STATUS:                            data_out[7:0] = line_status;
            SCRATCH:                                data_out[7:0] = scratch;
            default:                                data_out[7:0] = 8'd0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interrupt_enable    <= 8'd0;
            fifo_control        <= 8'd1; // Always enable fifo mode
            line_control        <= 8'd3; // Default: 8 data, 1 stop, no parity
            divisor             <= 16'd1;// Avoid zero divisor
            scratch             <= 8'd0;
        end else if (write_en) begin
            unique0 case (address)
                RX_BUFF_DIV_LOW:    if (div_latch_en)   divisor[7:0]        <= data_in;
                FIFO_CONTROL:                           fifo_control        <= data_in & 8'hC9; // Tx/Rx flushes are not stored
                INT_EN_DIV_HIGH:    if (div_latch_en)   divisor[15:8]       <= data_in;                    
                                    else                interrupt_enable    <= data_in & 8'h0F;
                LINE_CONTROL:                           line_control        <= data_in; 
                SCRATCH:                                scratch             <= data_in;
            endcase
        end
    end

//------------------------------------------------------------------------------
// Baud Rate
//------------------------------------------------------------------------------
    // baud_rate = clk_freq / (16 x divisor)
    // divisor = clk_freq / (baud_rate x 16)
    // 16 is the oversampling factor. For each bit period, the clock is pulsed 
    // 16 times and data is sampled halfway through to maximize accuracy.
    // Every time div_cnt wraps is 1/16th of a bit period
    // baud_16x_ce is enabled on div_cnt wrap
    // baud_ce is enabled every 16 baud_16x_ce enables (start of next bit period)
    // bit_div_cnt_(rx/tx) counts baud_16x_ce enables from 0 to 15

    logic [15:0]    div_cnt, next_div_cnt;
    logic           baud_16x_ce;
    
    assign next_div_cnt = baud_16x_ce ? '0 : div_cnt + 1'b1;
    assign baud_16x_ce  = (div_cnt == (divisor - 1'b1));

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) div_cnt <= '0;
        else        div_cnt <= next_div_cnt;
    end

//------------------------------------------------------------------------------
// Interrupts
//------------------------------------------------------------------------------
    // Currently, only FIFO mode is supported. TODO: Add support for polled mode
    // TODO: The datasheet says that reading the line status clears the interrupt and
    //       the flags, but then says in FIFO mode the errors exist with their associated
    //       character is at the top. I think this means it can be cleared just by
    //       reading the errored character, which is my current implementation. I will
    //       get back to this to decide if I want to clear on line_status read as well.
    // RX Interrupts:
    //  rx_data_available: Set when (rx_fifo_count >= rx_fifo_trigger), 
    //                     cleared when it falls below that value.
    //  rx_line_status:    Set when the current rx output has an error,
    //                     cleared when the errored output is read.
    //  rx_data_ready:     Set when rx_fifo is not empty, reset when it is empty
    //  rx_timeout:        Set when there is rx_data in the rx_fifo that hasn't been
    //                     read in 4 frame periods, as configured (start+data+parity+stops).
    //                     Cleared by reading from the rx_buffer, the timer is refreshed
    //                     every time rx_buffer is read. TODO: Implement this timer
    // TX Interrupts:
    //  tx_holding_empty:  Set when tx_fifo_empty, cleared by writing to it or reading
    //                     the interrupt identity register. TODO: Currently only reset by
    //                     the empty flag. Decide whether I want to add reading IIR to clear it.
    //  tx_empty:          Set whenever the tx_shift_register and tx_fifo are empty.
    //                     TODO: The datasheet explains some delay behavior for this interrupt.
    //                     If between the last time tx_fifo_empty was true and the most recent
    //                     time tx_fifo_empty is true, there wasn't at least 2 bytes in the tx_fifo
    //                     at the same time, this is delayed by 1 character time - last stop bit time.
    //                     I'm not sure that I will implement this. I will come back to it.
    // Priority: rx_line_status, rx_data_ready, tx_holding_empty, modem_status
    assign rx_line_status_intr      = interrupt_enable.rx_line_status_ie && (line_status | 8'h17); // Error bits
    assign rx_data_available_intr   = interrupt_enable.rx_data_available_ie && (line_status.data_ready); // TODO: And timeout
    assign tx_holding_empty_intr    = interrupt_enable.tx_holding_empty_ie && (line_status.tx_holding_empty);

    // TODO: The interrupts must not update while a CPU access is reading the interrupt_ident register.
    //       This can be enforced registering these bits instead of keeping them live.
    assign interrupt = !interrupt_ident.interrupt_pending; // Output interrupt signal is active high.
    assign interrupt_ident.interrupt_pending = !(rx_line_status_intr || rx_data_available_intr || tx_holding_empty_intr);
    assign interrupt_ident.reserved = '0;
    assign interrupt_ident.fifos_enabled = 2'b11; // Always fifo mode

    always_comb begin
        if (rx_line_status_intr)
            interrupt_ident.interrupt_id = UART_INT_RX_STATUS;
        else if (rx_data_available_intr)
            interrupt_ident.interrupt_id = UART_INT_RX_DATA; // TODO: Add timeout enum
        else if (tx_holding_empty_intr)
            interrupt_ident.interrupt_id = UART_INT_TX_EMPTY;
        else
            interrupt_ident.interrupt_id = UART_INT_NONE;
    end

//------------------------------------------------------------------------------
// Receiver
//------------------------------------------------------------------------------
    assign line_status_read             = (read_en && (address == LINE_STATUS));
    assign line_status.data_ready       = !rx_fifo_empty;
    assign line_status.parity_error     = rx_parity_error;
    assign line_status.framing_error    = rx_framing_error;
    assign line_status.break_interrupt  = rx_break_interrupt;
    assign line_status.rx_error         = rx_error_in_fifo;
    assign rx_fifo_flush                = (fifo_control_write && data_in[FIFO_CTRL_RX_CLR_POS]);
    assign rx_fifo_rd_en                = (address == RX_BUFF_DIV_LOW) && !div_latch_en && read_en;

    always_comb begin
        rx_fifo_trigger = $clog2(RX_FIFO_DEPTH)'(1);
        unique case (fifo_control.rx_trigger)
            TRIGGER_01: rx_fifo_trigger = $clog2(RX_FIFO_DEPTH)'(1);
            TRIGGER_04: rx_fifo_trigger = $clog2(RX_FIFO_DEPTH)'(4);
            TRIGGER_08: rx_fifo_trigger = $clog2(RX_FIFO_DEPTH)'(8);
            TRIGGER_14: rx_fifo_trigger = $clog2(RX_FIFO_DEPTH)'(14);
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            line_status.overrun_error <= 1'b0;
        end else if (rx_overrun_error) begin 
            line_status.overrun_error <= 1'b1;
        end else if (line_status_read) begin
            line_status.overrun_error <= 1'b0;
        end
    end

    uart_rx #(.FIFO_DEPTH(RX_FIFO_DEPTH)) uart_rx_inst (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .tick_16x               (baud_16x_ce),
        .rx_pin                 (rx_pin),
        .rx_fifo_rd_en          (rx_fifo_rd_en),
        .rx_fifo_flush          (rx_fifo_flush),
        .rx_config              (line_control.uart_config),
        .rx_fifo_empty          (rx_fifo_empty),
        .rx_fifo_full           (rx_fifo_full),
        .rx_parity_error        (rx_parity_error),
        .rx_framing_error       (rx_framing_error),
        .rx_break_interrupt     (rx_break_interrupt),
        .rx_overrun_error       (rx_overrun_error),
        .rx_data_out            (rx_data_out),
        .rx_fifo_count          (rx_fifo_count),
        .rx_error_in_fifo       (rx_error_in_fifo)
    );

//------------------------------------------------------------------------------
// Transmitter
//------------------------------------------------------------------------------
    assign tx_pin = (line_control.break_control) ? 1'b0 : tx_pin_tx;
    assign line_status.tx_holding_empty = tx_fifo_empty;
    assign line_status.tx_empty         = tx_empty;
    assign tx_fifo_flush                = (fifo_control_write && data_in[FIFO_CTRL_TX_CLR_POS]);
    assign tx_data_in                   = data_in;
    assign tx_fifo_wr_en                = ((address == TX_HOLDING) && !div_latch_en && write_en);

    uart_tx #(.FIFO_DEPTH(TX_FIFO_DEPTH)) uart_tx_inst (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .baud_16x_ce            (baud_16x_ce),
        .tx_fifo_wr_en          (tx_fifo_wr_en),
        .tx_fifo_flush          (tx_fifo_flush),
        .tx_data_in             (tx_data_in),
        .tx_config              (line_control.uart_config),
        .tx_pin                 (tx_pin_tx),
        .tx_fifo_empty          (tx_fifo_empty),
        .tx_fifo_full           (tx_fifo_full),
        .tx_fifo_count          (tx_fifo_count),
        .tx_empty               (tx_empty)
    );

endmodule