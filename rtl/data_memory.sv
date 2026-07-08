module data_memory #(
    parameter int SIZE = 1024,
    parameter int XLEN = 32,
    localparam int ADDR_WIDTH = $clog2(SIZE)
)(
    input logic     clk,
    input logic     write_en,

    input logic [ADDR_WIDTH-1:0] write_address,
    input logic [ADDR_WIDTH-1:0] read_address,
    input logic [XLEN-1:0]       write_data,

    output logic [XLEN-1:0] data_out
);

    logic [XLEN-1:0] memory [SIZE-1:0];
    //initial $readmemh("", memory);

    assign data_out = memory[read_address];

    always_ff @(posedge clk) begin
        if (write_en)
            memory[write_address] <= write_data;
    end
    
endmodule