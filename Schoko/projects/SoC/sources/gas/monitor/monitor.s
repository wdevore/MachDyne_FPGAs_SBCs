# A basic monitor

.set KEY_BUFFER_SIZE, 32
.set STACK_SIZE, 256

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# Port A
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set PORT_A_OFFSET, 0
.set PORT_A_REG, 0

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# UART
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set UART_OFFSET, 4
.set UART_CTRL_REG_ADDR, 0
.set UART_RX_REG_ADDR, 1
.set UART_TX_REG_ADDR, 2
.set MASK_CTL_RX_AVAL, 0b00000100
.set MASK_CTL_TX_BUSY, 0b00000010

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# Ascii
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set ASCII_EoT,         0x03        # Control-C = End-of-Text
.set ASCII_CR,          '\r'        # Carriage return
.set ASCII_LF,          '\n'        # Line feed
.set ASCII_DEL,         0x7F        # [Del] key
.set ASCII_BACK,        0x08        # Backspace

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

# ++++++++++++++++++++++++++++++++++++++++++++++++++++
.section .text
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    la t0, rom_data
    lw s2, PORT_A_OFFSET(t0)        # Port A base
    lw s3, UART_OFFSET(t0)          # UART
    la sp, stack_bottom             # Initialize Stack

    # Boot and send greetings
    la a0, str_Greet             # Set pointer to String
    jal PrintString

    # Clear working address
    la a0, working_addr
    sw zero, 0(a0)   

    jal PrintCursor

    # Clear port A
    li a0, 0
    jal WritePortA

    # Clear key buffer
    jal ClearKeyBuffer

    # Wait for an incomming byte
ScanInput:
    jal PollRxAvail                 # Blocks until byte arrives

    lbu a0, UART_RX_REG_ADDR(s3)    # Access byte just received

    # jal WritePortA                  # Echo to port A
    jal PrintChar                   # Echo char to Terminal

    li t0, ASCII_EoT                # Check EoT
    beq a0, t0, Exit                # Terminate

    # If CR then process buffer
    jal CheckForCR
    beq zero, a0, 1f                # a0 == 1 if CR detected
    jal ProcessBuf

    j ScanInput

1:
    jal CheckForDEL

    j ScanInput                     # Loop (aka Goto)

Exit:
    la a0, str_Bye
    jal PrintString
    ebreak

# ---------------------------------------------
# Process what was placed into the buffer
# ---------------------------------------------
ProcessBuf:
    PrologRa

    jal Process_A_Command
    bgtu a0, zero, PB_EXIT          # a == 0 then process next command

    jal Process_R_Command
    bgtu a0, zero, PB_EXIT

    jal Process_W_Command
    bgtu a0, zero, PB_EXIT

    jal Process_E_Command
    bgtu a0, zero, PB_EXIT

    la a0, str_UnknownCommand
    jal PrintString

PB_EXIT:
    jal PrintCursor

    jal ClearKeyBuffer

    EpilogeRa

    ret

# ---------------------------------------------
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
Process_A_Command:
    PrologRa

    # The first char in the key buffer is the command
    la t1, keyBuf
    lbu t1, 0(t1)
    li t0, 'a'
    bne t0, t1, PAC_NH          # Exit if not 'a' command

    la a0, keyBuf               # Pointer to buffer
    addi a0, a0, 1              # Move to 'type': ('b' or 'w')

    lbu t1, 0(a0)               # Get char to check

    li t0, 'b'
    beq t0, t1, PAC_Bytes

    li t0, 'w'
    beq t0, t1, PAC_Words

    j PRC_Error

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
    # jal WritePortA
    jal WordAlign               # a0 aligned and returned in a0

    la t0, working_addr
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

    la t0, working_addr
    sw a0, 0(t0)
    
    li a0, 1
    j PAC_Exit

PAC_Error:  # Display error message
    la a0, str_w_cmd_error
    jal PrintString
    li a0, 2
    j PAC_Exit

PAC_NH:
    li a0, 0                    # Not handled

PAC_Exit:
    EpilogeRa
    
    ret

# ---------------------------------------------
# Switch between big/little endian
# ] eb
# OR
# ] el
# ---------------------------------------------
Process_E_Command:
    PrologRa

    # The first char in the key buffer is the command
    la t1, keyBuf
    lbu t1, 0(t1)
    li t0, 'e'
    bne t0, t1, PEC_NH          # Exit if not 'r' command

    la a0, keyBuf
    addi a0, a0, 1              # Move to 'type'

    lbu t1, 0(a0)               # Get char to check

    li t0, 'b'
    beq t0, t1, PEC_Big

    li t0, 'l'
    beq t0, t1, PEC_Little

    j PRC_Error

PEC_Big:
    # Default (readable)
    la t1, endian_order
    li a0, 0
    sb a0, 0(t1)

    li a0, 1                    # Handled
    j PRC_Exit

PEC_Little:
    la t1, endian_order
    li a0, 1                    # Also happens to be "handled" signal
    sb a0, 0(t1)

    j PRC_Exit

PEC_Error:  # Display error message
    la a0, str_e_cmd_error
    jal PrintString
    li a0, 2
    j PRC_Exit

PEC_NH:
    li a0, 0                    # Not handled

PEC_Exit:

    EpilogeRa
    
    ret

# ---------------------------------------------
# a0 = 0 (not handled), 1 (handled), 2 (error)
# ] rw 25
# The 1st parm 'type' can be 'b' (byte) or 'w" (word)
# The 2nd parm 'count' must be a decimal number
# ---------------------------------------------
Process_R_Command:
    PrologRa

    # The first char in the key buffer is the command
    la t1, keyBuf
    lbu t1, 0(t1)
    li t0, 'r'
    bne t0, t1, PRC_NH          # Exit if not 'r' command

    la a0, keyBuf
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
    la a0, str_r_cmd_error
    jal PrintString
    li a0, 2
    j PRC_Exit

PRC_NH:
    li a0, 0                    # Not handled

PRC_Exit:

    EpilogeRa
    
    ret

# ---------------------------------------------
# a0 = 0 (not handled), 1 (handled), 2 (error)
# ] ww 1234abcd
# OR
# ] wb af
# The 1st parm 'type' can be 'b' (byte) or 'w" (word)
# The 2nd parm is a value
# ---------------------------------------------
Process_W_Command:
    PrologRa

    # The first char in the key buffer is the command
    la t1, keyBuf
    lbu t1, 0(t1)
    li t0, 'w'
    bne t0, t1, PWC_NH          # Exit if not 'w' command

    la a0, keyBuf
    addi a0, a0, 1              # Move to 'type'

    lbu t1, 0(a0)               # Get char to check

    li t0, 'b'
    li t2, 0                    # Indicate byte format
    beq t0, t1, PWC_Bytes

    li t0, 'w'
    li t2, 1                    # Indicate word format
    beq t0, t1, PWC_Words

    j PWC_Error

PWC_Words:
    addi a0, a0, 2              # Move to 'value' (space + char)
    mv t5, a0                   # Backup copy

    # Check the value is 4 bytes or 8 chars in length
    jal IsHex32String
    beq zero, a0, PWC_Error     # if zero then display error

    mv a0, t5                   # Restore char position
    jal LengthOfString          # a0 <== length
    li a1, 8                    # Set Max with to 8 chars
    bne a0, a1, PWC_Error

    # Now write word to working address
    la t0, working_addr         # Point to working address variable
    lw t0, 0(t0)                # Fetch value from variable = working address

    mv a0, t5                   # Restore char position
    jal String32ToWord          # a0 = word to store

    sw a0, 0(t0)                # Store it

    j PWC_Exit

PWC_Bytes:
    addi a0, a0, 2              # Move to 'value' (space + char)
    mv t5, a0                   # Backup copy

    jal IsHexByte               # a0 = 0 if invalid hex
    beq zero, a0, PWC_Error

    # Now write word to working address
    la t0, working_addr         # Point to working address variable
    lw t0, 0(t0)                # Fetch value from variable = working address

    mv a0, t5                   # Restore char position
    jal String8ToWord           # a0 = word (i.e. byte) to store

    sb a0, 0(t0)

    j PWC_Exit

PWC_Error:  # Display error message
    la a0, str_w_cmd_error
    jal PrintString
    li a0, 2
    j PWC_Exit

PWC_NH:
    li a0, 0                    # Not handled

PWC_Exit:
    EpilogeRa

    ret

# ---------------------------------------------
# a0 = count of Words to display
# ---------------------------------------------
DumpWords:
    PrologRa 16
    sw t0, 8(sp)
    sw t1, 12(sp)
    sw t2, 16(sp)

    # Format:
    # 00000000: 12345678
    # 00000001: 12345678
    la t0, working_addr         # Pointer to working address
    lw t1, 0(t0)                # Fetch value at pointer = new pointer
    mv t2, a0                   # Capture count argument

DW_Loop:
    mv a0, t1                   # t1 points to current working address
    jal HexWordToString         # Convert address (a0) to string
    la a0, string_buf
    jal PrintString             # Print address

    li a0, ':'
    jal PrintChar

    li a0, ' '
    jal PrintChar

    lw a0, 0(t1)                # Fetch value
    jal HexWordToString         # Convert value to string
    la a0, string_buf
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

    sw t2, 16(sp)
    sw t1, 12(sp)
    sw t0, 8(sp)
    EpilogeRa 16

    ret

# ---------------------------------------------
# Input:
#   a0 = count of lines to display, each 3 words + ascii
# Output format:
# ...] rb 1
# 00000000: 01 02 03 04 01 02 03 04 01 02 03 04  Hello World!
# ---------------------------------------------
DumpBytes:
    PrologRa 24
    sw t0, 8(sp)
    sw t1, 12(sp)
    sw t2, 16(sp)
    sw t3, 20(sp)
    sw t4, 24(sp)

    la t0, working_addr         # Pointer to working address
    lw t1, 0(t0)                # Fetch value at pointer = new pointer
    mv t2, a0                   # Capture lines-to-display argument

DB_Loop_Lines:
    li t3, 12                   # How many bytes per line
    mv a0, t1                   # t1 points to current working address
    jal HexWordToString         # Convert address (a0) to string
    la a0, string_buf
    jal PrintString             # Print address

    li a0, ':'
    jal PrintChar

    li a0, ' '
    jal PrintChar

    mv t4, t1

WRD_Loop_Bytes: # Print 3 Words of bytes
    lbu a0, 0(t1)
    jal HexByteToString
    la a0, string_buf
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
    sw t4, 24(sp)
    sw t3, 20(sp)
    sw t2, 16(sp)
    sw t1, 12(sp)
    sw t0, 8(sp)
    EpilogeRa 24

    ret

# ---------------------------------------------
# Check if a0 (char) is a hex digit: 0-9 or a-f
# return = a0 => 0 (no), 1 (yes)
# ---------------------------------------------
IsHexDigit:
    PrologRa 8
    sw t0, 8(sp)

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
    lw t0, 8(sp)
    EpilogeRa 8
    ret

# ---------------------------------------------
# Check if a0 (char) is a integer digit: 0-9
# return = a0 => 0 (no), 1 (yes)
# ---------------------------------------------
IsIntDigit:
    PrologRa 8
    sw t0, 8(sp)

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
    lw t0, 8(sp)
    EpilogeRa 8
    ret

# ---------------------------------------------
# Scan each char for valid integer chars
# a0 points to string
# return = a0 => 0 (no), 1 (yes)
# ---------------------------------------------
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
# Scan each char for valid hex chars
# Input:
#   a0 points to string
# Output:
#   a0 => 0 (no), 1 (yes)
# ---------------------------------------------
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
# Scan 2 chars for valid hex chars
# Input:
#   a0 points to string
# Output:
#   a0 => 0 (no), 1 (yes)
# ---------------------------------------------
IsHexByte:
    PrologRa 12
    sw t1, 8(sp)
    sw t2, 12(sp)

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
    lw t2, 12(sp)
    lw t1, 8(sp)
    EpilogeRa 12

    ret


# ---------------------------------------------
# Check for Backspace/Delete
# Moves the cursor back and then print a Space
# ---------------------------------------------
CheckForDEL:
    PrologRa 8
    sw t0, 8(sp)

    lbu a0, UART_RX_REG_ADDR(s3)    # Access byte just received

    # Update terminal visual only
    # Is a0 = [Del] key
    li t0, ASCII_DEL
    bne a0, t0, 1f

    # First move back "over" the character
    li a0, ASCII_BACK
    jal PrintChar

    # Now erase it with a Space char
    li a0, ' '
    jal PrintChar

    # Finally position the cursor back over the Space
    li a0, ASCII_BACK
    jal PrintChar

    # Now update buffer to reflect the delete
    jal TrimLastKeyBuffer

1:  # Exit
    lw t0, 8(sp)
    EpilogeRa 8

    ret

# ---------------------------------------------
# Check for Carriage return
# If it isn't CR then place into buffer
# a0 = key to check
# a0 = return value
# ---------------------------------------------
CheckForCR:
    PrologRa 12
    sw t0, 8(sp)
    sw t1, 12(sp)

    # Is a0 = CR
    li t0, ASCII_CR
    bne a0, t0, 1f              # branch if not CR
    beq a0, t0, 2f

1:  # Not CR, append to buffer
    # Fetch counter offset
    la t0, bufOffset
    lbu t0, 0(t0)               # current index value

    # Place into buffer
    la t1, keyBuf
    add t1, t1, t0              # Move pointer
    sb a0, 0(t1)                # Store in buffer

    addi t0, t0, 1              # Inc offset and store
    la t1, bufOffset
    sb t0, 0(t1)

    # Signal CR not detected
    li a0, 0

    j 3f

2:  # Is CR
    # Echo a LF back as well
    li a0, ASCII_LF
    jal PrintChar

    # Fetch current offset
    la t0, bufOffset
    lbu t0, 0(t0)               # current index value

    # Null terminate key buffer
    la t1, keyBuf               # Pointer to buf
    add t1, t1, t0              # Move pointer to current position
    sb zero, 0(t1)              # Store Null

    # Signal a CR was detected
    li a0, 1

3:  # Exit
    lw t1, 12(sp)
    lw t0, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# Clear key input buffer
# ---------------------------------------------
ClearKeyBuffer:
    PrologRa 12
    sw t0, 8(sp)
    sw t1, 12(sp)

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
    lw t1, 12(sp)
    lw t0, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# Trim off the last character in the key buffer.
# If the offset index is == 0 then just put a Null
# and return, otherwise, put a Null and dec the offset.
# Decrement by 2 because the "cursor" is always after
# last visible char.
# ---------------------------------------------
TrimLastKeyBuffer:
    PrologRa 12
    sw t0, 8(sp)
    sw t1, 12(sp)

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

    # Exit
    lw t1, 12(sp)
    lw t0, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# Wait for the Tx busy bit to Clear
# ---------------------------------------------
PollTxBusy:
    PrologRa 8
    sw t0, 8(sp)

1:
    lbu t0, UART_CTRL_REG_ADDR(s3)  # Read UART Control reg
    andi t0, t0, MASK_CTL_TX_BUSY   # Mask
    bne zero, t0, 1b                # Loop

    # Exit
    lw t0, 8(sp)
    EpilogeRa 8
    
    ret

# ----------------------------------------------------------
# Wait for the Rx byte available bit to Set when a byte
# has arrived.
# ----------------------------------------------------------
PollRxAvail:
    li t1, MASK_CTL_RX_AVAL         # Rx-Byte-Available mask

1:
    lbu t0, UART_CTRL_REG_ADDR(s3)  # Read UART Control reg
    and t0, t0, t1                  # Apply Mask
    bne t1, t0, 1b                  # Loop

    ret

# ---------------------------------------------
# a0 is byte to write to port
# ---------------------------------------------
WritePortA:
    sb a0, PORT_A_REG(s2)

    ret

# ---------------------------------------------
# Print a Null terminated String
# a0 points to start of String
# ---------------------------------------------
PrintString:
    PrologRa 8
    sw t0, 8(sp)

1:
    lbu t0, 0(a0)               # Load t0 to what a0 is pointing at
    beq t0, zero, 1f            # if t0 == Null then exit

    sb t0, UART_TX_REG_ADDR(s3) # Send

    jal PollTxBusy              # Call subroutine

    addi a0, a0, 1              # Next char
    j 1b

1:  # Exit
    lw t0, 8(sp)
    EpilogeRa 8

    ret

# ---------------------------------------------
# Print a single character
# a0 = char
# ---------------------------------------------
PrintChar:
    PrologRa

    sb a0, UART_TX_REG_ADDR(s3) # Send

    jal PollTxBusy              # Call subroutine

    EpilogeRa

    ret

PrintCrLn:
    PrologRa

    li a0, ASCII_CR
    sb a0, UART_TX_REG_ADDR(s3) # Send
    jal PollTxBusy

    li a0, ASCII_LF
    sb a0, UART_TX_REG_ADDR(s3) # Send
    jal PollTxBusy

    EpilogeRa

    ret

PrintCharCrLn:
    PrologRa

    jal PrintChar

    jal PrintCrLn

    EpilogeRa

    ret

# ---------------------------------------------
# Moves the cursor back to the begining of the line
# and prints the working address + "]" char.
# For example: 00001234]
# ---------------------------------------------
PrintCursor:
    PrologRa 8
    sw t0, 8(sp)

    # Print working address
    la t0, working_addr
    lw a0, 0(t0)                # Word value to convert
    jal PrintAddress
    # jal HexWordToString
    # la a0, string_buf
    # jal PrintString

    li a0, ']'
    jal PrintChar

    li a0, ' '
    jal PrintChar

    # Exit
    lw t0, 8(sp)
    EpilogeRa 8

    ret

PrintAddress:
    PrologRa

    jal HexWordToString
    la a0, string_buf
    jal PrintString

    EpilogeRa

    ret

# ---------------------------------------------
# Print a0's LS nibble
# ---------------------------------------------
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

    jal PollTxBusy              # Call subroutine

    # Exit
    lw t0, 12(sp)
    lw t3, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# Print a0's LSB
# ---------------------------------------------
PrintByte:
    PrologRa 12
    sw a0, 8(sp)
    sw t0, 12(sp)

    mv t0, a0                   # Backup a0
    andi a0, a0, 0x0F           # Mask off lower nibble
    jal PrintNibble
    mv a0, t0                   # Restore a0
    slli a0, a0, 4              # Shift higher nibble to lower nibble
    jal PrintNibble

    # Exit
    lw t0, 12(sp)
    lw a0, 8(sp)
    EpilogeRa 12
    
    ret

# ---------------------------------------------
# Print a0 Word as binary string
# ---------------------------------------------
PrintWordAsBinary:
    PrologRa 20
    sw t0, 8(sp)
    sw t1, 12(sp)
    sw t2, 16(sp)
    sw t3, 20(sp)

    li t0, 32                   # Load Dec Counter
    mv t2, a0                   # Copy a0 for modification
    li t3, 0x80000000           # MSb mask for slli

1:
    and t1, t2, t3              # Mask in MSb
    bne zero, t1, 2f            # Test

    li a0, '0'
    jal PrintChar
    j 3f

2:
    li a0, '1'
    jal PrintChar

3:
    slli t2, t2, 1              # Move next bit to MSb
    addi t0, t0, -1             # Dec counter
    bne zero, t0, 1b            # Loop while t0 > 0

    # Exit
    lw t3, 20(sp)
    lw t2, 16(sp)
    lw t1, 12(sp)
    lw t0, 8(sp)
    EpilogeRa 20

    ret

# \__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/
# Conversions
# /--\/--\/--\/--\/--\/--\/--\/--\/--\/--\/--\/--\/--\

# ---------------------------------------------
# Input:
#   a0 = Address of string to left-pad with '0' chars
#   a1 = output size requested, for example, 8 chars
# output is put in string_buf2
# 123.....
# 00000123
# ---------------------------------------------
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
    sw t4, 24(sp)
    sw t4, 20(sp)
    sw t3, 16(sp)
    sw t2, 12(sp)
    sw t1, 8(sp)

    EpilogeRa 24

    ret

# ---------------------------------------------
# Input:
#   a0 = Address of string to find size of
# Output:
#   a0 is overriden with size
# String must be Null terminated
# ---------------------------------------------
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
# Convert String (8 chars) to Word and return in a0
# Input:
#   a0 = address to source string buffer
# Output:
#   a0 = return = Word
#
#  28   24   20   16   12    8   4    0        <-- shift amount
# 0000_0000_0000_0000_0000_0000_0000_0000
# ---------------------------------------------
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
# Convert String (2 chars) to Word and return in a0
# Input:
#   a0 = address to source string buffer
# Output:
#   a0 = LSB of Word
# ---------------------------------------------
String8ToWord:
    PrologRa 16
    sw t4, 8(sp)
    sw t3, 12(sp)
    sw t2, 16(sp)

    mv t4, a0                   # Copy pointer
    mv t3, zero                 # The final converted Word pre cleared

    lbu a0, 0(t4)               # Get ascii char (upper nibble)
    jal HexCharToWord           # Convert to number in a0
    mv t2, a0                   # Copy for merging later
    slli t2, t2, 4              # Shift 4 bits to high position

    addi t4, t4, 1              # Move to next nibble char
    lbu a0, 0(t4)               # Get ascii char (lower nibble)
    jal HexCharToWord           # Convert to number in a0

    or a0, t2, a0               # Merge together

    # Exit
    lw t2, 16(sp)
    lw t3, 12(sp)
    lw t4, 8(sp)
    EpilogeRa 16

    ret

# ---------------------------------------------
# Converts a 32 bit value to an 8 char string.
# The string is stored in string_buf.
# left most nibble = LM nibble
# Input:
#   a0 = word to convert
# Output:
#   string_buf
# ---------------------------------------------
HexWordToString:
    PrologRa 20
    sw t0, 8(sp)
    sw t1, 12(sp)
    sw t2, 16(sp)
    sw t3, 20(sp)

    la t0, string_buf           # Pointer to buffer
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
# Converts a byte value to an ascii char.
# The string is stored in string_buf.
# Visible characters start at ' ' -> '~' otherwise
# Show a '.'
# Input:
#   a0 = word with LSB to convert
# Output:
#   a0 = visibility adjusted
# ---------------------------------------------
ByteToChar:
    PrologRa 8
    sw t0, 8(sp)

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
    lw t0, 8(sp)
    EpilogeRa 8

    ret

# ---------------------------------------------
# Converts a 8 bit value to an 2 char hex string.
# The string is stored in string_buf.
# Input:
#   a0 = word with LSB to convert
# Output:
#   string_buf
# ---------------------------------------------
HexByteToString:
    PrologRa 12
    sw t0, 8(sp)
    sw t1, 12(sp)

    la t0, string_buf           # Pointer to buffer
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
# Converts a Nibble to a char.
# Input:
#   a0 = word with the Nibble
# Output:
#   a0 = char
# ---------------------------------------------
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
# Convert ascii char (in a0) to Word and return in a0
# It is assumed that char is already a valid hex digit
# ---------------------------------------------
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
# Align by setting the lower 2 bits to zero
# Input:
#   a0 = word to be word aligned
# Output:
#   a0 = aligned
# ---------------------------------------------
WordAlign:
    andi a0, a0, 0xFFFFFFFC
    ret

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# ROM-ish
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
.word 0x00400000                # Port A base
.word 0x00400100                # UART base
str_Greet:   .string "\r\nMonitor 0.0.15 - Ranger SoC - Jun 2023\r\n"
.balign 4
str_Bye:  .string "\r\nBye\r\n"
.balign 4
debug_str:  .string "\r\nDEBUG\r\n"
.balign 4
str_w_cmd_error: .string "Invalid parameter(s): w('b' or 'w') value value...\r\n"
.balign 4
str_r_cmd_error: .string "Invalid parameter(s): r('b' or 'w') count\r\n"
.balign 4
str_e_cmd_error: .string "Invalid parameter(s): e('b' or 'l')\r\n"
.balign 4
str_UnknownCommand: .string "Unknown command\r\n"
.balign 4

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Incoming data buffer
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section keybuffer, "w", @nobits
bufOffset: .byte 0
.balign 4
keyBuf:
.skip KEY_BUFFER_SIZE

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Program variables
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .data
working_addr: .word 0x00000000
endian_order: .byte 0               # Default to readable (0 = big endian)
# String buffer used for conversions
.balign 4
string_buf:  .fill 128, 1, 0        # 128*1 bytes with value 0
string_buf2: .fill 128, 1, 0        # 128*1 bytes with value 0

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Stack. Grows towards rodata section
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section stack, "w", @nobits
.balign 4
.skip STACK_SIZE
