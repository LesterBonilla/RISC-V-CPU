module memory # (
    parameter int NUM_WORDS = 1024
)(
    input  logic            clk,

    input  logic [31:0]     imem_address,
    output logic [31:0]     imem_data,
    
    input  logic [31:0]     dmem_address,
    input  logic [31:0]     data_in,
    input  logic [3:0]      byte_en,
    input  logic            write_en,
    output logic [31:0]     dmem_data
);

    localparam int ADDR_WIDTH_WORDS = $clog2(NUM_WORDS);
    localparam int ADDR_WIDTH_BYTES = $clog2(NUM_WORDS * 4);

    logic [ADDR_WIDTH_WORDS-1:0]    imem_word_address;
    logic [ADDR_WIDTH_WORDS-1:0]    dmem_word_address;
    logic [3:0][7:0]                memory[0:NUM_WORDS-1];

    assign imem_word_address = imem_address[ADDR_WIDTH_BYTES-1:2];
    assign dmem_word_address = dmem_address[ADDR_WIDTH_BYTES-1:2];

    assign imem_data = memory[imem_word_address];
    assign dmem_data = memory[dmem_word_address];
    
    always_ff @(posedge clk) begin
        if (write_en) begin
            if (byte_en[0]) memory[dmem_word_address][0] <= data_in[7:0];
            if (byte_en[1]) memory[dmem_word_address][1] <= data_in[15:8];
            if (byte_en[2]) memory[dmem_word_address][2] <= data_in[23:16];
            if (byte_en[3]) memory[dmem_word_address][3] <= data_in[31:24]; 
        end
    end

endmodule