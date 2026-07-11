module instruction_memory #(
    parameter int SIZE_WORDS = 1024
)(
    input   logic [31:0]  address,
    output  logic [31:0]  data_out
);

    localparam int ADDR_WIDTH_BYTES = $clog2(SIZE_WORDS * 4);

    logic [31:0] memory [SIZE_WORDS-1:0];
    initial $readmemh("imem.hex", memory);

    assign data_out = memory[address[ADDR_WIDTH_BYTES-1:2]];
    
endmodule