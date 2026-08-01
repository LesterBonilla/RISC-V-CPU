module pipeline_register #(
    parameter int WIDTH = 32
)(
    input logic clk,
    input logic rst_n,
    input logic stall,
    input logic flush,

    input logic [WIDTH-1:0]     data_in,
    output logic [WIDTH-1:0]    data_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= '0;
            
        end else if (flush) begin
            data_out <= '0;
        
        end else if (!stall) begin
            data_out <= data_in;
        end
    end
    
endmodule