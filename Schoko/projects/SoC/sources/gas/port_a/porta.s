# A simple test to turn on the Blue led

.section .text, "ax", @progbits
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    la t0, rom_data
    lw s2, 0(t0)

    li a0, 0x42
    sb a0, 0(s2)

# Spin:
#     j Spin

Exit:
    ebreak

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# ROM-ish
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
.word 0x00400000                # 0: Port A base
.word 0x00400100                # 4: UART base
.word 0x00400200                # 8: Blue LED base
