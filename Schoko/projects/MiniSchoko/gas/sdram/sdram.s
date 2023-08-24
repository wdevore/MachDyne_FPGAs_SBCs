# A very simple SDRAM memory test.

# 0) Read address 0 for comparison
# 1) Write 0x55555555 to address 0
# 2) Read back and verify to prior value
# 3) Set green-on if new value equals written value else red-on
# 4) Wait 5 seconds
# 5) Turn blue on

# 1 = LED off, 0 = LED on

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
    la t2, SDRAM_Map
    lw t2, 0(t2)        # SDRAM mem map

    li t3, 7            # Mask to turn LEDs off (111)
    sb t3, 0(t1)        # Turn LEDs off

    # Read addr 0
    lw a0, 0(t2)        # Compare a0 against written value below

    # Write pattern data
    lw a1, 12(t0)       # load pattern
    sw a1, 0(t2)        # write to SDRAM

    # Readback pattern
    lw a2, 0(t2)        # read back

    # Compare prior value to read-back value
    bne a1, a2, Cmp_Err

    # They are equal set green on
                        #      BGR
    li t3, 5            # Mask 110 to turn on LEDs (6=R,5=G,3=B)
    sb t3, 0(t1)

    # ------- wait ------------
    lw t5, 8(t0)        # Reset counter
2:
    addi t5, t5, -1     # 3 cycles
    bne zero, t5, 2b    # 5 cycles

    # Write pattern data
    lw a1, 16(t0)       # load pattern
    sw a1, 0(t2)        # write to SDRAM

    # Readback pattern
    lw a2, 0(t2)        # read back

    # Compare prior value to read-back value
    bne a1, a2, Cmp_Err

    li t3, 3            # Turn blue on
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
LED_Map:   .word 0xF0001000    # LEDs base
SDRAM_Map: .word 0x40000000
