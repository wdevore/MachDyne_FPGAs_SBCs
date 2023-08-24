OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    /* The addresses specified are in byte-address form */
    BRAM(wx) :ORIGIN =0x00000000,LENGTH =128
    DATA     :ORIGIN =0x00000080,LENGTH =128
}

SECTIONS
{
    .text : {
        *(.text)
    }> BRAM

    .rodata : {
        prog_data = .;
        *(.rodata)
    }> DATA
}