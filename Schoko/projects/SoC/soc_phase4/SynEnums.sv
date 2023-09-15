typedef enum logic [4:0] {
    SoCReset,           
    SoCResetSDRAM,
    SoCResetting,       
    SoCResetComplete,   
    SoCSystemResetComplete,
    SoCIdle
} SynState; 
