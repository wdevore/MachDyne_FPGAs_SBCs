// SCHOKO UART

typedef enum logic [7:0] {
    TopReset,           // 0000
    TopResetting,       // 0001
    TopResetComplete,   // 0010
	TopWriteByte1,		// 0011
	TopWriteByte2, 		// 0100
	TopWriteByte3,		// 0101
	TopWriteByte4,		// 0110
	TopWriteByte5,		// 0111
	TopWriteByte6,		// 1000
	TopWriteByte7,		// 1001
	TopWriteByte8,		// 1010
	TopWriteByte9,		// 1011
	TopWriteByte10,		// 1100
	TopWriteByte11,		// 1101
	TopWriteByte12,		// 1110
	TopWriteByte13,		// 1110
	TopWriteByte14,		// 1110
	TopWriteByte15,		// 1110
	TopWriteByte16,		// 1110
	TopWriteByte17,		// 1110
	TopWriteByte18,		// 1110
    TopIdle             // 1111
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
	input   logic PMOD_B1,		// transmit (active low)
	output  logic PMOD_B3,		// (to client) Rx
	input   logic PMOD_B4 		// (from client) Tx
);

logic reset;

logic [26:0] counter = 0;

assign LED_R = ~counter[23];
assign LED_G = 1;//~counter[25];
assign LED_B = 1;//~counter[24];

assign PMOD_A1  =  cnt[3];
assign PMOD_A2  =  cnt[2];
assign PMOD_A3  =  cnt[1];
assign PMOD_A4  =  cnt[0];
assign PMOD_A7  =  state[3];
assign PMOD_A8  =  state[2];
assign PMOD_A9  =  state[1];
assign PMOD_A10 =  state[0];

// assign PMOD_A1  =  tx_bo[7];
// assign PMOD_A2  =  tx_bo[6];
// assign PMOD_A3  =  tx_bo[5];
// assign PMOD_A4  =  tx_bo[4];
// assign PMOD_A7  =  tx_bo[3];
// assign PMOD_A8  =  tx_bo[2];
// assign PMOD_A9  =  tx_bo[1];
// assign PMOD_A10 =  tx_bo[0];

logic tx_en;
logic [7:0] tx_buffer;
logic [7:0] tx_out;
logic tx_complete;

UARTTx uart_tx (
    .sourceClk(CLK_48),
    .reset(reset),
	.cs(cs),
    .tx_en(tx_en),
    .tx_byte(tx_buffer),
    .tx_out(PMOD_B3),
    .tx_complete(tx_complete)
);

TopState state = TopReset;
TopState next_state;
logic [3:0] cnt;
logic transmit = PMOD_B1;

initial begin
	tx_en = 1;
	cs = 0;
end

always_comb begin
	next_state = TopReset;
	reset = 1'b1;			// Reset disabled
    tx_en = 1;

    case (state)
        TopReset: begin
			reset = 1'b0;	// Start reset
            next_state = TopResetting;
        end

		TopResetting: begin
			reset = 1'b0;
			next_state = TopWriteByte1;
		end

		// ------------------------------------------
        TopWriteByte1: begin
			// Load byte
			next_state = TopWriteByte2;
        end

        TopWriteByte2: begin
			tx_en = 0;
			next_state = TopWriteByte3;
        end

        TopWriteByte3: begin
			next_state = TopWriteByte3;
			if (tx_complete) begin
				next_state = TopWriteByte4;
			end
        end

		// ------------------------------------------
        TopWriteByte4: begin
			next_state = TopWriteByte5;
        end

        TopWriteByte5: begin
			tx_en = 0;
			next_state = TopWriteByte6;
        end

        TopWriteByte6: begin
			next_state = TopWriteByte6;
			if (tx_complete) begin
				next_state = TopWriteByte7;
			end
        end

		// ------------------------------------------
        TopWriteByte7: begin
			next_state = TopWriteByte8;
        end

        TopWriteByte8: begin
			tx_en = 0;
			next_state = TopWriteByte9;
        end

        TopWriteByte9: begin
			next_state = TopWriteByte9;
			if (tx_complete) begin
				next_state = TopWriteByte10;
			end
        end

		// ------------------------------------------
        TopWriteByte10: begin
			next_state = TopWriteByte11;
        end

        TopWriteByte11: begin
			tx_en = 0;
			next_state = TopWriteByte12;
        end

        TopWriteByte12: begin
			next_state = TopWriteByte12;
			if (tx_complete) begin
				next_state = TopIdle;
			end
        end

        // TopIdle: begin
		// 	next_state = TopIdle;
        // end

        default: begin
        end
    endcase
end

always @(posedge CLK_48) begin
    case (state)
        TopReset: begin
        end

		// TopResetting: begin
		// end

        // TopResetComplete: begin
        // end

        TopWriteByte1: begin
			tx_buffer <= 8'h4F;
        end

        TopWriteByte4: begin
			tx_buffer <= 8'h6B;
        end

        TopWriteByte7: begin
			tx_buffer <= 8'h0D;  // 0x0D = CR
        end

        TopWriteByte10: begin
			tx_buffer <= 8'h0A;
        end

        TopIdle: begin
			cs <= 0;
        end

        default: begin
        end
    endcase

	if (~transmit & ~tx_complete) begin
		cs <= 1;
		state <= TopWriteByte1;
	end
	else
		state <= next_state;
end

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

endmodule
