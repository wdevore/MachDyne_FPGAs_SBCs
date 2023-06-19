OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    BRAM(wx) :ORIGIN =0x00000000,LENGTH =1K
    ROM      :ORIGIN =0x00000400,LENGTH =256
    KEYBUFF  :ORIGIN =0x00000500,LENGTH =64
    STACK(w) :ORIGIN =0x00000600,LENGTH =256
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

    stack : {
        *(stack)
        stack_bottom = .;
    }> STACK
}