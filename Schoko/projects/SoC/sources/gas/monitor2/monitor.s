# A basic monitor

# -------------------------------------------------
# @note Registers definitions
# -------------------------------------------------
# sp : monitor stack pointer
# gp : ROM data pointer
# tp : keyboard buffer pointer
# s0 : Port-A base pointer
# s1 : String scratch buffer pointer
# s2 : Working address pointer
# s3 : UART base pointer

.set STACK_SIZE, 256
.set MICROCODE_SIZE, 2048

.include "sets.s"

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# Ascii
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set ASCII_EoT,         0x03        # Control-C = End-of-Text
.set ASCII_DEL,         0x7F        # [Del] key
.set ASCII_BACK,        0x08        # Backspace

.include "macros.s"

# ++++++++++++++++++++++++++++++++++++++++++++++++++++
.section .text, "ax", @progbits
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    la gp, rom_data
    lw s0, PORT_A_OFFSET(gp)        # Port A base
    la s1, string_buf               # String scratch buffer
    la s2, working_addr
    lw s3, UART_OFFSET(gp)          # UART
    la tp, keyBuf                   # Pointer to keyboard input buffer
    la sp, stack_bottom             # Initialize Stack

    # Boot and send greetings
    la a0, str_Greet             # Set pointer to String
    jal PrintString

    # Clear working address
    mv a0, s2
    sw zero, 0(a0)   

    jal PrintCursor

    # Clear port A
    li a0, 0
    jal WritePortA

    # Clear key buffer
    jal ClearKeyBuffer

    # Set interrupt trap vector
    jal ISR_Set_Trap

    # Wait for an incomming byte
ScanInput:
    jal UART_PollRxAvail            # Blocks until byte arrives

    lbu a0, UART_RX_REG_ADDR(s3)    # Access byte just received

    jal PrintChar                   # Echo char to Terminal

    # If CR then process buffer and store char in buffer
    jal CheckForCR
    beq zero, a0, 1f                # a0 == 1 if CR detected
    jal ProcessBuf

ResumeScan:
    jal PrintCursor

    jal ClearKeyBuffer

    j ScanInput

1:  # CR Not detected
    jal CheckForDEL
# 2:
    j ScanInput                     # Loop (aka Goto)

Exit:
    la a0, str_Bye
    jal PrintString
    ebreak

# ---------------------------------------------
# @note ReEntry
# This is the Trap vector redirect target. Once the Trap
# completes it would normally return to the micro program.
# Instead it's redirected here and the original mepc address
# is printed.
# Finally jump/resume back to the Monitor, scanning for input.
# ---------------------------------------------
.global ReEntry
ReEntry:
    # Print mepc. The value is the interrupt address somewhere
    # in the micro program.
    jal PrintCrLn

    # Example: "Program interrupted at: 0x000004dc"
    la a0, str_irq_msg
    jal PrintString

    la a0, mepc_return_addr
    lw a0, 0(a0)
    jal HexWordToString

    mv a0, s1
    jal PrintString

    jal PrintCrLn

    # Resume Monitor's scanner
    j ResumeScan

# ---------------------------------------------
# @note Processbuf
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

    jal Process_U_Command
    bgtu a0, zero, PB_EXIT

    jal Process_X_Command
    bgtu a0, zero, PB_EXIT

    la a0, str_UnknownCommand
    jal PrintString

PB_EXIT:
    EpilogeRa

    ret

# ---------------------------------------------
# @note CheckForDEL
# Check for Backspace/Delete
# Moves the cursor back and then print a Space
# ---------------------------------------------
CheckForDEL:
    PrologRa 12
    sw t0, 8(sp)
    sw a0, 12(sp)

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
    lw a0, 12(sp)
    lw t0, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# @note CheckForCR
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
    li t0, '\r'                 # Carriage return
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
    li a0, '\n'                 # Line feed
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

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# ROM-ish
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
.word 0x00400000                # Port A base
.word 0x00400100                # UART base
.word 0x00000008                # Mask for Global interrupts of mstatus
.balign 4
str_Greet:          .string "\r\nMonitor 0.0.4 - Ranger Retro - Sep 2023\r\n"
.balign 4
str_Bye:            .string "\r\nBye\r\n"
.balign 4
.global str_cmd_error
str_cmd_error:      .string "Invalid inputs\r\n"
.balign 4
.global str_u_load_error
str_u_load_error:   .string "SoT not detected\r\n"
.balign 4
.global str_u_data_error
str_u_data_error:   .string "DAT not detected\r\n"
.balign 4
.global str_u_loading
str_u_loading:      .string "Loading...\r\n"
.balign 4
.global str_u_load_Wait
str_u_load_Wait:    .string "Waiting for SoT...\r\n"
.balign 4
.global str_u_load_cmplt
str_u_load_cmplt:   .string "Loading complete.\r\n"
.balign 4
str_UnknownCommand: .string "Unknown command\r\n"
.balign 4
.global str_return_msg
str_return_msg:     .string "Exit code: ("
.balign 4
.global str_running_msg
str_running_msg:    .string "Running micro program\r\n"
.balign 4
str_irq_msg:        .string "Program interrupted at: 0x"
.balign 4

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Incoming data buffer
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section keybuffer, "w", @nobits
.global bufOffset
bufOffset: .byte 0

.balign 4
.global keyBuf
keyBuf:
.skip KEY_BUFFER_SIZE

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Program variables
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .data
.global working_addr
working_addr:     .word 0x00000000
.global mepc_return_addr
mepc_return_addr: .word 0x00000000
.global stack_backup
stack_backup:     .word 0x00000000
.global endian_order
endian_order:     .byte 0            # Default to readable (0 = big endian)
# String buffer used for conversions
.balign 4
.global string_buf
string_buf:  .fill 128, 1, 0        # 128*1 bytes with value 0
.global string_buf2
string_buf2: .fill 128, 1, 0        # 128*1 bytes with value 0

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Stack. Grows towards rodata section
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section stack, "w", @nobits
.balign 4
.skip STACK_SIZE

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Micro code program area
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section micro_code, "wx", @nobits
.balign 4
.skip MICROCODE_SIZE

