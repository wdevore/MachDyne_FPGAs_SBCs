RVector: @0

Main: @
    addi x1, x0, @Data      // x1 = pointer to 0x4F
    lw x2, @Data+1(x0)      // Load IO base
    lbu x3, 0x0(x1)         // x3 = what x1 points to
    sb x3, 0x0(x2)          // Write to IO port.
    ebreak                  // Stop

Data: @030
    d: 0000004F         // data to load into x3
    d: 00400000         // Base address of Port A


