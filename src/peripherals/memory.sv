module memory # (
    parameter int NUM_WORDS = 1024
)(
    input  logic            clk,

    input  logic [31:0] address_b,
    input  logic [31:0] address_a,

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
    initial $readmemh("ExceptionsSm-00.hex", memory);

    logic [$clog2(NUM_WORDS)-1:0] word_address_a, word_address_b;

    assign word_address_a = address_a[$clog2(NUM_WORDS)+1:2];
    assign word_address_b = address_b[$clog2(NUM_WORDS)+1:2];

    always_ff @(posedge clk) begin
        if (write_a) begin
            if (byte_en_a[0]) memory[word_address_a][0] <= data_in_a[0];
            if (byte_en_a[1]) memory[word_address_a][1] <= data_in_a[1];
            if (byte_en_a[2]) memory[word_address_a][2] <= data_in_a[2];
            if (byte_en_a[3]) memory[word_address_a][3] <= data_in_a[3]; 
        end 
            data_out_a <= memory[word_address_a];
            
            
    end

    always_ff @(posedge clk) begin
        data_out_b <= memory[word_address_b];
    end

endmodule