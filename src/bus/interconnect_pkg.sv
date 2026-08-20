package interconnect_pkg;
    localparam              DATA_WIDTH      = 32;
    localparam              ADDR_WIDTH      = 32;
    localparam              WSTRB_WIDTH     = (DATA_WIDTH/8);
    localparam AxSIZE_e     AxSIZE_DEFAULT  = AxSIZE_e'($clog2(DATA_WIDTH/8));
    localparam AxBURST_e    AxBURST_DEFAULT = AxBURST_INCR;

    typedef enum logic[2:0] {
        AxSIZE_1BYTE    = 3'b000,
        AxSIZE_2BYTE    = 3'b001,
        AxSIZE_4BYTE    = 3'b010,
        AxSIZE_8BYTE    = 3'b011,
        AxSIZE_16BYTE   = 3'b100,
        AxSIZE_32BYTE   = 3'b101,
        AxSIZE_64BYTE   = 3'b110,
        AxSIZE_124BYTE  = 3'b111 
    } AxSIZE_e;

    typedef enum logic [1:0] {
        AxBURST_FIXED       = 2'b00,
        AxBURST_INCR        = 2'b01,
        AxBURST_WRAP        = 2'b10,
        AxBURST_RESERVED    = 2'b11
    } AxBURST_e;

    typedef struct packed {
        axi_manager_aw_t    AW;
        axi_manager_w_t     W;
        axi_manager_b_t     B;
        axi_manager_ar_t    AR;
        axi_manager_r_t     R;
    } axi_manager_t;

    typedef struct packed {
        logic                   AWVALID;
        AxSIZE_e                AWSIZE;
        logic [7:0]             AWLEN;
        logic [ADDR_WIDTH-1:0]  AWADDR;
        AxBURST_e               AWBURST;
    } axi_manager_aw_t;

    typedef struct packed {
        logic                   WVALID;
        logic [DATA_WIDTH-1:0]  WDATA;
        logic                   WLAST;
        logic [WSTRB_WIDTH-1:0] WSTRB;
    } axi_manager_w_t;

    typedef struct packed {
        logic                   BREADY;
    } axi_manager_b_t;

    typedef struct packed {
        logic                   ARVALID;
        AxSIZE_e                ARSIZE;
        logic [7:0]             ARLEN;
        logic [ADDR_WIDTH-1:0]  ARADDR;
        AxBURST_e               ARBURST;
    } axi_manager_ar_t;

    typedef struct packed {
        logic   RREADY;
    } axi_manager_r_t;

    typedef struct packed {
        axi_subordinate_aw_t    AW;
        axi_subordinate_w_t     W;
        axi_subordinate_b_t     B;
        axi_subordinate_ar_t    AR;
        axi_subordinate_r_t     R;
    } axi_subordinate_t;

    typedef struct packed {
        logic   AWREADY;
    } axi_subordinate_aw_t;

    typedef struct packed {
        logic    WREADY;     
    } axi_subordinate_w_t;

    typedef struct packed {
        logic   BVALID;
    } axi_subordinate_b_t;

    typedef struct packed {
        logic   ARREADY;
    } axi_subordinate_ar_t;

    typedef struct packed {
        logic   RVALID;
        logic   RLAST;
        logic [DATA_WIDTH-1:0]  RDATA;       
    } axi_subordinate_r_t;

endpackage : interconnect_pkg