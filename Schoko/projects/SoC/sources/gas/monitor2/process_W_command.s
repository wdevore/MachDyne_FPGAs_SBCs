.section .text, "ax", @progbits
.align 2

.include "macros.s"

# ---------------------------------------------
# @note Process_W_Command
# a0 = 0 (not handled), 1 (handled), 2 (error)
# ] ww 1234abcd
# OR
# ] wb af
# OR
# ] wb 01 02 ff ef...
# The 1st parm 'type' can be 'b' (byte) or 'w" (word)
# The 2nd parm is a value
# ---------------------------------------------
.global Process_W_Command
Process_W_Command:
    PrologRa
    
    # The first char in the key buffer is the command
    la t1, keyBuf
    lbu t1, 0(t1)
    li t0, 'w'
    bne t0, t1, PWC_NH          # Exit if not 'w' command

    la t4, keyBuf               # t4 Points to input buffer
    addi t4, t4, 1              # Move to 'type'

    lbu t1, 0(t4)               # Get char to check

    li t0, 'b'
    li t2, 0                    # Indicate byte format
    beq t0, t1, PWC_Bytes

    li t0, 'w'
    li t2, 1                    # Indicate word format
    beq t0, t1, PWC_Words

    j PWC_Error

PWC_Words:
    addi t4, t4, 2              # Move to 'value' (space + char)

    # Check the value is 4 bytes or 8 chars in length
    mv a0, t4
    jal IsHex32String
    beq zero, a0, PWC_Error     # if zero then display error

    mv a0, t4
    jal LengthOfString          # a0 <== length
    li a1, 8                    # Set Max with to 8 chars
    bne a0, a1, PWC_Error

    # Now write word to working address
    la t0, working_addr         # Point to working address variable
    lw t0, 0(t0)                # Fetch value from variable = working address

    mv a0, t4
    jal String32ToWord          # a0 = word to store

    sw a0, 0(t0)                # Store it

    j PWC_Exit

PWC_Bytes:
    addi t4, t4, 2              # Move to 'value' (space + char)

    mv a0, t4
    jal IsHexByte               # a0 = 0 if invalid hex
    beq zero, a0, PWC_Error

    # Fetch the location where bytes will be stored
    la t0, working_addr         # Point to working address variable
    lw t0, 0(t0)                # Fetch value from variable = working address

PWC_BLoop: # Scan for 2 char bytes and repeat until Null reached
    mv a0, t4
    jal String8ToWord           # a0 = word (i.e. byte) to store
    sb a0, 0(t0)

    addi t4, t4, 2              # Move source pointer 2 bytes. We will
                                # be at Space or Null

    lbu t3, 0(t4)               # Fetch it
    beq zero, t3, 1f            # If Null exit

    addi t4, t4, 1              # Move to next hex char
    mv a0, t4
    jal IsHexByte               # a0 = 0 if invalid hex
    beq zero, a0, PWC_Error
    
    addi t0, t0, 1              # Move destination pointer
    j PWC_BLoop

1:  
    j PWC_Exit

PWC_Error:  # Display error message
    la a0, str_cmd_error
    jal PrintString
    li a0, 2
    j PWC_Exit

PWC_NH:
    li a0, 0                    # Not handled

PWC_Exit:
    EpilogeRa

    ret
