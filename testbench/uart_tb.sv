import uart_pkg::*;

module uart_tb;
    localparam RX_FIFO_DEPTH = 16;
    localparam TX_FIFO_DEPTH = 16;

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
    logic       clk = 0;
    logic       rst_n, rx_pin, read_en, write_en;
    logic       tx_pin, interrupt;
    logic [7:0] data_in, data_out;
    logic [2:0] address;

    line_control_t line_control;
    uart_config_t config_8n1;

    assign line_control.break_control   = 1'b0;
    assign line_control.uart_config     = config_8n1;
    assign config_8n1.char_length       = LENGTH_8;
    assign config_8n1.parity_en         = PARITY_OFF;
    assign config_8n1.parity_type       = PARITY_EVEN;
    assign config_8n1.stop_bit          = ONE_STOP_BIT;

//------------------------------------------------------------------------------
// Clock and Reset
//------------------------------------------------------------------------------
    always #5 clk = ~clk;

    task automatic reset_dut();
        rst_n   = 0;
        address = 0;
        rx_pin  = 0;
        read_en = 0;
        data_in = 0;
        write_en = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------
    uart #(.RX_FIFO_DEPTH(RX_FIFO_DEPTH), .TX_FIFO_DEPTH(TX_FIFO_DEPTH)) 
    uart_inst (.*);

//------------------------------------------------------------------------------
// DUT Operations
//------------------------------------------------------------------------------
    task automatic write(logic [2:0] address_in, logic [7:0] data);
        address     = address_in;
        write_en    = 1;
        data_in     = data;
        @(posedge clk);
        write_en    = 0;
    endtask

    task automatic read(logic [2:0] address_in);
        address     = address_in;
        read_en     = 1'b1;
    endtask
    
    // Configure registers for 8 data bits, no parity, 1 stop bit, divide by 3
    task automatic configure_8n1();
        line_control.divisor_latch = 1'b1;
        write(.address_in(LINE_CONTROL), .data(line_control));

        write(.address_in(RX_BUFF_DIV_LOW), .data(8'd3));

        line_control.divisor_latch = 1'b0;
        write(.address_in(LINE_CONTROL), .data(line_control));
    endtask

//------------------------------------------------------------------------------
// Tests
//------------------------------------------------------------------------------
    task automatic wait_baud_period();
        for (int i = 0; i < 16;) begin
            if (uart_inst.baud_16x_ce) i++;
            @(posedge clk);
        end
    endtask

    task automatic wait_half_baud_period();
        for (int i = 0; i < 8;) begin
            if (uart_inst.baud_16x_ce) i++;
            @(posedge clk);
        end
    endtask
    
    // Write some bytes to the tx_holding register
    task automatic tx_driver(int num_bytes);
        logic [7:0] data;
        for (int i = 0; i < num_bytes; i++) begin
            data = $urandom_range(0, 255);
            write(.address_in(TX_HOLDING), .data(data));
        end
    endtask

    // Act as a UART receiver to verify the tx output, write to screen
    task automatic rx_monitor();
        logic [7:0] rx_byte;
        forever begin
            @(negedge tx_pin);
            wait_half_baud_period();
            start_bit_check: assert (tx_pin == START_BIT_VALUE)
                else $error("Assertion start_bit_check failed!");

            for (int i = 0; i < 8; i++) begin
                wait_baud_period();
                rx_byte[i] = tx_pin;
            end

            wait_baud_period();
            stop_bit_check: assert (tx_pin == STOP_BIT_VALUE)
                else $error("Assertion stop_bit_check failed!");

            $write("%h", rx_byte);
        end
    endtask

//------------------------------------------------------------------------------
// Run tests
//------------------------------------------------------------------------------
    initial begin
        reset_dut();
        configure_8n1();
        fork 
            tx_driver(exp_mbox, 16);
            monitor(obs_mbox);
        join_none

        repeat (10000) @(posedge clk);
        $finish;
    end

endmodule