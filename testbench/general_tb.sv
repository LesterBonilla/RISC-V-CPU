`timescale 1ns/1ps

module general_tb;

    logic clk;
    logic rst_n;
    logic test_done;

    localparam logic [31:0] TEST_STATUS_ADDR = 32'hCAFE0000;

    core # (.MEM_SIZE_WORDS(1024*256)) dut (
        .clk    (clk),
        .rst_n  (rst_n)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;
    end

    initial begin
        $readmemh("../tests/I-jalr-00.hex",dut.memory_inst.memory);
    end

    assign test_done = (dut.memory_inst.dmem_address == TEST_STATUS_ADDR && dut.memory_inst.write_en == 1'b1);

    always_ff @(posedge clk) begin
        if (test_done) begin
            if (dut.memory_inst.data_in == 32'd1)   $display("TEST PASSED");
            else                                    $display("TEST FAILED");
            $stop;
        end
    end

endmodule