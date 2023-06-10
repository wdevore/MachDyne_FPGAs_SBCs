ENTRY(_start)

MEMORY
{
    BRAM(wx) :ORIGIN =0x00000000,LENGTH =256
    ROM      :ORIGIN =0x00000200,LENGTH =256
    STACK(w) :ORIGIN =0x00000300,LENGTH =256
}

SECTIONS
{
    .text : {
        *(.text)
    }> BRAM

    .rodata : {
        *(.rodata)
    }> ROM

    stack : {
        *(stack)
        stack_bottom = .;
    }> STACK
}