.section .text, "ax", @progbits
.align 2

.include "macros.s"
.include "sets.s"

# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
# Unidirectional signals
# **__**__**__**__**__**__**__**__**__**__**__**__**__**__
.set SIGNAL_SOT,        0x01        # Start of transmission
.set SIGNAL_DAT,        0x02        # Byte of data
.set SIGNAL_EOT,        0x03        # End of Transmission
.set SIGNAL_ADR,        0x04        # Address value

# ---------------------------------------------
# @note Process_U_Command
# Causes the monitor to wait for bytes from UART.
# The bytes are stored starting at working address which is
# typically at 0x00001000.
# A simple unidirectional protocol is used:
# SoT data Signal data Signal data Signal data...EoT
# 
# Need to add Timer component as a "watch dog".
# 
# t6 = ADR tracking flag. It is set on the first appearence of
# the ADR signal.
# s0 is set/cleared on each incoming byte.
# 
# Output:
#   a0 = 0 (not handled), 1 (handled), 2 (error)
# ---------------------------------------------
.global Process_U_Command
Process_U_Command:
    PrologRa

    # The first char in the key buffer is the command
    mv t1, tp
    lbu t1, 0(t1)
    li t0, 'u'
    bne t0, t1, PUC_NH              # Exit if not 'u' command

    la a0, str_u_load_Wait
    jal PrintString

    # Begin waiting for a signal byte
    jal UART_PollRxAvail            # Blocks until byte arrives
    lbu t0, UART_RX_REG_ADDR(s3)    # Access byte just received

    li t1, SIGNAL_SOT               # Check SoT
    bne t0, t1, PUC_LError          # Terminate

    la a0, str_u_loading
    jal PrintString

    mv t2, s2             # Point to working address variable
    lw t2, 0(t2)                    # Fetch value from variable = working address

    # # !!!!!!!!!!!!!!!!!!!!!!!!!!!
    # li a0, '!'
    # jal PrintCharCrLn
    # # !!!!!!!!!!!!!!!!!!!!!!!!!!!

# Loops while != EoT
PUC_Load_Loop:
    # Each byte that arrives is shifted into byte position within a Word
    mv t3, zero                     # Reset byte accumulator
    mv t4, zero                     # Reset shift amount
    li t5, 4                        # A word is four bytes

PUC_Accum_Word:
    # Wait for DAT, EOT or ADR
    jal UART_PollRxAvail            # Block until a byte arrives
    lbu t0, UART_RX_REG_ADDR(s3)    # Fetch data byte

    li t1, SIGNAL_EOT
    beq t0, t1, PUC_End             # Finish if EoT

    li t1, SIGNAL_DAT
    beq t0, t1, PUC_Adr_Skip        # Skip flag check

    bne zero, t6, PUC_Adr_Skip      # If flag set then skip
    li t1, SIGNAL_ADR
    sub t1, t1, t0                  # (SIGNAL_ADR - incoming_signal)
    seqz t6, t1                     # Set flag

    j PUC_Load_Loop                 # Now Restart loop for Data bytes

PUC_Adr_Skip:
    jal UART_PollRxAvail                 # Wait for Byte
    lbu t0, UART_RX_REG_ADDR(s3)    # Fetch byte

    sll t0, t0, t4                  # Shift byte into position
    or t3, t3, t0                   # Merge into accumulator

    addi t4, t4, 8                  # Inc shift amount by 8 bits
    addi t5, t5, -1                 # Dec byte counter
    bne zero, t5, PUC_Accum_Word

    beq zero, t6, PUC_Store         # Storing or Updating?

    # Else: update working addr variable
    mv t2, s2                       # Point to working address variable
    slli t3, t3, 2                  # Convert Addr from Word to Byte addressing
    sw t3, 0(t2)                    # Update address variable
    mv t2, t3                       # Use new working address
    mv t6, zero                     # Reset ADR tracking flag

    j PUC_Load_Loop

PUC_Store:  # Store accumulator into memory
    sw t3, 0(t2)                    # Store it

    addi t2, t2, 4                  # Move to next destination Word location
    j PUC_Load_Loop

# PUC_Loop:
    j PUC_Load_Loop

PUC_End:
    li a0, 1                    # Handled
    j PUC_LD_Complete

PUC_Data_Error:
    la a0, str_u_data_error
    jal PrintString
    li a0, 2
    j PUC_LD_Complete

PUC_LError:
    la a0, str_u_load_error
    jal PrintString
    li a0, 2
    j PUC_LD_Complete

PUC_NH:
    li a0, 0                    # Not handled
    j PUC_Exit

PUC_LD_Complete:
    la a0, str_u_load_cmplt
    jal PrintString

PUC_Exit:
    EpilogeRa

    ret
