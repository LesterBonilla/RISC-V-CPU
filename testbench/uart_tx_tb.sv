import uart_pkg::*;

module uart_tx_tb;

//------------------------------------------------------------------------------
// Clock, Reset, Baud
//------------------------------------------------------------------------------
    logic clk = 0;
    logic rst_n = 0;
    logic baud_16x_ce;

    always #5 clk = ~clk;

    task automatic reset_dut();
        rst_n = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

    initial begin
        baud_16x_ce = 0;
    end

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------
    localparam int unsigned FIFO_DEPTH = 16;

    logic [7:0] tx_data_in;
    logic       tx_fifo_wr_en, tx_fifo_flush, tx_pin, tx_fifo_empty, tx_fifo_full;

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

    task automatic wait_baud();
        for (int i = 0; i < 16; i++) begin
            baud_cnt = i;
            @(posedge clk);
        end
    endtask

    task automatic sample_transmission();

    endtask


endmodule