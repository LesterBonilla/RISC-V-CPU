package uart_pkg;

    typedef enum logic [2:0] { 
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_PARITY,
        RX_STOP,
        RX_FRAME_END
    } rx_state_e;

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
endpackage