module simple_irq_gen(
    input logic         clk,
    input logic         rst_n,

    input logic [31:0]  address,
    input logic [31:0]  data_in,
    input logic         write_en,

    output logic        irq_msip,
    output logic        irq_meip,
    output logic [31:0] data_out
);

    localparam VERSION_ADDR = 32'h0C000000;
    localparam PLATFORM     = 32'h0C000004;
    localparam VERSION      = 32'h0010000;
    localparam MASK         = (32'd1 << 3) & (32'd1 << 11);

    logic [31:0] platform;
    
    assign irq_msip = platform[3];
    assign irq_meip = platform[11];
    assign data_out = (address == VERSION_ADDR) ? VERSION : 32'd0; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            platform    <= '0;

        end else if (write_en && (address == PLATFORM)) begin
            if (data_in[31])    platform <= platform | (data_in & MASK);
            else                platform <= platform & ~(data_in & MASK);
        end
    end

endmodule