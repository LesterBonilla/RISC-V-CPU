module synch_fifo_tb;

//------------------------------------------------------------------------------
// Clock and Reset
//------------------------------------------------------------------------------
    localparam int unsigned WIDTH = 8;
    localparam int unsigned DEPTH = 16;

    logic clk = 0;
    logic rst_n;

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
    logic                   write_en, read_en, flush;
    logic                   full, empty;
    logic [WIDTH-1:0]       data_in, data_out;
    logic [$clog2(DEPTH):0] count;

    synch_fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .flush      (flush),
        .write_en   (write_en),
        .read_en    (read_en),
        .data_in    (data_in),
        .empty      (empty),
        .full       (full),
        .data_out   (data_out),
        .count      (count)
    );

//------------------------------------------------------------------------------
// Queue Model and Update Task
//------------------------------------------------------------------------------
    logic [WIDTH-1:0] model_queue[$];
    bit model_full, model_empty;

    assign model_full  = (model_queue.size() == DEPTH);
    assign model_empty = (model_queue.size() == 0); 

    task automatic update_model();
        // Perform same operation on the model
        if (write_en && (!model_full || read_en)) model_queue.push_back(data_in);
        if (read_en && !model_empty)              void'(model_queue.pop_front());

        #1;

        if (model_queue.size() > 0) begin
            if (data_out != model_queue[0]) $error("Mismatch in data_out: Got: %0h, Expected: %0h", data_out, model_queue[0]);
        end
        if (count != model_queue.size())    $error("Mismatch in count: Got: %0d, Expected: %0d", count, model_queue.size());
        if (empty != model_empty)           $error("Mismatch in empty: Got %0d, Expected: %0d", empty, model_empty);
        if (full != model_full)             $error("Mismatch in full: Got: %0d, Expected: %0d", full, model_full);
    endtask 

    task automatic reset_fifos();
        model_queue.delete();
        write_en    = 0;
        read_en     = 0;
        data_in     = 0;
        flush       = 0;
    endtask 

//------------------------------------------------------------------------------
// Tests
//------------------------------------------------------------------------------
    task automatic test_single_push_pop();
        $display("TEST: Single Push/Pop");
        reset_fifos();
        reset_dut();

        // Push
        write_en    = 1'b1;
        read_en     = 1'b0;
        data_in     = 8'hFF;
        @(posedge clk); update_model();

        // Pop
        write_en    = 1'b0;
        read_en     = 1'b1;
        @(posedge clk); update_model();
    endtask

    task automatic test_full();
        $display("TEST: Full");
        reset_fifos();
        reset_dut();

        // Push until full
        for (int i = 0; i < DEPTH; i++) begin
            write_en    = 1'b1;
            read_en     = 1'b0;
            data_in     = i;
            @(posedge clk);
            update_model();
        end

        // This write should be ignored
        write_en = 1'b1;
        data_in = 8'hAA;
        @(posedge clk);
        update_model();
    endtask

    task automatic test_rd_wr_full();
        $display("TEST: Read and Write when Full");
        reset_fifos();
        reset_dut();

        // Push until full
        for (int i = 0; i < DEPTH; i++) begin
            write_en    = 1'b1;
            read_en     = 1'b0;
            data_in     = i;
            @(posedge clk);
            update_model();
        end

        // This write should not be ignored
        write_en    = 1'b1;
        read_en     = 1'b1;
        data_in     = 8'h37;
        @(posedge clk);
        update_model();
    endtask

//------------------------------------------------------------------------------
// Start tests
//------------------------------------------------------------------------------
    initial begin
        test_single_push_pop();
        test_full();
        test_rd_wr_full();
        $display("=== TESTS DONE ===");
        $finish;
    end

endmodule