// https://support.arm.com/documentation/ihi0022/l/?lang=en

interface bus_if #(
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
        output  AWVALID, AWSIZE, AWLEN, AWADDR,
        output  WVALID, WDATA, WLAST, WSTRB,
        output  ARVALID, ARSIZE, ARLEN, ARADDR
    );

    modport subordinate (
        input   ACLK, ARESETn,
        input   RREADY, BREADY,
        output  BVALID,
        output  RVALID, RDATA, RLAST,
        output  AWREADY, WREADY, ARREADY,
        input   AWVALID, AWSIZE, AWLEN, AWADDR,
        input   WVALID, WDATA, WLAST, WSTRB,
        input   ARVALID, ARSIZE, ARLEN, ARADDR
    );

endinterface