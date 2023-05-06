typedef enum logic [4:0] {
    SoCReset,           
    SoCResetting,       
    SoCResetComplete,   
    SoCDelayCnt,        
    SoCSystemResetComplete,
    SoCIdle
} SynState; 
