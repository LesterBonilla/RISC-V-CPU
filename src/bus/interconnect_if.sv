// https://support.arm.com/documentation/ihi0022/l/?lang=en

interface interconnect_if #(
    parameter DATA_WIDTH    = 32,
    parameter ADDR_WIDTH    = 32,
    parameter BRESP_WIDTH   = 0, // Not implemented
    parameter RRESP_WIDTH   = 0, // Not implemented
    parameter ID_W_WIDTH    = 0, // Not implemented 
    parameter ID_R_WIDTH    = 0  // Not implemented
)(
    input logic ACLK,
    input logic ARESETn
);

//------------------------------------------------------------------------------
// Localparams
//------------------------------------------------------------------------------
    localparam              WSTRB_WIDTH     = (DATA_WIDTH/8);
    localparam AxSIZE_e     AxSIZE_DEFAULT  = AxSIZE_e'($clog2(DATA_WIDTH/8));
    localparam AxBURST_e    AxBURST_DEFAULT = AxBURST_INCR;

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------

    // Write Request (AW)
    logic                   AWVALID;
    logic                   AWREADY;
    AxSIZE_e                AWSIZE;
    logic [7:0]             AWLEN;
    logic [ADDR_WIDTH-1:0]  AWADDR;
    AxBURST_e               AWBURST;

    // Write Data (W)
    logic                   WVALID;
    logic                   WREADY;
    logic [DATA_WIDTH-1:0]  WDATA;
    logic                   WLAST;
    logic [WSTRB_WIDTH-1:0] WSTRB;

    // Write response (B)
    logic                   BVALID;
    logic                   BREADY;

    // Read Request (AR)
    logic                   ARVALID;
    logic                   ARREADY;
    AxSIZE_e                ARSIZE;
    logic [7:0]             ARLEN;
    logic [ADDR_WIDTH-1:0]  ARADDR;
    AxBURST_e               ARBURST;

    // Read Data (R)
    logic                   RVALID;
    logic                   RREADY;
    logic [DATA_WIDTH-1:0]  RDATA;
    logic                   RLAST;

//------------------------------------------------------------------------------
// Types
//------------------------------------------------------------------------------
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

//------------------------------------------------------------------------------
// Modports
//------------------------------------------------------------------------------
    modport manager (
        input   ACLK, ARESETn,
        input   RVALID, RDATA, RLAST,
        output  RREADY, BREADY,
        input   BVALID,
        input   AWREADY, WREADY, ARREADY,
        output  AWVALID, AWSIZE, AWLEN, AWADDR, AWBURST,
        output  WVALID, WDATA, WLAST, WSTRB,
        output  ARVALID, ARSIZE, ARLEN, ARADDR, ARBURST
    );

    modport subordinate (
        input   ACLK, ARESETn,
        input   RREADY, BREADY,
        output  BVALID,
        output  RVALID, RDATA, RLAST,
        output  AWREADY, WREADY, ARREADY,
        input   AWVALID, AWSIZE, AWLEN, AWADDR, AWBURST,
        input   WVALID, WDATA, WLAST, WSTRB,
        input   ARVALID, ARSIZE, ARLEN, ARADDR, ARBURST
    );

//------------------------------------------------------------------------------
// Helper Functions
//------------------------------------------------------------------------------
    function automatic void set_manager_outputs_idle();
        RREADY  = '0;
        BREADY  = '0;
        AWVALID = '0;
        AWLEN   = '0;
        AWADDR  = '0;
        WVALID  = '0;
        WDATA   = '0;
        WLAST   = '0;
        WSTRB   = '0;
        ARVALID = '0;
        ARADDR  = '0;
        ARLEN   = '0;
        AWSIZE  = AxSIZE_DEFAULT;
        ARSIZE  = AxSIZE_DEFAULT;
        AWBURST = AxBURST_DEFAULT;
        ARBURST = AxBURST_DEFAULT;
    endfunction

    function automatic void set_subordinate_outputs_idle();
        BVALID  = '0;
        RVALID  = '0;
        RDATA   = '0;
        RLAST   = '0;
        AWREADY = '0;
        WREADY  = '0;
        ARREADY = '0;
    endfunction

    function automatic void connect_subordinate(interconnect_if.manager manager);
        manager.RVALID  = RVALID;
        manager.RDATA   = RDATA;
        manager.RLAST   = RLAST;
        manager.BVALID  = BVALID;
        manager.AWREADY = AWREADY;
        manager.WREADY  = WREADY;
        manager.ARREADY = ARREADY;
        RREADY  = manager.RREADY;
        BREADY  = manager.BREADY;
        AWVALID = manager.AWVALID;
        AWLEN   = manager.AWLEN;
        AWADDR  = manager.AWADDR;
        WVALID  = manager.WVALID;
        WDATA   = manager.WDATA;
        WLAST   = manager.WLAST;
        WSTRB   = manager.WSTRB;
        ARVALID = manager.ARVALID;
        ARADDR  = manager.ARADDR;
        ARLEN   = manager.ARLEN;
        AWSIZE  = manager.AWSIZE;
        ARSIZE  = manager.ARSIZE;
        AWBURST = manager.AWBURST;
        ARBURST = manager.ARBURST;
    endfunction

endinterface