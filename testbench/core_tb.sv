`timescale 1ns/1ps

module core_tb;

    logic clk;
    logic rst_n;

    core # (.IMEM_SIZE_WORDS(1024*256), .DMEM_SIZE_WORDS(1024*256)) dut (
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
        repeat (1000) @(posedge clk);
        $finish;
    end

endmodule