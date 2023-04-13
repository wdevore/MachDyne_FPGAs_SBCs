// Store 0x99 at 0x00400000 which is the first IO mapped register.
// 0x99 = 1001_1001

RVector: @0
    @: Main

Main: @
    lbu x1, @Data(x0)       // Load x1 = 0x99
    lw x2, @Data+1(x0)      // Load IO base
    sb x1, 0x0(x2)          // Write to IO port. Causes io wr to assert
    lw x2, @Data+2(x0)      // Load mem location
    sb x1, 0x0(x2)          // Write 0x99 to Memory
    ebreak                  // Stop

Data: @00A
    d: 00000099         // data to load
    d: 00400000         // Base address of IO
    d: 0000000F         // Memory address
    @: Data             // Base address of data section


