import csr_pkg::*;
import bus_pkg::*;

module bus # (
    parameter int NUM_WORDS = 1024
)(
    input  logic            clk,
    input  logic            rst_n,

    input  logic [31:0]     imem_address,
    output logic [31:0]     imem_data,
    input  logic            imem_read,

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

    logic dmem_wr, mtimer_wr, irq_gen_wr, uart_wr;
    logic uart_rd, dmem_rd, mtimer_rd, irq_gen_rd;
    logic irq_msip, irq_meip, irq_mtip;

    logic [31:0] dmem_out, irq_gen_out, mtimer_out, uart_out;

    bus_sel_e bus_select, bus_select_r;

    always_comb begin
        irq_p = '0;

        irq_p.MSI = irq_msip;
        irq_p.MEI = irq_meip;
        irq_p.MTI = irq_mtip;
    end

//------------------------------------------------------------------------------
// Address Decoding
//------------------------------------------------------------------------------

    assign dmem_wr      = write_en && (bus_select == SEL_DMEM);
    assign dmem_rd      = read_en && (bus_select == SEL_DMEM);
    assign mtimer_wr    = write_en && (bus_select == SEL_MTIMER);
    assign mtimer_rd    = read_en && (bus_select == SEL_MTIMER);
    assign irq_gen_wr   = write_en && (bus_select == SEL_IRQGEN);
    assign irq_gen_rd   = read_en && (bus_select == SEL_IRQGEN);
    assign uart_wr      = write_en && (bus_select == SEL_UART);
    assign uart_rd      = read_en && (bus_select == SEL_UART);

    always_comb begin
        unique case (1'b1)
            region_en(DMEM_REGION, address):    bus_select = SEL_DMEM;
            region_en(UART_REGION, address):    bus_select = SEL_UART;
            region_en(MSIP_REGION, address):    bus_select = SEL_IRQGEN;
            region_en(IRQGEN_REGION, address):  bus_select = SEL_IRQGEN;
            region_en(MTIMER_REGION, address):  bus_select = SEL_MTIMER;
            default:                            bus_select = SEL_NONE;
        endcase
    end

//------------------------------------------------------------------------------
// Reading
//------------------------------------------------------------------------------
    always_comb begin
        unique case (bus_select_r)
            SEL_DMEM:   data_out = dmem_out;
            SEL_IRQGEN: data_out = irq_gen_out;
            SEL_MTIMER: data_out = mtimer_out;
            SEL_UART:   data_out = uart_out;
            SEL_NONE:   data_out = '0;
            default:    data_out = '0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         bus_select_r <= SEL_NONE;
        else if (read_en)   bus_select_r <= bus_select;
    end

//------------------------------------------------------------------------------
// Modules
//------------------------------------------------------------------------------

    memory # (.NUM_WORDS(NUM_WORDS)) memory_inst (
        .clk            (clk),
        .imem_address   (imem_address),
        .imem_data      (imem_data),
        .imem_read      (imem_read),
        .dmem_address   (address),
        .data_in        (data_in),
        .write_en       (dmem_wr),
        .read_en        (dmem_rd),
        .byte_en        (byte_en),
        .dmem_data      (dmem_out)
    );
    
    simple_irq_gen irq_gen_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .address        (address),
        .data_in        (data_in),
        .write_en       (irq_gen_wr),
        .read_en        (irq_gen_rd),
        .irq_msip       (irq_msip),
        .irq_meip       (irq_meip),
        .data_out       (irq_gen_out)
    );

    mtimer mtimer_inst (
        .clk            (clk),
        .rst_n          (rst_n),
        .write_en       (mtimer_wr),
        .read_en        (mtimer_rd),
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

endmodule