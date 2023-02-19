typedef enum logic [5:0] {
    UAReset0,
    UAReset1,
    UAResetComplete,

    // -------------------------------------
    // Device
    // -------------------------------------
    UADeviceIdle,
    UADeviceTransmit,
    UADeviceTransmitSending,
    UADeviceCheckBuffer,

    // --- Send Granted signal to Client ---
    UADeviceRGCSignalEnter,
    UADeviceTriggerRGCSignal,
    UADeviceSendingRGCSignal,
    UADeviceAcknowledge,
    
    UADeviceTriggerACKSignal,
    UADeviceSendingACKSignal,

    // -------------------------------------
    // Client
    // -------------------------------------
    // --- Client main process ---
    UAClientIdle,
    UAClientCheckBuffer,

    // --- Client Key-code ---
    UAClientKeyCodeAcknowledge,
    UAClientKeyCodeStore,
    UAClientKeyCodeExit,

    // --- Client stream ---
    UAClientStreamStart,
    UAClientStreamReceive,
    UAClientDataStore,
    UAClientDataNext,

    // --- Client DAT/Byte pair stream ---
    UAClientTriggerBytePair,

    // -------------------------------------
    // System
    // -------------------------------------
    // --- System relinquish sequence ---
    UASystemEnter,
    UASystemIdle,
    UASystemCheckACK,
    UASystemRelinquish,
    UASystemSendSECSignal,
    UASystemSendingSECSignal,

    // -- Tx Sequence ---
    UASystemTransmitEnter,
    UASystemTransmitRead,
    UASystemTransmitEnable,
    UASystemTransmitSending,

    // --- Read Rx buffer ---
    UASystemReadEnter,
    UASystemRead
} UARTState; 

typedef enum logic [2:0] {
    // Enable (1) or Disable (0) interrupts
    CTL_IRQ_EN,
    // -------------------------------------
    // Client
    // -------------------------------------
    // If Set then Client has been granted the mutex and has control.
    CTL_CLI_GRNT,
    // Client can request via Client-Request-Control (CRC) bit. This bit is set
    // when the Client has sent the CRC byte.
    CTL_CLI_CRC,
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
    CTL_SYS_ARE,    // Signal System to send an ACK
    CTL_SYS_TRX     // DEPRECATED System sets this bit when ready to Transmit
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
    RFC_Signal = 4'b0010,    // Device is asking Client if it want's control (optional)
    DAT_Signal = 4'b0011,    // Data Signal
    BOS_Signal = 4'b0100,    // Beginging-of-Stream Signal
    EOS_Signal = 4'b0101,    // End-of-Stream Signal
    SHC_Signal = 4'b0110,    // Device is telling Client the System-has-Control
    KEY_Signal = 4'b0111,    // Key code
    ACK_Signal = 4'b1000     // Acknowledge
} UARTSignals; 

typedef enum logic [2:0] {
    Storage_Out_Select,
    RGC_Signal_Select,
    CRC_Signal_Select,
    SEC_Signal_Select,
    ACK_Signal_Select
} UARTSignalSelects; 

typedef enum logic {
    System_Select,
    Device_Select
} UARTWrSelects; 

typedef enum logic {
    TxByte_Select,
    RGC_Signal_Select
} UARTTxMuxSelects; 

typedef enum logic {
    EnableBuffWrite,
    DisableBuffWrite
} UARTWriteState; 

