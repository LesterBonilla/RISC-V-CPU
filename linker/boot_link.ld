ENTRY(_start)

MEMORY
{
    BOOT (rwx) : ORIGIN = 0xFFFFF000, LENGTH = 4K
}

SECTIONS
{
    .text :
    {
        *(.text.init)
        *(.text)
    } > BOOT

    .rodata :
    {
        *(.rodata*)
    } > BOOT

    .data : 
    {
        _data_start = .;
        *(.data*)
        _data_end = .;
    } > BOOT

    .bss : 
    {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > BOOT

    . = ALIGN(4);
    _boot_stack_top = ORIGIN(BOOT) + LENGTH(BOOT) - 4;
}