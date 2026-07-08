module data_memory #(
    parameter int SIZE = 1024,
    parameter int XLEN = 32,
    localparam int ADDR_WIDTH = $clog2(SIZE),
    localparam int NUM_BYTES = (XLEN/8)
)(
    input logic     clk,
    input logic     write_en,

    input logic [ADDR_WIDTH-1:0] read_address,
    input logic [ADDR_WIDTH-1:0] write_address,
    input logic [XLEN-1:0]       write_data,
    input logic [NUM_BYTES-1:0]  write_mask,

    output logic [XLEN-1:0] data_out
);

    logic [XLEN-1:0] memory [SIZE-1:0];
    //initial $readmemh("", memory);

    assign data_out = memory[read_address];

    always_ff @(posedge clk) begin
        if (write_en) begin
            if (write_mask[0]) memory[write_address][7:0]   <= write_data[7:0];
            if (write_mask[1]) memory[write_address][15:8]  <= write_data[15:8];
            if (write_mask[2]) memory[write_address][23:16] <= write_data[23:16];
            if (write_mask[3]) memory[write_address][31:24] <= write_data[31:24];
        end
    end
    
endmodule