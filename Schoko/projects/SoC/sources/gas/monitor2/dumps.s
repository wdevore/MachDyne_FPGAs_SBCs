.section .text, "ax", @progbits
.align 2

.include "macros.s"

# ---------------------------------------------
# @note DumpWords
# a0 = count of Words to display
# ---------------------------------------------
.global DumpWords
DumpWords:
    PrologRa 16
    sw t0, 8(sp)
    sw t1, 12(sp)
    sw t2, 16(sp)

    # Format:
    # 00000000: 12345678
    # 00000001: 12345678
    mv t0, s2                   # Pointer to working address
    lw t1, 0(t0)                # Fetch value at pointer = new pointer
    mv t2, a0                   # Capture count argument

DW_Loop:
    mv a0, t1                   # t1 points to current working address
    jal HexWordToString         # Convert address (a0) to string
    mv a0, s1
    jal PrintString             # Print address

    li a0, ':'
    jal PrintChar

    li a0, ' '
    jal PrintChar

    lw a0, 0(t1)                # Fetch value
    jal HexWordToString         # Convert value to string
    mv a0, s1
    jal PrintString             # Print value

    li a0, ' '
    jal PrintChar
    li a0, ' '
    jal PrintChar

    # To match the little-endian order use a sequence "3,2,1,0"
    # If you want it in readable form then use "0,1,2,3"
    la t0, endian_order         # Check for readable flag
    lbu t0, 0(t0)
    beq zero, t0, 1f

    lbu a0, 3(t1)
    jal ByteToChar
    jal PrintChar    

    lbu a0, 2(t1)
    jal ByteToChar
    jal PrintChar    

    lbu a0, 1(t1)
    jal ByteToChar
    jal PrintChar    

    lbu a0, 0(t1)
    jal ByteToChar
    jal PrintChar    

    j 2f

1:  # Readable form
    lbu a0, 0(t1)
    jal ByteToChar
    jal PrintChar    

    lbu a0, 1(t1)
    jal ByteToChar
    jal PrintChar    

    lbu a0, 2(t1)
    jal ByteToChar
    jal PrintChar    

    lbu a0, 3(t1)
    jal ByteToChar
    jal PrintChar    

2:

    jal PrintCrLn
    
    addi t1, t1, 4              # Move to next address = move by 4 Bytes addressing
    addi t2, t2, -1             # Dec word count
    bne zero, t2, DW_Loop

    lw t2, 16(sp)
    lw t1, 12(sp)
    lw t0, 8(sp)
    EpilogeRa 16

    ret

# ---------------------------------------------
# @note DumpBytes
# Input:
#   a0 = count of lines to display, each 3 words + ascii
# Output format:
# ...] rb 1
# 00000000: 01 02 03 04 01 02 03 04 01 02 03 04  Hello World!
# ---------------------------------------------
.global DumpBytes
DumpBytes:
    PrologRa 24
    sw t0, 8(sp)
    sw t1, 12(sp)
    sw t2, 16(sp)
    sw t3, 20(sp)
    sw t4, 24(sp)

    mv t0, s2                   # Pointer to working address
    lw t1, 0(t0)                # Fetch value at pointer = new pointer
    mv t2, a0                   # Capture lines-to-display argument

DB_Loop_Lines:
    li t3, 12                   # How many bytes per line
    mv a0, t1                   # t1 points to current working address
    jal HexWordToString         # Convert address (a0) to string
    mv a0, s1
    jal PrintString             # Print address

    li a0, ':'
    jal PrintChar

    li a0, ' '
    jal PrintChar

    mv t4, t1

WRD_Loop_Bytes: # Print 3 Words of bytes
    lbu a0, 0(t1)
    jal HexByteToString
    mv a0, s1
    jal PrintString             # Print Byte

    li a0, ' '
    jal PrintChar
    addi t1, t1, 1              # Move to next address = move by 1 Byte addressing

    addi t3, t3, -1
    bne zero, t3, WRD_Loop_Bytes

    li a0, ' '
    jal PrintChar
    li a0, ' '
    jal PrintChar

    # Print Ascii chars
    # To match the little-endian order use a sequence "3,2,1,0"
    # If you want it in readable form then use "0,1,2,3"
    la t0, endian_order         # Check for readable flag
    lbu t0, 0(t0)
    beq zero, t0, WRD_Big

    # Little endian TODO currently mirrors Big.
    # It doesn't really make much sense as it would look strange.
#     li t3, 12                   # How many chars per line
# 1:
#     lbu a0, 0(t4)
#     jal ByteToChar
#     jal PrintChar    

#     addi t4, t4, 1
#     addi t3, t3, -1
#     bne zero, t3, 1b

#     j WRD_Cont

WRD_Big:
    li t3, 12                   # How many chars per line
1:
    lbu a0, 0(t4)
    jal ByteToChar
    jal PrintChar    

    addi t4, t4, 1
    addi t3, t3, -1
    bne zero, t3, 1b

WRD_Cont:
    jal PrintCrLn

    addi t2, t2, -1             # Dec word count
    bne zero, t2, DB_Loop_Lines

    # Exit
    lw t4, 24(sp)
    lw t3, 20(sp)
    lw t2, 16(sp)
    lw t1, 12(sp)
    lw t0, 8(sp)
    EpilogeRa 24

    ret
