.section .text.start
.global _start

_start:
    la      sp, _stack_top

    la      t0, _bss_start
    la      t1, _bss_end

bss_clear_loop:
    bge     t0, t1, bss_clear_done
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       bss_clear_loop
bss_clear_done:

    call    main

done:
    j       done
    