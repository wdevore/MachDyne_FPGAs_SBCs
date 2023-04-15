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
    input  logic reset,             // Reset (active low)
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
logic wr_active = cs | wr; // = inverted inputs Nand gate = ~(~cs & ~wr) (Active low)
logic rd_active = cs | rd;

// ------------------------------------------------------------------
// Control registers N-bits
// ------------------------------------------------------------------
localparam CONTROL_SIZE = 8;
logic [CONTROL_SIZE-1:0] control;  // Address 0x00
logic control_wr = (wr_active | ~(addr[2:0] == 3'b000)); // Active low

// ------------------------------------------------------------------------
// Tx/Rx buffers
// ------------------------------------------------------------------------
logic [CONTROL_SIZE-1:0] rx_buffer;  // Address 0x01
logic [CONTROL_SIZE-1:0] tx_buffer;  // Address 0x02
logic tx_buff_wr = (wr_active | ~(addr[2:0] == 3'b010)); // Active low

// ------------------------------------------------------------------------
// Data Ports
// ------------------------------------------------------------------------
logic in_select = addr[2:0] == 3'b000; 

logic [DATA_WIDTH-1:0] byte_in;
logic [DATA_WIDTH-1:0] control_in;

// Incoming interface data from System
DeMux2 #(
    .DATA_WIDTH(DATA_WIDTH)
) in_demux (
    .select(in_select),
    .data_i(in_data),
    .data0_o(control_in),
    .data1_o(byte_in)
);

// Outgoing interface data to System
logic out_select = addr[2:0] == 3'b000;

Mux2 #(
    .DATA_WIDTH(DATA_WIDTH)
) out_mux(
    .select_i(out_select),
    .data0_i(control),
    .data1_i(rx_buffer),
    .data_o(out_data)
);

// ------------------------------------------------------------------------
// UART IO channels
// ------------------------------------------------------------------------

// UART Transmitter reads from the Tx buffer
logic tx_en;
logic tx_complete;

UARTTx uart_tx (
    .sourceClk(clock),
    .reset(reset),
    .tx_en(tx_en),
    .tx_byte(tx_buffer),
    .tx_out(tx_out),
    .tx_complete(tx_complete)
);

// UART Receiver writes to the Rx buffer
logic [DATA_WIDTH-1:0] rx_byte;
logic rx_complete;
logic rx_start;

UARTRx uart_rx (
    .sourceClk(clock),
    .reset(reset),
    .rx_in(rx_in),      // bits
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
logic [3:0] signal = rx_buffer[7:4];

// #__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__
// ------------
// ------------
// ------------
// ------------
// #__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__
always_comb begin
    next_state = UAReset0;
    tx_en = 1;          // Disable
    irq = 0;            // Deactivate

    case (state)
        // --------------------------------
        // Reset
        // --------------------------------
        UAReset0: begin
            next_state = UAResetComplete;
        end

        UAResetComplete: begin
            next_state = UADeviceIdle;
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Main process
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UADeviceIdle: begin
            next_state = UADeviceIdle;

            if (rx_complete) begin
                next_state = UARxComplete;

                if (control[CTL_IRQ_ENAB]) begin
                    irq = 1;   // Trigger interrupt
                    next_state = UAIRQComplete;
                end
            end

            if (~tx_buff_wr) begin
                next_state = UATxTransmit;
            end
        end

        UATxTransmit: begin
            tx_en = 0; // Enable transmission
            next_state = UATxTransmitComplete;
        end

        UATxTransmitComplete: begin
            tx_en = 0; // Maintain
            next_state = UADeviceIdle;
        end

        UARxComplete: begin
            // Set CTL_RX_AVAL
            next_state = UADeviceIdle;
        end

        UAIRQComplete: begin
            irq = 1;
            next_state = UADeviceIdle;
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
end

// #__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__
// -----------
// #__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__
always_ff @(posedge clock) begin
    case (state)
        // --------------------------------
        // Reset
        // --------------------------------
        UAReset0: begin
            control <= 0;
            rx_buffer <= 0;
            irq_id <= Component_ID;    // Component id
        end

        UAResetComplete: begin
            // $display("UAResetComplete");
        end

        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        // Main process
        // #### __---__---__---__---__---__---__---__---__---__---__--- ####
        UADeviceIdle: begin
            if (~control_wr)
                control <= control_in;

            // --------------------------------
            // System events
            // --------------------------------
            // The System should check the CTL_TX_BUSY flag first before
            // writing to the buffer
            if (~tx_buff_wr) begin
                tx_buffer <= byte_in;
                control[CTL_TX_READY] <= 1;
                control[CTL_TX_BUSY] <= 1;
                // Move to UATxTransmit
            end

            if (tx_complete) begin
                control[CTL_TX_BUSY] <= 0;
            end

            // Clear byte-available flag when the System reads the rx_buffer
            if (~rd_active & out_select)
                control[CTL_RX_AVAL] <= 0;

            // --------------------------------
            // Client events
            // --------------------------------
            if (rx_complete) begin
                // Capture byte
                rx_buffer <= rx_byte;

                if (control[CTL_IRQ_ENAB]) begin
                    // irq <= 1;   // Trigger interrupt
                    // Move to UAIRQComplete
                end
                // else
                // Move to UARxComplete
            end
        end

        UATxTransmit: begin
        end

        UARxComplete: begin
            // Signal a byte has arrived
            control[CTL_RX_AVAL] <= 1;
            // Move to UADeviceIdle
        end

        UAIRQComplete: begin
            // Move to UADeviceIdle
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

