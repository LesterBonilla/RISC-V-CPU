module uart_tb;

//------------------------------------------------------------------------------
// Clock, Reset, Baud Generator
//------------------------------------------------------------------------------
    logic clk = 0;
    logic rst_n = 0;
    logic tick_16x = 0;

    always #5 clk = ~clk;

    task automatic reset_dut();
        rst_n = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

    task automatic generate_tick_16x();
        forever begin
            @(posedge clk);
            tick_16x = 1;
            @(posedge clk);
            tick_16x = 0;
        end
    endtask

    initial generate_tick_16x();

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------
    localparam int unsigned FIFO_WIDTH = 8;
    localparam int unsigned FIFO_DEPTH = 16;

    logic rx_pin, rx_fifo_rd_en, rx_fifo_flush;
    logic rx_fifo_empty, rx_fifo_full;

    logic [$clog2(FIFO_DEPTH):0]    rx_fifo_count;
    logic [FIFO_WIDTH-1:0]          data_out;

    uart_rx #(.FIFO_DEPTH(FIFO_DEPTH), .FIFO_WIDTH(FIFO_WIDTH)) dut (
        .clk                (clk),
        .rst_n              (rst_n),
        .tick_16x           (clk),
        .rx_pin             (rx_pin),
        .rx_fifo_rd_en      (rx_fifo_rd_en),
        .rx_fifo_flush      (rx_fifo_flush),
        .rx_fifo_empty      (rx_fifo_empty),
        .rx_fifo_full       (rx_fifo_full),
        .rx_fifo_count      (rx_fifo_count),
        .rx_fifo_data_out   (data_out)
    );

//------------------------------------------------------------------------------
// DUT Operation and Expected Behavior
//------------------------------------------------------------------------------
    logic [7:0] write_queue[$];
    logic [7:0] queue_data;
    int         baud_cnt;
    int         sample_idx;

    task automatic wait_baud();
        for (int i = 0; i < 16; i++) begin
            baud_cnt = i;
            @(posedge clk);
        end
    endtask

    task automatic reset_test();
        write_queue.delete();
        rx_pin  = 1;
        rx_fifo_rd_en = 0;
        rx_fifo_flush = 0;
        reset_dut();
    endtask

    task automatic read_uart();
        // Read values from the UART, check against the write_queue
        int size = write_queue.size();
        for (int i = 0; i < size; i++) begin
            rx_fifo_rd_en = 1'b1;
            queue_data  = write_queue.pop_front();
            if (queue_data != data_out) 
                $error("MISMATCH data_out:\nGot: %0h\nExpected: %0h", data_out, queue_data);
            else
                $display("Read %0h from UART", data_out);
            @(posedge clk); #0.5;
        end
        rx_fifo_rd_en = 0;
    endtask

    task automatic write_uart(logic [7:0] data);
        // Serialize the data and send over rx_pin
        localparam STOP_BIT     = 1;
        localparam START_BIT    = 0;

        rx_pin = START_BIT;
        wait_baud();

        for (int i = 0; i < 8; i++) begin
            sample_idx = i;
            rx_pin = data[i];
            wait_baud();
        end

        rx_pin = STOP_BIT;
        wait_baud();

        // Wait for frame to settle and FIFO to be written
        repeat (2) wait_baud();

        // Save data to write queue
        write_queue.push_back(data);
    endtask

//------------------------------------------------------------------------------
// Tests
//------------------------------------------------------------------------------
    string test = "NONE";

    task automatic test_writing_one(logic [7:0] data);
        test = "WRITING ONE";
        $display("\n=== TEST: Writing value %0h ===", data);
        reset_test();
        write_uart(data);
        read_uart();    
    endtask

    task automatic test_write_many();
        $display("\n=== TEST: Write many ===");
        reset_test();

        for (int i = 0; i < 16; i++) begin
            $display("Writing %0h to UART", i);
            write_uart(i);
        end
        read_uart();
    endtask

//------------------------------------------------------------------------------
// Start tests
//------------------------------------------------------------------------------
    initial begin
        reset_test();
        test_writing_one(8'h77);
        test_write_many();
        $finish;
    end


endmodule