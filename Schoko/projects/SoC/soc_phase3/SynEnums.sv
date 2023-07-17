typedef enum logic [4:0] {
    SoCReset,           
    SoCResetting,       
    SoCResetComplete,   
    SoCSystemResetComplete,
    SoCIdle
} SynState; 
