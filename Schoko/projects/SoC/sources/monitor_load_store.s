// Simple load/store test
//

RVector: @0

Main: @
    lw x3, @Data(x0)        // Port A base
    lw x2, @Data+1(x0)      // UART base
    addi x11, x0, 0x3c0 //@Stack    // Initialize Stack

    addi x1, x0, 0x0a
    sw x1, 0x3c0(x0)          // offset must be BA
    lw x1, 0x3c0(x0)

    sb x1, 0x0(x3)

    ebreak

// ----------------------------------------------------------
// Data
// ----------------------------------------------------------
Data: @050
    d: 00400000    // Base address of Port A
    d: 00400100    // Base address of UART IO
// Visually the chars (bytes) read from right to left
String_OK: @
    d: 0A0D6B4F    // "Ok\r\n" + null
    d: 00000000
String_Bye: @
    d: 0D657942    // "Bye\r\n" + null
    d: 0000000A

// ----------------------------------------------------------
// Stack (grows towards @Data)
// ----------------------------------------------------------
Stack: @0A0

