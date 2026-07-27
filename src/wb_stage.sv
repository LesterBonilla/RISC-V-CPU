import decode_pkg::*;
import pipeline_pkg::*;
import csr_pkg::*;

module wb_stage (
    input mem_wb_reg_t  mem_wb,

    output logic        reg_write,
    output logic [4:0]  rd_addr,
    output logic [31:0] wb_result,

    // Zicsr Extension
    input  logic [31:0] csr_read_data,
    output logic [31:0] csr_write_data,
    output logic [11:0] csr_addr,
    output csr_op_e     csr_op,
    output logic        inst_ret,

    // Exceptions and interrupts
    input mip_mie_csr_t mip,
    input mip_mie_csr_t mie,
    input mstatus_csr_t mstatus,
    input logic [31:0]  mepc_in,
    input logic [31:0]  mtvec,
    
    output logic        redirect,
    output logic        trap,
    output logic        mret,
    output logic [31:0] mepc_out,
    output logic [31:0] mcause,
    output logic [31:0] pc_target
);

    opcode_e        opcode_wb;
    logic           valid_irq, csr_mstatus_access, csr_mie_access;
    mip_mie_csr_t   csr_mie_next; 
    mstatus_csr_t   csr_mstatus_next, mret_mstatus_next;

//------------------------------------------------------------------------------
// Traps and MRET
//------------------------------------------------------------------------------
    assign trap                 = valid_irq || mem_wb.exception;
    assign mret                 = mem_wb.mret && !mem_wb.exception;
    assign redirect             = trap || mret;
    assign csr_mstatus_access   = (mem_wb.csr_addr == MSTATUS)  && (mem_wb.csr_op != CSR_NOP);
    assign csr_mie_access       = (mem_wb.csr_addr == MIE)      && (mem_wb.csr_op != CSR_NOP);

    always_comb begin : handle_csr_irq_access
        // Per the spec, if a csr operation updates an interrupt register,
        // an interrupt evaluation must happen immediately.
        csr_mie_next        = '0;
        csr_mstatus_next    = '0;

        if ((mem_wb.csr_addr == MSTATUS)) begin
            unique case (mem_wb.csr_op)
                CSR_RW, CSR_RWI: csr_mstatus_next = (mem_wb.csr_data & MSTATUS_WR_MASK);
                CSR_RS, CSR_RSI: csr_mstatus_next = mstatus | (mem_wb.csr_data & MSTATUS_WR_MASK);
                CSR_RC, CSR_RCI: csr_mstatus_next = mstatus & ~(mem_wb.csr_data & MSTATUS_WR_MASK);
                default: ;
            endcase
        end else if ((mem_wb.csr_addr == MIE)) begin
            unique case (mem_wb.csr_op)
                CSR_RW, CSR_RWI: csr_mie_next = (mem_wb.csr_data & MIE_WR_MASK);
                CSR_RS, CSR_RSI: csr_mie_next = mie | (mem_wb.csr_data & MIE_WR_MASK);
                CSR_RC, CSR_RCI: csr_mie_next = mie & ~(mem_wb.csr_data & MIE_WR_MASK);
                default: ;
            endcase
        end
    end // always_comb handle_csr_irq_access

    always_comb begin : handle_trap_source
        // Priority: Exception > MEI > MSI > MTI
        mip_mie_csr_t valid_irqs;

        valid_irq   = 1'b0;
        mcause      = '0;
        mepc_out    = '0;
        valid_irqs  = (mip & mie);
        
        mret_mstatus_next       = mstatus;
        mret_mstatus_next.MIE   = mstatus.MPIE;
        mret_mstatus_next.MPIE  = 1'b1;

        if (mret) begin
            valid_irq   = mret_mstatus_next.MIE && (valid_irqs != '0);

        end else if (csr_mie_access) begin
            valid_irqs  = (mip & csr_mie_next);
            valid_irq   = mstatus.MIE && (valid_irqs != '0);

        end else if (csr_mstatus_access) begin    
            valid_irq   = csr_mstatus_next.MIE && (valid_irqs != '0);

        end else begin
            valid_irq   = mstatus.MIE && (valid_irqs != '0);
        end

        if (mem_wb.exception) begin
            mepc_out    = mem_wb.pc;
            mcause      = mem_wb.mcause;

        end else if (valid_irq) begin
            if (mret)   mepc_out = mepc_in; // If interrupt is serviced after mret, keep same mepc
            else        mepc_out = mem_wb.pc_plus4; 
            
            priority case (1'b1) 
                valid_irqs.MEI: mcause = INTERRUPT_MACHINE_EXTERNAL;
                valid_irqs.MSI: mcause = INTERRUPT_MACHINE_SOFTWARE;
                valid_irqs.MTI: mcause = INTERRUPT_MACHINE_TIMER;
                default: ;
            endcase

        end
    end // always_comb handle_trap_source

    always_comb begin : calculate_trap_pc_target        
        pc_target       = '0;        
        // TODO: Add support for rw mtvec and vectored mode
        if (mret & !valid_irq)  pc_target = mepc_in;
        else                    pc_target = mtvec;
    end

//------------------------------------------------------------------------------
// Regfile and CSR Writeback
//------------------------------------------------------------------------------

    assign opcode_wb        = mem_wb.opcode;
    assign reg_write        = mem_wb.valid && !mem_wb.exception && mem_wb.reg_write;
    assign rd_addr          = mem_wb.rd_addr;

    // Zicsr Extension
    assign csr_write_data   = mem_wb.csr_data;
    assign csr_addr         = mem_wb.csr_addr;
    assign csr_op           = mem_wb.csr_op;
    assign inst_ret         = mem_wb.valid && !mem_wb.exception; // Valid means not a bubble

    always_comb begin
        wb_result = '0;

        unique case (mem_wb.wb_src) 
            WB_SRC_ALU:         wb_result = mem_wb.alu_result;
            WB_SRC_MEM:         wb_result = mem_wb.mem_data;
            WB_SRC_PC_PLUS4:    wb_result = mem_wb.pc_plus4;
            WB_SRC_CSR:         wb_result = csr_read_data;
            default: ;
        endcase
    end
    
endmodule