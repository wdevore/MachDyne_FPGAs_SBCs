// The beginings of a Monitor (phase a)
// When the monitor starts it sends "Ok\r\n" and then waits
// for incomming bytes.
//
// This stage also reads the Rx buffer and Received bit.
//
// It recognizes ascii characters "1" or "2". If "1" then send
// "One\r\n" else if "2" send "Two\r\n".
// The received char is also written to Port A LEDS

// x1 = byte to send or UART control register (aka scratch reg)
// x2 = Base address of UART
// x3 = Base address of Port A
// x4 = byte pointer to string
// x7 = Data to scan
// x8 = Scratch
// x9 = Scratch

RVector: @0

Main: @
    lw x3, @Data(x0)        // Port A base
    lw x2, @Data+1(x0)      // UART base
    addi x8, x0, 0x04       // Load scratch Rx-Byte-Available mask

    // Boot by sending "Ok"
    addi x4, x0, @String_OK    // Set pointer to String
    jal x5, @PrintString

    sb x0, 0x0(x3)          // Clear port A

    // Wait for an incomming byte
WaitForByte: @
    jal x6, @PollRxAvail
    lbu x1, 0x1(x2)         // Read Rx reg at offset 0x01
    sb x1, 0x0(x3)          // Display it on port A

    addi x7, x0, 0x60       // Set Exit ascii character "`"
    beq x1, x7, @Exit       // Is it the "`" char = "0x60"

    addi x7, x0, 0x31
    beq x1, x7, @ShowOne    // Is it the "1"

    addi x7, x0, 0x32
    beq x1, x7, @ShowTwo    // Is it the "2"

    jal x0, @WaitForByte

ShowOne: @
    addi x4, x0, @String_One
    jal x5, @PrintString
    jal x0, @WaitForByte

ShowTwo: @
    addi x4, x0, @String_Two
    jal x5, @PrintString
    jal x0, @WaitForByte

Exit: @
    addi x4, x0, @String_Bye
    jal x5, @PrintString
    ebreak

// ----------------------------------------------------------
// Print a Null terminated String
// x4 to points to String
// x5 is the return address
// ----------------------------------------------------------
PrintString: @
    lbu x1, 0x0(x4)         // Load x1 to what x4 is pointing at
    beq x1, x0, @PSExit     // Is x1 a Null char
    sb x1, 0x2(x2)          // Send
    jal x6, @PollTxBusy
    addi x4, x4, 1          // Next char
    jal x0, @PrintString
PSExit: @
    jalr x0, 0x0(x5)        // return

// ----------------------------------------------------------
// Wait for the Tx busy bit to Clear
// x6 is the return address
// ----------------------------------------------------------
PollTxBusy: @
    lbu x1, 0x0(x2)         // Load UART Control reg
    andi x1, x1, 0x02       // Mask = 00000010
    bne x0, x1, @PollTxBusy
    jalr x0, 0x0(x6)        // return

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
String_One: @
    d: 0D656E4F    // "One\r\n" + null
    d: 0000000A
String_Two: @
    d: 0D6F7754    // "Two\r\n" + null
    d: 0000000A
String_Bye: @
    d: 0D657942    // "Bye\r\n" + null
    d: 0000000A


