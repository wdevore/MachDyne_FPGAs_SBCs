// The beginings of a Monitor (phase a)
// When the monitor starts it sends "Ok\r\n" and then waits
// for incomming bytes.
// It recognizes ascii characters "1" or "2". If "1" then send
// "One\r\n" else if "2" send "Two\r\n".
// The received char is also written to Port A LEDS

// x2 = Base address of UART
// x3 = Base address of Port A
// x1 = byte to send or UART control register
// x5 = subroutine return address
// x4 = byte pointer to string

RVector: @0

Main: @
    lw x3, @Data(x0)        // Port A base
    lw x2, @Data+1(x0)      // UART base

    // Boot by sending "Ok\r\n"
    addi x4, x0, @String_OK    // Set pointer to String
    lbu x1, 0x0(x4)         // Load x1 to what x4 is pointing at
    sb x1, 0x2(x2)          // Send 'O'. Write to UART Tx port.
    jal x5, @PollTxBusy     // Poll CTL_TX_BUSY bit

    addi x4, x4, 1          // Move to next char
    lbu x1, 0x0(x4)         
    sb x1, 0x2(x2)          // Send 'k'
    jal x5, @PollTxBusy

    addi x4, x4, 1
    lbu x1, 0x0(x4)         // Send '\r'
    sb x1, 0x2(x2)
    jal x5, @PollTxBusy

    addi x4, x4, 1
    lbu x1, 0x0(x4)         // Send '\n'
    sb x1, 0x2(x2)
    jal x5, @PollTxBusy

    ebreak

PollTxBusy: @
    lbu x1, 0x0(x2)         // Load UART Control reg
    andi x1, x1, 0x02       // Mask = 00000010
    bne x0, x1, @PollTxBusy
    jalr x0, 0x0(x5)         // return

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
    d: 0D656E4F    // "One\r"
    d: 6E77540A    // "\nTwo"
    d: 00000A0D    // "\r\n"


