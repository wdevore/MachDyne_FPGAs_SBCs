.section .text, "ax", @progbits
.align 2

.include "macros.s"

# ---------------------------------------------
# @note Process_R_Command
# a0 = 0 (not handled), 1 (handled), 2 (error)
# ] rw 25
# The 1st parm 'type' can be 'b' (byte) or 'w" (word)
# The 2nd parm 'count' must be a decimal number. It can
# mean either word-count or lines-to-display
# ---------------------------------------------
.global Process_R_Command
Process_R_Command:
    PrologRa

    # The first char in the key buffer is the command
    mv t1, tp
    lbu t1, 0(t1)
    li t0, 'r'
    bne t0, t1, PRC_NH          # Exit if not 'r' command

    mv a0, tp
    addi a0, a0, 1              # Move to 'type'

    lbu t1, 0(a0)               # Get char to check

    li t0, 'b'
    beq t0, t1, PRC_Bytes

    li t0, 'w'
    beq t0, t1, PRC_Words

    j PRC_Error

PRC_Words:
    addi a0, a0, 2              # Move to 'count' (space + char)
    mv t5, a0

    # The 'count' parm should be an Integer not Hex number
    jal IsInteger               # a0 = 1 = valid
    beq zero, a0, PRC_Error

    mv a0, t5                   # Reset address

    li a1, 8
    jal PadLeftZerosString      # Results into string_buf2 for next call
    la a0, string_buf2
    jal String32ToWord          # Convert count String to Word = a0

    jal DumpWords               # Input a0 = count of Words to display
    li a0, 1                    # Handled
    j PRC_Exit
    
PRC_Bytes:
    addi a0, a0, 2              # Move to 'count' (space + char)
    mv t5, a0

    # The 'count' parm should be an Integer not Hex number
    jal IsInteger               # a0 = 1 = valid
    beq zero, a0, PRC_Error

    mv a0, t5                   # Reset address

    li a1, 8
    jal PadLeftZerosString      # Results into string_buf2 for next call
    la a0, string_buf2
    jal String32ToWord          # Convert count String to Word = a0

    jal DumpBytes
    li a0, 1                    # Handled
    j PRC_Exit

PRC_Error:  # Display error message
    la a0, str_cmd_error
    jal PrintString
    li a0, 2
    j PRC_Exit

PRC_NH:
    li a0, 0                    # Not handled

PRC_Exit:

    EpilogeRa
    
    ret
