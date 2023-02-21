typedef enum logic [5:0] {
    UAReset0,                       // 0
    UAResetComplete,                // 1

    // -------------------------------------
    // Device
    // -------------------------------------
    UADeviceIdle,                   // 2
    UADeviceTransmit,               // 3
    UADeviceTransmitSending,        // 4
    UADeviceCheckBuffer,            // 5

    // --- Send Granted signal to Client ---
    UADeviceRGCSignalEnter,         // 6
    UADeviceTriggerRGCSignal,       // 7
    UADeviceSendingRGCSignal,       // 8

    // -------------------------------------
    // Client
    // -------------------------------------
    // --- Client main process ---
    UAClientIdle,                   // 9
    UAClientCheckBuffer,            // 10

    // --- Client Key-code ---
    UAClientKeyCodeAcknowledge,     // 11
    UAClientKeyCodeStore,           // 12
    UAClientKeyCodeRxAck,           // 13
    UAClientKeyCodeExit,            // 14

    // -------------------------------------
    // System
    // -------------------------------------
    // --- System relinquish sequence ---
    UASystemIdle,                   // 15
    UASystemCheckByte,              // 16
    UASystemREJSignalEnter,         // 17
    UASystemSendingREJSignal        // 18
} UARTState; 

typedef enum logic [2:0] {
    // Enable (1) or Disable (0) interrupts
    CTL_IRQ_EN,
    // -------------------------------------
    // Client
    // -------------------------------------
    // If Set then Client has been granted the mutex and has control.
    CTL_CLI_GRNT,
    // Indicates Key-code is waiting
    CTL_KEY_RDY,
    // Client Stream signals
    CTL_STR_BOS,
    CTL_STR_DAT,
    CTL_STR_BYT,
    CTL_STR_EOS
} UARTControl1Bits; 

typedef enum logic [2:0] {
    // -------------------------------------
    // System
    // -------------------------------------
    // The System is requesting control via the mutex
    // System-Request-Control (SRC) bit = 1 if requesting control
    CTL_SYS_SRC,
    // If Set then System has the mutex and has control.
    CTL_SYS_GRNT,
    // The Device is transmitting byte
    CTL_DEV_TRX
} UARTControl2Bits; 

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
    BOS_Signal = 4'b0100,    // Beginging-of-Stream Signal
    EOS_Signal = 4'b0101,    // End-of-Stream Signal
    REJ_Signal = 4'b0110,    // Reject Control request
    KEY_Signal = 4'b0111     // Key code
} UARTSignals; 

typedef enum logic [1:0] {
    TxByte_Select,
    RGC_Signal_Select,
    REJ_Signal_Select
} UARTTxMuxSelects; 

typedef enum logic {
    EnableBuffWrite,
    DisableBuffWrite
} UARTWriteState; 

