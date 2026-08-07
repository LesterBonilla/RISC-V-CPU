#ifndef _RVMODEL_MACROS_H
#define _RVMODEL_MACROS_H

//------------------------------------------------------------------------------
// Test Results
//------------------------------------------------------------------------------
#define TEST_RESULT_ADDR 0xCAFE0000
#define RVMODEL_HALT_PASS        \
    li  x1, 1                   ;\
    li  t0, TEST_RESULT_ADDR    ;\
    sw  x1, 0(t0)               ;\
    DONE_PASS:                  ;\
        j   DONE_PASS           ;\

#define RVMODEL_HALT_FAIL        \
    li  x1, -1                  ;\
    li  t0, TEST_RESULT_ADDR    ;\
    sw  x1, 0(t0)               ;\
    DONE_FAIL:                  ;\
        j   DONE_FAIL           ;\

//------------------------------------------------------------------------------
// IO Writing (UART)
//------------------------------------------------------------------------------
#define IO_ADDR 0xCAFECAF0
#define UART_BASE_ADDR 0x10000000
#define UART_THR (UART_BASE_ADDR + 0)
#define UART_LCR (UART_BASE_ADDR + 12)
#define UART_LSR (UART_BASE_ADDR + 20)

#define RV_MODEL_IO_INIT(_R1, _R2, _R3) \
uart_init:              ;\
    li _R1, UART_LCR    ; /* Load address of UART line control register */ \
    li _R2, 3           ; /* Configure for 8 data bits, 1 stop bits, no parity */ \
    sb _R2, 0(_R1)      ;\

#define RVMODEL_IO_WRITE_STR(_R1, _R2, _R3, _STR_PTR) \
    li      _R2, IO_ADDR            ;\
    mv      _R3, _STR_PTR           ;\
1:                                  ; /* Write to IO_ADDR for simple testbench capture */ \
    lbu     _R1, 0(_STR_PTR)        ;\
    beqz    _R1, 3f                 ;\
2:                                  ;\
    sw      _R1, 0(_R2)             ;\
    addi    _STR_PTR, _STR_PTR, 1   ;\
    j       1b                      ;\
3:                                  ; /* Write to UART */ \
    mv      _STR_PTR, _R3           ; /* Restore _STR_PTR */ \
4:                                  ;\
    lbu     _R1, 0(_STR_PTR)        ;\
    beqz    _R1, 7f                 ; /* Done when NULL-terminator is found */ \
    li      _R2, UART_LSR           ; /* Load address of UART line status register */ \
5:                                  ;\
    lbu     _R3, 0(_R2)             ; /* Poll tx_empty flag */ \
    andi    _R3, _R3, 0x20          ;\
    beqz    _R3, 5b                 ;\
6:                                  ;\
    li      _R2, UART_THR           ; /* Load addres of UART tx_holding register */ \
    sb      _R1, 0(_R2)             ;\
    addi    _STR_PTR, _STR_PTR, 1   ; /* Increment _STR_PTR for next char */ \
    j       4b                      ; /* Loop to next char */ \
7:                                  ; /* Done */ 

//------------------------------------------------------------------------------
// Interrupts
//------------------------------------------------------------------------------
#define STANDARD_SM_SUPPORTED
#define RVMODEL_DATA_SECTION
#define RVMODEL_INTERRUPT_LATENCY 1
#define RVMODEL_TIMER_INT_SOON_DELAY 30

// Simple interrupt generator address
#define SIG_ADDRESS  (0xC000000 + 0x4)
#define RVMODEL_SET_MEXT_INT(_R1, _R2)                                      \
    li _R1, 0x80000800              ; /* set | MEI (bit 11) */              \
    li _R2, SIG_ADDRESS             ; /* simple_interrupt_generator + 4 */  \
    sw _R1, 0(_R2)

#define RVMODEL_CLR_MEXT_INT(_R1, _R2)                              \
    li _R1, 0x00000800              ; /* clear | MEI (bit 11) */    \
    li _R2, SIG_ADDRESS             ;                               \
    sw _R1, 0(_R2)

#define CLINT_BASE_ADDRESS 0x02000000
#define RVMODEL_MSIP_ADDRESS (CLINT_BASE_ADDRESS + 0x0)
#define RVMODEL_SET_MSW_INT(_R1, _R2)    \
    li _R1, 1                           ;\
    li _R2, RVMODEL_MSIP_ADDRESS        ;\
    sw _R1, 0(_R2)                      ;\

#define RVMODEL_CLR_MSW_INT(_R1, _R2)    \
    li _R2, RVMODEL_MSIP_ADDRESS        ;\
    sw zero, 0(_R2)                     ;\

#define RVMODEL_SET_SEXT_INT(_R1, _R2)
#define RVMODEL_CLR_SEXT_INT(_R1, _R2)
#define RVMODEL_SET_SSW_INT(_R1, _R2)
#define RVMODEL_CLR_SSW_INT(_R1, _R2)
#define RVMODEL_IO_INIT(_R1, _R2, _R3)

#define RVMODEL_MTIMECMP_ADDRESS   0x02004000  // Address of mtimecmp CSR
#define RVMODEL_MTIME_ADDRESS      0x0200BFF8  // Address of mtime CSR

#endif // _RVMODEL_MACROS_H