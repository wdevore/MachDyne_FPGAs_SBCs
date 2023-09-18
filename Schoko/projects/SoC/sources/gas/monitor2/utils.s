.section .text, "ax", @progbits
.align 2

.include "macros.s"
.include "sets.s"

# \__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/
# Conversions
# /--\/--\/--\/--\/--\/--\/--\/--\/--\/--\/--\/--\/--\

# ---------------------------------------------
# @note HexWordToString
# Converts a 32 bit value to an 8 char string.
# The string is stored in string_buf.
# left most nibble = LM nibble
# Input:
#   a0 = word to convert
# Output:
#   string_buf
# ---------------------------------------------
.global HexWordToString
HexWordToString:
    PrologRa 20
    sw t0, 8(sp)
    sw t1, 12(sp)
    sw t2, 16(sp)
    sw t3, 20(sp)

    mv t0, s1                   # Pointer to buffer
    li t2, 8                    # Count 8 chars
    li t3, ':'

HWT_Loop:
    srli t1, a0, 28             # Shift LM nibble to right most position
    slli a0, a0, 4              # Update word by shifting in a new LM nibble
                                # for next pass.
    andi t1, t1, 0xF            # Isolate current nibble
    addi t1, t1, '0'            # Translate to Ascii by adding '0' = 0x30
    blt t1, t3, HWT_Store       # See if t1 > '9' i.e. t1 > ':'
    addi t1, t1, 39             # Else convert to 'a'-'f' chars first

HWT_Store:
    sb t1, 0(t0)                # Store char in buffer
    addi t0, t0, 1              # Move pointer
    addi t2, t2, -1
    bne zero, t2, HWT_Loop      # Loop while count > 0

    sb zero, 0(t0)              # Null terminate

    # Exit
    lw t3, 20(sp)
    lw t2, 16(sp)
    lw t1, 12(sp)
    lw t0, 8(sp)
    EpilogeRa 20

    ret

# ---------------------------------------------
# @note ClearKeyBuffer
# Clear key input buffer
# ---------------------------------------------
.global ClearKeyBuffer
ClearKeyBuffer:
    # Reset offset to zero
    la t0, bufOffset
    sb zero, 0(t0)

    la t0, keyBuf
    li t1, KEY_BUFFER_SIZE
1:
    sb zero, 0(t0)
    addi t0, t0, 1              # Move pointer
    addi t1, t1, -1             # Dec counter
    beq zero, t1, 1f
    j 1b

1:  # Exit
    ret

# ---------------------------------------------
# @note TrimLastKeyBuffer
# Trim off the last character in the key buffer.
# If the offset index is == 0 then just put a Null
# and return, otherwise, put a Null and dec the offset.
# Decrement by 2 because the "cursor" is always after
# last visible char.
# ---------------------------------------------
.global TrimLastKeyBuffer
TrimLastKeyBuffer:
    la t0, bufOffset            # Pointer to offset

    # Is offset == 0?
    lbu t0, 0(t0)               # t0 = offset value
    beq zero, t0, 1f

    # Else decrement offset
    la t1, bufOffset            # Pointer to offset
    addi t0, t0, -2             # Dec offset value
    sb t0, 0(t1)                # Save value

1:
    # Put a Null at the current offset
    la t1, keyBuf               # Pointer to key buffer
    add t1, t1, t0              # Move pointer
    sb zero, 0(t1)              # zero = Null

    ret

# ---------------------------------------------
# @note PadLeftZerosString
# Input:
#   a0 = Address of string to left-pad with '0' chars
#   a1 = output size requested, for example, 8 chars
# output is put in string_buf2
# 123.....
# 00000123
# ---------------------------------------------
.global PadLeftZerosString
PadLeftZerosString:
    PrologRa 24
    sw t1, 8(sp)
    sw t2, 12(sp)
    sw t3, 16(sp)
    sw t4, 20(sp)
    sw t5, 24(sp)

    la t3, string_buf2
    li t4, '0'
    mv t1, a0                   # Copy address of source to t1

    # Is string to pad is already = to size then just copy
    jal LengthOfString          # a0 now = length
    beq a0, a1, PLZ_Append      # Just copy src to dest

    # Calc difference: output_size - length => how many '0's to pad
    sub t2, a1, a0

    blt t2, zero, PLZ_Exit      # buf2 is larger than output size requested

PLZ_Loop: # Pad destination buffer with '0's
    sb t4, 0(t3)                # Write '0'
    addi t3, t3, 1              # Move pointer
    addi t2, t2, -1             # Dec count of '0's
    bne zero, t2, PLZ_Loop      # Loop

PLZ_Append:  # Now append source chars to new buffer
    lbu t5, 0(t1)               # Read source char
    sb t5, 0(t3)                # Write to destination
    addi t1, t1, 1              # Inc both pointers
    addi t3, t3, 1
    addi a0, a0, -1             # Dec source length
    bne zero, a0, PLZ_Append    # Loop while a0 != 0

    # Finally Null terminate
    addi t3, t3, 1
    sb zero, 0(t3)                # Null

PLZ_Exit:
    lw t4, 24(sp)
    lw t4, 20(sp)
    lw t3, 16(sp)
    lw t2, 12(sp)
    lw t1, 8(sp)

    EpilogeRa 24

    ret

# ---------------------------------------------
# @note LengthOfString
# Input:
#   a0 = Address of string to find size of
# Output:
#   a0 is overriden with size
# String must be Null terminated
# ---------------------------------------------
.global LengthOfString
LengthOfString:
    PrologRa 12
    sw t1, 8(sp)
    sw t0, 12(sp)

    li t0, 0                    # Clear counter

1:
    lbu t1, 0(a0)               # Fetch char
    beq zero, t1, 1f            # Loop while not Null
    addi a0, a0, 1              # Move to next char
    addi t0, t0, 1              # Inc counter
    j 1b

1:
    mv a0, t0                   # Return value

    # Exit
    lw t0, 12(sp)
    lw t1, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# @note String32ToWord
# Convert String (8 chars) to Word and return in a0
# Input:
#   a0 = address to source string buffer
# Output:
#   a0 = return = Word
#
#  28   24   20   16   12    8   4    0        <-- shift amount
# 0000_0000_0000_0000_0000_0000_0000_0000
# ---------------------------------------------
.global String32ToWord
String32ToWord:
    PrologRa 20
    sw t1, 8(sp)
    sw t2, 12(sp)
    sw t3, 16(sp)
    sw t4, 20(sp)

    mv t4, a0                   # Copy pointer
    li t2, 28                   # Shift amount shrinks by 4 on each pass
    mv t3, zero                 # The final converted Word pre cleared

1:
    lbu a0, 0(t4)               # Get char
    jal HexCharToWord           # Convert to number in a0
    sll t1, a0, t2              # Shift LM nibble of a0 by t2 into t1
    or t3, t3, t1               # Merge into t3

    addi t2, t2, -4             # Dec shift amount value
    addi t4, t4, 1              # Move pointer to next char
    bge t2, zero, 1b            # Loop while t2 >= 0

    mv a0, t3                   # Move result to return arg

    # Exit
    lw t4, 20(sp)
    lw t3, 16(sp)
    lw t2, 12(sp)
    lw t1, 8(sp)
    EpilogeRa 20

    ret

# ---------------------------------------------
# @note String8ToWord
# Convert String (2 chars) to Word and return in a0
# It only looks at two chars. It doesn't check for Null.
# Input:
#   a0 = address to source string buffer
# Output:
#   a0 = LSB of Word
# ---------------------------------------------
.global String8ToWord
String8ToWord:
    PrologRa 12
    sw t4, 8(sp)
    sw t2, 12(sp)

    mv t4, a0                   # Copy pointer

    lbu a0, 0(t4)               # Get ascii char (upper nibble)
    jal HexCharToWord           # Convert to number in a0
    mv t2, a0                   # Copy for merging later
    slli t2, t2, 4              # Shift 4 bits to high position

    addi t4, t4, 1              # Move to next nibble char
    lbu a0, 0(t4)               # Get ascii char (lower nibble)
    jal HexCharToWord           # Convert to number in a0

    or a0, t2, a0               # Merge together

    # Exit
    lw t2, 12(sp)
    lw t4, 8(sp)
    EpilogeRa 12

    ret


# ---------------------------------------------
# @note ByteToChar
# Converts a byte value to an ascii char.
# The string is stored in string_buf.
# Visible characters start at ' ' -> '~' otherwise
# Show a '.'
# Input:
#   a0 = word with LSB to convert
# Output:
#   a0 = visibility adjusted
# ---------------------------------------------
.global ByteToChar
ByteToChar:
    # PrologRa 8
    # sw t0, 8(sp)

    # If byte value < 0x20 (space), or = 7F (delete)
    # return a '.'
    li t0, ' '
    bltu a0, t0, 1f
    li t0, '~'
    bgtu a0, t0, 1f
    j 2f

1:
    # Translate to '.'
    li a0, '.'

2:  # Exit
    # lw t0, 8(sp)
    # EpilogeRa 8

    ret

# ---------------------------------------------
# @note HexByteToString
# Converts a 8 bit value to an 2 char hex string.
# The string is stored in string_buf.
# Input:
#   a0 = word with LSB to convert
# Output:
#   string_buf
# ---------------------------------------------
.global HexByteToString
HexByteToString:
    PrologRa 12
    sw t0, 8(sp)
    sw t1, 12(sp)

    mv t0, s1           # Pointer to buffer
    mv t1, a0                   # Copy argument

    # Convert upper Nibble
    andi a0, a0, 0xF0           # Isolate nibble
    srli a0, a0, 4              # Move nibble 4 bits for subroutine
    jal NibbleToHexChar
    sb a0, 0(t0)                # Store char in buffer

    addi t0, t0, 1
    mv a0, t1                   # Reset from copy

    # Convert lower Nibble
    andi a0, a0, 0x0F           # Isolate nibble
    jal NibbleToHexChar
    sb a0, 0(t0)                # Store char in buffer

    addi t0, t0, 1
    sb zero, 0(t0)              # Null terminate

    # Exit
    lw t1, 12(sp)
    lw t0, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# @note NibbleToHexChar
# Converts a Nibble to a char.
# Input:
#   a0 = word with the Nibble
# Output:
#   a0 = char
# ---------------------------------------------
.global NibbleToHexChar
NibbleToHexChar:
    PrologRa 8
    sw t0, 8(sp)

    li t0, ':'

    addi a0, a0, '0'            # Translate to Ascii by adding '0' = 0x30
    blt a0, t0, 1f              # See if t1 > '9' i.e. t1 > ':'
    addi a0, a0, 39             # Else convert to 'a'-'f'

1:  # Exit
    lw t0, 8(sp)
    EpilogeRa 8

    ret

# ---------------------------------------------
# @note HexCharToWord
# Convert ascii char (in a0) to Word and return in a0
# It is assumed that char is already a valid hex digit
# ---------------------------------------------
.global HexCharToWord
HexCharToWord:
    PrologRa 8
    sw t3, 8(sp)

    li t3, ':'                 # Determine which ascii group
    bltu a0, t3, 1f

    # a-f
    addi a0, a0, -'a'+10
    j 2f

1:
    # 0-9
    addi a0, a0, -'0'

2:  # Exit
    lw t3, 8(sp)
    EpilogeRa 8

    ret

# ---------------------------------------------
# @note WordAlign
# Align by setting the lower 2 bits to zero
# Input:
#   a0 = word to be word aligned
# Output:
#   a0 = aligned
# ---------------------------------------------
.global WordAlign
WordAlign:
    andi a0, a0, 0xFFFFFFFC
    ret

# ---------------------------------------------
# @note IsHexDigit
# Check if a0 (char) is a hex digit: 0-9 or a-f
# return = a0 => 0 (no), 1 (yes)
# ---------------------------------------------
.global IsHexDigit
IsHexDigit:
    li t0, '0'                  # if a0 < '0' it isn't a digit
    bltu a0, t0, 1f

    li t0, 'f'                  # if a0 > 'f' it isn't a digit
    bgtu a0, t0, 1f

    li t0, ':'                  # if a0 < ':' it IS a digit
    bltu a0, t0, 2f
    
    li t0, '`'                  # if a0 > '`' it IS a digit
    bgtu a0, t0, 2f

1:
    li a0, 0                    # No: not valid
    j 3f

2:
    li a0, 1                    # Yes: it valid

3:  # Exit
    ret

# ---------------------------------------------
# @note IsIntDigit
# Check if a0 (char) is a integer digit: 0-9
# return = a0 => 0 (no), 1 (yes)
# ---------------------------------------------
.global IsIntDigit
IsIntDigit:
    li t0, '0'                  # if a0 < '0' it isn't a digit
    bltu a0, t0, 1f

    li t0, '9'                  # if a0 <= '9' it isn't a digit
    bleu a0, t0, 2f

1:
    li a0, 0                    # No: not integer
    j 3f

2:
    li a0, 1                    # Yes: it integer

3:  # Exit
    ret

# ---------------------------------------------
# @note IsInteger
# Scan each char for valid integer chars
# a0 points to string
# return = a0 => 0 (no), 1 (yes)
# ---------------------------------------------
.global IsInteger
IsInteger:
    PrologRa 12
    sw t2, 8(sp)
    sw t1, 12(sp)

    mv t1, a0                   # Copy pointer

II_Loop:
    lbu t2, 0(t1)               # Fetch char
    beq zero, t2, II_Valid      # If Null then all are valid

    addi t1, t1, 1              # Else move to next char
    mv a0, t2                   # Set argument for IsInt...
    jal IsIntDigit              # a0 = 0 = invalid
    beq zero, a0, II_Invalid    # Exit to invalid if a0 = 0
    j II_Loop                   # Loop while a0 = 1

II_Valid:
    li a0, 1                    # Valid number
    j II_Exit

II_Invalid:
    li a0, 0                    # Invalid number

II_Exit:
    lw t1, 12(sp)
    lw t2, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# @note IsHex32String
# Scan each char for valid hex chars
# Input:
#   a0 points to string
# Output:
#   a0 => 0 (no), 1 (yes)
# ---------------------------------------------
.global IsHex32String
IsHex32String:
    PrologRa 12
    sw t1, 8(sp)
    sw t2, 12(sp)

    mv t1, a0                   # Copy pointer

IH_Loop:
    lbu t2, 0(t1)               # Fetch char
    beq zero, t2, IH_Valid      # If Null then all are valid

    addi t1, t1, 1              # Move to next char
    mv a0, t2                   # Pass argument to "is" check
    jal IsHexDigit
    beq zero, a0, IH_Invalid    # Exit to invalid if a0 = 0
    j IH_Loop                   # Loop while a0 = 1

IH_Valid:
    li a0, 1                    # Valid address
    j IH_Exit

IH_Invalid:
    li a0, 0                    # Invalid address

IH_Exit:
    lw t2, 12(sp)
    lw t1, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# @note IsHexByte
# Scan 2 chars for valid hex chars
# Input:
#   a0 points to string
# Output:
#   a0 => 0 (no), 1 (yes)
# ---------------------------------------------
.global IsHexByte
IsHexByte:
    PrologRa 8
    sw t1, 8(sp)

    mv t1, a0                   # Copy pointer a0 will be destroyed

    lbu a0, 0(t1)               # Fetch char into argument
    jal IsHexDigit
    beq zero, a0, IHB_Invalid    # Exit to invalid if a0 = 0

    addi t1, t1, 1              # Move to 2nd char
    lbu a0, 0(t1)               # Fetch char
    jal IsHexDigit
    beq zero, a0, IHB_Invalid    # Exit to invalid if a0 = 0

IHB_Valid:
    li a0, 1                    # Valid address
    j IHB_Exit

IHB_Invalid:
    li a0, 0                    # Invalid address

IHB_Exit:
    lw t1, 8(sp)
    EpilogeRa 8

    ret
