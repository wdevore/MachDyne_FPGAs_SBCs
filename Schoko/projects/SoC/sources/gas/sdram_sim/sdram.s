# A very simple SDRAM access test bed

.section .text
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    la t0, BRAM_base
    lw t1, 0(t0)

    la t0, SDRAM_base
    lw t1, 0(t0)

    lw t2, 0(t1)

    lw t2, 4(t1)

    li t0, 0x42
    sw t0, 8(t1)

    ebreak

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# ROM-ish
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
BRAM_base:  .word 0x00400000
SDRAM_base: .word 0x00800000
