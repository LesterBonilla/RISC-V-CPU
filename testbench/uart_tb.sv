module uart_tb;

//------------------------------------------------------------------------------
// Clock and Reset
//------------------------------------------------------------------------------
    logic clk = 0;
    logic rst_n = 0;

    always #5 clk = ~clk;

    task automatic reset_dut();
        rst_n = 0;
        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);
    endtask

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------
    logic       rx_pin, read_en;
    logic [7:0] data_out;

    uart dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .rx_pin     (rx_pin),
        .read_en    (read_en),
        .data_out   (data_out)
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

    task automatic reset_queue();
        write_queue.delete();
    endtask

    task automatic read_uart();
        // Read values from the UART, check against the write_queue
        for (int i = 0; i < write_queue.size(); i++) begin
            read_en     = 1'b1;
            queue_data  = write_queue.pop_front();
            if (queue_data != data_out) 
                $error("MISMATCH data_out:\nGot: %0h\nExpected: %0h", data_out, queue_data);
            else
                $info("Read %0h from UART", data_out);
            @(posedge clk);
        end
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
        $display("TEST: Writing value %0h", data);
        write_uart(data);
        read_uart();    
    endtask

//------------------------------------------------------------------------------
// Start tests
//------------------------------------------------------------------------------
    initial begin
        force dut.divisor_r = 1;
        rx_pin  = 1;
        read_en = 0;
        reset_dut();
        test_writing_one(8'h77);
        $finish;
    end


endmodule