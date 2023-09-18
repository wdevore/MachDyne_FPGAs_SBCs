# ---__------__------__------__------__------__------__---
# Macros
# ---__------__------__------__------__------__------__---

# ---------------------------------------------
# Pushes Return address onto the stack
# You must use this macro if your subroutine has 1 or more
# "jal" calls present, otherwise your stack will corrupt
# AND your program WILL crash!
# ---------------------------------------------
.macro PrologRa frameSize=4
    addi sp, sp, -\frameSize
    sw ra, 4(sp)
.endm

# ---------------------------------------------
# Pops Return address from the stack
# ---------------------------------------------
.macro EpilogeRa frameSize=4
    lw ra, 4(sp)
    addi sp, sp, \frameSize
.endm

