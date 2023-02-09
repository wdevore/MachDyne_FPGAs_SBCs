typedef enum logic [5:0] {
    UAReset0,
    UAReset1,
    UAResetComplete,
    UAIdle,
    // -------------------------------------
    // Device
    // -------------------------------------
    // --- Send Granted signal to Client ---
    UADeviceCRCSignalEnter,
    UADeviceTriggerCRCSignal,
    UADeviceSendingCRCSignal,
    // -------------------------------------
    // Client
    // -------------------------------------
    // --- Client idle ---
    UAClientEnter,
    UAClientIdle,

    // --- Rx Sequence ---
    // -------------------------------------
    // System
    // -------------------------------------
    // --- System relinquish sequence ---
    UASystemEnter,
    UASystemIdle,
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
    // The party that has control sets this bit when no more data is
    // to be sent.
    CTL_EOT,
    // Enable (1) or Disable (0) interrupts
    CTL_IRQ_EN,
    // -------------------------------------
    // Client
    // -------------------------------------
    CTL_RX_BUFF_RDY,
    // If Set then Client has been granted the mutex and has control.
    CTL_CLI_GRNT,
    // Client can request via Client-Request-Control (CRC) bit. This bit is set
    // When the Client sends the CRC byte.
    CTL_CLI_CRC,
    // Client-Control-Granted (CCG) allows the Client to request control.
    // It is set if the client gains the mutex
    CTL_CLI_CCG
} UARTControl1Bits; 

typedef enum logic [2:0] {
    // -------------------------------------
    // System
    // -------------------------------------
    // System is ready for the device to send
    // a Tx buffer or for the System to ready the Rx buffer.
    // Once the buffer is read the bit is cleared automatically.
    CTL_TX_BUFF_RDY,
    // The System is requesting control via the mutex
    // System-Request-Control (SRC) bit = 1 if requesting control
    CTL_SYS_SRC,
    // If Set then System has the mutex and has control.
    CTL_SYS_GRNT,
    // If Set then System has been granted control
    // System-Control-Granted (SCG) bit
    CTL_SYS_SCG,
    // The System can relinquish control by setting 
    // System-Relinquish-Control (SEC) bit. Once it is set the Device
    // Will clear it as begins a relinquish sequence.
    CTL_SYS_SEC,
    // System-Data-Sent (SDS) bit
    CTL_SYS_SDS
} UARTControl2Bits; 

// ------------------------------------------------------------------
// Signals
// ------------------------------------------------------------------
// Signals are broken into 2 parts:
// |---3bits---|------5bits------|
// |  Signal   |    Data Count   |

typedef enum logic [7:0] {
    RGC_Signal = 8'b000_00000,
    CRC_Signal = 8'b001_00000,
    SEC_Signal = 8'b010_00000,
    KEY_Signal = 8'b100_00000
} UARTSignals; 

typedef enum logic [1:0] {
    Storage_Select,
    RGC_Signal_Select,
    CRC_Signal_Select,
    SEC_Signal_Select
} UARTSignalSelects; 
