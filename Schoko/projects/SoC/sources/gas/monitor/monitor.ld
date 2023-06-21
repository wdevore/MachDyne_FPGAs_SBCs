OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    BRAM(wx) :ORIGIN =0x00000000,LENGTH =2K
    ROM      :ORIGIN =0x00000800,LENGTH =256
    KEYBUFF  :ORIGIN =0x00000900,LENGTH =256
    DATA     :ORIGIN =0x00000A00,LENGTH =512
    STACK(w) :ORIGIN =0x00000C00,LENGTH =256
}

SECTIONS
{
    .text : {
        *(.text)
    }> BRAM

    .rodata : {
        rom_data = .;
        *(.rodata)
    }> ROM

    keybuffer : {
        *(keybuffer)
    }> KEYBUFF

    .data : {
        *(.data)
    }> DATA

    stack : {
        *(stack)
        stack_bottom = .;
    }> STACK
}