module pipeline_register #(
    parameter type T = logic [31:0]
)(
    input logic clk,
    input logic rst_n,
    input logic en_n,
    input logic flush,

    input T     data_in,

    output T    data_out
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= '0;
            
        end else if (flush) begin // TODO: Decide if this should affect just the valid bit
            data_out <= '0;
        
        end else if (!en_n) begin
            data_out <= data_in;
        end
    end
    
endmodule