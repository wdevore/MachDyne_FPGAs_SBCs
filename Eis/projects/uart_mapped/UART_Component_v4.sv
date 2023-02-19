`default_nettype none
`ifdef SIMULATE
`timescale 10ns/1ns
`endif

// ------------------------------------------------------
// Version 4
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
// Internal signals
// ------------------------------------------------------------------

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
// Tx/Rx buffer at address 0x03/0x04
// ------------------------------------------------------------------------
logic [CONTROL_SIZE-1:0] rx_buffer;  // Address 0x03
logic [DATA_WIDTH-1:0] rx_buff_out;
logic [CONTROL_SIZE-1:0] tx_buffer;  // Address 0x04

logic rx_buff_rd;       // active (low)
assign rx_buff_rd = ~(rd_active & (addr[1:0] == 2'b11) & control1[CTL_CLI_GRNT]);

logic tx_buff_wr;       // active (low)
assign tx_buff_wr = ~(wr_active & (addr[1:0] == 2'b11) & control1[CTL_SYS_GRNT]);

// ------------------------------------------------------------------------
// Data Ports
// ------------------------------------------------------------------------
// There are 3 destinations specified by the lower 2 bits
logic [1:0] in_select;
assign in_select = addr[1:0]; 

logic [DATA_WIDTH-1:0] byte_in;

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
    .data3_o(byte_in)
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
    .data3_i(rx_buff_out),
    .data_o(out_data)
);

// ------------------------------------------------------------------------
// IO channels
// ------------------------------------------------------------------------
logic [DATA_WIDTH-1:0] src_to_tx;  // From control bits
logic [2:0] tx_select;

Mux8 #(
    .DATA_WIDTH(DATA_WIDTH)
) tx_mux(
    .select_i(tx_select),
    .data0_i(tx_buffer),
    .data1_i({RGC_Signal, 4'b0000}),
    .data2_i({CRC_Signal, 4'b0000}),
    .data3_i({ACK_Signal, 4'b0000}),
    .data4_i(ZERO),
    .data5_i(ZERO),
    .data6_i(ZERO),
    .data7_i(ZERO),
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
logic rx_complete;
/* verilator lint_off UNUSED */
/* verilator lint_on UNUSED */
logic rx_ack;       // Active high

UARTRx uart_rx (
    .sourceClk(clock),
    .reset(reset),
    .rx_in(rx_in),
    .rx_ack(rx_ack),
    .rx_byte(rx_byte),
    .rx_complete(rx_complete)
);

// ------------------------------------------------------------------------
// State machine controlling device
// ------------------------------------------------------------------------
UARTState state = UAReset0;
UARTState next_state;

// logic streaming;

logic neither_have_control;  // Neither granted control
assign neither_have_control = control1[CTL_SYS_GRNT] == 0 || control1[CTL_CLI_GRNT] == 0;

always_ff @(posedge clock) begin
    // --------------------------------
    // IO inteface accessing: Control registers and Buffers
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
        else if (rx_buff_rd)
            rx_buff_out <= rx_buffer;
        else if (tx_buff_wr)
            tx_buffer <= byte_in;
    end

    case (state)
        // --------------------------------
        // Reset
        // --------------------------------
        UAReset0: begin
            control1 <= 0;
            control2 <= 0;
            tx_select <= Storage_Out_Select;
            tx_en <= 1;
            rx_ack <= 0;
            
            irq <= 1;       // Non-active
            irq_id <= Component_ID;    // UART component id
            
            key_code <= 0;

            // Temp
            rx_buffer <= 0;
        end

        UAResetComplete: begin
            next_state <= UADeviceIdle;
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Main process
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UADeviceIdle: begin
            // ---- Check any byte arriving -----
            // Checking the byte can only be done when either:
            // 1) neither party has control or
            // 2) or the System has control.
            if (rx_complete) begin
                if ((rx_byte[7:4] == KEY_Signal) & (neither_have_control | control1[CTL_SYS_GRNT])) begin
                    // We can acknowlegde immediately because we are not doing anything with it.
                    rx_ack <= 1;
                    // Client sent a key-code. Store it and potentially notify System
                    next_state <= UAClientKeyCodeAcknowledge;
                end
                else if (neither_have_control & (rx_byte[7:4] == CRC_Signal)) begin
                    rx_ack <= 1;
                    // The Client is requesting control
                    control1[CTL_CLI_CRC] <= 1;
                    next_state <= UADeviceAcknowledge;
                end
                else if (neither_have_control & control2[CTL_SYS_SRC]) begin
                    // The System is requesting control
                    // Grant control to System.
                    // The System is either polling this bit
                    // TODO or will receive an interrupt if it's enabled.
                    control2[CTL_SYS_GRNT] <= 1;

                    // Clear request bit too
                    control1[CTL_SYS_SRC] <= 0;

                    // Enter System sequence
                    next_state <= UASystemEnter;
                end
            end

            // ------ CLIENT ------
            if (control1[CTL_CLI_CRC]) begin // Is the Client requesting control.
                // Grant control to Client.
                control1[CTL_CLI_GRNT] <= 1;
                // Clear request bit too
                control1[CTL_CLI_CRC] <= 0;
                // Send Request-Granted-Control (RGC) byte to Client
                next_state <= UADeviceRGCSignalEnter;
            end
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Device sequences
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UADeviceAcknowledge: begin
            rx_ack <= 0;
            next_state <= UADeviceIdle;
        end

        // -------------------------------------
        // Send RGC Granted signal to Client
        // -------------------------------------
        // Write RGC byte directly to UART sub-module because we
        // are sending only 1 byte signal.
        UADeviceRGCSignalEnter: begin
            tx_select <= RGC_Signal_Select;        // Select the signal value
            next_state <= UADeviceTriggerRGCSignal;
        end

        UADeviceTriggerRGCSignal: begin
            tx_en <= 0; // Trigger transmission
            next_state <= UADeviceSendingRGCSignal;
        end

        UADeviceSendingRGCSignal: begin
            tx_en <= 1; // Disable trigger

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                tx_select <= Storage_Out_Select;
                // The Client is now aware it has control.
                // Move to Client idle sequence
                next_state <= UAClientIdle;
            end
        end

        // -------------------------------------
        // Key-code sub-sequence
        // -------------------------------------
        // Device will wait and then store key-code
        UAClientKeyCodeAcknowledge: begin
            rx_ack <= 0;
            next_state <= UAClientKeyCodeStore;
        end

        UAClientKeyCodeStore: begin
            // Wait for a Key-code to arrive.
            if (rx_complete) begin
                // Store key-code byte
                key_code <= rx_byte;
                // Either generate interrupt (TODO) or set control bit.
                control1[CTL_KEY_RDY] <= 1; // System polls this bit.

                // Acknowledge UARTRx's signal
                rx_ack <= 1;
                next_state <= UAClientKeyCodeExit;
            end
        end

        UAClientKeyCodeExit: begin
            rx_ack <= 0;
            next_state <= UADeviceIdle;
        end

        // -------------------------------------
        // Acknowlege response
        // -------------------------------------
        UADeviceTriggerACKSignal: begin
            rx_ack <= 0;
            tx_en <= 0; // Trigger transmission
            next_state <= UADeviceSendingACKSignal;
        end

        UADeviceSendingACKSignal: begin
            tx_en <= 1; // Disable trigger

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                rx_ack <= 1;
                tx_select <= Storage_Out_Select;
                next_state <= UAClientIdle;
            end
        end


        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // System sequences
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UASystemEnter: begin
        end


        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Client sequences
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####

        // The Client will either send a Key-code via 2 bytes or start a stream.
        // Once the Client begins streaming it can't send a Key-code until
        // the stream ends.
        // The Device handles Key-codes directly.
        UAClientIdle: begin
            // Wait for a Signal to arrive to determine which path. It will
            // either be EOS or KEY signal.
            if (rx_complete) begin
                rx_ack <= 1;

                // Upper 4 bits indicate signal type
                case (rx_byte[7:4])
                    BOS_Signal: begin
                        // Client is starting a stream. Key-codes will no longer
                        // be recognized.
                        // streaming <= 1;
                        // Send ACK back in response.
                        tx_select <= ACK_Signal_Select;        // Select the signal value

                        next_state <= UADeviceTriggerACKSignal;
                    end
                    DAT_Signal: begin
                        // Client sent DAT signal which indicates a byte is comming

                        tx_select <= ACK_Signal_Select;        // Select the signal value

                        // Move to specific DAT/Byte pair sequence
                        next_state <= UAClientTriggerBytePair;
                    end
                    default: begin
                        // If it isn't a signal then it is a byte
                    end
                endcase
            end
        end

        // -------------------------------------
        // DAT/Byte sub-sequence
        // -------------------------------------
        UAClientTriggerBytePair: begin
            rx_ack <= 0;
            // ???????????????????????????????????????????
            // next_state <= UADeviceSendingACKSignal;
        end

        // -------------------------------------
        // Streaming sub-sequence
        // -------------------------------------
        UAClientStreamStart: begin
            rx_ack <= 0;

            next_state <= UAClientStreamReceive;
        end

        UAClientStreamReceive: begin
            // Signal UARTRx that we captured the data
            rx_ack <= 1;
        end

        UAClientDataStore: begin
            rx_ack <= 0;
            next_state <= UAClientStreamReceive;
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

endmodule

