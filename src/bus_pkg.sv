package bus_pkg;
    localparam MAIN_MEMORY_START_ADDR   = 32'h00000000;
    localparam MAIN_MEMORY_END_ADDR     = 32'h0003FFFF;
    
    localparam IRQ_GEN_BASE_ADDR        = 32'h0C000000;
    localparam IRQ_GEN_END_ADDR         = 32'h0C0003FF;
    
    localparam MTIMER_BASE_ADDR         = 32'h02004000;
    localparam MTIMER_END_ADDR          = 32'h0200BFFF;

    localparam MSIP_BASE_ADDR           = 32'h02000000;
endpackage