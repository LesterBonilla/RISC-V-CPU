module uart (
    input logic         clk,
    input logic         rst_n,

    input logic         rx_pin,
    input logic         read_en,
    input logic         write_en,
    input logic [7:0]   data_in,
    input logic [2:0]   address,

    output logic        tx_pin,
    output logic [7:0]  data_out
);

//------------------------------------------------------------------------------
// Address Map
//------------------------------------------------------------------------------
    localparam RX_BUFF_DIV_LOW      = 3'b000; // Read only, DLAB = 0
    localparam TX_HOLDING           = 3'b000; // Write only, DLAB = 0
    localparam INT_EN_DIV_HIGH      = 3'b001; // DLAB = 0
    localparam INTERRUPT_IDENT      = 3'b010; // Read only
    localparam FIFO_CONTROL         = 3'b010; // Write only
    localparam LINE_CONTROL         = 3'b011;
    localparam MODEM_CONTROL        = 3'b100; // Not implemented
    localparam LINE_STATUS          = 3'b101;
    localparam MODEM_STATUS         = 3'b110; // Not implemented
    localparam SCRATCH              = 3'b111;
    localparam DIVISOR_LATCH_LOW    = 3'b000; // DLAB = 1
    localparam DIVISOR_LATCH_HIGH   = 3'b001; // DLAB = 1

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
    // Registers
    line_control_t      line_control;
    line_status_t       line_status;
    interrupt_enable_t  interrupt_enable;
    interrupt_ident_t   interrupt_ident;
    fifo_control_t      fifo_control;
    logic [7:0]         rx_buffer, tx_holding, scratch;
    logic [15:0]        divisor;
    logic               div_latch_en;

//------------------------------------------------------------------------------
// Read/Write
//------------------------------------------------------------------------------
    always_comb begin
        unique case (address)
            RX_BUFF_DIV_LOW:    if (div_latch_en)   data_out = divisor[7:0];
                                else                data_out = rx_buffer;
            INT_EN_DIV_HIGH:    if (div_latch_en)   data_out = divisor[15:8];
                                else                data_out = interrupt_enable;
            INTERRUPT_IDENT:                        data_out = interrupt_ident & 8'hCF;
            LINE_CONTROL:                           data_out = line_control;
            LINE_STATUS:                            data_out = line_status;
            SCRATCH:                                data_out = scratch;
            default:                                data_out = 8'd0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            interrupt_enable    <= 8'd0;
            fifo_control        <= 8'd1; // Always enable fifo mode
            line_control        <= 8'd3; // Default: 8 data, 1 stop, no parity
            line_status         <= 8'd0;
            divisor             <= '0;
        end else if (write_en) begin
            unique0 case (address)
                RX_BUFF_DIV_LOW:    if (div_latch_en)   divisor[7:0]        <= data_in;
                FIFO_CONTROL:                           fifo_control        <= data_in;
                INT_EN_DIV_HIGH:    if (div_latch_en)   divisor[15:8]       <= data_in;                    
                                    else                interrupt_enable    <= data_in & 8'h0F;
                LINE_CONTROL:                           line_control        <= data_in; 
                LINE_STATUS:                            line_status         <= data_in;
                SCRATCH:                                scartch             <= data_in;
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
    
    assign next_div_cnt = (div_cnt == divisor - 1'b1) ? '0 : div_cnt + 1'b1;
    assign baud_16x_ce  = (next_div_cnt == '0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) div_cnt <= '0;
        else        div_cnt <= next_div_cnt;
    end

//------------------------------------------------------------------------------
// Receiver
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Transmitter
//------------------------------------------------------------------------------
  

endmodule