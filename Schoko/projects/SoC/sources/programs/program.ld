OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    BRAM(wx) :ORIGIN =0x00000000,LENGTH =1K
}

SECTIONS
{
    .text : {
        *(.text)
    }> BRAM
}