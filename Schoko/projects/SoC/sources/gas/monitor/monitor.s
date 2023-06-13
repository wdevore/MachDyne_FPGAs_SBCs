# A basic monitor

.set KEY_BUFFER_SIZE, 32
.set STACK_SIZE, 256

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# Port A
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set PORT_A_REG, 0

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# UART
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set UART_CTRL_REG_ADDR, 0
.set UART_RX_REG_ADDR, 1
.set UART_TX_REG_ADDR, 2
.set MASK_CTL_RX_AVAL, 0b00000100
.set MASK_CTL_TX_BUSY, 0b00000010

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# Ascii
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set ASCII_EoT, 0x03        # Control-C = End-of-Text
.set ASCII_CR, '\r'         # Carriage return
.set ASCII_LF, '\n'         # Line feed

.section .text
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    lla s2, rom_data
    lw s2, 0(s2)                    # Port A base
    lla s3, rom_data
    lw s3, 4(s3)                    # UART
    lla sp, stack_bottom            # Initialize Stack

    # Boot by sending "Ok"
    lla a0, string_Ok               # Set pointer to String
    jal PrintString

    # Clear port A
    li a0, 0
    jal WritePortA

    # Wait for an incomming byte
WaitForByte:
    jal PollRxAvail

    lbu t0, UART_RX_REG_ADDR(s3)    # Access byte just received

    mv a0, t0                       # Set argument for Jal(s)
    jal WritePortA                  # Echo to port A
    jal PrintChar                   # Echo char to Terminal

    li t0, ASCII_EoT                # Check EoT
    beq a0, t0, Exit                # Exit

    li t0, ASCII_CR                 # Check CR char
    bne a0, t0, 1f                  # Continue

    li t0, ASCII_LF                 # Send line-feed
    sb t0, UART_TX_REG_ADDR(s3)
    jal PollTxBusy

1:
    j WaitForByte                   # Loop

Exit:
    lla a0, string_Bye
    jal PrintString
    ebreak

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

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# ROM-ish
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
.word 0x00400000                # Port A base
.word 0x00400100                # UART base
string_Ok:   .string "Ok\r\n"
.balign 4
string_Bye:  .string "\r\nBye\r\n"
.balign 4

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Incoming data buffer
# __++__++__++__++__++__++__++__++__++__++__++__++__++
# .section keybuffer, "w", @nobits
# keyBuf:
# .skip KEY_BUFFER_SIZE
   

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Stack. Grows towards rodata section
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section stack, "w", @nobits
.balign 4
.skip STACK_SIZE

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# IO
# __++__++__++__++__++__++__++__++__++__++__++__++__++
