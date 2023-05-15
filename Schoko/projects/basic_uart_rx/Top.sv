// SCHOKO UART Rx

typedef enum logic [7:0] {
    TopReset,           // 0000
    TopResetting,       // 0001
    TopResetComplete,   // 0010
	TopState1,
	TopState2,
	TopState3,
	TopState4,
	TopState5,
	TopState6,
	TopState7,
	TopState8,
	TopState9,
	TopState10,
    TopIdle
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
	// B1 is connected to a switch that idles High
	// Pushing the button pulls it Low
	input  logic PMOD_B1,		// Manual reset (active low)
	// output logic PMOD_B2,
	// B3 sends to the Client which is the USB/UART's Rx (brown)
	output logic PMOD_B3,
	// B4 receive from the Client which is the USB/UART's Tx (orange)
	input  logic PMOD_B4
	// B5 = GRD, B6 = VSS
	// output logic PMOD_B7,
	// output logic PMOD_B8,
	// output logic PMOD_B9,
	// output logic PMOD_B10
);

logic reset;

logic [26:0] counter = 0;

assign LED_R = ~counter[23];
assign LED_G = 1;//~counter[25];
assign LED_B = 1;//~counter[24];

assign PMOD_A1  =  port_a[7];	// MSb
assign PMOD_A2  =  port_a[6];
assign PMOD_A3  =  port_a[5];
assign PMOD_A4  =  port_a[4];
assign PMOD_A7  =  port_a[3];
assign PMOD_A8  =  port_a[2];
assign PMOD_A9  =  port_a[1];
assign PMOD_A10 =  port_a[0];  // LSb

logic rx_start;
logic [7:0] rx_byte;
logic rx_complete;
logic [7:0] port_a;

UARTRx uart_rx (
    .sourceClk(CLK_48),
    .reset(reset),			// Active low
	.rx_in(PMOD_B4),		// From UART device
	.rx_byte(rx_byte),
	.rx_start(rx_start),
	.rx_complete(rx_complete)
);

TopState state = TopReset;
TopState next_state;

initial begin
end

// Idle until a byte starts arriving then move to TopState1

always_comb begin
	next_state = TopReset;
	reset = 1'b1;			// Reset disabled

    case (state)
        TopReset: begin
			reset = 1'b0;	// Start reset
            next_state = TopResetting;
        end

		TopResetting: begin
			reset = 1'b0;
			next_state = TopIdle;
		end

		// ------------------------------------------
        TopState1: begin
			// A byte is arriving
			next_state = TopState1;
			if (rx_complete) begin
				next_state = TopState2;
			end
        end

        TopState2: begin
			next_state = TopIdle;
        end

        TopIdle: begin
			next_state = TopIdle;
			if (rx_start) begin
				next_state = TopState1;
			end
        end

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

        TopState2: begin
			// Store byte
			port_a <= rx_byte;
        end

        default: begin
        end
    endcase

	// if (~reset) begin
	// 	state <= TopReset;
	// end
	// else
		state <= next_state;
end

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

endmodule
