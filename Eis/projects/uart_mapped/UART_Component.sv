`default_nettype none
`ifdef SIMULATE
`timescale 10ns/1ns
`endif

// UART Component
// It is mapped into memory. You only interact via memory mapped addresses.

// Control register is address 0
// Input/Output Data is address 1

module UART_Component
(
    input  logic clock,              // System clock
    input  logic reset,              // Reset
    input  logic rd,
    input  logic wr,
    input  logic rx_in,              // Incoming bits
    output logic tx_out,             // Outgoing bits
    input  logic [1:0] addr,         // Address: controls or buffers
    output logic [7:0] out_data,     // Ouput data port
    input  logic [7:0] in_data       // Input data port
);

// Control register N-bits
//         .--------------------- Data Complete (DC)
//         | .------------------- Data Ready (DR)
//         | | .----------------- Reset Rx Address
//         | | | .--------------- Reset Tx Address
//         | | | | .------------- Enable/Disable interrupts
//         | | | | | .----------- Stop bits
//         | | | | | | .-.------- Control Granted (CG) bit-2 = device, bit-3 = CPU
//         | | | | | | | | .----- Request Control (RC)
//         | | | | | | | | | .--- Start Tx
// ----_ - 0 0_0 0 0 0_0 0 0 0
//  addr-1    |  addr-0
localparam CONTROL_SIZE = 10;
logic [CONTROL_SIZE-1:0] control_register;

// ------------------------------------------------------------------------
// Buffers
// ------------------------------------------------------------------------
localparam WORDS = 6; // 64 bytes each = 2^6  
localparam DATA_WIDTH = 8;

// 2 BRAM buffer(s)
// 0x00 -> 0x3F

// --------------------------------
// Tx buffer
// --------------------------------
// The CPU can only write bytes to the buffer when it has gained
// control.
logic cpu_wr;   // active (low)
assign cpu_wr = ~wr & addr == 2'b10 & control_register[3];
logic device_rd;
logic [DATA_WIDTH-1:0] tx_storage_in;
logic [DATA_WIDTH-1:0] tx_storage_out;
// Address counter
logic [WORDS-1:0] buff_tx_address;

Memory #(
    .WORDS(WORDS),
    .DATA_WIDTH(DATA_WIDTH)
) tx_buff(
    .clk_i(clock),
    .data_i(tx_storage_in),
    .addr_i(buff_tx_address),
    .wr_i(~cpu_wr),
    .rd_i(device_rd),
    .data_o(tx_storage_out)
);

// --------------------------------
// Rx buffer
// --------------------------------
logic cpu_rd;       // active (low)
assign cpu_rd = ~rd & addr == 2'b10 & control_register[2];
// device_wr is when the component needs to transfer data from the
// UART Rx to the buffer. The device can only write to the buffer
// when the device has control.
logic device_wr;
logic [DATA_WIDTH-1:0] rx_storage_in;   // From UARTRx output
logic [DATA_WIDTH-1:0] rx_storage_out;  // To Memory map interface Mux
// Address counter
logic [WORDS-1:0] buff_rx_address;

Memory #(
    .WORDS(WORDS),
    .DATA_WIDTH(DATA_WIDTH)
) rx_buff(
    .clk_i(clock),
    .data_i(rx_storage_in),
    .addr_i(buff_rx_address),
    .wr_i(device_wr),
    .rd_i(~cpu_rd),
    .data_o(rx_storage_out)
);

// ------------------------------------------------------------------------
// IO channels
// ------------------------------------------------------------------------
// UART Transmitter reads from the buffer
logic tx_en;
logic [DATA_WIDTH-1:0] tx_byte;
logic tx_complete;

UARTTx uart_tx (
    .sourceClk(clock),
    .reset(reset),
    .tx_en(tx_en),
    .tx_byte(tx_byte),
    .tx_out(tx_out),
    .tx_complete(tx_complete)
);

// UART Receiver writes to the buffer
logic rx_en;
logic [DATA_WIDTH-1:0] rx_byte;
logic rx_complete;

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
SimState state = UAReset0;
SimState next_state;

always_comb begin
    next_state = SMReset0;

    // --------------------------------
    // Reset
    // --------------------------------
    case (state)
        UAReset0: begin
        end

        UAResetComplete: begin
        end


        default: begin
            `ifdef SIMULATE
                $display("********* UNKNOWN STATE ***********");
            `endif
        end

    endcase
end

always_ff @(posedge clock) begin
    // --------------------------------
    // Reset
    // --------------------------------
    case (state)
        UAReset0: begin
            control_register <= 0;
            buff_tx_address <= 0;
            buff_rx_address <= 0;
        end

        UAResetComplete: begin
        end

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

