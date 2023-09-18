.section .text, "ax", @progbits
.align 2

.include "macros.s"
.include "sets.s"

# ---------------------------------------------
# @note PrintString
# Print a Null terminated String
# Input:
#   a0 points to start of String
# ---------------------------------------------
.global PrintString
PrintString:
    PrologRa 8
    sw t0, 8(sp)

1:
    lbu t0, 0(a0)               # Load t0 to what a0 is pointing at
    beq t0, zero, 1f            # if t0 == Null then exit

    sb t0, UART_TX_REG_ADDR(s3) # Send

    jal UART_PollTxBusy              # Call subroutine

    addi a0, a0, 1              # Next char
    j 1b

1:  # Exit
    lw t0, 8(sp)
    EpilogeRa 8

    ret

# ---------------------------------------------
# @note PrintChar
# Print a single character
# Input:
#   a0 = char
# ---------------------------------------------
.global PrintChar
PrintChar:
    PrologRa

    sb a0, UART_TX_REG_ADDR(s3) # Send

    jal UART_PollTxBusy              # Call subroutine

    EpilogeRa

    ret

# ---------------------------------------------
# @note PrintCrLn
# Print a CR and LF
# ---------------------------------------------
.global PrintCrLn
PrintCrLn:
    PrologRa

    li a0, '\r'                 # Carriage return
    sb a0, UART_TX_REG_ADDR(s3) # Send
    jal UART_PollTxBusy

    li a0, '\n'                 # Line feed
    sb a0, UART_TX_REG_ADDR(s3) # Send
    jal UART_PollTxBusy

    EpilogeRa

    ret

# ---------------------------------------------
# @note PrintCharCrLn
# Print a char followed by CR and LF
# ---------------------------------------------
.global PrintCharCrLn
PrintCharCrLn:
    PrologRa

    jal PrintChar

    jal PrintCrLn

    EpilogeRa

    ret

# ---------------------------------------------
# @note PrintCursor
# Moves the cursor back to the begining of the line
# and prints the working address + "]" char.
# For example: 00001234]
# ---------------------------------------------
.global PrintCursor
PrintCursor:
    PrologRa 8
    sw t0, 8(sp)

    # Print working address
    mv t0, s2
    lw a0, 0(t0)                # Word value to convert
    jal PrintAddress

    li a0, ']'
    jal PrintChar

    li a0, ' '
    jal PrintChar

    # Exit
    lw t0, 8(sp)
    EpilogeRa 8

    ret

# ---------------------------------------------
# @note PrintAddress
# ---------------------------------------------
.global PrintAddress
PrintAddress:
    PrologRa

    jal HexWordToString
    mv a0, s1
    jal PrintString

    EpilogeRa

    ret

# ---------------------------------------------
# @note PrintNibble
# Print a0's LS nibble
# ---------------------------------------------
.global PrintNibble
PrintNibble:
    PrologRa 12
    sw t3, 8(sp)
    sw t0, 12(sp)

    li t3, 10
    bltu a0, t3, 1f
    addi t0, a0, '`' - 9
    j 2f

1:
    addi t0, a0, '0'

2:
    sb t0, UART_TX_REG_ADDR(s3) # Send

    jal UART_PollTxBusy              # Call subroutine

    # Exit
    lw t0, 12(sp)
    lw t3, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# @audit Unused PrintByte
# Print a0's LSB
# Input:
#   a0 = byte to print
# ---------------------------------------------
# .global PrintByte
# PrintByte:
#     PrologRa 12
#     sw a0, 8(sp)
#     sw t0, 12(sp)

#     mv t0, a0                   # Backup a0
#     andi a0, a0, 0x0F           # Mask off lower nibble
#     jal PrintNibble
#     mv a0, t0                   # Restore a0
#     slli a0, a0, 4              # Shift higher nibble to lower nibble
#     jal PrintNibble

#     # Exit
#     lw t0, 12(sp)
#     lw a0, 8(sp)
#     EpilogeRa 12
    
#     ret

# ---------------------------------------------
# @audit Unused PrintWordAsBinary
# Print a0 Word as binary string
# ---------------------------------------------
# .global PrintWordAsBinary
# PrintWordAsBinary:
#     PrologRa 20
#     sw t0, 8(sp)
#     sw t1, 12(sp)
#     sw t2, 16(sp)
#     sw t3, 20(sp)

#     li t0, 32                   # Load Dec Counter
#     mv t2, a0                   # Copy a0 for modification
#     li t3, 0x80000000           # MSb mask for slli

# 1:
#     and t1, t2, t3              # Mask in MSb
#     bne zero, t1, 2f            # Test

#     li a0, '0'
#     jal PrintChar
#     j 3f

# 2:
#     li a0, '1'
#     jal PrintChar

# 3:
#     slli t2, t2, 1              # Move next bit to MSb
#     addi t0, t0, -1             # Dec counter
#     bne zero, t0, 1b            # Loop while t0 > 0

#     # Exit
#     lw t3, 20(sp)
#     lw t2, 16(sp)
#     lw t1, 12(sp)
#     lw t0, 8(sp)
#     EpilogeRa 20

#     ret
