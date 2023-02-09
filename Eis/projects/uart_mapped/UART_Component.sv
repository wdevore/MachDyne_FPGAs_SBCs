`default_nettype none
`ifdef SIMULATE
`timescale 10ns/1ns
`endif

// ------------------------------------------------------
// Version 3
// ------------------------------------------------------
// UART Component
// It is mapped into memory. You only interact via memory mapped addresses.

// Control register is address 0
// Input/Output Data is address 1

module UART_Component
(
    input  logic clock,             // System clock
    input  logic reset,             // Reset
    input  logic cs,                // Chip select (active low)
    input  logic rd,                // Active Low
    input  logic wr,                // Active Low
    input  logic rx_in,             // Incoming bits
    output logic tx_out,            // Outgoing bits
    input  logic [1:0] addr,        // Address: controls, buffer, key-code
    output logic [7:0] out_data,    // Ouput data port
    /* verilator lint_off UNUSED */
    input  logic [7:0] in_data,     // Input data port (routed to DeMux)
    /* verilator lint_on UNUSED */
    output logic irq,               // Active high
    output logic [2:0] irq_id       // ID. 8 possible ids.
);

localparam Component_ID = 3'b000;

localparam DATA_WIDTH = 8;
localparam ZERO = 0;

logic rd_active;
assign rd_active = ~cs & ~rd;
logic wr_active;
assign wr_active = ~cs & ~wr;

logic [DATA_WIDTH-1:0] key_code;  // Address 0x00
logic keycode_rd;
assign keycode_rd = ~(rd_active & (addr[1:0] == 2'b00));
logic [DATA_WIDTH-1:0] keycode_out;


// ------------------------------------------------------------------
// Control registers N-bits
// ------------------------------------------------------------------
localparam CONTROL_SIZE = 8;
logic [CONTROL_SIZE-1:0] control1;  // Address 0x01
logic [CONTROL_SIZE-1:0] control2;  // Address 0x02

logic control1_rd;
assign control1_rd = ~(rd_active & (addr[1:0] == 2'b01));
logic control1_wr;
assign control1_wr = ~(wr_active & (addr[1:0] == 2'b01));
logic control2_rd;
assign control2_rd = ~(rd_active & (addr[1:0] == 2'b10));
logic control2_wr;
assign control2_wr = ~(wr_active & (addr[1:0] == 2'b10));

// ------------------------------------------------------------------------
// Tx/Rx buffer at address 0x03
// ------------------------------------------------------------------------
localparam WORDS = 5; // 32 bytes = 2^5
// The Device or System drive these signals.
// The Device reads in order to send
// The System reads in to access recieved data.
logic buff_rd;       // active (low)
assign buff_rd = ~(rd_active & (addr[1:0] == 2'b11) & control1[CTL_CLI_GRNT]);
logic buff_wr;       // active (low)
assign buff_wr = ~(wr_active & (addr[1:0] == 2'b11) & control1[CTL_CLI_GRNT]);

logic [DATA_WIDTH-1:0] storage_out;
logic [DATA_WIDTH-1:0] buff_in;

// Address counter.
logic [WORDS-1:0] buff_address;
logic [DATA_WIDTH-1:0] storage_in;
logic buff_select;

Mux2 #(
    .DATA_WIDTH(DATA_WIDTH)
) buff_mux(
    .select_i(buff_select),
    .data0_i(rx_byte),
    .data1_i(storage_in),
    .data_o(buff_in)
);

Memory #(
    .WORDS(WORDS),
    .DATA_WIDTH(DATA_WIDTH)
) data_buff(
    .clk_i(clock),
    .data_i(buff_in),
    .addr_i(buff_address),
    .wr_i(buff_wr),
    .rd_i(buff_rd),
    .data_o(storage_out)
);

// ------------------------------------------------------------------------
// Data Ports
// ------------------------------------------------------------------------
// There are 3 destinations specified by the lower 2 bits
logic [1:0] in_select;
assign in_select = addr[1:0]; 

logic [DATA_WIDTH-1:0] control1_in;
logic [DATA_WIDTH-1:0] control2_in;
logic [DATA_WIDTH-1:0] control1_out;
logic [DATA_WIDTH-1:0] control2_out;

// Incoming interface data (3 destinations)
DeMux4 #(
    .DATA_WIDTH(DATA_WIDTH)
) in_demux (
    .select(in_select),
    .data_i(in_data),
    .data0_o(ZERO),
    .data1_o(control1_in),
    .data2_o(control2_in),
    .data3_o(storage_in)
);

// Outgoing interface data (4 sources)
logic [1:0] out_select;
assign out_select = addr[1:0]; 

Mux4 #(
    .DATA_WIDTH(DATA_WIDTH)
) out_mux(
    .select_i(out_select),
    .data0_i(keycode_out),
    .data1_i(control1_out),
    .data2_i(control2_out),
    .data3_i(storage_out),
    .data_o(out_data)
);

// ------------------------------------------------------------------------
// IO channels
// ------------------------------------------------------------------------
logic [DATA_WIDTH-1:0] src_to_tx;  // From control bits
logic [1:0] tx_select;

Mux4 #(
    .DATA_WIDTH(DATA_WIDTH)
) tx_mux(
    .select_i(tx_select),
    .data0_i(storage_out),
    .data1_i(RGC_Signal),
    .data2_i(CRC_Signal),
    .data3_i(SEC_Signal),
    .data_o(src_to_tx)
);

// UART Transmitter reads from the buffer
logic tx_en;
/* verilator lint_off UNUSED */
logic tx_complete;
/* verilator lint_on UNUSED */

UARTTx uart_tx (
    .sourceClk(clock),
    .reset(reset),
    .tx_en(tx_en),
    .tx_byte(src_to_tx),
    .tx_out(tx_out),
    .tx_complete(tx_complete)
);

// UART Receiver writes to the buffer
logic [DATA_WIDTH-1:0] rx_byte;
/* verilator lint_off UNUSED */
logic rx_complete;
/* verilator lint_on UNUSED */

UARTRx uart_rx (
    .sourceClk(clock),
    .reset(reset),
    .rx_in(rx_in),
    .rx_byte(rx_byte),
    .rx_complete(rx_complete)
);

// ------------------------------------------------------------------------
// State machine controlling device
// ------------------------------------------------------------------------
UARTState state = UAReset0;
UARTState next_state;

logic neither_have_control;  // Neither granted control
assign neither_have_control = control1[CTL_SYS_GRNT] == 0 || control1[CTL_CLI_GRNT] == 0;

always_ff @(posedge clock) begin
    // --------------------------------
    // Control registers
    // --------------------------------
    if (~cs) begin
        if (control1_wr)
            control1 <= control1_in;
        else if (control2_wr)
            control2 <= control2_in;
        else if (control1_rd)
            control1_out <= control1;
        else if (control2_rd)
            control2_out <= control2;
        else if (keycode_rd)
            keycode_out <= key_code;
    end

    case (state)
        // --------------------------------
        // Reset
        // --------------------------------
        UAReset0: begin
            control1 <= 0;
            control2 <= 0;
            buff_address <= 0;
            buff_select <= 0;
            tx_select <= 0;
            tx_en <= 1;

            irq <= 1;       // Non-active
            irq_id <= Component_ID;    // UART component id
            
            key_code <= 0;
        end

        UAResetComplete: begin
            next_state <= UAIdle;
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Main process
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UAIdle: begin
            // Check which party wants control.
            // The Client has priority.
            if (control1[CTL_CLI_CRC]) begin
                // Both parties may already have it and if so skip.
                if (neither_have_control) begin
                    // Neither have control, so grant control to Client.
                    control1[CTL_CLI_GRNT] <= 1;
                    // Clear request bit too
                    control1[CTL_CLI_CRC] <= 0;
                    // Send Request-Granted-Control (RGC) byte to Client
                    next_state <= UADeviceCRCSignalEnter;
                end
            end
            else if (control2[CTL_SYS_SRC]) begin // Is System is requesting control.
                // Both parties may already have it and if so skip.
                if (neither_have_control) begin
                    // Neither have control, so grant control to System.
                    // The System is either polling this bit
                    // TODO or will receive an interrupt if it's enabled.
                    // Either way it remains Set until the party finishes.
                    control2[CTL_SYS_GRNT] <= 1;

                    // Clear request bit too
                    control1[CTL_SYS_SRC] <= 0;

                    // Transition to System idle.
                    next_state <= UASystemEnter;
                end
            end
            // Check if the System wants to transmit the buffer.
            else if (control2[CTL_SYS_GRNT] && control2[CTL_TX_BUFF_RDY]) begin
                next_state <= UASystemTransmitEnter;
            end
            
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Device sequences
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####

        // -------------------------------------
        // Send RGC signal to Client
        // -------------------------------------
        // Write RGC byte directly to UART sub-module because we
        // are sending only 1 byte.
        UADeviceCRCSignalEnter: begin
            tx_select <= RGC_Signal_Select;        // Select the signal value
            next_state <= UADeviceTriggerCRCSignal;
        end

        UADeviceTriggerCRCSignal: begin
            tx_en <= 0; // Trigger transmission
            next_state <= UADeviceSendingCRCSignal;
        end

        UADeviceSendingCRCSignal: begin
            tx_en <= 1; // Disable trigger

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                tx_select <= Storage_Select;  // Switch back to buffer
                // The Client is now aware it has control.
                // Move to Client sequences
                next_state <= UAClientEnter;
            end
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // System sequences
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####


        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Client sequences
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####

        // The Client will either send a Key-code via 2 bytes or a stream.
        // Once the Client begins streaming it can't send a Key-code until
        // the stream ends.
        // The Device handles Key-codes directly.
        UAClientEnter: begin
            // Wait for a Signal byte of some sort to arrive.
            if (rx_complete) begin
                if (rx_byte == KEY_Signal) begin
                    // Wait for the Key-code and store it.
                end
            end

            // next_state <= ???;
        end

        // -------------------------------------
        // Wait for bytes to arrive from Client
        // -------------------------------------

        // -------------------------------------
        // Unknown State
        // -------------------------------------
        default: begin
            `ifdef SIMULATE
                $display("********* UNKNOWN STATE ***********");
            `endif
        end

    endcase

    if (~reset)
        state <= UAReset0;
    else
        state <= next_state;
end

endmodule

