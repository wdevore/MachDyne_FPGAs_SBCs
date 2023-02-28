`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// This module simulates a CPU driving a UART module in a memory mapped arrangement.

// Simulate sending several bytes by following the Tx workflow.

module Top
(
    input logic  sysClock      // System High Freq Clock
);

// -----------------------------------------------------------
// Memory mapped UART Module
// -----------------------------------------------------------
UART_Component uart_uut (
    .clock(sysClock),
    .reset(reset),
    .cs(cs),
    .rd(rd),
    .wr(wr),
    .rx_in(client_tx_out),      // From Client (bit)
    .tx_out(client_rx_in),      // To Client (bit)
    .addr(addr),
    .out_data(out_data),
    .in_data(in_data),
    .irq(irq),
    .irq_id(irq_id)
);

// -----------------------------------------------------------
// The Client is UART modules (Tx/Rx) that we control
// In reality this may be a Go program for example.
// -----------------------------------------------------------
logic tx_en;
logic tx_complete;
logic [7:0] client_tx_byte;
logic client_tx_out;

// Pseudo Client Transmitter
UARTTx client_uart (
    .sourceClk(sysClock),
    .reset(reset),
    .tx_en(tx_en),
    .tx_byte(client_tx_byte),
    .tx_out(client_tx_out),        // Routes to rx_in on uart_uut
    .tx_complete(tx_complete)
);

logic rx_in;
logic rx_ack;
logic [7:0] rx_byte;
logic rx_start;
logic rx_complete;

// Pseudo Client Receiver
UARTRx client_rx_uart (
    .sourceClk(sysClock),
    .reset(reset),
    .rx_in(client_rx_in),
    .rx_ack(rx_ack),
    .rx_byte(rx_byte),
    .rx_start(rx_start),        
    .rx_complete(rx_complete)
);

logic client_rx_in;

// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = SMReset0;
SimState next_state;

logic reset_complete;
logic [3:0] reset_cnt;
logic reset = 0;
logic rd;
logic wr;
logic irq;
logic [2:0] irq_id;
logic [2:0] addr;
logic [7:0] out_data;
logic [7:0] in_data;
logic cs;

logic [7:0] component_data;

always_ff @(posedge sysClock) begin
    // --------------------------------
    // Reset
    // --------------------------------
    case (state)
        SMReset0: begin
            // $display("SMReset");
            reset_complete <= 0;
            reset_cnt <= 0;
            rd <= 1'b1;  // disable
            wr <= 1'b1;  // disable
            addr <= 0;
            in_data <= 0;
            reset <= 0;
            cs <= 1;
            tx_en <= 1; // Disable trigger
            component_data <= 0;
        end

        SMReset1: begin
            if (reset_cnt == 4'b1111) begin
                reset_complete <= 1;
                reset <= 1;
            end
            reset_cnt <= reset_cnt + 1;
        end

        SMResetComplete: begin
        end

        SMIdle: begin
        end

        // `include "Client_Send_Keycode_Top_FF.sv"
        // `include "System_Set_Bits_Top_FF.sv"
        // `include "Client_Rejected_Request_Top_FF.sv"
        `include "Client_Accepted_Request_Top_FF.sv"

        SMStop: begin
            // $display(" STOPPED ! %d", state);
            // $finish();
        end

        default: begin
            $display("FF ********* UNKNOWN STATE *********** %d",state);
        end

    endcase

    state <= next_state;
end

always_comb begin
    next_state = SMReset0;

    // --------------------------------
    // Reset
    // --------------------------------
    case (state)
        SMReset0: begin
            // $display("SMReset");
            next_state = SMReset1;
        end

        SMReset1: begin
            next_state = SMReset1;

            if (reset_cnt == 4'b1111) begin
                next_state = SMResetComplete;
            end
        end

        SMResetComplete: begin
            next_state = SMIdle;
        end

        // `include "Client_Send_Keycode_Top_Comb.sv"
        // `include "System_Set_Bits_Top_Comb.sv"
        // `include "Client_Rejected_Request_Top_Comb.sv"
        `include "Client_Accepted_Request_Top_Comb.sv"

        SMStop: begin
            next_state = SMStop;
        end

        default: begin
            $display("Comb ********* UNKNOWN STATE *********** Sync: %d", next_state);
        end

    endcase
end

endmodule
