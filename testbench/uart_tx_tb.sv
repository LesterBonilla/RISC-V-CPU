import uart_pkg::*;

module uart_tx_tb;

    localparam DIVISOR = 1;
    localparam int unsigned FIFO_DEPTH = 16;

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
        .baud_16x_ce    (clk),
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
    int unsigned baud_cnt = 0;

    task automatic wait_baud_period();
        for (int i = 0; i < (16 * DIVISOR); i++) begin
            baud_cnt = i;
            @(posedge clk);
        end
    endtask

//------------------------------------------------------------------------------
// Start tests
//------------------------------------------------------------------------------
    initial begin
        reset_dut();
    end


endmodule