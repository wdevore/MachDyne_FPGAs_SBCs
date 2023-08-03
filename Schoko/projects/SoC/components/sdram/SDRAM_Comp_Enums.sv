typedef enum logic [4:0] {
    RESET,
    ASSERT_CKE,
    INIT_SEQ_PRE_CHARGE_ALL,
    INIT_SEQ_AUTO_REFRESH0,
    INIT_SEQ_AUTO_REFRESH1,
    INIT_SEQ_LOAD_MODE,
    IDLE,
    COL_READ,
    COL_READL,
    COL_READH,
    COL_WRITEL,
    COL_WRITEH,
    AUTO_REFRESH,
    PRE_CHARGE_ALL,
    WAIT_STATE,
    RESET_WAIT,
    ASSERT_CKE_WAIT,
    INIT_SEQ_PRE_CHARGE_ALL_WAIT,
    INIT_SEQ_AUTO_REFRESH0_WAIT,
    INIT_SEQ_AUTO_REFRESH1_WAIT,
    INIT_SEQ_LOAD_MODE_WAIT,
    AUTO_REFRESH_WAIT,
    READY_WAIT,
    COL_READ_WAIT,
    COL_READH_WAIT,
    COL_WRITEH_WAIT
} SDRAMState;

// ISSI-IS425 datasheet page 16
// (CS, RAS, CAS, WE)
typedef enum logic [3:0] {
    CMD_MRS   = 4'b0000,    // mode register set
    CMD_ACT   = 4'b0011,    // bank active
    CMD_READ  = 4'b0101,    // to have read variant with autoprecharge set A10=H
    CMD_WRITE = 4'b0100,    // A10=H to have autoprecharge
    CMD_BST   = 4'b0110,    // Unused
    CMD_PRE   = 4'b0010,    // precharge selected bank, A10=H both banks
    CMD_REF   = 4'b0001,    // auto refresh (cke=H), selfrefresh assign cke=L
    CMD_NOP   = 4'b0111,
    CMD_DSEL  = 4'b1xxx     // Unused
} SDRAMCommands;

