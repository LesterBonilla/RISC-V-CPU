module synch_fifo #(
    parameter int unsigned WIDTH    = 16,
    parameter int unsigned DEPTH    = 16
)(
    input logic                 clk,
    input logic                 rst_n,
    input logic                 flush,

    input logic                 write_en,
    input logic                 read_en,
    input logic [WIDTH-1:0]     data_in,

    output logic                empty,
    output logic                full,
    output logic [WIDTH-1:0]    data_out,

    output logic [$clog2(DEPTH):0] count
);

    // FIFO flags and count:
    //  Empty:  No entries pushed. Determined by read_ptr == write_ptr.
    //  Full:   No space for new entries. Determined by read and write 
    //          pointers being equal in all but the most significant bit.      
    //  Count:  The number of entries in the FIFO.
    //
    // FIFO Pointers:
    //  read_ptr: Points to next data to be read. Incremented on a read_en signal.
    //  write_ptr: Points to next empty slot in the FIFO. Incremented on a write_en signal.
    //  
    // The pointers have a width of $clog(DEPTH) to address each entry of the FIFO plus one bit. 
    // The extra bit is used to determine if the write pointer has caught up to the read pointer. 
    // If they match exactly, the FIFO is empty. If they match in all than the most significant bit, 
    // the FIFO is full.
    //
    // FIFO Operations:
    //  Push/Write: If !full, register the data and increment the write pointer.
    //  Pop/Read: If !empty, increment the read pointer.
    //  Flush: Reset the pointers to zero
    //  
    // Reads and writes are ignored if empty or full, respectively. An exception for writes is below.
    //
    // Fall through behavior: The first item in the FIFO is always visible.
    //
    // Edge cases:
    //  Simultaneous read/write of a full FIFO should work

    localparam int unsigned PTR_WIDTH = $clog2(DEPTH);

    logic [PTR_WIDTH:0] read_ptr, next_read_ptr, write_ptr, next_write_ptr;
    logic [WIDTH-1:0] data [0:DEPTH-1];
    
    assign empty    = (read_ptr == write_ptr);
    assign full     = (read_ptr[PTR_WIDTH] != write_ptr[PTR_WIDTH]) && (read_ptr[PTR_WIDTH-1:0] == write_ptr[PTR_WIDTH-1:0]);

    assign data_out = data[read_ptr[PTR_WIDTH-1:0]];
    assign count    = write_ptr - read_ptr;

    always_comb begin
        next_read_ptr   = read_ptr;
        next_write_ptr  = write_ptr;

        // Push
        if (write_en && (!full || read_en)) begin
            next_write_ptr  = write_ptr + 1'b1;
        end
        // Pop
        if (read_en && !empty) begin
            next_read_ptr   = read_ptr + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_ptr    <= '0;
            write_ptr   <= '0;
        end else if (flush) begin
            read_ptr    <= '0;
            write_ptr   <= '0;
        end else begin
            read_ptr    <= next_read_ptr;
            write_ptr   <= next_write_ptr;

            if (write_en && (!full || read_en))
                data[write_ptr[PTR_WIDTH-1:0]] <= data_in;
        end
    end

endmodule