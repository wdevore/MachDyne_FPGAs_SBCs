// The beginings of a Monitor (phase a)
// This is a very basic test.

// x2 = Base address of UART
// x3 = Base address of Port A
// x1 = byte to send or UART control register
// x4 = byte pointer to string

RVector: @0

Main: @
    lw x3, @Data(x0)        // Port A base
    lw x2, @Data+1(x0)      // UART base

    // Boot by sending "Ok\r\n"
    addi x4, x0, @String_OK    // Set pointer to String
    lbu x1, 0x0(x4)         // Load x1 to what x4 is pointing at
    sb x1, 0x0(x3)          // Store to port A
    sb x1, 0x2(x2)          // Send 'O'. Write to UART Tx port.

TxWait: @
    lbu x1, 0x0(x2)         // Load UART Control reg
    andi x1, x1, 0x02          // Mask = 00000010
    bne x0, x1, @TxWait

    ebreak

// Note Memory is little endian.
// The least significant byte of the data is placed at the byte with the lowest address.
// Example:
//
//        M     L
//        S     S
//        B     B
//    d: 0A0D6B4F
// 4F is the LSB and 0A is the MSB. This means that at address 0x38 is "4F" and address
// 0x3C is "0A"
Data: @030
    d: 00400000    // Base address of Port A
    d: 00400100    // Base address of UART IO
String_OK: @
    d: 0A0D6B4F    // "Ok\r\n" Note: 


