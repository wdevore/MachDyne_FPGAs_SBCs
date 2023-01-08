module Top (
	input logic CLK_48,
	output logic LED_A,
	output logic PMOD_A7,
	output logic PMOD_A8,
	output logic PMOD_A9,
	output logic PMOD_A10,
);

	logic [26:0] counter = 0;

	assign LED_A = ~counter[23];

	assign PMOD_A7 = ~counter[24];
	assign PMOD_A8 = ~counter[23];
	assign PMOD_A9 = ~counter[22];
	assign PMOD_A10 = ~counter[21];

	always @(posedge CLK_48) begin
		counter <= counter + 1;
	end

endmodule
