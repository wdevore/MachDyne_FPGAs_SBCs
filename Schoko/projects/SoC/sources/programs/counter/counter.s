.set STACK_SIZE, 256         # 64 Words

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# Port A
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set PORT_A_OFFSET, 0
.set PORT_A_REG, 0

.set DELAY_COUNT, 4

.include "macros.s"

.section .text
.align 2

# Counts to N and repeats. Writes to port A

.global _start
_start:
    # Note: the Monitor has already saved its (sp)
    la sp, stack_bottom             # Initialize Micro Stack

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # Micro Prolog
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    PrologRa 16
    sw s2, 8(sp)
    sw s1, 12(sp)
    sw s0, 16(sp)

    # --- Micro code starts here ---
    la s0, rom_data
    lw s2, PORT_A_OFFSET(s0)
    li t0, 0x10                       # Count max
    
1:
    mv a0, zero                     # Reset
2:
    jal WritePortA
    addi a0, a0, 1
    bgtu a0, t0, 1b
    jal Delay
    j 2b                            # Next digit

    # ---       Ends here        ---

Exit_success:
    mv a0, zero

Exit:
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # Micro Epilog
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    lw s0, 16(sp)
    lw s1, 12(sp)
    lw s2, 8(sp)
    EpilogeRa 16

    ret

# ---------------------------------------------
# @note Delay
# ---------------------------------------------
Delay:
    PrologRa

    lw s1, DELAY_COUNT(s0)
1:
    addi s1, s1, -1
    nop
    bne zero, s1, 1b

    EpilogeRa

    ret

# ---------------------------------------------
# @note WritePortA
# Input:
#   a0 is byte to write to port
# ---------------------------------------------
WritePortA:
    sb a0, PORT_A_REG(s2)

    ret

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Rom data
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
.word 0x00400000                # Port A base
.word 500000

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Stack. Grows towards rodata section
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section stack, "w", @nobits
.balign 4
.skip STACK_SIZE
