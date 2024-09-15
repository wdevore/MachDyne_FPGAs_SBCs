// SCHOKO BLINKY

module Top
#(
)
(
	input logic CLK_48,
	output logic led_r,
	output logic led_g,
	output logic led_b,

	// I have LEDs connected to pmod A
	// output logic PMOD_A1,
	// output logic PMOD_A2,
	// output logic PMOD_A3,
	// output logic PMOD_A4,
	// output logic PMOD_A7,
	// output logic PMOD_A8,
	// output logic PMOD_A9,
	// output logic PMOD_A10
);

logic [26:0] counter = 0;

assign led_g = 1'b1;//~counter[23];
assign led_b = 1'b1;//~counter[23];
assign led_r = ~counter[23];
// assign PMOD_A1 = counter[26];
// assign PMOD_A2 = counter[25];
// assign PMOD_A3 = counter[24];
// assign PMOD_A4 = counter[23];
// assign PMOD_A7 = counter[22];
// assign PMOD_A8 = counter[21];
// assign PMOD_A9 = counter[20];
// assign PMOD_A10 = counter[19];

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

endmodule
