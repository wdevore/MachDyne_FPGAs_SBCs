// A bare minimum
// Simply wait for a byte from the client and write it to port A

// x1 = byte to send or UART control register (aka scratch reg)
// x2 = Base address of UART
// x3 = Base address of Port A
// x4 = byte pointer to string
// x8 = Scratch

RVector: @0

Main: @
    lw x3, @Data(x0)        // Port A base
    lw x2, @Data+1(x0)      // UART base
    addi x8, x0, 0x04       // Load scratch Rx-Byte-Available mask
    addi x9, x0, 0x33

    sb x9, 0x0(x3)          // Write 0x33 to port A to indicate ready

    // Wait for an incomming byte
WaitForByte: @
    jal x6, @PollRxAvail
    lbu x1, 0x1(x2)         // Read Rx reg at offset 0x01
    sb x1, 0x0(x3)          // Write it on port A
    jal x0, @WaitForByte

Exit: @
    ebreak

// ----------------------------------------------------------
// Wait for the Rx byte available bit to Set when a byte
// has arrived.
// x6 is the return address
// ----------------------------------------------------------
PollRxAvail: @
    lbu x1, 0x0(x2)         // Read Control reg at offset 0x0
    and x1, x1, x8          // Mask = 00000100
    bne x8, x1, @PollRxAvail
    jalr x0, 0x0(x6)        // return

// ----------------------------------------------------------
// Data
// ----------------------------------------------------------
Data: @030
    d: 00400000    // Base address of Port A
    d: 00400100    // Base address of UART IO
// Visually the chars (bytes) read from right to left
String_OK: @
    d: 0A0D6B4F    // "Ok\r\n" + null
    d: 00000000    //


