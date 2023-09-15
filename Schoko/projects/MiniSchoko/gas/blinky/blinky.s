# A very simple SDRAM memory test.
# 1 = LED off, 0 = LED on

.section .text
.align 2

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# Main
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.global _start
_start:
    la t0, prog_data
    lw a0, 0(t0)        # LED port address

    li t1, 7            # Mast to turn LEDs off (111)
    li t4, 6            # AND Mask 110 to turn on (3,5,6)

    sb t1, 0(a0)        # Turn LEDs off

1:
    sb t4, 0(a0)      # Turn on

    # ------- Delay-------
    lw t2, 4(t0)        # Reset counter
2:
    addi t2, t2, -1     # 3 cycles
    bne zero, t2, 2b    # 5 cycles

    sb t1, 0(a0)        # Turn off

    # ------- Delay-------
    lw t2, 4(t0)        # Reset counter
3:
    addi t2, t2, -1     # 3 cycles
    bne zero, t2, 3b    # 5 cycles

    j 1b

    ebreak              # Should not be reached

# __++__++__++__++__++__++__++__++__++__++__++__++__++
# prog_data is defined in linker script
# __++__++__++__++__++__++__++__++__++__++__++__++__++
.section .rodata
.balign 4
.word 0xF0001000    # red LED
.word 0x002FAF08    # Calibrated for 50MHz at 8 cycles = 0.5s

