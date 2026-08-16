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

    logic dmem_wr, mtimer_wr, irq_gen_wr, uart_wr, boot_wr;
    logic uart_rd, dmem_rd, mtimer_rd, irq_gen_rd, boot_rd;
    logic irq_msip, irq_meip, irq_mtip;

    logic [31:0] dmem_out, irq_gen_out, mtimer_out, uart_out, boot_out;
    logic [31:0] imem_data_boot, imem_data_ram;

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
    assign boot_rd      = read_en && (bus_select == SEL_BOOT);
    assign boot_wr      = write_en && (bus_select == SEL_BOOT);

    always_comb begin
        unique case (1'b1)
            region_en(DMEM_REGION, address):    bus_select = SEL_DMEM;
            region_en(UART_REGION, address):    bus_select = SEL_UART;
            region_en(MSIP_REGION, address):    bus_select = SEL_IRQGEN;
            region_en(IRQGEN_REGION, address):  bus_select = SEL_IRQGEN;
            region_en(MTIMER_REGION, address):  bus_select = SEL_MTIMER;
            region_en(BOOT_REGION, address):    bus_select = SEL_BOOT;
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
            SEL_BOOT:   data_out = boot_out;
            SEL_NONE:   data_out = '0;
            default:    data_out = '0;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)         bus_select_r <= SEL_NONE;
        else if (read_en)   bus_select_r <= bus_select;
    end

    logic boot;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) boot <= 1'b1;
        else if (!region_en(BOOT_REGION, imem_address)) boot <= 1'b0;
    end

    always_comb begin
        if (boot) imem_data = imem_data_boot;
        else      imem_data = imem_data_ram;
    end

//------------------------------------------------------------------------------
// Modules
//------------------------------------------------------------------------------

    true_dual_port # (.NUM_WORDS(NUM_WORDS)) memory_inst (
        .clk            (clk),
        .address_b      (imem_address),
        .data_out_b     (imem_data_ram),
        .data_in_b      (32'd0),
        .write_b        (1'b0),
        .byte_en_b      (4'b1111),
        .address_a      (address),
        .write_a        (dmem_wr),
        .byte_en_a      (byte_en),
        .data_in_a      (data_in),
        .data_out_a     (dmem_out)
    );

    true_dual_port # (.NUM_WORDS(1024*4), .LOAD_MEM(1)) boot_inst (
        .clk            (clk),
        .address_a      (address - 32'hFFFFF000),
        .write_a        (boot_wr),
        .byte_en_a      (byte_en),
        .data_in_a      (data_in),
        .data_out_a     (boot_out), 
        .address_b      (imem_address - 32'hFFFFF000),
        .data_out_b     (imem_data_boot),
        .data_in_b      (32'd0),
        .byte_en_b      (4'd0),
        .write_b        (1'b0)
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