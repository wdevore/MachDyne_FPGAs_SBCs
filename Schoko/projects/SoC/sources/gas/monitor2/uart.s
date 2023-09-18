.set UART_CTRL_REG_ADDR, 0

.set MASK_CTL_RX_AVAL, 0b00000100
.set MASK_CTL_TX_BUSY, 0b00000010
.set MASK_IRQ_ENADIS, 0b00001000        # Enable/Disable

.section .text, "ax", @progbits
.align 2

# ---------------------------------------------
# @note UART_PollTxBusy
# Wait for the Tx busy bit to Clear
# ---------------------------------------------
.global UART_PollTxBusy
UART_PollTxBusy:
1:
    lbu t0, UART_CTRL_REG_ADDR(s3)  # Read UART Control reg
    andi t0, t0, MASK_CTL_TX_BUSY   # Mask
    bne zero, t0, 1b                # Loop

    ret

# ----------------------------------------------------------
# @note UART_PollRxAvail
# Wait for the Rx byte available bit to Set when a byte
# has arrived.
# ----------------------------------------------------------
.global UART_PollRxAvail
UART_PollRxAvail:
    li t1, MASK_CTL_RX_AVAL         # Rx-Byte-Available mask

1:
    lbu t0, UART_CTRL_REG_ADDR(s3)  # Read UART Control reg
    and t0, t0, t1                  # Apply Mask
    bne t1, t0, 1b                  # Loop

    ret

# ----------------------------------------------------------
# @note UART_IRQ_Enable
# Set IRQ bit.
# ----------------------------------------------------------
.global UART_IRQ_Enable
UART_IRQ_Enable:
    lbu t0, UART_CTRL_REG_ADDR(s3)  # Read UART Control reg

    ori t1, t0, MASK_IRQ_ENADIS
    sb t1, UART_CTRL_REG_ADDR(s3)

    ret

# ----------------------------------------------------------
# @note UART_IRQ_Disable
# Clear IRQ bit.
# ----------------------------------------------------------
.global UART_IRQ_Disable
UART_IRQ_Disable:
    lbu t0, UART_CTRL_REG_ADDR(s3)  # Read UART Control reg

    andi t1, t0, ~MASK_IRQ_ENADIS
    sb t1, UART_CTRL_REG_ADDR(s3)

    ret
