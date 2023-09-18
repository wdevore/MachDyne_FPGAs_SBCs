.section .text, "ax", @progbits
.align 2

.include "macros.s"

# ---------------------------------------------
# @note Process_E_Command
# Switch between big/little endian
# ] eb
# OR
# ] el
# ---------------------------------------------
.global Process_E_Command
Process_E_Command:
    PrologRa

    # The first char in the key buffer is the command
    mv t1, tp
    lbu t1, 0(t1)
    li t0, 'e'
    bne t0, t1, PEC_NH          # Exit if not 'r' command

    mv a0, tp
    addi a0, a0, 1              # Move to 'type'

    lbu t1, 0(a0)               # Get char to check

    li t0, 'b'
    beq t0, t1, PEC_Big

    li t0, 'l'
    beq t0, t1, PEC_Little

    j PEC_Error

PEC_Big:
    # Default (readable)
    la t1, endian_order
    li a0, 0
    sb a0, 0(t1)

    li a0, 1                    # Handled
    j PEC_Exit

PEC_Little:
    la t1, endian_order
    li a0, 1                    # Also happens to be "handled" signal
    sb a0, 0(t1)

    j PEC_Exit

PEC_Error:  # Display error message
    la a0, str_cmd_error
    jal PrintString
    li a0, 2
    j PEC_Exit

PEC_NH:
    li a0, 0                    # Not handled

PEC_Exit:

    EpilogeRa
    
    ret
