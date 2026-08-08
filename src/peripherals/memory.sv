module memory # (
    parameter int NUM_WORDS = 1024
)(
    input  logic            clk,

    input  logic [31:0]     address_b,
    input  logic [31:0]     data_in_b,
    input  logic [3:0]      byte_en_b,
    input  logic            write_b,
    output logic [31:0]     data_out_b,
    
    input  logic [31:0]     address_a,
    input  logic [31:0]     data_in_a,
    input  logic [3:0]      byte_en_a,
    input  logic            write_a,
    output logic [31:0]     data_out_a
);

    localparam int ADDR_WIDTH_WORDS = $clog2(NUM_WORDS);
    localparam int ADDR_WIDTH_BYTES = $clog2(NUM_WORDS * 4);

    logic [ADDR_WIDTH_WORDS-1:0]    word_address_a, word_address_b;
    logic [3:0][7:0]                memory[0:NUM_WORDS-1];

    assign word_address_a = address_a[ADDR_WIDTH_BYTES-1:2];
    assign word_address_b = address_b[ADDR_WIDTH_BYTES-1:2];

    always_ff @(posedge clk) begin
        if (write_a) begin
            if (byte_en_a[0]) memory[word_address_a][0] <= data_in_a[7:0];
            if (byte_en_a[1]) memory[word_address_a][1] <= data_in_a[15:8];
            if (byte_en_a[2]) memory[word_address_a][2] <= data_in_a[23:16];
            if (byte_en_a[3]) memory[word_address_a][3] <= data_in_a[31:24]; 

            data_out_a <= memory[word_address_a];
        end else begin
            data_out_a <= memory[word_address_a];
        end
    end

    always_ff @(posedge clk) begin
        if (write_b) begin
            if (byte_en_b[0]) memory[word_address_b][0] <= data_in_b[7:0];
            if (byte_en_b[1]) memory[word_address_b][1] <= data_in_b[15:8];
            if (byte_en_b[2]) memory[word_address_b][2] <= data_in_b[23:16];
            if (byte_en_b[3]) memory[word_address_b][3] <= data_in_b[31:24]; 

            data_out_b <= memory[word_address_b];
        end else begin
            data_out_b <= memory[word_address_b];
        end
    end

endmodule