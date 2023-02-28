typedef enum logic [5:0] {
    SMReset0,               // 0
    SMReset1,               // 1
    SMResetComplete,        // 2
    SMIdle,                 // 3

    //`include "Client_Send_Keycode_Top_Enums.sv"
    // `include "System_Set_Bits_Top_Enums.sv"
    // `include "Client_Rejected_Request_Top_Enums.sv"
    `include "Client_Accepted_Request_Top_Enums.sv"

    SMStop              // N

} SimState; 
