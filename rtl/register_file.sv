module register_file (
    input logic         clk,
    input logic         rst_n,

    input logic [4:0]   rs1_addr,
    input logic [4:0]   rs2_addr,
    input logic [4:0]   dest_addr,
    input logic         dest_write_en,
    input logic [31:0]  dest_write_data,

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    logic [31:0] registers [0:31];

    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : registers[rs2_addr];

    // Write on falling edge so it can write a result in first half of cycle and read
    // that result in the second half. Prevents needing to forward from WB -> ID.
    always_ff @(negedge clk or negedge rst_n) begin
        if (!rst_n) 
            registers <= '0;
        else if (dest_write_en && dest_addr != 5'd0)
            registers[dest_addr] <= dest_write_data;
    end
    
endmodule