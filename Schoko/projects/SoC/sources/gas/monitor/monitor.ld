OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    /* The addresses specified are in byte-address form */
    BRAM(wx) :ORIGIN =0x00000000,LENGTH =5K
    ROM      :ORIGIN =0x00001400,LENGTH =512
    KEYBUFF  :ORIGIN =0x00001A00,LENGTH =256
    DATA     :ORIGIN =0x00001B00,LENGTH =512
    STACK(w) :ORIGIN =0x00001D00,LENGTH =256
    CODE(x)  :ORIGIN =0x00001E00,LENGTH =1K
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
        stack_bottom = . + 256;
    }> STACK
}