OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    /* The address specified is in byte-address form = 4K Words */
    BRAM(wx) :ORIGIN =0x00001E00,LENGTH =4K
}

SECTIONS
{
    .text : {
        *(.text)
    }> BRAM
}