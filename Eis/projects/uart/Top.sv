`default_nettype none

// Brown = Rx from USB-UART
// Orange = Tx from USB-UART
// Brown is cross/routed to FPGA Tx pin = PMOD_A3
// Orange is cross/routed to FPGA Rx pin = PMOD_A2
module Top (
    input  logic CLK_48,    // 48MHz Clock from board
	output logic LED_A,
    input  logic UART0_RX,  // rx_in  = PMOD_A2 = Orange = Tx from USB
    output logic UART0_TX,  // tx_out = PMOD_A3 = Brown = Rx from USB
	output logic PMOD_A7,
	output logic PMOD_A8,
	output logic PMOD_A9,
	output logic PMOD_A10
);

localparam MAX_BIT = 24;

logic [26:0] counter = 0;
// assign LED_A = ~rx_complete;
assign LED_A = UART0_RX;
// assign LED_A = ~counter[23];

// assign PMOD_A7 = ~rx_byte[0];
// assign PMOD_A8 = ~rx_byte[1];
// assign PMOD_A9 = ~rx_byte[2];
// assign PMOD_A10 = ~rx_byte[3];

assign PMOD_A7 = state[3];     // orange MSB
assign PMOD_A8 = state[2];     // white
assign PMOD_A9 = state[1];     // blue
assign PMOD_A10 = state[0];    // blue   LSB

// This module reflects the byte back to the receiver.
logic tx_en;
logic [7:0] tx_byte;
logic tx_out;
logic tx_complete;

UARTTx uart_tx (
    .sourceClk(CLK_48),
    .reset(reset),
    .tx_en(tx_en),
    .tx_byte(tx_byte),
    .tx_out(UART0_TX),
    .tx_complete(tx_complete)
);

logic rx_complete;
logic [7:0] rx_byte;

UARTRx uart_rx (
    .sourceClk(CLK_48),
    .reset(reset),
    .rx_in(UART0_RX),
    .rx_byte(rx_byte),
    .rx_complete(rx_complete)
);

// ------------------------------------------------------------------------
// State machine controlling module
// ------------------------------------------------------------------------
ControlState state = 0;
ControlState next_state = 0;

logic [26:0] cnt_state_hold = 0;

logic reset;

always_ff @(posedge CLK_48) begin
    counter <= counter + 1;
    cnt_state_hold <= cnt_state_hold + 1;

    case (state)
        CSReset: begin
            reset <= 1'b1;
            tx_en <= 1;         // Disable transmission
            next_state <= CSReset1;
        end

        CSReset1: begin
            reset <= 1'b0;
            next_state <= CSResetComplete;
        end

        CSResetComplete: begin
            reset <= 1'b1;
            next_state <= CSIdle;
        end

        CSIdle: begin
            // Wait for a byte to arrive
            if (rx_complete) begin
                // Reflect it back.
                next_state <= CSSend;
            end
        end

        CSSend: begin
            tx_en <= 0; // Enable transmission
            next_state <= CSSending;

            tx_byte <= rx_byte;
        end

        CSSending: begin
            tx_en <= 1; // Disable transmission
            
            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                next_state <= CSIdle;
            end
        end

        default: begin
        end
    endcase

    state <= next_state;
end

endmodule

