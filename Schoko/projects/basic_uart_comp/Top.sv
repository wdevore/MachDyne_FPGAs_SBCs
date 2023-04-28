// SCHOKO UART

typedef enum logic [7:0] {
    TopReset,           // 000
    TopResetting,       // 001
    TopResetComplete,   // 010
	TopWriteByte1,		// 011
	TopWriteByte2, 		// 100
	TopWriteByte3,		// 101
	TopWriteByte4,		// 110
	TopWriteByte5,		// 110
	TopWriteByte6,		// 110
    TopIdle             // 111
} TopState; 

module Top
(
	input logic CLK_48,
	// Note: the default .lpf has the Red and Green backwards (fixed)
	// The LEDs are negative logic (i.e. 1 = off, 0 = on)
	output logic LED_R,
	output logic LED_G,
	output logic LED_B,
	// ------------ PMOD A ---------------------
	// I have LEDs connected to pmod A
	// Positive logic (i.e. 1 = on)
	output logic PMOD_A1,
	output logic PMOD_A2,
	output logic PMOD_A3,
	output logic PMOD_A4,
	output logic PMOD_A7,
	output logic PMOD_A8,
	output logic PMOD_A9,
	output logic PMOD_A10,
	// ------------ PMOD B ---------------------
	input  logic PMOD_B1,		// transmit (active low)
	output logic PMOD_B3,		// (to client) Rx
	input  logic PMOD_B4 		// (from client) Tx
);

logic reset = 1;

logic [26:0] counter = 0;

assign LED_R = ~counter[25];
assign LED_G = ~counter[24];
assign LED_B = ~counter[23];

logic uart_cs;
logic uart_rd = 1;
logic uart_wr;
logic uart_irq;
logic [2:0] uart_irq_id;

// Address  |  Description
// --------- ---------------------------------
//   0      |  Control 1 register
//   1      |  Rx buffer (byte, read only)
//   2      |  Tx buffer (byte, write only)
logic [2:0] uart_addr;

logic [7:0] uart_out_data;
logic [7:0] uart_in_data;

// assign PMOD_A1  =  debug[3];
// assign PMOD_A2  =  debug[2];
// assign PMOD_A3  =  debug[1];
// assign PMOD_A4  =  debug[0];
// assign PMOD_A7  =  state[3];
// assign PMOD_A8  =  state[2];
// assign PMOD_A9  =  state[1];
// assign PMOD_A10 =  state[0];

assign PMOD_A1  =  debugT[7];
assign PMOD_A2  =  debugT[6];
assign PMOD_A3  =  debugT[5];
assign PMOD_A4  =  debugT[4];
assign PMOD_A7  =  debugT[3];
assign PMOD_A8  =  debugT[2];
assign PMOD_A9  =  debugT[1];
assign PMOD_A10 =  debugT[0];

// Debug ---------------
logic [7:0] debug;
logic [7:0] debugT;

UART_Component uart_comp (
    .clock(CLK_48),
    .reset(reset),				// Active low
    .cs(uart_cs),				// Active low
    .rd(uart_rd),				// Active low
    .wr(uart_wr),				// Active low
    .rx_in(PMOD_B4),         	// From Client (bit)
    .tx_out(PMOD_B3),       	// To Client (bit)
    .addr(uart_addr),
    .out_data(uart_out_data),	// Byte received
    .in_data(uart_in_data),		// Byte to transmit
    .irq(uart_irq),
    .irq_id(uart_irq_id),
	.debug(debug)
);

TopState state = TopReset;
TopState next_state;
logic transmit = PMOD_B1;
logic transmitting;

always_comb begin
	next_state = TopReset;
	reset = 1'b1;			// Reset disabled
	uart_wr = 1;

    case (state)
        TopReset: begin
			reset = 1'b0;	// Start reset
            next_state = TopResetting;
        end

		TopResetting: begin
			reset = 1'b0;
			next_state = TopResetComplete;
		end

        TopResetComplete: begin
			next_state = TopIdle;
        end

		// ------------------------------------------
        TopWriteByte1: begin
			// Load byte
			next_state = TopWriteByte2;
        end

        TopWriteByte2: begin
			next_state = TopWriteByte3;
        end

        TopWriteByte3: begin
			uart_wr = 0;	// Write to tx_buf
			// TODO Read control register
			next_state = TopIdle;
        end

		// ------------------------------------------
        // TopWriteByte4: begin
		// 	// Load byte
		// 	next_state = TopWriteByte5;
        // end

        // TopWriteByte5: begin
		// 	next_state = TopWriteByte6;
        // end

        // TopWriteByte6: begin
		// 	uart_wr = 0;	// Write to tx_buf
		// 	// TODO Read control register
		// 	next_state = TopIdle;
        // end

        TopIdle: begin
			next_state = TopIdle;
        end

        default: begin
        end
    endcase
end

always @(posedge CLK_48) begin
	debugT[0] <= uart_cs;
	debugT[1] <= uart_wr;

    case (state)
        TopReset: begin
			debugT <= 0;
			transmitting <= 0;
			uart_cs <= 1; // Disable
        end

		TopResetting: begin
		end

        TopResetComplete: begin
        end

		// ------------------------------------------
        TopWriteByte1: begin
			uart_cs <= 0; // Chip Enable
			uart_in_data <= 8'h4F;  // Ascii "O"
			uart_addr <= 3'b010;	// Select Tx buf
        end

        TopWriteByte2: begin
        end

        TopWriteByte3: begin
			transmitting <= 0;
			// TODO Read control register
			uart_cs <= 1; // Disable
        end

		// ------------------------------------------
        // TopWriteByte4: begin
		// 	uart_cs <= 0; // Chip Enable
		// 	uart_in_data <= 8'h6F;  // Ascii "k"
		// 	uart_addr <= 3'b010;	// Select Tx buf
        // end

        // TopWriteByte5: begin
        // end

        // TopWriteByte6: begin
		// 	transmitting <= 0;
		// 	// TODO Read control register
		// 	uart_cs <= 1; // Disable
        // end

        TopIdle: begin
			debugT[7] <= 1;
        end
        default: ;
    endcase

	if (~transmit & ~transmitting) begin
		debugT[7] <= 0;
		transmitting <= 1;
		state <= TopWriteByte1;
	end
	else
		state <= next_state;
end

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

endmodule
