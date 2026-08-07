package uart_pkg;

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
    localparam FIFO_CTRL_TX_CLR_POS = 2;
    localparam FIFO_CTRL_RX_CLR_POS = 1;

    localparam logic STOP_BIT_VALUE     = 1'b1;
    localparam logic IDLE_BIT_VALUE     = 1'b1;
    localparam logic START_BIT_VALUE    = 1'b0;

//------------------------------------------------------------------------------
// Types
//------------------------------------------------------------------------------
 
    typedef enum logic [2:0] { 
        UART_IDLE,
        UART_START,
        UART_DATA,
        UART_PARITY,
        UART_STOP,
        UART_FRAME_END,
        UART_BREAK
    } uart_state_e;

    typedef struct packed {
        logic [7:0] data;
        logic       parity_error;
        logic       framing_error;
        logic       break_interrupt;
    } rx_fifo_entry_t;

    typedef enum logic [1:0] { 
        LENGTH_5    = 2'b00,
        LENGTH_6    = 2'b01,
        LENGTH_7    = 2'b10,
        LENGTH_8    = 2'b11
    } uart_char_length_e;

    typedef enum logic { 
        ONE_STOP_BIT  = 1'b0,
        TWO_STOP_BITS = 1'b1 
    } uart_stop_bit_e;

    typedef enum logic { 
        PARITY_OFF  = 1'b0,
        PARITY_ON   = 1'b1
    } uart_parity_en_e;

    typedef enum logic [1:0] { 
        PARITY_ODD      = 2'b00,
        PARITY_EVEN     = 2'b01,
        PARITY_STICK_1  = 2'b10,
        PARITY_STICK_0  = 2'b11
    } uart_parity_e;

    typedef enum logic [1:0] { 
        TRIGGER_01  = 2'b00,
        TRIGGER_04  = 2'b01,
        TRIGGER_08  = 2'b10,
        TRIGGER_14  = 2'b11   
    } rx_fifo_trigger_e;

    // Shown in order of priority
    typedef enum logic [2:0] {
        UART_INT_NONE       = 3'b000,
        UART_INT_RX_STATUS  = 3'b011,
        UART_INT_RX_DATA    = 3'b010,
        UART_INT_RX_TIMEOUT = 3'b110,
        UART_INT_TX_EMPTY   = 3'b001
    } uart_intr_ident_e;

    typedef struct packed {
        uart_parity_e       parity_type;
        uart_parity_en_e    parity_en;
        uart_stop_bit_e     stop_bit;
        uart_char_length_e  char_length;         
    } uart_config_t;

    typedef struct packed {
        logic           divisor_latch;
        logic           break_control;
        uart_config_t   uart_config;
    } line_control_t;

    typedef struct packed {
        logic   rx_error;
        logic   tx_empty;
        logic   tx_holding_empty;
        logic   break_interrupt;
        logic   framing_error;
        logic   parity_error;
        logic   overrun_error;
        logic   data_ready;
    } line_status_t;

    typedef struct packed {
        logic [2:0] reserved;
        logic       loop;
        logic       out2;
        logic       out1;
        logic       rts;
        logic       data_terminal_ready;
    } modem_control_t;

    typedef struct packed {
        logic data_carrier_detected;
        logic ring_indicator;
        logic data_set_ready;
        logic cts;
        logic delta_data_carrier_detected;
        logic trailing_edge_ring_indicator;
        logic delta_data_set_ready;
        logic delta_cts;
    } modem_status_t;

    typedef struct packed {
        logic [3:0] reserved;
        logic       modem_status_ie;
        logic       rx_line_status_ie;
        logic       tx_holding_empty_ie;
        logic       rx_data_available_ie;
    } interrupt_enable_t;

    typedef struct packed {
        logic [1:0] fifos_enabled;
        logic [1:0] reserved;
        logic [2:0] interrupt_id;
        logic       interrupt_pending;
    } interrupt_ident_t;

    typedef struct packed {
        rx_fifo_trigger_e   rx_trigger;
        logic [1:0]         reseverd;
        logic               dma_mode_select;
        logic               tx_fifo_reset; // Not stored, used directly as strobe
        logic               rx_fifo_reset; // Not stored, used directly as strobe
        logic               fifo_enable;
    } fifo_control_t;

endpackage