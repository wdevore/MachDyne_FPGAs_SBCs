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
.set ASCII_EoT, 0x04        # End of transmission
.set ASCII_CR, '\r'         # Carriage return
.set ASCII_LF, '\n'         # Line feed

.section .text
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    lla s2, Port_A_base
    lw s2, 0(s2)

    li a0,0xff
    sb a0, PORT_A_REG(s2)

    ebreak

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# ROM-ish
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
Port_A_base: .word 0x00400000
UART_base:   .word 0x00400100
string_Ok:   .string "Ok\n"
string_Bye:  .string "\nBye\n"

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Stack. Grows towards rodata section
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section stack, "w", @nobits
.balign 4
.skip STACK_SIZE

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# IO
# __++__++__++__++__++__++__++__++__++__++__++__++__++
