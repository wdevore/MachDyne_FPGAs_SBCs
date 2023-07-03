// Simple test of stack
//

// x1 = byte to send or UART control register (aka scratch reg)
// x2 = Base address of UART
// x3 = Base address of Port A
// x4 = byte pointer to string
// x5 = return address of subroutines
// x6 = return address of sub-subroutines
// x7 = Data to scan
// x10 = Scratch
// x11 = Stack


RVector: @0

Main: @
    lw x3, @Data(x0)        // Port A base
    lw x2, @Data+1(x0)      // UART base
    addi x11, x0, @Stack    // Initialize Stack

    // Boot by sending "Ok"
    addi x4, x0, @String_OK     // Set pointer to String
    jal x5, @PrintString

    addi x1, x0, 0x0a

    // call subroutine
    jal x6, @ChangeX1

    // write to port a. should = 0x0a
    addi x10, x1, 0x00
    jal x5, @WritePortA

Exit: @
    addi x4, x0, @String_Bye
    jal x5, @PrintString
    ebreak

// ----------------------------------------------------------
// ----------------------------------------------------------
ChangeX1: @
    addi x11, x11, -4      // Move stack pointer
    sw x1, 0x04(x11)        // Push x1

    addi x1, x0, 0x0b
    
    lw x1, 0x04(x11)         // Pop x1
    addi x11, x11, 4        // Move stack pointer

    jalr x0, 0x0(x6)        // return

// ----------------------------------------------------------
// Expects x10 as byte to write to port
// x5 is the return address
// ----------------------------------------------------------
WritePortA: @
    sb x10, 0x0(x3)
    jalr x0, 0x0(x5)        // return

// ----------------------------------------------------------
// Print a Null terminated String
// Expects x4 to point to start of String
// x5 is the return address
// ----------------------------------------------------------
PrintString: @
    addi x11, x11, -4      // Move stack pointer
    sw x1, 0x4(x11)        // Push x1

PrintLoop: @
    lbu x1, 0x0(x4)         // Load x1 to what x4 is pointing at
    beq x1, x0, @PSExit     // Is x1 a Null char
    sb x1, 0x2(x2)          // Send
    jal x6, @PollTxBusy
    addi x4, x4, 1          // Next char
    jal x0, @PrintLoop
PSExit: @
    lw x1, 0x4(x11)        // Pop x1
    addi x11, x11, 4       // Move stack pointer

    jalr x0, 0x0(x5)        // return

// ----------------------------------------------------------
// Wait for the Tx busy bit to Clear
// x6 is the return address
// ----------------------------------------------------------
PollTxBusy: @
    addi x11, x11, -4      // Move stack pointer
    sw x1, 0x4(x11)        // Push x1

PollLoop: @
    lbu x1, 0x0(x2)         // Load UART Control reg
    andi x1, x1, 0x02       // Mask = 00000010
    bne x0, x1, @PollLoop

    lw x1, 0x4(x11)         // Pop x1
    addi x11, x11, 4        // Move stack pointer

    jalr x0, 0x0(x6)        // return

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
Stack: @0F0

