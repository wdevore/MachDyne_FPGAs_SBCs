typedef enum logic [4:0] {
    SoCReset,           // 000
    SoCResetting,       // 001
    SoCDelayReset,      // 010
    SoCResetComplete,   // 011
    SoCDelayCnt,        // 100
    SoCSystemResetComplete,
    SoCIdle             // 101
} SynState; 
