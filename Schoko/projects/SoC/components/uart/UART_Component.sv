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
    input  logic rd,                // Active Low
    input  logic wr,                // Active Low
    input  logic rx_in,             // Incoming bits
    output logic tx_out,            // Outgoing bits
    input  logic [2:0] addr,        // Address: controls, buffer, key-code
    output logic [7:0] out_data,    // Ouput data port
    input  logic [7:0] in_data,     // Input data port (routed to DeMux)
    output logic irq,               // Active high
    output logic [2:0] irq_id,      // ID. 8 possible ids.
    // Debug ----------------------------
    output logic [7:0] debug
);

localparam Component_ID = 3'b000;

localparam DATA_WIDTH = 8;

// ------------------------------------------------------------------
// Internal signals
// ------------------------------------------------------------------
logic wr_active;
logic rd_active;
assign wr_active = cs | wr; // = inverted inputs Nand gate = ~(~cs & ~wr) (Active low)
assign rd_active = cs | rd;

// ------------------------------------------------------------------
// Control N-bits (combined at Addres 0x00)
// ------------------------------------------------------------------
localparam CONTROL_SIZE = 8;
logic [CONTROL_SIZE-1:0] control;  // Address 0x00
logic is_Ctrl_address;
assign is_Ctrl_address = ~(addr[2:0] == 3'b000);
logic control_wr; // Active low
assign control_wr = wr_active | is_Ctrl_address; // Active low

// ------------------------------------------------------------------------
// Tx/Rx buffers
// ------------------------------------------------------------------------
localparam BUFFER_SIZE = 8;
logic [BUFFER_SIZE-1:0] rx_buffer;  // Address 0x01
logic [BUFFER_SIZE-1:0] tx_buffer;  // Address 0x02

logic is_Tx_address;
assign is_Tx_address = ~(addr[2:0] == 3'b010);
logic tx_buff_wr;
assign tx_buff_wr = wr_active | is_Tx_address; // Active low

// ------------------------------------------------------------------------
// Data Ports
// ------------------------------------------------------------------------
logic in_select;
assign in_select = addr[2:0] != 3'b000; 

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
logic out_select;
assign out_select = addr[2:0] == 3'b000;

Mux2 #(
    .DATA_WIDTH(DATA_WIDTH)
) out_mux(
    .select_i(out_select),
    .data0_i(rx_buffer),
    .data1_i(control),
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
	.cs(~cs),
    .tx_en(tx_en),
    .tx_byte(tx_buffer),
    .tx_out(tx_out),
    .tx_complete(tx_complete)
);

// UART Receiver writes to the Rx buffer
logic [DATA_WIDTH-1:0] rx_byte;
logic rx_complete;
logic rx_start; // Active high

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

UARTState tx_state = UATxIdle;
UARTState tx_next_state;

UARTState rx_state = UARxIdle;
UARTState rx_next_state;

always_comb begin
    next_state = UAReset0;
    tx_next_state = UATxIdle;
    rx_next_state = UARxIdle;
    tx_en = 1;          // Disable
    irq = 0;            // Deactivate

    case (state)
        UAReset0: begin
            next_state = UAResetComplete;
        end

        UAResetComplete: begin
            next_state = UADeviceIdle;
        end

        UADeviceIdle: begin
            next_state = UADeviceIdle;
        end

        default: ;
    endcase

    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    // Transmit
    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    case (tx_state)
        UATxIdle: begin
            if (~tx_buff_wr) begin
                tx_next_state = UATxTransmit;
            end
        end

        UATxTransmit: begin
            tx_en = 0; // Enable transmission
            tx_next_state = UATxTransmitComplete;
        end

        UATxTransmitComplete: begin
            tx_next_state = UATxTransmitComplete;
			if (tx_complete) begin
				tx_next_state = UATxIdle;
			end
        end
        default: ;
    endcase

    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    // Receive
    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    case (rx_state)
        UARxIdle: begin
            // if (rx_start) begin
            // end

            if (rx_complete) begin
                // Byte arrived
                rx_next_state = UARxComplete;

                if (control[CTL_IRQ_ENAB]) begin
                    irq = 1;   // Trigger interrupt
                    rx_next_state = UAIRQComplete;
                end
            end
        end

        UARxComplete: begin
            // Set CTL_RX_AVAL
            rx_next_state = UARxIdle;
        end

        UAIRQComplete: begin
            // Set CTL_RX_AVAL
            rx_next_state = UARxIdle;
        end

        default: ;
    endcase    
end

// #__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__
// -----------
// #__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__#__
always_ff @(posedge clock) begin
    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    // Device/Component
    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    if (~control_wr)
        control <= control_in;

    // Clear byte-available flag when the System reads the rx_buffer
    if (~rd_active & ~out_select) begin
        control[CTL_RX_AVAL] <= 0;
    end

    case (state)
        // --------------------------------
        // Reset
        // --------------------------------
        UAReset0: begin
            control <= 0;
            rx_buffer <= 0;
            irq_id <= Component_ID;    // Component id
            debug <= 0;
        end

        UAResetComplete: begin
            // Move to UADeviceIdle
        end

        UADeviceIdle: begin
            // Move to UADeviceIdle
        end

        default: ;
    endcase

    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    // Transmit
    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    case (tx_state)
        UATxIdle: begin
            // The System should check the CTL_TX_BUSY flag first before
            // writing to the buffer
            if (~tx_buff_wr) begin
                tx_buffer <= byte_in;
                control[CTL_TX_BUSY] <= 1;
                // Move to UATxTransmit
            end
        end

        UATxTransmit: begin
        end

        UATxTransmitComplete: begin
            if (tx_complete) begin
                control[CTL_TX_BUSY] <= 0;
            end
        end
        default: ;
    endcase

    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    // Receive
    // #### __---__---__---__---__---__---__---__---__---__---__--- ####
    case (rx_state)
        UARxIdle: begin
            if (rx_complete) begin
                // A byte just arrived. Capture it.
                rx_buffer <= rx_byte;
                // Move to UARxComplete
            end
        end


        UARxComplete: begin
            // Signal a byte has arrived
            control[CTL_RX_AVAL] <= 1;
            // Move to UARxIdle
        end

        default: ;
    endcase

    if (~reset) begin
        state <= UAReset0;
        tx_state <= UATxIdle;
        rx_state <= UARxIdle;
    end
    else begin
        state <= next_state;
        tx_state <= tx_next_state;
        rx_state <= rx_next_state;
    end
end

endmodule

