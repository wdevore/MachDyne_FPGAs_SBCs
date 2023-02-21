typedef enum logic [5:0] {
    SMReset0,               // 0
    SMReset1,               // 1
    SMResetComplete,        // 2
    SMIdle,                 // 3

    SMSendKeySetup,         // 4
    SMSendKeyTrigger,       // 5
    SMSendKeyUnTrigger,     // 6
    SMSendKeySending,       // 7

    SMSendKeyCodeSetup,     // 8
    SMSendKeyCodeTrigger,   // 9
    SMSendKeyCodeUnTrigger, // 10
    SMSendKeyCodeSending,   // 11

    SMReadControl1,         // 12
    SMReadControl1_A,       // 13
    SMReadControl1_B,       // 14

    SMReadKeycode_A,        // 15
    SMReadKeycode_B,        // 16
    SMReadKeycode_C,        // 17

    SMStop              // N

} SimState; 
