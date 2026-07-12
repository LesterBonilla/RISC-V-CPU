module memory # (
    parameter int IMEM_SIZE_BYTES = 1024,
    parameter int DMEM_SIZE_BYTES = 1024
)(
    input  logic            clk,

    input  logic [31:0]     imem_address,
    
    input  logic [31:0]     dmem_address,
    input  logic [31:0]     write_data,
    input  logic [3:0]      write_mask,
    input  logic            write_en,
    
    output logic [31:0]     imem_data,
    output logic [31:0]     dmem_data

);

    localparam int IMEM_SIZE_WORDS = IMEM_SIZE_BYTES / 4;
    localparam int DMEM_SIZE_WORDS = DMEM_SIZE_BYTES / 4;

    localparam int IMEM_WIDTH_WORDS = $clog2(IMEM_SIZE_WORDS);
    localparam int DMEM_WIDTH_WORDS = $clog2(DMEM_SIZE_WORDS);

    localparam int IMEM_WIDTH_BYTES = $clog2(IMEM_SIZE_BYTES);
    localparam int DMEM_WIDTH_BYTES = $clog2(IMEM_SIZE_BYTES);

    logic [31:0] imem [IMEM_SIZE_WORDS-1:0];
    logic [31:0] dmem [DMEM_SIZE_WORDS-1:0];

    logic [IMEM_WIDTH_WORDS-1:0] imem_word_addr;
    logic [DMEM_WIDTH_WORDS-1:0] dmem_word_addr;

    assign imem_word_addr = imem_address[IMEM_WIDTH_BYTES-1:2];
    assign dmem_word_addr = dmem_address[DMEM_WIDTH_BYTES-1:2];

    
    always_ff @(posedge clk) begin
        
    end

    
endmodule