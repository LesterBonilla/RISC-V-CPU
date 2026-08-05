package uart_pkg;

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
        logic [1:0] rx_trigger;
        logic [1:0] reseverd;
        logic       dma_mode_select;
        logic       xmit_fifo_reset;
        logic       rx_fifo_reset;
        logic       fifo_enable;
    } fifo_control_t;

endpackage