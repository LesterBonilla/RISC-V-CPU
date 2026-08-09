module memory # (
    parameter int NUM_WORDS = 1024
)(
    input  logic            clk,

    input  logic [$clog2(NUM_WORDS)-1:0] address_b,
    input  logic [$clog2(NUM_WORDS)-1:0] address_a,

    input  logic [3:0][7:0] data_in_b,
    input  logic [3:0]      byte_en_b,
    input  logic            write_b,
    input  logic            read_b,
    output logic [3:0][7:0] data_out_b,
    
    input  logic [3:0][7:0] data_in_a,
    input  logic [3:0]      byte_en_a,
    input  logic            write_a,
    input  logic            read_a,
    output logic [3:0][7:0] data_out_a
);

    logic [3:0][7:0] memory[0:NUM_WORDS-1];

    always_ff @(posedge clk) begin
        if (write_a) begin
            if (byte_en_a[0]) memory[address_a][0] <= data_in_a[0];
            if (byte_en_a[1]) memory[address_a][1] <= data_in_a[1];
            if (byte_en_a[2]) memory[address_a][2] <= data_in_a[2];
            if (byte_en_a[3]) memory[address_a][3] <= data_in_a[3]; 
        end 
            data_out_a <= memory[address_a];
            
            if (read_b) data_out_b <= memory[address_b];
    end

endmodule