# A very simple UART test with flow-control.
# 1 = LED off, 0 = LED on

# Send a char to minicom (with flow-control enabled)
# Type a char 'a' in minicom and compare to expected value
#   green if matched, red if not.

# 0x40000000 = read/write address
# 0x40000004 = read of control signals (tx_busy and uart_dr)

# **NOTE**: minicom allows a Go program to open a connection but **screen** does not.
# Note: The Tigard's exposes the UART channel as USB0
# minicom -b 115200 -o -D /dev/ttyUSB0   <-- "Ctrl-a Crtl-z x"

.section .text
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    la t0, prog_data
    la t1, LED_Map
    lw t1, 0(t1)        # LED memory map
    la t2, UART_Map
    lw t2, 0(t2)        # UART mem map

    li t3, 7            # Mask to turn LEDs off (111)
    sb t3, 0(t1)        # Turn LEDs off

    # Read control signals to see if Tx is busy sending something.
1:
    # Turn on green led as an indicator
    li t3, 6
    sb t3, 0(t1)

    # Wait on busy signal
    lb a1, 4(t2)
2:
    andi a2, a1, 2      # bit 1 is Tx busy flag  (Active high)
    bne zero, a2, 2b    # If set then still transmitting

    # Send 'O' to client
    li a0, 'O'
    sb a0, 0(t2)

    # ------- Delay-------
    lw t5, 0(t0)        # Reset counter 1sec
3:
    addi t5, t5, -1     # 3 cycles
    bne zero, t5, 3b    # 5 cycles

    # Turn off green
    li t3, 7
    sb t3, 0(t1)

    # ------- Delay-------
    lw t5, 0(t0)        # Reset counter 1sec
3:
    addi t5, t5, -1     # 3 cycles
    bne zero, t5, 3b    # 5 cycles

    j 1b

    # Turn on green led as an indicator
    li t3, 5
    sb t3, 0(t1)

    # Wait for char from client by reading _dr signal
    lb a1, 4(t2)
2:
    andi a2, a1, 1      # bit 0 is _dr (Active high)
    beq zero, a2, 2b    # If set then data received

    # Fetch new byte
    lb a1, 0(t2)

    # a1 should = 'a' because the user typed 'a'
    li a2, 'a'
    bne a2, a1, Cmp_Err

    li t3, 3            # Turn blue on to indicate success.
    sb t3, 0(t1)

    ebreak

Cmp_Err:
    li t3, 6            # Turn red on
    sb t3, 0(t1)

    ebreak


# __++__++__++__++__++__++__++__++__++__++__++__++__++
# prog_data is defined in linker script
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
.word 0x002FAF08    # 0 : Calibrated for 50MHz at 8 cycles = 0.5s
.word 0x005F5E10    # 4 : 1sec
.word 0x00BEBC20    # 8 : 2sec
.word 0x55555555    # 12: Write data pattern
.word 0xaaaaaaaa    # 16: Write data pattern
LED_Map:   .word 0xF0001000     # LEDs base
UART_Map:  .word 0xF0000000     # 0004 reading control signals
