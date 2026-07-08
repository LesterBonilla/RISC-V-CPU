module instruction_memory #(
    parameter int SIZE = 1024,
    parameter int XLEN = 32,
    localparam int ADDR_WIDTH = $clog2(SIZE)
)(
    input   logic [ADDR_WIDTH-1:0]  read_address,
    output  logic [XLEN-1:0]        data_out
);

    logic [XLEN-1:0] memory [SIZE-1:0];
    //initial $readmemh("", memory);

    assign data_out = memory[read_address];
    
endmodule