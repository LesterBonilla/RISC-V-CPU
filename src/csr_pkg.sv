package csr_pkg;
    // Unprivileged Counters/Timers
    localparam CYCLE            = 12'hC00;
    localparam TIME             = 12'hC01;
    localparam INSTRET          = 12'hC02;
    localparam HPMCOUNTER3      = 12'hC03;
    // Counters 4-30
    localparam HPMCOUNTER31     = 12'hC1F;
    localparam CYCLEH           = 12'hC80;
    localparam TIMEH            = 12'hC81;
    localparam INSTRETH         = 12'hC82;
    localparam HPMCOUNTER3H     = 12'hC83;
    // Counters 4-30
    localparam HPMCOUNTER31H    = 12'hC9F;

    // Machine Information Registers (Read only)
    localparam MVENDORID        = 12'hF11;
    localparam MARCHID          = 12'hF12;
    localparam MIMPID           = 12'hF13;
    localparam MHARTID          = 12'hF14;
    localparam MCONFIGPTR       = 12'hF15;

    // Machine Trap Setup 
    localparam MSTATUS          = 12'h300;
    localparam MISA             = 12'h301;
    localparam MEDELEG          = 12'h302; // Does not exist if S-mode not supported 
    localparam MIDELEG          = 12'h303; // Does not exist if S-mode not supported
    localparam MIE              = 12'h304;
    localparam MTVEC            = 12'h305;
    localparam MCOUNTEREN       = 12'h306; // Does not exist if U-mode not supported
    localparam MSTATUSH         = 12'h310;
    localparam MEDELEGH         = 12'h312; // Does not exist if S-mode not supported

    // Machine Trap Handling
    localparam MSCRATCH         = 12'h340;
    localparam MEPC             = 12'h341;
    localparam MCAUSE           = 12'h342;
    localparam MTVAL            = 12'h343;
    localparam MIP              = 12'h344;
    localparam MTINST           = 12'h34A;
    localparam MTVAL2           = 12'h34B;

    // Machine Indirect 
    localparam MISELECT         = 12'h350;
    localparam MIREG            = 12'h351;
    localparam MIREG2           = 12'h352;
    localparam MIREG3           = 12'h353;
    localparam MIREG5           = 12'h355;
    localparam MIREG6           = 12'h356;
    localparam MIREG7           = 12'h357;

    // Machine Configuration
    localparam MENVCFG          = 12'h30A; // Does not exist if U-mode not supported
    localparam MENVCFGH         = 12'h31A; // Does not exist if U-mode not supported
    localparam MSECCFG          = 12'h747; // Reserved if no extenions adds a field to it
    localparam MSECCFGH         = 12'h757; // Does not exist if MSECCFG is not implemented

    // Machine Counters
    localparam MCYCLE           = 12'hB00;
    localparam MINSTRET         = 12'hB02;
    localparam MHPMCOUNTER3     = 12'hB03;
    // ... Counters 4-30
    localparam MHPCOUNTER31     = 12'hB1F;
    localparam MCYCLEH          = 12'hB80;
    localparam MINSTRETH        = 12'hB82;
    localparam MHPMCOUNTER3H    = 12'hB83;
    // ... Counters 4-30
    localparam MHPCOUNTER31H    = 12'hB9F;

    // Machine Counter Setup (mhpeventnh depend on Sscofpmf extension)
    localparam MCOUNTINHIBIT    = 12'h320;
    localparam MCYCLECFG        = 12'h321;
    localparam MINSTRETCFG      = 12'h322;
    localparam MHPMEVENT3       = 12'h323;
    // ... MHPEVENT 4-30
    localparam MHPMEVENT31      = 12'h33F;
    localparam MCYCLECFGH       = 12'h721;
    localparam MINSTRETCFGH     = 12'h722;
    localparam MHPMEVENT3H      = 12'h723;
    // ... MHPEVENT 4-30
    localparam MHPMEVENT31H     = 12'h73F;

    // Machine Control Transfer Records Configuration
    localparam MCTRCTL          = 12'h34E;

    // Debug/Trace Registers (shared between M-mode and Debug mode)
    localparam TSELECT          = 12'h710;
    localparam TDATA1           = 12'h7A1;
    localparam TDATA2           = 12'h7A2;
    localparam TDATA3           = 12'h7A3;
    localparam MCONTEXT         = 12'h7A8;

    // Debug Mode Registers
    localparam DCSR             = 12'h7B0;
    localparam DPC              = 12'h7B1;
    localparam DSCRATCH0        = 12'h7B2;
    localparam DSCRATCH1        = 12'h7B3;

    typedef struct packed {
        logic [20:0]    reserved;   // Bits 31:11 
        logic           MDT;        // M-mode disable trap, Smdbltrp extension, set to 1 on reset, 
                                    // clears MIE when set to 1 by CSR write. When a trap is taken into
                                    // M-mode, set to 1 if it is 0. If already 1, the trap is an "unexpected trap"
                                    // If Smrnmi extension is implemented, an RNMI trap is not unexpected and does not 
                                    // set the MDT bit. Unexpected traps are handled differently if Smrnmi is present.
                                    // If an unexpected trap happens without Smrnmi, the hart enters critical-error state.
                                    // MRET and SRET set MDT to 0. If Smrnmi is implemented, MNRET sets MDT to 0 if the new
                                    // privilege mode is not M.
        logic           MPELP;      // M-mode previous expected landing pad, read-only 0 if Zicflip not supported
        logic           reserved2;  // Bit 8
        logic           MPV;        // M-mode previous virtualization mode, read-only 0 when only M-mode supported
        logic           GVA;        // Guest virtual address, read-only 0 when S-mode is not supported
        logic           MBE;        // M-mode big endian, for memory accesses other than instructions, which are always little
        logic           SBE;        // S-mode big endian, read-only 0 if S-mode not supported
        logic [3:0]     reserved3;  // {S-XLEN[1:0], U-SXLEN[1:0]} Both default to 32 when XLEN = 32.
    } mstatush_csr_t;

    localparam MSTATUSH_WR_MASK = {21'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0};

    typedef struct packed {
        logic           SD;         // Status dirty, read-only 0 if XS, VS, FS are read-only 0
        logic [5:0]     reserved;   // Bits 30:25
        logic           SDT;        // S-mode disable trap, read-only 0 if S-mode not supported
        logic           SPELP;      // S-mode previous expected landing pad, read-only 0 if Zicflip not supported
        logic           TSR;        // Trap SRET, read-only 0 if S-mode not supported
        logic           TW;         // Timeout wait, read-only 0 if only M-mode is supported
        logic           TVM;        // Trap virtual memory, read-only 0 if S-mode is not supported
        logic           MXR;        // Make executable readable, read-only 0 if S-mode is not supported
        logic           SUM;        // Permit supervisor user memory access, read-only 0 if S-mode not supported
        logic           MPRV;       // Modify effective privilege mode, read-only 0 if U-mode is not supported
        logic [1:0]     XS;         // Extension context status, read-only 0 if no extensions implemented that add new state
        logic [1:0]     FS;         // Floating point context status, read-only 0 if F extension and S-mode are not supported
        logic [1:0]     MPP;        // M-mode previous privilige mode
        logic [1:0]     VS;         // Vector context status, read-only 0 if V registers and S-mode are not supported
        logic           SPP;        // S-mode previous privlilege mode, read-only 0 if not supported
        logic           MPIE;       // M-mode previous interrupt-enable
        logic           UBE;        // U-mode big endian, read-only 0 if U-mode not supported
        logic           SPIE;       // S-mode previous interrupt-enable, read-only 0 if not supported
        logic           reserved2;  // Bit 4
        logic           MIE;        // M-mode global interrupt-enable, can only be set to 1 if MDT is 0
        logic           reserved3;  // Bit 2
        logic           SIE;        // S-mode global interrupt-enable, read-only 0 if not supported
        logic           reserved4;  // Bit0
    } mstatus_csr_t;

    localparam MSTATUS_WR_MASK  = {1'b0, 6'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 2'b0, 2'b0, 2'b0, 2'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0};
    localparam MSTATUS_RESET    = 32'h00001800; // Set MPP to 11 = M-Mode

    typedef struct packed {
        logic [31:2]    base;       // Vector base address, [XLEN-1:2], low 2 bits are 0 to align with 4-byte boundary
        logic [1:0]     mode;       // Vector mode:
                                    //  0 : Direct: All traps set pc to base
                                    //  1 : Vectored: Asynchronous interrupts set pc to (base + 4 x cause)
    } mtvec_csr_t; 

    typedef struct packed {
        // Interrupt priority in descending order:
        // MEI, MSI, MTI, SEI, SSI, STI, LCOFI
        logic [31:16]   custom;     // Platform-specific interrupts
        logic [1:0]     zero;       //
        logic           LCOF;       // Local-counter-overflow interrupts, read-only 0 if Sscofpmf extension not implemented
        logic           zero1;      //
        logic           MEI;        // Machine-level external interrupts, used by platform-specific interrupt controller
        logic           zero2;      //
        logic           SEI;        // Supervisor-level external interrupts, read-only 0 if S-mode not supported
        logic           zero3;      //
        logic           MTI;        // Machine-level machine timer interrupts
        logic           zero4;      //
        logic           STI;        // Supervisor-level timer interrupts, read-only 0 if S-mode not supported
        logic           zero5;      //
        logic           MSI;        // Machine-level software interrupts, may be read-only 0 if only one hart 
        logic           zero6;      //
        logic           SSI;        // Supervisor-level software interrupts, read-only 0 if S-mode not supported
        logic           zero7;      //
    } mip_mie_csr_t;

    typedef struct packed {
        logic [28:0]    stop_hpm;   // When 0: increment as usual, when 1: Stop incrementing. Zero if mcountinhibit not supported
        logic           stop_ir;    // Inhibit minstret
        logic           zero;       // Unused
        logic           stop_cy;    // Inhibit mcycle
    } mcountinhibit_csr_t;

    typedef struct packed {
        logic           interrupt;  // Set if trap was caused by an interrupt
        logic [30:0]    ex_code;    // Exception code that caused the trap
    } mcause_csr_t;

endpackage