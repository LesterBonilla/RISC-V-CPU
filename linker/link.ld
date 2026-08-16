ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS
{
    .text :
    {
        *(.text.start)
        *(.text)
    } > RAM

    .rodata :
    {
        *(.rodata*)
    } > RAM

    .data : 
    {
        _data_start = .;
        *(.data*)
        _data_end = .;
    } > RAM

    .bss : 
    {
        _bss_start_ = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > RAM

    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}