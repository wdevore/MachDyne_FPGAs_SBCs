# A basic monitor

.set KEY_BUFFER_SIZE, 32
.set STACK_SIZE, 256

.set IO_PORT_A_BASE, 0x00400000
.set IO_UART_BASE, 0x00400100

.set PORT_A_REG, 0

.set UART_CTRL_REG, 0
.set UART_RX_REG, 1
.set UART_TX_REG, 2

.section .text
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    la s2, Port_A_base
    la s3, UART_base
    la sp, stack                # Initialize Stack

    # Boot by sending "Ok"
    la a0, string_Ok            # Set pointer to String
    j PrintString

    # Clear port A
    addi a0, zero, 0
    j WritePortA

    # Wait for an incomming byte
WaitForByte:
    j PollRxAvail
    lbu t0, UART_RX_REG(s3)     # Read Rx reg

    addi a0, t0, 0
    j WritePortA

    j PrintChar                 # Echo char to Terminal

    addi t0, zero, 0x04         # Check EoT
    beq a0, t0, Exit            # Exit

    addi t0, zero, 0x0D         # Check return char = 0x0D
    bne a0, t0, Cont            # Continue

    addi t0, zero, 0x0A         # Send line-feed
    sb t0, UART_TX_REG(s3)
    j PollTxBusy

Cont:
    j WaitForByte               # Loop

Exit:
    la a0, string_Bye
    j PrintString
    ebreak


# ---------------------------------------------
# Print a Null terminated String
# a0 points to start of String
# ---------------------------------------------
PrintString:
    lbu t0, 0(a0)               # Load t0 to what a0 is pointing at
    beq t0, zero, PSExit        # Is t0 a Null char
    sb t0, UART_TX_REG(s3)      # Send
    jal t1, PollTxBusy
    addi a0, a0, 1              # Next char
    j PrintString

PSExit:
    ret

# ---------------------------------------------
# Wait for the Tx busy bit to Clear
# t1 is the return address
# ---------------------------------------------
PollTxBusy:
    addi sp, sp, -4             # Move stack pointer
    sw t0, 0x4(sp)              # Push

1:
    lbu t0, UART_CTRL_REG(s3)   # Read UART Control reg
    andi t0, t0, 0x02           # Mask = 00000010
    bne zero, t0, 1b            # Loop

    lw t0, 4(sp)                # Pop
    addi sp, sp, 4              # Move stack pointer

    jalr x0, 0(t1)              # return

# ----------------------------------------------------------
# Wait for the Rx byte available bit to Set when a byte
# has arrived.
# ----------------------------------------------------------
PollRxAvail:
    addi sp, sp, -4             # Move stack pointer
    sw t0, 4(sp)                # Push
    li t1, 0x04                 # Rx-Byte-Available mask

1:
    lbu t0, UART_CTRL_REG(s3)   # Read Control reg at offset 0x0
    and t0, t0, t1              # Mask = 00000100
    bne t1, t0, 1b              # Loop

    lw t0, 0x4(sp)              # Pop
    addi sp, sp, 4              # Move stack pointer
    ret

# ---------------------------------------------
# a0 is byte to write to port
# ---------------------------------------------
WritePortA:
    sb a0, PORT_A_REG(s2)
    ret

# ---------------------------------------------
# Print a single character
# a0 = char
# ---------------------------------------------
PrintChar:
    sb a0, UART_TX_REG(s3)      # Send
    jal t1, PollTxBusy
    ret


# __++__++__++__++__++__++__++__++__++__++__++__++__++
# ROM-ish
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
string_Ok: .string "Ok\n"
string_Bye: .string "Bye\n"
Port_A_base: .word IO_PORT_A_BASE
UART_base: .word IO_UART_BASE

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Incoming data buffer
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .data
keyBuf:
.skip KEY_BUFFER_SIZE
   

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Stack. Grows towards data section
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.bss
.balign 4
.skip STACK_SIZE
stack:

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# IO
# __++__++__++__++__++__++__++__++__++__++__++__++__++
