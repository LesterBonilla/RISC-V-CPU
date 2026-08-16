import uart_pkg::*;

module uart_tx_tb;

    localparam DIVISOR = 1;
    localparam int unsigned FIFO_DEPTH = 16;
    localparam logic STOP_BIT_VALUE = 1'b1;
    localparam logic START_BIT_VALUE = 1'b0;

//------------------------------------------------------------------------------
// Clock, Reset, Baud
//------------------------------------------------------------------------------
    logic clk = 0;
    logic rst_n = 0;
    logic baud_16x_ce;
    logic [$clog2(DIVISOR)-1:0] div_cnt, next_div_cnt;

    always #5 clk = ~clk;

    task automatic reset_dut();
        rst_n = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

    assign baud_16x_ce  = (div_cnt == DIVISOR-1);
    assign next_div_cnt = baud_16x_ce ? '0 : div_cnt + 1; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) div_cnt <= '0;
        else        div_cnt <= next_div_cnt;
    end
//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------

    logic [7:0] tx_data_in;
    logic       tx_fifo_wr_en, tx_fifo_flush, tx_pin, tx_fifo_empty, tx_fifo_full;
    uart_config_t tx_config;

    logic [$clog2(FIFO_DEPTH):0] tx_fifo_count;

    uart_tx #(.FIFO_DEPTH(FIFO_DEPTH)) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .baud_16x_ce    (baud_16x_ce),
        .tx_fifo_wr_en  (tx_fifo_wr_en),
        .tx_fifo_flush  (tx_fifo_flush),
        .tx_data_in     (tx_data_in),
        .tx_config      (tx_config),
        .tx_pin         (tx_pin),
        .tx_fifo_empty  (tx_fifo_empty),
        .tx_fifo_full   (tx_fifo_full),
        .tx_fifo_count  (tx_fifo_count)
    );

//------------------------------------------------------------------------------
// DUT Operation and Expected Behavior
//------------------------------------------------------------------------------

    task automatic wait_baud_period();
        for (int i = 0; i < 16;) begin
            if (baud_16x_ce) i++;
            @(posedge clk);
        end
    endtask

    task automatic wait_half_baud_period();
        for (int i = 0; i < 8;) begin
            if (baud_16x_ce) i++;
            @(posedge clk);
        end
    endtask

    task automatic set_config_8n1();
        tx_config.char_length = LENGTH_8;
        tx_config.parity_en = PARITY_OFF;
        tx_config.parity_type = PARITY_EVEN;
        tx_config.stop_bit = ONE_STOP_BIT;
    endtask

    task automatic reset_test();
        tx_fifo_wr_en = 0;
        tx_fifo_flush = 0;
        tx_data_in = 0;
        set_config_8n1();
        reset_dut();
    endtask

    task automatic driver(mailbox #(logic [7:0]) exp_mbox, int num_bytes);
        logic [7:0] data;
        for (int i = 0; i < num_bytes; i++) begin
            data = $urandom_range(0, 255);
            @(posedge clk);
            tx_fifo_wr_en = 1'b1;
            tx_data_in = data;
            @(posedge clk);
            tx_fifo_wr_en = 1'b0;
            exp_mbox.put(data);
        end
    endtask

    task automatic monitor(mailbox #(logic [7:0]) obs_mbox);
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

            obs_mbox.put(rx_byte);
        end
    endtask

    task automatic scoreboard(mailbox #(logic [7:0]) exp_mbox, mailbox #(logic [7:0]) obs_mbox, int num_bytes);
        logic [7:0] exp_byte, obs_byte;
        int pass_count = 0;

        for (int i = 0; i < num_bytes; i++) begin
            exp_mbox.get(exp_byte);
            obs_mbox.get(obs_byte);
            if (exp_byte != obs_byte)
                $error("Mismatch #%0d: \nExpected: %0d \nGot: %0d", i, exp_byte, obs_byte);
            else
                pass_count++;
        end
        $display("Scoreboard: \n%0d/%0d passed", pass_count, num_bytes);
    endtask

//------------------------------------------------------------------------------
// Start tests
//------------------------------------------------------------------------------
    mailbox #(logic [7:0]) exp_mbox = new();
    mailbox #(logic [7:0]) obs_mbox = new();
    
    initial begin
        reset_test();
        fork 
            driver(exp_mbox, 16);
            monitor(obs_mbox);
        join_none

        scoreboard(exp_mbox, obs_mbox, 16);
        disable fork;
        $finish;
    end

endmodule