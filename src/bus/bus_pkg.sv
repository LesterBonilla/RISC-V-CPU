package bus_pkg;
    localparam DMEM_BASE_ADDR       = 32'h00000000;
    localparam DMEM_SIZE            = 32'h00040000;
    
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

    typedef struct packed { 
        logic [31:0] base;
        logic [31:0] size;
    } mem_region_t;

    typedef enum logic [2:0] { 
        SEL_NONE,
        SEL_DMEM,
        SEL_IRQGEN,
        SEL_MTIMER,
        SEL_UART,
        SEL_BOOT 
    } bus_sel_e;

    localparam mem_region_t DMEM_REGION     = '{base: DMEM_BASE_ADDR, size: DMEM_SIZE};
    localparam mem_region_t IRQGEN_REGION   = '{base: IRQ_GEN_BASE_ADDR, size: IRQ_GEN_SIZE};
    localparam mem_region_t MTIMER_REGION   = '{base: MTIMER_BASE_ADDR, size: MTIMER_SIZE};
    localparam mem_region_t UART_REGION     = '{base: UART_BASE_ADDR, size: UART_SIZE};
    localparam mem_region_t MSIP_REGION     = '{base: MSIP_BASE_ADDR, size: MSIP_SIZE};
    localparam mem_region_t BOOT_REGION     = '{base: BOOT_BASE_ADDR, size: BOOT_SIZE};

    function automatic logic region_en(mem_region_t region, logic [31:0] address);
        return (address & ~(region.size - 1)) == region.base;
    endfunction

endpackage