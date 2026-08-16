.equ UART_BASE, 0x10000000
.equ UART_TX,   UART_BASE + 0   # Tx holding, write only, DLAB = 0
.equ UART_LSR,  UART_BASE + 20  # Line status, read only
.equ LSR_THRE,  (1 << 5)        # THR empty, ready to send frame
.equ UART_RX,   UART_BASE + 0   # Rx buffer, read only, DLAB = 0
.equ LSR_RXR,   (1 << 0)        # Rx ready to be read

.section .text.init
.global _start

_start:
    la  sp, _boot_stack_top
    j   bootloader_main

#------------------------------------------------------------------------------
# uart_putc: Send one byte over uart, blocking
#  Input: a0 = byte to send
#------------------------------------------------------------------------------
uart_putc:
    li      t1, UART_LSR
1:  lbu     t0, 0(t1)           # Poll Line Status
    andi    t0, t0, LSR_THRE    # Check THR empty
    beqz    t0, 1b
2:  li      t1, UART_TX         # Send character
    sb      a0, 0(t1)
    ret

#------------------------------------------------------------------------------
# uart_puts: Send a null-terminated string over uart, blocking
#  Input: a0 = pointer to string
#------------------------------------------------------------------------------
uart_puts:
    addi    sp, sp, -16
    sw      ra, 4(sp)
    sw      s0, 0(sp)

    mv      s0, a0

1:  lbu     a0, 0(s0)
    beqz    a0, 2f
    call    uart_putc
    addi    s0, s0, 1
    j       1b
2:  lw      ra, 4(sp)
    lw      s0, 0(sp)
    addi    sp, sp, 16
    ret

#------------------------------------------------------------------------------
# uart_getc: Read a character from UART, blocking
#   Input: None
#   Output: Character read is returned in a0
#------------------------------------------------------------------------------
uart_getc:
    li      t0, UART_LSR
1:  lbu     t1, 0(t0)
    andi    t1, t1, LSR_RXR
    beqz    t1, 1b
    li      t0, UART_RX
    lbu     a0, 0(t0)
    ret

#------------------------------------------------------------------------------
# uart_getword: Read 4 characters from UART, blocking
#   Input: None
#   Output: Word read is returned in a0
#------------------------------------------------------------------------------
uart_getword:
    addi    sp, sp, -16
    sw      ra, 0(sp)

    call    uart_getc
    sb      a0, 4(sp)
    call    uart_getc
    sb      a0, 5(sp)
    call    uart_getc
    sb      a0, 6(sp)
    call    uart_getc
    sb      a0, 7(sp)

    lw      a0, 4(sp)

    lw      ra, 0(sp)
    addi    sp, sp, 16
    ret

#------------------------------------------------------------------------------
# uart_putword: Write 4 characters to UART, blocking
#   Input: a0 = word to write, little end first
#------------------------------------------------------------------------------
uart_putword:
    addi    sp, sp, -16
    sw      ra, 0(sp)
    sw      s0, 4(sp)

    mv      s0, a0

    call    uart_putc
    srli    s0, s0, 8
    mv      a0, s0
    call    uart_putc
    srli    s0, s0, 8
    mv      a0, s0
    call    uart_putc
    srli    s0, s0, 8
    mv      a0, s0
    call    uart_putc

    lw      ra, 0(sp)
    lw      s0, 4(sp)
    addi    sp, sp, 16
    ret

#------------------------------------------------------------------------------
# bootloader_main: Wait for 0x37 to start loading data to RAM, jump to 0x0
#------------------------------------------------------------------------------
bootloader_main:
    la      a0, start_message
    call    uart_puts
    li      s0, 0x37
    call    uart_getc           # Sync
    bne     a0, s0, 1b
    la      a0, sycn_received
    call    uart_puts
    call    uart_getword        # Size in bytes
    mv      s1, a0
    la      a0, size_received
    call    uart_puts
    mv      a0, s1
    call    uart_putword
    li      s0, 0               # Read and store words
2:  beq     s0, s1, 3f
    call    uart_getword
    mv      s2, a0
    sw      a0, 0(s0)
    addi    s0, s0, 4
    mv      a0, s2
    call    uart_putword
    j       2b

3:  la      a0, loading_done
    call    uart_puts

    li      t0, 0               # Jump to entry at 0x00000000
    jr      t0

.section .rodata
start_message:
    .string "Waiting for program...\n"
sycn_received:
    .string "Sync received, waiting for size...\n"
size_received:
    .string "Size received: \n"
loading_done:
    .string "Loading done, starting program...\n"
