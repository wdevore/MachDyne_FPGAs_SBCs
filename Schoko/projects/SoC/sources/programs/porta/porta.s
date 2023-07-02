.set STACK_SIZE, 256         # 64 Words

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# Port A
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set PORT_A_OFFSET, 0
.set PORT_A_REG, 0

.include "macros.s"

.section .text
.align 2

# Write 0x42 to port A and exit

.global _start
_start:
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # Micro Prolog
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    la sp, stack_bottom             # Initialize Micro Stack

    PrologRa 12
    sw s2, 8(sp)
    sw s0, 12(sp)

    # --- Micro code starts here ---
    la s0, rom_data
    lw s2, PORT_A_OFFSET(s0)
    
    li a0, 0x42
    jal WritePortA
    # ---       Ends here        ---

Exit_success:
    mv a0, zero

Exit:
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # Micro Epilog
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    lw s0, 12(sp)
    lw s2, 8(sp)
    EpilogeRa 12

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

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Stack. Grows towards rodata section
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section stack, "w", @nobits
.balign 4
.skip STACK_SIZE
