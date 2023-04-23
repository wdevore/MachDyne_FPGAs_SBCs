typedef enum logic [5:0] {
    UAReset0,                       // 0
    UAResetComplete,                // 1
    UADeviceIdle                    // 2
} UARTState; 

typedef enum logic [3:0] {
    UATxIdle,
    UATxTransmit,
    UATxTransmitComplete
} UARTTxState; 

typedef enum logic [3:0] {
    UARxIdle,
    UARxComplete,
    UAIRQComplete
} UARTRxState; 

typedef enum logic [2:0] {
    // A byte has been loaded and is ready to transmit
    CTL_TX_READY,
    // Device is busy sending byte
    CTL_TX_BUSY,
    // A byte is waiting in the Rx buffer
    CTL_RX_AVAL,
    // Enable/Disable interrupts
    CTL_IRQ_ENAB
} UARTControlBits; 

// ------------------------------------------------------------------
// Signals
// ------------------------------------------------------------------
// Signals are broken into 2 parts:
// |---4bits---|------4bits------|
// |  Signal   |      -----      |
//
// Currently the lower 4 bits aren't used. It could be used for counts.

typedef enum logic [3:0] {
    CRC_Signal = 4'b0000,    // Client-Request-Control
    RGC_Signal = 4'b0001,    // Request Granted for Client
    DAT_Signal = 4'b0011,    // Data Signal
    BOS_Signal = 4'b0100,    // Begining-of-Stream Signal
    EOS_Signal = 4'b0101,    // End-of-Stream Signal
    REJ_Signal = 4'b0110,    // Reject Control request
    ACK_Signal = 4'b0111,    // Acknowledge a data byte
    KEY_Signal = 4'b1000     // Key code
} UARTSignals; 

typedef enum logic {
    EnableBuffWrite,
    DisableBuffWrite
} UARTWriteState; 

