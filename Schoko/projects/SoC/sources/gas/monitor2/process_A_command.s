.section .text, "ax", @progbits
.align 2

.include "macros.s"

# ---------------------------------------------
# @note Process_A_Command
# 'a' Command
# a0 = 0 (not handled), 1 (handled), 2 (error)
# ] aw word-address Word aligned
# Example: 00000000] aw 000012ab
# ] ab byte-address
# Example: 00000000] ab ef
#
# Sets the working address
# The address can be of the form 1234, 00001234
# The address is converted from String to Word. Any invalid
# hex character signals an error.
# ---------------------------------------------
.global Process_A_Command
Process_A_Command:
    PrologRa

    # The first char in the key buffer is the command
    mv t1, tp
    lbu t1, 0(t1)
    li t0, 'a'
    bne t0, t1, PAC_NH          # Exit if not 'a' command

    mv a0, tp                   # Pointer to buffer
    addi a0, a0, 1              # Move to 'type': ('b' or 'w')

    lbu t1, 0(a0)               # Get char to check

    li t0, 'b'
    beq t0, t1, PAC_Bytes

    li t0, 'w'
    beq t0, t1, PAC_Words

    j PAC_Error

PAC_Words:
    addi a0, a0, 2              # Move to address (space + char)

    mv t5, a0                   # Backup
    jal IsHex32String
    beq zero, a0, PAC_Error     # if zero then display error

    mv a0, t5                   # Restore char position
    jal LengthOfString          # a0 <== length
    li a1, 8                    # Set Max with to 8 chars
    bgt a0, a1, PAC_Error

    mv a0, t5                   # Restore char position
    jal PadLeftZerosString      # Results into string_buf2 for next call

    la a0, string_buf2
    jal String32ToWord          # returns a0 = converted Word
    jal WordAlign               # a0 aligned and returned in a0

    mv t0, s2
    sw a0, 0(t0)
    
    li a0, 1
    j PAC_Exit

PAC_Bytes:
    addi a0, a0, 2              # Move to address (space + char)

    mv t5, a0                   # Backup
    jal IsHex32String
    beq zero, a0, PAC_Error     # if zero then display error

    mv a0, t5                   # Restore char position
    jal LengthOfString          # a0 <== length
    li a1, 8                    # Set Max with to 8 chars
    bgt a0, a1, PAC_Error

    mv a0, t5                   # Restore char position
    jal PadLeftZerosString      # Results into string_buf2 for next call

    la a0, string_buf2
    jal String32ToWord          # returns a0 = converted Word

    mv t0, s2
    sw a0, 0(t0)
    
    li a0, 1
    j PAC_Exit

PAC_Error:  # Display error message
    la a0, str_cmd_error
    jal PrintString
    li a0, 2
    j PAC_Exit

PAC_NH:
    li a0, 0                    # Not handled

PAC_Exit:
    EpilogeRa
    
    ret
