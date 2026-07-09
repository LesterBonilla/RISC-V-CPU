module data_memory #(
    parameter int SIZE_WORDS = 1024
)(
    input logic         clk,
    input logic         write_en,

    input logic [31:0]  address,
    input logic [31:0]  write_data,
    input logic [3:0]   write_mask,

    output logic [31:0] data_out
);

    localparam int ADDR_WIDTH_BYTES = $clog2(SIZE_WORDS * 4);
    localparam int ADDR_WIDTH_WORDS = $clog2(SIZE_WORDS);

    logic [ADDR_WIDTH_WORDS-1:0]    word_address;
    logic [31:0]                    memory [SIZE_WORDS-1:0];
    //initial $readmemh("", memory);

    assign word_address = address[ADDR_WIDTH_BYTES-1:2];
    assign data_out     = memory[word_address];

    always_ff @(posedge clk) begin
        if (write_en) begin
            if (write_mask[0]) memory[word_address][7:0]   <= write_data[7:0];
            if (write_mask[1]) memory[word_address][15:8]  <= write_data[15:8];
            if (write_mask[2]) memory[word_address][23:16] <= write_data[23:16];
            if (write_mask[3]) memory[word_address][31:24] <= write_data[31:24];
        end
    end
    
endmodule