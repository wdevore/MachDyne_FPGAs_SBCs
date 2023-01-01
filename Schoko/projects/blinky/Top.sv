// SCHOKO BLINKY

module Top
#(
)
(
	input logic CLK_48,
	output logic LED_R,
	output logic LED_G,
	output logic LED_B,
);

	logic [26:0] counter = 0;

	assign LED_G = ~counter[25];
	assign LED_B = ~counter[25];
	assign LED_R = ~counter[25];

	always @(posedge CLK_48) begin
		counter <= counter + 1;
	end

endmodule
