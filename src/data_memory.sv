module data_memory #(
    parameter int SIZE_WORDS = 1024
)(
    input logic         clk,
    input logic         write_en,

    input logic [31:0]  address,
    input logic [31:0]  data_in,
    input logic [3:0]   byte_en,

    output logic [31:0] data_out
);

    localparam int ADDR_WIDTH_BYTES = $clog2(SIZE_WORDS * 4);
    localparam int ADDR_WIDTH_WORDS = $clog2(SIZE_WORDS);

    logic [ADDR_WIDTH_WORDS-1:0]    word_address;
    logic [3:0][7:0]                memory[0:SIZE_WORDS-1];

    assign word_address = address[ADDR_WIDTH_BYTES-1:2];
    assign data_out     = memory[word_address];

    always_ff @(posedge clk) begin
        if (write_en) begin
            if (byte_en[0]) memory[word_address][0] <= data_in[7:0];
            if (byte_en[1]) memory[word_address][1] <= data_in[15:8];
            if (byte_en[2]) memory[word_address][2] <= data_in[23:16];
            if (byte_en[3]) memory[word_address][3] <= data_in[31:24]; 
        end
    end
    
endmodule