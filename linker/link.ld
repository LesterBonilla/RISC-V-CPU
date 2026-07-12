ENTRY(_start)

MEMORY
{
    IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 1K
    DMEM (rw) : ORIGIN = 0x00000000, LENGTH = 1K 
}

SECTIONS
{
    .text :
    {
        *(.text.start)
        *(.text)
    } > IMEM

    .rodata :
    {
        *(.rodata*)
    } > DMEM

    .data : 
    {
        _data_start = .;
        *(.data*)
        _data_end = .;
    } > DMEM

    .bss : 
    {
        _bss_start_ = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > DMEM

    _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
}