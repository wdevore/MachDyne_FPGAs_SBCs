// Test BNE instruction

RVector: @0

Main: @
    addi x1, x0, 0       // x1 = 0
    addi x2, x0, 1       // x2 = 1
    bne x1, x2, @Main
    ebreak                  // Stop


