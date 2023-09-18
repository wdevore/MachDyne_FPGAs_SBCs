.section .text, "ax", @progbits
.align 2

.include "macros.s"

# ---------------------------------------------
# @note Process_X_Command
# Run code at working address that was set prior.
# ---------------------------------------------
.global Process_X_Command
Process_X_Command:
    PrologRa
    
    # The first char in the key buffer is the command
    mv t1, tp
    lbu t1, 0(t1)
    li t0, 'x'
    bne t0, t1, PXC_NH          # Exit if not 'x' command

    la a0, str_running_msg
    jal PrintString

    # Preserve Monitor stack, Micro code will use its own stack
    # Note! We don't use (sp) because the micro program will
    # overwrite (sp) thus destroying the Monitor's restore ability.
    # So we use a memory location instead.
    la t0, stack_backup
    sw sp, 0(t0)

    jal ISR_Enable
    jal UART_IRQ_Enable

    jal micro_code              # Run the micro program

    # At this point the micro program exited without interruption.
    la t0, stack_backup
    lw sp, 0(t0)                # Restore (sp)

    jal ISR_Disable
    jal UART_IRQ_Disable

    # a0 has return code from micro program
    mv t0, a0                   # backup prior to printing
    la a0, str_return_msg
    jal PrintString
    mv a0, t0                   # Restore for conversion
    jal HexByteToString
    mv a0, s1
    jal PrintString
    li a0, ')'
    jal PrintCharCrLn

    li a0, 1                    # Indicate: handled

    j PXC_Exit

PXC_NH:
    li a0, 0                    # Not handled

# Technically this won't be reached
PXC_Exit:
    EpilogeRa
    ret
