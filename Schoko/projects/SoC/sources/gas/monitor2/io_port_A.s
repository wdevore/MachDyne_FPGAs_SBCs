.section .text, "ax", @progbits
.align 2

.include "sets.s"

# ---------------------------------------------
# @note WritePortA
# Input:
#   a0 is byte to write to port
# ---------------------------------------------
.global WritePortA
WritePortA:
    sb a0, PORT_A_REG(s0)

    ret

