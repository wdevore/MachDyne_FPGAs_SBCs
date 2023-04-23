// Write "Ok" "0x4f, 0x6f" to uart port
// Base IO = 0x00400000
// Base UART = IO + 1

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

    // Wait for byte to send by polling CTL_TX_BUSY bit
TxWait: @
    lbu x1, 0x0(x2)         // Load UART Control reg
    andi x1, x1, 2          // Mask = 00000010
    bne x0, x1, @TxWait

    lbu x1, @Data+2(x0)     // Load 2nd char
    sb x1, 0x2(x2)          // Write to UART Tx port.

//TxWait2: @
//    lbu x1, 0x0(x2)         // Load UART Control reg
//    andi x1, x1, 2          // Mask = 00000010
//    bne x0, x1, @TxWait2

    ebreak                  // Stop

Data: @020
    d: 00400001         // Base address of UART IO
    d: 0000004F         // "O"
    d: 0000006F         // "k"
    @: Data             // Base address of data section


