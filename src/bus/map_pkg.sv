package map_pkg;
//------------------------------------------------------------------------------
// Address Map
//------------------------------------------------------------------------------
    localparam RAM_BASE_ADDR        = 32'h00000000;
    localparam RAM_SIZE             = 32'h00040000;
    
    localparam IRQ_GEN_BASE_ADDR    = 32'h0C000000;
    localparam IRQ_GEN_SIZE         = 32'h00001000;
    localparam MSIP_BASE_ADDR       = 32'h02000000;
    localparam MSIP_SIZE            = 32'h00001000;
    
    localparam MTIMER_BASE_ADDR     = 32'h02008000;
    localparam MTIMER_SIZE          = 32'h00004000;

    localparam UART_BASE_ADDR       = 32'h10000000;
    localparam UART_SIZE            = 32'h00001000;

    localparam BOOT_BASE_ADDR       = 32'hFFFFF000;
    localparam BOOT_SIZE            = 32'h00001000;

//------------------------------------------------------------------------------
// Types
//------------------------------------------------------------------------------
    typedef struct packed { 
        logic [31:0] base;
        logic [31:0] size;
    } mem_region_t;

    typedef enum logic [1:0] {
        OWNER_NONE,
        OWNER_IMEM,
        OWNER_DMEM
    } owner_e;

    typedef enum int { 
        SEL_NONE,
        SEL_RAM,
        SEL_IRQGEN,
        SEL_MTIMER,
        SEL_UART,
        SEL_BOOT 
    } subordinates_e;

    typedef enum int {
        MANAGER_NONE,
        MANAGER_IMEM,
        MANAGER_DMEM
    } managers_e;

    localparam mem_region_t RAM_REGION      = '{base: RAM_BASE_ADDR, size: RAM_SIZE};
    localparam mem_region_t IRQGEN_REGION   = '{base: IRQ_GEN_BASE_ADDR, size: IRQ_GEN_SIZE};
    localparam mem_region_t MTIMER_REGION   = '{base: MTIMER_BASE_ADDR, size: MTIMER_SIZE};
    localparam mem_region_t UART_REGION     = '{base: UART_BASE_ADDR, size: UART_SIZE};
    localparam mem_region_t MSIP_REGION     = '{base: MSIP_BASE_ADDR, size: MSIP_SIZE};
    localparam mem_region_t BOOT_REGION     = '{base: BOOT_BASE_ADDR, size: BOOT_SIZE};

    localparam int NUM_SUBORDINATES = 5;
    localparam int NUM_MANAGERS = 2;

    function automatic logic region_en(mem_region_t region, logic [31:0] address);
        logic [31:0] mask;
        mask = ~(region.size - 1);
        return ((address & mask) == region.base);
    endfunction

    function automatic int unsigned region_addr_width(mem_region_t region);
        return $clog2(region.size);
    endfunction

    function automatic subordinates_e decode_address(logic [31:0] address);
        case (1'b1) 
            region_en(RAM_REGION, address):     decode_address = SEL_RAM;
            region_en(BOOT_REGION, address):    decode_address = SEL_BOOT;
            region_en(UART_REGION, address):    decode_address = SEL_UART;
            region_en(MSIP_REGION, address):    decode_address = SEL_IRQGEN;
            region_en(IRQGEN_REGION, address):  decode_address = SEL_IRQGEN;
            region_en(MTIMER_REGION, address):  decode_address = SEL_MTIMER;
            default:                            decode_address = SEL_NONE;
        endcase
    endfunction

endpackage