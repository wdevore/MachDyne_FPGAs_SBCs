typedef enum logic [3:0] {
    CSReset,            // 0000
    CSReset1,           // 0001
    CSResetComplete,    // 0010
    CSIdle,             // 0011
    CSSend,             // 0100
    CSSending,          // 0101
    CSStop              // 0110
} ControlState; 

