OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    /* The address specified is in byte-address form */
    BRAM(wx) :ORIGIN =0x00001E00,LENGTH =2K - 512 - 256
    ROM      :ORIGIN =0x00002300,LENGTH =512
    STACK(w) :ORIGIN =0x00002500,LENGTH =256
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

    stack : {
        *(stack)
        stack_bottom = . + 256;
    }> STACK
}