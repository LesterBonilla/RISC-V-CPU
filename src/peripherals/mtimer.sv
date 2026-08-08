module mtimer (
    input logic         clk,
    input logic         rst_n,

    input logic         write_en,
    input logic         read_en,
    input logic [31:0]  address,
    input logic [31:0]  data_in,

    output logic [31:0] data_out,
    output logic        irq_mtip
);
    localparam MTIME_L    = 32'h0200BFF8;
    localparam MTIME_H    = 32'h0200BFFC;
    localparam MTIMECMP_L = 32'h02008000;
    localparam MTIMECMP_H = 32'h02008004;

    logic [63:0] mtime, mtimecmp, next_mtime, next_mtimecmp;
    logic [31:0] next_data_out;

    assign irq_mtip = (mtime >= mtimecmp);

    always_comb begin
        next_mtime      = mtime + 1'b1;
        next_mtimecmp   = mtimecmp;

        if (write_en) begin
            unique case (address)
                    MTIME_L:    next_mtime[31:0]     = data_in;
                    MTIME_H:    next_mtime[63:32]    = data_in;
                    MTIMECMP_L: next_mtimecmp[31:0]  = data_in;
                    MTIMECMP_H: next_mtimecmp[63:32] = data_in;
                    default: ;
            endcase
        end
    end

    always_comb begin
        next_data_out = '0;
        
         unique case (address)
            MTIME_L:    next_data_out = mtime[31:0]; 
            MTIME_H:    next_data_out = mtime[63:32];   
            MTIMECMP_L: next_data_out = mtimecmp[31:0]; 
            MTIMECMP_H: next_data_out = mtimecmp[63:32];
            default: ;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mtime       <= 64'd0;
            mtimecmp    <= 64'd0 - 64'd1;
            data_out    <= '0;

        end else begin
            mtime       <= next_mtime;
            mtimecmp    <= next_mtimecmp;

            if (read_en) begin
                data_out <= next_data_out;
            end
        end
    end

endmodule