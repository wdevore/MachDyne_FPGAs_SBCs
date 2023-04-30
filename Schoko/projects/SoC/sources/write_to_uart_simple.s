// Write "O" 0x4f to uart port

// Offset   |  Description
// --------- ---------------------------------
//   0      |  Control 1 register
//   1      |  Rx buffer (byte, read only)
//   2      |  Tx buffer (byte, write only)

RVector: @0

Main: @
    lw x2, @Data(x0)        // Load IO base
    lbu x1, @Data+1(x0)     // Load first char
    sb x1, 0x2(x2)          // Write to UART Tx port.
    ebreak                  // Stop
// Note: the UARTTx component is independent and will continue
// to transmit 0x4F even after the ebreak instruction.

Data: @020
    d: 00400100         // Base address of UART IO
    d: 0000004F         // "O"
    @: Data             // Base address of data section


