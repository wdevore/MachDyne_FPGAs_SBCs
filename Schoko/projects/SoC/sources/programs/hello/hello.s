.set STACK_SIZE, 256         # 64 Words

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# UART
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set UART_OFFSET, 0
.set UART_CTRL_REG_ADDR, 0
.set UART_TX_REG_ADDR, 2
.set MASK_CTL_TX_BUSY, 0b00000010

.include "macros.s"

.section .text
.align 2

# Print "Hello World!" and exit

.global _start
_start:
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # Micro Prolog
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    la sp, stack_bottom             # Initialize Micro Stack

    PrologRa 12
    sw s3, 8(sp)
    sw s0, 12(sp)

    # --- Micro code starts here ---
    la s0, rom_data
    lw s3, UART_OFFSET(s0)          # UART
   
    la a0, str_hello
    jal PrintString

    # --- Ends here ---

Exit_success:
    mv a0, zero

Exit:
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    # Micro Epilog
    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    lw s0, 12(sp)
    lw s3, 8(sp)
    EpilogeRa 12

    ret

# ---------------------------------------------
# @note PrintString
# Print a Null terminated String
# Input:
#   a0 points to start of String
# ---------------------------------------------
PrintString:
    PrologRa 8
    sw s0, 8(sp)

1:
    lbu s0, 0(a0)               # Load s0 to what a0 is pointing at
    beq s0, zero, 1f            # if s0 == Null then exit

    sb s0, UART_TX_REG_ADDR(s3) # Send

    jal PollTxBusy              # Call subroutine

    addi a0, a0, 1              # Next char
    j 1b

1:  # Exit
    lw s0, 8(sp)
    EpilogeRa 8

    ret

# ---------------------------------------------
# @note PollTxBusy
# Wait for the Tx busy bit to Clear
# ---------------------------------------------
PollTxBusy:
    PrologRa 8
    sw s0, 8(sp)

1:
    lbu s0, UART_CTRL_REG_ADDR(s3)  # Read UART Control reg
    andi s0, s0, MASK_CTL_TX_BUSY   # Mask
    bne zero, s0, 1b                # Loop

    # Exit
    lw s0, 8(sp)
    EpilogeRa 8
    
    ret

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Rom data
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
.word 0x00400100                # UART base
.balign 4
str_hello:   .string "\r\nHello World!\r\n"
.balign 4

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Stack. Grows towards rodata section
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section stack, "w", @nobits
.balign 4
.skip STACK_SIZE
