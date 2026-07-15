`include "tests.svh"

import decode_pkg::*;
import pipeline_pkg::*;

module archtest_tb;
//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------
    logic clk, rst_n;

    core # (.IMEM_SIZE_WORDS(1024*256), .DMEM_SIZE_WORDS(1024*256)) dut (
        .clk    (clk),
        .rst_n  (rst_n)
    );

//------------------------------------------------------------------------------
// Test state machine
//------------------------------------------------------------------------------

    typedef enum logic [1:0] { 
        RESET_TEST,
        RUNNING_TEST,
        TESTS_DONE
    } test_state_e;

    localparam logic [31:0] TEST_STATUS_ADDR = 32'hCAFE0000;
    test_state_e            curr_state, next_state;
    int                     test_idx;
    logic                   test_done, reset_fsm_n;

    always_comb begin : next_test_state
        next_state = curr_state;

        unique case (curr_state)
            RESET_TEST:                                                 next_state = RUNNING_TEST;
            RUNNING_TEST:   if (test_done && test_idx == NUM_TESTS-1)   next_state = TESTS_DONE;
                            else if (test_done)                         next_state = RESET_TEST;
                            else                                        next_state = RUNNING_TEST;
            TESTS_DONE:                                                 next_state = TESTS_DONE;
            default:                                                    next_state = RESET_TEST;
        endcase
    end

    always_ff @(posedge clk or negedge reset_fsm_n) begin
        if (!reset_fsm_n)   curr_state <= RESET_TEST;
        else                curr_state <= next_state;
    end

//------------------------------------------------------------------------------
// Memory loading and result checking
//------------------------------------------------------------------------------
    assign rst_n        = !(curr_state == RESET_TEST);
    assign test_done    = (dut.dmem_inst.address == TEST_STATUS_ADDR && dut.dmem_inst.write_en == 1'b1);

    always_ff @(posedge clk) begin
        if (curr_state == RESET_TEST) begin
            $readmemh(test_hexfiles[test_idx], dut.dmem_inst.memory);
            $readmemh(test_hexfiles[test_idx], dut.imem_inst.memory);
        end

        if (curr_state == TESTS_DONE) begin
            $display("\n===== All tests complete =====\n");
            $finish;
        end

        if (test_done) begin
            if (dut.dmem_inst.data_in == 32'd1) $display("TEST %0d %s: PASSED", test_idx, test_names[test_idx]);
            else begin                               
                $display("TEST %0d %s: FAILED", test_idx, test_names[test_idx]);
                $stop;
            end
        end
    end

    always_ff @(posedge clk or negedge reset_fsm_n) begin
        if (!reset_fsm_n)       test_idx = '0;
        else if (test_done)     test_idx <= test_idx + 1;
    end


//------------------------------------------------------------------------------
// Initial signals and clk
//------------------------------------------------------------------------------
    initial begin
        reset_fsm_n = 1'b0;
        # 10
        reset_fsm_n = 1'b1;
    end

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial $display("\n ==== Starting riscv-arch-tests ====\n");

endmodule