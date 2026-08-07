import csr_pkg::*;
import bus_pkg::*;

module bus # (
    parameter int NUM_WORDS = 1024
)(
    input  logic            clk,
    input  logic            rst_n,

    input  logic [31:0]     imem_address,
    output logic [31:0]     imem_data,

    input  logic [31:0]     address,
    input  logic [31:0]     data_in,
    input  logic [3:0]      byte_en,
    input  logic            write_en,
    input  logic            read_en,

    input  logic            rx_pin,
    output logic            tx_pin,

    output logic [31:0]     data_out,
    output mip_mie_csr_t    irq_p
);

    logic dmem_en, mtimer_en, irq_gen_en, msip_en, uart_en;
    logic dmem_wr, mtimer_wr, irq_gen_wr, uart_wr;
    logic irq_msip, irq_meip, irq_mtip;
    logic uart_rd;

    logic [31:0] dmem_out, irq_gen_out, mtimer_out, uart_out; 

    always_comb begin
        irq_p = '0;

        irq_p.MSI = irq_msip;
        irq_p.MEI = irq_meip;
        irq_p.MTI = irq_mtip;
    end

//------------------------------------------------------------------------------
// Address Decoding
//------------------------------------------------------------------------------

    assign dmem_en      = (address >= MAIN_MEMORY_START_ADDR && address <= MAIN_MEMORY_END_ADDR);
    assign mtimer_en    = (address >= MTIMER_BASE_ADDR && address <= MTIMER_END_ADDR);
    assign irq_gen_en   = (address >= IRQ_GEN_BASE_ADDR && address <= IRQ_GEN_END_ADDR);
    assign msip_en      = (address == MSIP_BASE_ADDR);
    assign uart_en      = (address >= UART_BASE_ADDR && address <= UART_END_ADDR);

    assign dmem_wr      = dmem_en && write_en;
    assign mtimer_wr    = mtimer_en && write_en;
    assign irq_gen_wr   = (irq_gen_en || msip_en) && write_en;
    assign uart_wr      = uart_en && write_en;

    assign uart_rd      = uart_en && read_en;

//------------------------------------------------------------------------------
// Modules
//------------------------------------------------------------------------------

    memory # (.NUM_WORDS(NUM_WORDS)) memory_inst (
        .clk            (clk),

        .imem_address   (imem_address),
        .imem_data      (imem_data),

        .dmem_address   (address),
        .data_in        (data_in),
        .write_en       (dmem_wr),
        .byte_en        (byte_en),
        .dmem_data      (dmem_out)
    );
    
    simple_irq_gen irq_gen_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .address        (address),
        .data_in        (data_in),
        .write_en       (irq_gen_wr),
        .irq_msip       (irq_msip),
        .irq_meip       (irq_meip),
        .data_out       (irq_gen_out)
    );

    mtimer mtimer_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .write_en       (mtimer_wr),
        .address        (address),
        .data_in        (data_in),
        .data_out       (mtimer_out),
        .irq_mtip       (irq_mtip)
    );

    uart uart_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .rx_pin         (rx_pin),
        .read_en        (uart_rd),
        .write_en       (uart_wr),
        .data_in        (data_in[7:0]),
        .address        (address),
        .tx_pin         (tx_pin),
        .interrupt      (),
        .data_out       (uart_out)
    );

//------------------------------------------------------------------------------
// Reading
//------------------------------------------------------------------------------
    always_comb begin
        data_out = '0;

        unique case (1'b1)
            dmem_en:        data_out = dmem_out;
            irq_gen_en:     data_out = irq_gen_out;
            mtimer_en:      data_out = mtimer_out;
            uart_en:        data_out = uart_out;
            default:        data_out = '0;
        endcase
    end

endmodule