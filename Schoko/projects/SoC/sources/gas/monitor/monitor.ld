OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    BRAM(wx) :ORIGIN =0x00000000,LENGTH =4K
    CODE(x)  :ORIGIN =0x00001000,LENGTH =1K
    ROM      :ORIGIN =0x00001400,LENGTH =512
    KEYBUFF  :ORIGIN =0x00001600,LENGTH =256
    DATA     :ORIGIN =0x00001700,LENGTH =512
    STACK(w) :ORIGIN =0x00001900,LENGTH =256
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