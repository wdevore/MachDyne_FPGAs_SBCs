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
.set ASCII_SPC,         0x20        # [Space] char
.set ASCII_R_SQR_BRAK,  ']'         # Square bracket char
.set ASCII_a,           'a'
.set ASCII_w,           'w'
.set ASCII_colon,       ':'         # Colon is used to check < '9'
.set ASCII_0,           '0'

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
    la a0, string_Greet             # Set pointer to String
    jal PrintString

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

    jal WritePortA                  # Echo to port A
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
    la a0, string_Bye
    jal PrintString
    ebreak

# ---------------------------------------------
# Process what was placed into the buffer
# ---------------------------------------------
ProcessBuf:
    addi sp, sp, -4             # Prologe
    sw ra, 4(sp)

    # la a0, keyBuf
    # jal PrintString

    jal ProcessWCommand

    jal PrintCursor

    jal ClearKeyBuffer

    lw ra, 4(sp)                # Epiloge
    addi sp, sp, 4

    ret

# ---------------------------------------------
# 'a' Command:
# Example: 00000000] a 000012ab
#
# Sets the working address
# The address can be of the form 1234, 00001234
# The address is converted from String to Word. Any invalid
# hex character signals an error.
# ---------------------------------------------
ProcessWCommand:
    addi sp, sp, -8             # Prologe
    sw ra, 4(sp)
    sw a0, 8(sp)

    # The first char in the key buffer is the command
    la t1, keyBuf
    lbu t1, 0(t1)
    li t0, ASCII_a
    bne t0, t1, 3f              # Exit if not 'a' command

    # It is the 'w' command. Handle it.
    la t3, string_buf           # Pointer to buffer
    li t4, 0

    # Is valid address
    la a0, keyBuf
    addi a0, a0, 2              # Move past Space, and at first hex digit
    jal IsHexAddress
    beq zero, a0, 2f            # if zero then display error

    # Convert address to Word and Store

    # Check the digit is actually a hex digit
    # lbu a0, 0(t1)
    # jal IsHexDigit
    # beq zero, a0, 2f            # if zero then display error

    la a0, debug_str
    jal PrintString

    
    j 3f                        # Exit

2:
    # Display error message
    la a0, str_w_cmd_error
    jal PrintString

3:
    lw a0, 8(sp)                # Epiloge
    lw ra, 4(sp)
    addi sp, sp, 8
    
    ret

# ---------------------------------------------
# Check if a0 (char) is a hex digit: 0-9 or a-f
# return = a0 => 0 (no), 1 (yes)
# ---------------------------------------------
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
    ret

2:
    li a0, 1                    # Yes: it valid
    ret

# ---------------------------------------------
# Scan each char for valid hex chars
# a0 points to string
# return = a0 => 0 (no), 1 (yes)
# ---------------------------------------------
IsHexAddress:
    addi sp, sp, -4             # Prologe
    sw ra, 4(sp)

    mv t1, a0                   # Copy pointer

1:
    lbu t2, 0(t1)               # Fetch char
    beq zero, t2, 1f            # Loop while not Null

    addi t1, t1, 1              # Move to next char
    mv a0, t2                   # Set argument hex check
    jal IsHexDigit
    beq zero, a0, 2f            # Exit if invalid

    j 1b                        # Loop while a0 = 1

1:
    li a0, 1                    # Valid address
    j 3f

2:
    li a0, 0                    # Invalid address

3:
    lw ra, 4(sp)                # Epiloge
    addi sp, sp, 4

    ret

# ---------------------------------------------
# Check for Backspace/Delete
# Moves the cursor back and then print a Space
# ---------------------------------------------
CheckForDEL:
    addi sp, sp, -4             # Prologe
    sw ra, 4(sp)

    lbu a0, UART_RX_REG_ADDR(s3)    # Access byte just received

    # Update terminal visual only
    # Is a0 = [Del] key
    li t0, ASCII_DEL
    bne a0, t0, 1f

    # First move back "over" the character
    li a0, ASCII_BACK
    jal PrintChar

    # Now erase it
    li a0, ASCII_SPC
    jal PrintChar

    # Finally position the cursor back over the Space
    li a0, ASCII_BACK
    jal PrintChar

    # Now update buffer
    jal TrimLastKeyBuffer

1:
    lw ra, 4(sp)                # Epiloge
    addi sp, sp, 4

    ret

# ---------------------------------------------
# Check for Carriage return
# If it isn't CR then place into buffer
# a0 = key to check
# a0 = return value
# ---------------------------------------------
CheckForCR:
    addi sp, sp, -4             # Prologe
    sw ra, 4(sp)

    # Is a0 = CR
    li t0, ASCII_CR
    bne a0, t0, 1f              # branch if not CR
    beq a0, t0, 2f

1:                              # Not CR, append to buffer
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

2:                              # Is CR
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

3:
    lw ra, 4(sp)                # Epiloge
    addi sp, sp, 4

    ret

# ---------------------------------------------
# Clear key input buffer
# ---------------------------------------------
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

1:
    ret

# ---------------------------------------------
# Trim off the last character in the key buffer.
# If the offset index is == 0 then just put a Null
# and return, otherwise, put a Null and dec the offset.
# Decrement by 2 because the "cursor" is always after
# last visible char.
# ---------------------------------------------
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
# Wait for the Tx busy bit to Clear
# ---------------------------------------------
PollTxBusy:
    lbu t0, UART_CTRL_REG_ADDR(s3)  # Read UART Control reg
    andi t0, t0, MASK_CTL_TX_BUSY   # Mask
    bne zero, t0, PollTxBusy        # Loop

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
    addi sp, sp, -4             # Move stack pointer
    sw ra, 4(sp)                # Push any return address

1:
    lbu t0, 0(a0)               # Load t0 to what a0 is pointing at
    beq t0, zero, 1f            # if t0 == Null then exit

    sb t0, UART_TX_REG_ADDR(s3) # Send

    jal PollTxBusy              # Call subroutine

    addi a0, a0, 1              # Next char
    j 1b

1:
    lw ra, 4(sp)                # Restore return address
    addi sp, sp, 4              # Reset stack pointer

    ret

# ---------------------------------------------
# Print a single character
# a0 = char
# ---------------------------------------------
PrintChar:
    addi sp, sp, -4             # Move stack pointer
    sw ra, 4(sp)                # Push any return address

    sb a0, UART_TX_REG_ADDR(s3) # Send

    jal PollTxBusy              # Call subroutine

    lw ra, 4(sp)                # Restore return address
    addi sp, sp, 4              # Reset stack pointer

    ret

PrintCharCrLn:
    addi sp, sp, -4
    sw ra, 4(sp)

    sb a0, UART_TX_REG_ADDR(s3) # Send
    jal PollTxBusy

    li a0, ASCII_CR
    sb a0, UART_TX_REG_ADDR(s3) # Send
    jal PollTxBusy

    li a0, ASCII_LF
    sb a0, UART_TX_REG_ADDR(s3) # Send
    jal PollTxBusy

    lw ra, 4(sp)
    addi sp, sp, 4

    ret

# ---------------------------------------------
# Moves the cursor back to the begining of the line
# and prints the working address + "]" char.
# For example: 00001234]
# ---------------------------------------------
PrintCursor:
    addi sp, sp, -4             # Prologe
    sw ra, 4(sp)

    # li a0, ASCII_LF
    # jal PrintChar

    # li a0, ASCII_CR
    # jal PrintChar

    # Print working address
    la t0, working_addr
    lw a0, 0(t0)                # Word value to convert
    jal HexWordToString
    la a0, string_buf
    jal PrintString

    li a0, ASCII_R_SQR_BRAK
    jal PrintChar

    li a0, ASCII_SPC
    jal PrintChar

    lw ra, 4(sp)                # Epiloge
    addi sp, sp, 4

    ret

# \__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/\__/
# Conversions
# /--\/--\/--\/--\/--\/--\/--\/--\/--\/--\/--\/--\/--\

# ---------------------------------------------
# Converts a 32 bit value to an 8 char string.
# The string is stored in string_buf.
# left most nibble = LM nibble
# a0 = word to convert
# ---------------------------------------------
HexWordToString:
    la t0, string_buf           # Pointer to buffer
    li t2, 8                    # Count 8 chars
    li t3, ASCII_colon

1:
    srli t1, a0, 28             # Shift LM nibble to right most position
    slli a0, a0, 4              # Update word by shifting in a new LM nibble
                                # for next pass.
    andi t1, t1, 0xF            # Isolate current nibble
    addi t1, t1, '0'            # Translate to Ascii by adding '0' = 0x30
    blt t1, t3, 2f              # See if t1 > '9' i.e. t1 > ':'
    addi t1, t1, 39             # Else convert to 'a'-'f' chars first

2:
    sb t1, 0(t0)                # Store char in buffer
    addi t0, t0, 1              # Move pointer

    addi t2, t2, -1
    bne zero, t2, 1b            # Loop while count > 0

    sb zero, 0(t0)              # Null terminate

    ret

# ---------------------------------------------
# a0 = Address of string to left-pad with '0' chars
# a1 = output size requested, for example, 8 chars
# output is put in string_buf2
# 23456...
# 00023456
# ---------------------------------------------
PadLeftZerosString:
    addi sp, sp, -4             # Prologe
    sw ra, 4(sp)

    mv t1, a0                   # backup address of source to t1

    # If string to pad is already = to size then return
    jal LengthOfString          # a0 now = length
    beq a0, a1, 2f              # If equal then exit

    # Calc difference: source_length  - size
    sub t2, a1, a0              # t2 = how many '0's to pad

    # First pad destination buffer with '0's
    la t3, string_buf2
    li t4, ASCII_0
1:
    sb t4, 0(t3)                # Write '0'
    addi t3, t3, 1              # Move pointer
    addi t2, t2, -1             # Dec counter
    bne zero, t2, 1b            # Loop

    # Finally append source chars to new buffer
1:
    lbu t5, 0(t1)               # Read source char
    sb t5, 0(t3)                # Write to destination
    addi t1, t1, 1              # Inc both pointers
    addi t3, t3, 1
    addi a0, a0, -1             # Dec source length
    bne zero, a0, 1b            # Loop while a0 != 0

2:
    lw ra, 4(sp)                # Epiloge
    addi sp, sp, 4

    ret

# ---------------------------------------------
# a0 = Address of string to find size of
# a0 is overriden with size
# String must be Null terminated
# ---------------------------------------------
LengthOfString:
    li t0, 0                    # Clear counter

1:
    lbu t1, 0(a0)               # Fetch char
    beq zero, t1, 1f            # Loop while not Null
    addi a0, a0, 1              # Move to next char
    addi t0, t0, 1              # Inc counter
    j 1b

1:
    mv a0, t0                   # Return value
    ret

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# ROM-ish
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
.word 0x00400000                # Port A base
.word 0x00400100                # UART base
string_Greet:   .string "\r\nMonitor 0.0.7 - Ranger SoC - Jun 2023\r\n"
.balign 4
string_Bye:  .string "\r\nBye\r\n"
.balign 4
debug_str:  .string "\r\nDEBUG\r\n"
.balign 4
str_w_cmd_error: .string "Invalid address\r\n"
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

# String buffer used for conversions
string_buf:  .fill 128, 1, 0      # 128*1 bytes with value 0
string_buf2: .fill 128, 1, 0      # 128*1 bytes with value 0

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Stack. Grows towards rodata section
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section stack, "w", @nobits
.balign 4
.skip STACK_SIZE
