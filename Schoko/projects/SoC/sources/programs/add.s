.section .text
.align 2

.global _start
_start:

    li a0, 10
    li a1, 5
    add t0, a0, a1
    ebreak
