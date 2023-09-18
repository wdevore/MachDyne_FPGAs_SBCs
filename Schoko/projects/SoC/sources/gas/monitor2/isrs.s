# Note: You need to tell the assembler that you intend to use
# CSR instructions, otherwise you get this kind of error:
# monitor.s:1945: Error: unrecognized opcode `csrrw zero,mtvec,t0', extension `zicsr' required
.option arch, +zicsr

.set MSTATUS_IRQ_ENABLE, 8

.section .text, "ax", @progbits
.align 2

# --/\--/\--/\--/\--/\--/\--/\--/\--/\--/\--/\--/\--/\--
# Interrupt service routine (ISR)
# --/\--/\--/\--/\--/\--/\--/\--/\--/\--/\--/\--/\--/\--
# ---------------------------------------------
# @note ISR_Set_Trap
# Configure: mtvec (word)
# ---------------------------------------------
.global ISR_Set_Trap
ISR_Set_Trap:
    # Set trap vector
    la t0, ISR_Entry
    csrrw zero, mtvec, t0       # Write, ignore read
    
    ret

# ---------------------------------------------
# @note ISR_Enable
# Configure: mstatus (mie enable bit),
# mcause (bit set at onset of interrupt, cleared during mret).
# Basically mcause is a guard bit.
# ---------------------------------------------
.global ISR_Enable
ISR_Enable:
    # Enable machine mode interrupts (default is disabled)
    lw t0, MSTATUS_IRQ_ENABLE(gp)
    csrrs zero, mstatus, t0     # Set bit, ignore read
    
    ret

# ---------------------------------------------
# @note ISR_Disable
# Configure: mstatus (mie enable bit),
# ---------------------------------------------
.global ISR_Disable
ISR_Disable:
    # Disable machine mode interrupts (default to disabled)
    lw t0, MSTATUS_IRQ_ENABLE(gp)
    csrrc zero, mstatus, t0     # Clear bit, ignore read
    
    ret

# ---------------------------------------------
# @note ISR_Entry
# Is called once an interrupt is detected. The address
# of this trap routine is loaded into mtvec.
# This ISR services only Ctrl-C bytes received via UART.
# Note: The UART IRQ flag must be enabled.
# ---------------------------------------------
.global ISR_Entry
ISR_Entry:
    la sp, stack_backup         # Restore Monitor's stack
    lw sp, 0(sp)

    addi sp, sp, -8             # Prolog
    sw t0, 4(sp)
    sw t1, 8(sp)

    # We first disable interrupts globally to prevent reentrantency.
    jal ISR_Disable
    # And disable the UART's interrupt ability as well.
    jal UART_IRQ_Disable
    
    # Now store original mepc into memory. The Monitor will print
    # the address to the console.
    la t0, mepc_return_addr
    csrr t1, mepc               # Fetch current return address
    sw t1, 0(t0)                # Store in memory

    # Next we "intercept" mepc such that mret is "redirected" to
    # the Monitor's reentry routine instead of back to the micro program.
    la t0, ReEntry
    csrrw zero, mepc, t0        # Overwrite current return address

    lw t1, 8(sp)
    lw t0, 4(sp)
    addi sp, sp, 8              # Epilog

    mret                        # Exit trap. Set mcause to zero.

