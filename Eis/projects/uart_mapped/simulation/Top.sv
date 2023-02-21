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
    .rx_in(client_tx_out),      // From Client
    .tx_out(client_rx_in),            // To Client
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
logic [7:0] tx_byte;
logic client_tx_out;

UARTTx client_uart (
    .sourceClk(sysClock),
    .reset(reset),
    .tx_en(tx_en),
    .tx_byte(tx_byte),
    .tx_out(client_tx_out),        // Routes to rx_in on uart_uut
    .tx_complete(tx_complete)
);

/* verilator lint_off UNUSED */
logic client_rx_in;
/* verilator lint_on UNUSED */

// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = SMReset0;
SimState next_state;

/* verilator lint_off UNUSED */
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
/* verilator lint_on UNUSED */

logic [7:0] component_data;

// always_ff @(negedge sysClock) begin
//     case (state)
//         SMReset0: begin
//             component_data <= 0;
//         end
//     endcase
// end

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
            // rx_in <= 0;
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

        // __--__##__--__##__--__##__--__##__--__##__--__##__--__##
        // Send Key-code
        // __--__##__--__##__--__##__--__##__--__##__--__##__--__##
        // At this point the component is idling.
        // We simulate a Client sending a key-code pair: 0x70 and 0x42

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Send key signal
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMSendKeySetup: begin
            tx_byte <= 8'h70;   // KEY_Signal
        end

        SMSendKeyTrigger: begin
            tx_en <= 0; // Trigger transmission
        end

        SMSendKeyUnTrigger: begin
            tx_en <= 1; // Disable trigger
        end

        SMSendKeySending: begin
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Send key code
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMSendKeyCodeSetup: begin
            tx_byte <= 8'h42;   // Ascii
        end

        SMSendKeyCodeTrigger: begin
            tx_en <= 0; // Trigger transmission
        end

        SMSendKeyCodeUnTrigger: begin
            tx_en <= 1; // Disable trigger
        end

        SMSendKeyCodeSending: begin
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Read control1 for key ready signal
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMReadControl1: begin
            addr <= 3'b001; // Address control1 register
            cs <= 0;    // Chip select active
        end

        SMReadControl1_A: begin
            component_data <= out_data;
        end

        SMReadControl1_B: begin
            cs <= 1;    // Disable chip
            if (component_data[CTL_KEY_RDY] == 0) begin
                $display("!!!!!!! Expected CTL_KEY_RDY to be Set !!!!!!!");
                $exit();
            end
        end

        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        // Read key-code
        // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        SMReadKeycode_A: begin
            addr <= 3'b000; // Address key-code register
            cs <= 0;    // Chip select active
        end

        SMReadKeycode_B: begin
            component_data <= out_data;
        end
        
        SMReadKeycode_C: begin
            cs <= 1;    // Disable chip
        end

        SMStop: begin
            // $display(" STOPPED !");
            // $finish();
        end

        default: begin
            $display("********* UNKNOWN STATE *********** %d",state);
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

        SMIdle: begin
            next_state = SMSendKeySetup;
        end

        SMSendKeySetup: begin
            next_state = SMSendKeyTrigger;
        end

        SMSendKeyTrigger: begin
            next_state = SMSendKeyUnTrigger;
        end

        SMSendKeyUnTrigger: begin
            next_state = SMSendKeySending;
        end

        SMSendKeySending: begin
            next_state = SMSendKeySending;

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                next_state = SMSendKeyCodeSetup;
            end
        end

        SMSendKeyCodeSetup: begin
            next_state = SMSendKeyCodeTrigger;
        end

        SMSendKeyCodeTrigger: begin
            next_state = SMSendKeyCodeUnTrigger;
        end

        SMSendKeyCodeUnTrigger: begin
            next_state = SMSendKeyCodeSending;
        end

        SMSendKeyCodeSending: begin
            next_state = SMSendKeyCodeSending;

            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                next_state = SMReadControl1;
            end
        end

        SMReadControl1: begin
            next_state = SMReadControl1_A;
        end

        SMReadControl1_A: begin
            next_state = SMReadControl1_B;
        end

        SMReadControl1_B: begin
            if (component_data[CTL_KEY_RDY] == 1) begin
                next_state = SMReadKeycode_A;
            end
            else
                next_state = SMStop;
        end

        SMReadKeycode_A: begin
            next_state = SMReadKeycode_B;
        end

        SMReadKeycode_B: begin
            next_state = SMReadKeycode_C;
        end

        SMReadKeycode_C: begin
            next_state = SMStop;
        end

        SMStop: begin
            next_state = SMStop;
        end

        default: begin
            $display("********* UNKNOWN STATE *********** Sync: %d", next_state);
        end

    endcase
end

endmodule
