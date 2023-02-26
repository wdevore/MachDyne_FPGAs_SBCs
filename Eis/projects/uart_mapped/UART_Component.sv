`default_nettype none
`ifdef SIMULATE
`timescale 10ns/1ns
`endif

// ------------------------------------------------------
// Version 5
// ------------------------------------------------------
// UART Component
// It is mapped into memory. You only interact via memory mapped addresses.

module UART_Component
(
    input  logic clock,             // System clock
    input  logic reset,             // Reset
    input  logic cs,                // Chip select (active low)
    /* verilator lint_off UNUSED */
    input  logic rd,                // Active Low
    /* verilator lint_on UNUSED */
    input  logic wr,                // Active Low
    input  logic rx_in,             // Incoming bits
    output logic tx_out,            // Outgoing bits
    input  logic [2:0] addr,        // Address: controls, buffer, key-code
    output logic [7:0] out_data,    // Ouput data port
    input  logic [7:0] in_data,     // Input data port (routed to DeMux)
    output logic irq,               // Active high
    output logic [2:0] irq_id       // ID. 8 possible ids.
);

localparam Component_ID = 3'b000;

localparam DATA_WIDTH = 8;
localparam ZERO = 0;

// ------------------------------------------------------------------
// Internal signals
// ------------------------------------------------------------------
logic wr_active;        // Active low
assign wr_active = cs | wr;

// ------------------------------------------------------------------------
// Key codes
// ------------------------------------------------------------------------
logic [DATA_WIDTH-1:0] key_code;  // Address 0x00

// ------------------------------------------------------------------
// Control registers N-bits
// ------------------------------------------------------------------
localparam CONTROL_SIZE = 8;
logic [CONTROL_SIZE-1:0] control1;  // Address 0x01
logic [CONTROL_SIZE-1:0] control2;  // Address 0x02

logic control1_wr;  // Active low
assign control1_wr = (wr_active | ~(addr[2:0] == 3'b001));
logic control2_wr;
assign control2_wr = (wr_active | ~(addr[2:0] == 3'b010));

// ------------------------------------------------------------------------
// Tx/Rx buffer at address 0x03/0x04
// ------------------------------------------------------------------------
logic [CONTROL_SIZE-1:0] rx_buffer;  // Address 0x03
logic [CONTROL_SIZE-1:0] tx_buffer;  // Address 0x04

logic tx_buff_wr;       // Active (low)
assign tx_buff_wr = (wr_active | ~(addr[2:0] == 3'b100));

// ------------------------------------------------------------------------
// Data Ports
// ------------------------------------------------------------------------
// There are 3 destinations but they are split up.
logic [1:0] in_select;
assign in_select = addr[2:0] == 3'b100 ? 2'b11 : addr[1:0]; 

logic [DATA_WIDTH-1:0] byte_in;
logic [DATA_WIDTH-1:0] control1_in;
logic [DATA_WIDTH-1:0] control2_in;

// Incoming interface data (3 destinations)
DeMux4 #(
    .DATA_WIDTH(DATA_WIDTH)
) in_demux (
    .select(in_select),
    .data_i(in_data),
    .data0_o(ZERO),
    .data1_o(control1_in),
    .data2_o(control2_in),
    .data3_o(byte_in)
);

// Outgoing interface data (4 sources)
logic [1:0] out_select;
assign out_select = addr[1:0]; 

Mux4 #(
    .DATA_WIDTH(DATA_WIDTH)
) out_mux(
    .select_i(out_select),
    .data0_i(key_code),
    .data1_i(control1),
    .data2_i(control2),
    .data3_i(rx_buffer),
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
    .data0_i(tx_buffer),
    .data1_i({RGC_Signal, 4'b0000}),
    .data2_i({REJ_Signal, 4'b0000}),
    .data3_i(ZERO),
    .data_o(src_to_tx)
);

// UART Transmitter reads from the buffer
logic tx_en;
logic tx_complete;

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
logic rx_complete;
logic rx_start;
logic rx_ack;       // Active high

UARTRx uart_rx (
    .sourceClk(clock),
    .reset(reset),
    .rx_in(rx_in),      // bits
    .rx_ack(rx_ack),
    .rx_byte(rx_byte),
    .rx_start(rx_start),
    .rx_complete(rx_complete)
);

// ------------------------------------------------------------------------
// State machine controlling device
// ------------------------------------------------------------------------
UARTState state = UAReset0;
UARTState next_state;

// Upper 4 bits indicate signal type
logic [3:0] signal;
assign signal = rx_buffer[7:4];

logic neither_have_control;  // Neither granted control
assign neither_have_control = control1[CTL_SYS_GRNT] == 0 || control1[CTL_CLI_GRNT] == 0;

always_ff @(posedge clock) begin
    // --------------------------------
    // IO interface accessing: Control registers and Buffers
    // --------------------------------
    if (~control1_wr)
        control1 <= control1_in;
    else if (~control2_wr)
        control2 <= control2_in;
    // The System can write to the buffer if it is sending an ACK
    // or if it has control and is sending a stream.
    else if ((byte_in[7:4] == ACK_Signal) | control2[CTL_SYS_GRNT]) begin
        // Anytime a byte is written to the Tx buffer
        // the device immediately sends it.
        if (~tx_buff_wr) begin
            tx_buffer <= byte_in;
            control2[CTL_DEV_TRX] <= 1;     // Siganl that a Trx should begin
        end
    end

    case (state)
        // --------------------------------
        // Reset
        // --------------------------------
        UAReset0: begin
            // $display("UAReset0");

            control1 <= 0;
            control2 <= 0;
            key_code <= 0;
            rx_buffer <= 0;

            tx_en <= 1;
            rx_ack <= 0;
            
            irq <= 0;       // Non-active
            irq_id <= Component_ID;    // UART component id
        end

        UAResetComplete: begin
            // $display("UAResetComplete");
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Main process
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UADeviceIdle: begin
            // While the Device is idling either party can request control.
            // The System will request via a control bit.
            // The Client will request via an Rx byte.
            // The Client has priority thus it is checked first.
            // We only return to DeviceIdle when a party loses control via EOS.

            if (rx_complete) begin
                // Capture byte
                rx_buffer <= rx_byte;

                // We can acknowlegde immediately because we are not doing anything with the byte.
                rx_ack <= 1;
            end
            else if (neither_have_control & control2[CTL_SYS_SRC]) begin
                $display("Granting System control");
                // The System is requesting control
                // Grant control to System.
                // The System is either polling this bit
                // TODO or will receive an interrupt if it's enabled.
                control2[CTL_SYS_GRNT] <= 1;

                // Clear request bit too
                control2[CTL_SYS_SRC] <= 0;
            end
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Device sequences
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UADeviceCheckBuffer: begin
            rx_ack <= 0;

            // if ((signal == KEY_Signal) & (neither_have_control | control1[CTL_SYS_GRNT])) begin
            //     // Client sent a key-code. Store it and potentially notify System
            //     // next_state <= UAClientKeyCodeAcknowledge;
            // end
            // else
            if (neither_have_control & (signal == CRC_Signal)) begin
                // Grant control to Client.
                $display("Granting control to Client");
                control1[CTL_CLI_GRNT] <= 1;

                // Send Request-Granted-Control (RGC) byte to Client
            end
        end

        // -------------------------------------
        // Key-code sub-sequence
        // -------------------------------------
        // Device will wait and then store key-code
        UAClientKeyCodeAcknowledge: begin
            // rx_ack <= 0;
        end

        UAClientKeyCodeStore: begin
            // Wait for a Key-code to arrive.
            if (rx_complete) begin
                // Store key-code byte
                key_code <= rx_byte;

                // Either generate an interrupt and/or set control bit.
                if (control1[CTL_IRQ_EN]) begin
                    irq <= 1;       // Raise interrupt signal
                end
                else begin
                    control1[CTL_KEY_RDY] <= 1; // System can poll this bit.
                end

                // Acknowledge UARTRx's signal
                rx_ack <= 1;
            end
        end

        UAClientKeyCodeRxAck: begin
            rx_ack <= 0;
        end

        UAClientKeyCodeExit: begin
            // $display("C key ready 0x%h", control1);
            irq <= 0;       // Lower interrupt signal
        end

        // -------------------------------------
        // Send RGC Granted signal to Client
        // -------------------------------------
        // Write RGC byte directly to UART sub-module because we
        // are sending only 1 byte signal.
        UADeviceRGCSignalEnter: begin
            tx_select <= RGC_Signal_Select;        // Select the signal value
        end

        UADeviceTriggerRGCSignal: begin
            tx_en <= 0; // Trigger transmission
        end

        UADeviceSendingRGCSignal: begin
            tx_en <= 1; // Disable trigger

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                tx_select <= TxByte_Select;
            end
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // System sequences (has control)
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // The only thing the System does is send bytes. The Client responds with
        // ACK signals.
        // TODO:NOT-IMPLEMENTED:
        // The Client can still send Key-codes and this will in turn generate
        // interrupts (if enabled).
        UASystemIdle: begin
            // Wait for ACK from Client (software)
            // However, it could be something rouge like a Request for control.
            if (rx_complete) begin
                // Capture byte
                rx_buffer <= rx_byte;

                // We can acknowlegde immediately because we are not doing anything with the byte.
                rx_ack <= 1;

                // Move to: UASystemCheckByte
            end
            else if (control2[CTL_DEV_TRX]) begin
                $display("Data written to tx buffer");
                // A byte has been written to the Tx buffer.
                // Transmit it.
                control2[CTL_DEV_TRX]  <= 0;
                // Reset data sent signal too.
                control2[CTL_TRX_CMP] <= 0;
                // Move to: UASystemTransmit
            end
        end

        UASystemCheckByte: begin
            rx_ack <= 0;

            // Check if the Client is requesting control.
            if (signal == CRC_Signal) begin
                // Reject it because System currently has control.
                tx_select <= REJ_Signal_Select;  // Select the signal value
                control2[CTL_DVC_BSY] <= 1; // Device is now busy sending Reject signal
            end
        end

        UASystemREJSignalEnter: begin
            tx_en <= 0; // Trigger transmission
        end

        UASystemSendingREJSignal: begin
            tx_en <= 1; // Disable trigger

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                tx_select <= TxByte_Select;
                // The Client has been notified of rejection
                control2[CTL_DVC_BSY] <= 0; // Device is no longer busy

                // Move to Client's idle sequence
                // next_state <= UASystemIdle;
            end
        end

        // -------------------------------------
        // System transmission of Tx buffer
        // -------------------------------------
        // Most likely a ACK is being sent by the System
        UASystemTransmit: begin
            $display("Starting transmission");
            tx_en <= 0; // Trigger transmission
            tx_select <= TxByte_Select;
        end

        UASystemTransmitSending: begin
            tx_en <= 1; // Disable trigger
            
            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                control2[CTL_DEV_TRX] <= 0;     // Signal the System a byte is sent.
                // Automatically relinqesh control if detected EOS
                if (tx_buffer[7:4] == EOS_Signal) begin
                    $display("EOS sent and detected");
                    control2[CTL_SYS_GRNT] <= 0;
                end

                tx_buffer <= 0;
                
                control2[CTL_TRX_CMP] <= 1; // Signal data sent

                // Transition back to idle: UASystemIdle
            end
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Client sequences (has control)
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####

        // The Client will either send a Key-code via 2 bytes or start a stream.
        // Once the Client begins streaming it can't send a Key-code until
        // the stream ends.
        // The Device handles Key-codes directly.
        UAClientIdle: begin
            // Wait for a Signal or BYTE to arrive to determine which path.
            if (rx_complete) begin
                // Capture byte
                rx_buffer <= rx_byte;

                // We can acknowlegde immediately because we are not doing anything with the byte.
                rx_ack <= 1;
            end
        end

        UAClientCheckBuffer: begin
            rx_ack <= 0;

            // Once any one of these bits are sets the System will write
            // an ACK signal to the Tx buffer. The System does not need control to
            // perform it part.
            // The System (software) is polling these bits.
            case (signal)
                BOS_Signal: begin
                    control1[CTL_STR_BOS] <= 1;
                end
                DAT_Signal: begin
                    control1[CTL_STR_DAT] <= 1;
                end
                EOS_Signal: begin
                    control1[CTL_STR_EOS] <= 1;
                end
                default: begin
                    // If it isn't a signal then it is a BYTE
                    // The System will read the rx_buffer to fetch it.
                    control1[CTL_STR_BYT] <= 1;
                end
            endcase
        end

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

always_comb begin
    next_state = UADeviceIdle;

    // if (~tx_buff_wr) begin
    //     next_state = UASystemTransmit;
    // end

    case (state)
        // --------------------------------
        // Reset
        // --------------------------------
        UAReset0: begin
            next_state = UAResetComplete;
        end

        UAResetComplete: begin
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Main process
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UADeviceIdle: begin
            next_state = UADeviceIdle;

            // While the Device is idling either party can request control.
            // The System will request via a control bit.
            // The Client will request via an Rx byte.
            // The Client has priority thus it is checked first.
            // We only return to DeviceIdle when a party loses control via EOS.

            if (rx_complete) begin
                next_state = UADeviceCheckBuffer;
            end
            else if (neither_have_control & control2[CTL_SYS_SRC]) begin
                // Enter System sequence
                next_state = UASystemIdle;
            end
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Device sequences
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UADeviceCheckBuffer: begin
            // next_state = UADeviceCheckBuffer;

            if ((signal == KEY_Signal) & (neither_have_control | control1[CTL_SYS_GRNT])) begin
                // Client sent a key-code. Store it and potentially notify System
                next_state = UAClientKeyCodeAcknowledge;
            end
            else if (neither_have_control & (signal == CRC_Signal)) begin
                // Send Request-Granted-Control (RGC) byte to Client
                next_state = UADeviceRGCSignalEnter;
            end
        end

        // -------------------------------------
        // Key-code sub-sequence
        // -------------------------------------
        // Device will wait and then store key-code
        UAClientKeyCodeAcknowledge: begin
            next_state = UAClientKeyCodeStore;
        end

        UAClientKeyCodeStore: begin
            next_state = UAClientKeyCodeStore;

            if (rx_complete) begin
                next_state = UAClientKeyCodeRxAck;
            end
        end

        UAClientKeyCodeRxAck: begin
            next_state = UAClientKeyCodeExit;
        end

        UAClientKeyCodeExit: begin
            next_state = UADeviceIdle;
        end

        // -------------------------------------
        // Send RGC Granted signal to Client
        // -------------------------------------
        // Write RGC byte directly to UART sub-module because we
        // are sending only 1 byte signal.
        UADeviceRGCSignalEnter: begin
            next_state = UADeviceTriggerRGCSignal;
        end

        UADeviceTriggerRGCSignal: begin
            next_state = UADeviceSendingRGCSignal;
        end

        UADeviceSendingRGCSignal: begin
            next_state = UADeviceSendingRGCSignal;

            if (tx_complete) begin
                // The Client is now aware it has control.
                // Move to Client's idle sequence
                next_state = UAClientIdle;
            end
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // System sequences (has control)
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // The only thing the System does is send bytes. The Client responds with
        // ACK signals.
        // TODO:NOT-IMPLEMENTED:
        // The Client can still send Key-codes and this will in turn generate
        // interrupts (if enabled).
        UASystemIdle: begin
            next_state = UASystemIdle;

            if (rx_complete) begin
                next_state = UASystemCheckByte;
            end
            else if (control2[CTL_DEV_TRX]) begin
                next_state = UASystemTransmit;
            end

        end

        UASystemCheckByte: begin
            // Check if the Client is requesting control.
            if (signal == CRC_Signal) begin
                next_state = UASystemREJSignalEnter;
            end
            else
                next_state = UASystemIdle;
        end

        UASystemREJSignalEnter: begin
            next_state = UASystemSendingREJSignal;
        end

        UASystemSendingREJSignal: begin
            next_state = UASystemSendingREJSignal;

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                // The Client is now aware it has control.
                // Move to Client's idle sequence
                next_state = UASystemIdle;
            end
        end

        // -------------------------------------
        // Device transmission of Tx buffer
        // -------------------------------------
        // Most likely a ACK is being sent by the System
        UASystemTransmit: begin
            next_state = UASystemTransmitSending;
        end

        UASystemTransmitSending: begin
            next_state = UASystemTransmitSending;

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                next_state = UASystemIdle;
            end
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Client sequences (has control)
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####

        // The Client will either send a Key-code via 2 bytes or start a stream.
        // Once the Client begins streaming it can't send a Key-code until
        // the stream ends.
        // The Device handles Key-codes directly.
        UAClientIdle: begin
            next_state = UAClientIdle;

            if (rx_complete) begin
                next_state = UAClientCheckBuffer;
            end
        end

        UAClientCheckBuffer: begin
            next_state = UAClientIdle;
        end

        // -------------------------------------
        // Unknown State
        // -------------------------------------
        default: begin
            `ifdef SIMULATE
                $display("********* UNKNOWN STATE ***********");
            `endif
        end

    endcase

    // if (~reset)
    //     state <= UAReset0;
    // else
    //     state <= next_state;
end

endmodule

