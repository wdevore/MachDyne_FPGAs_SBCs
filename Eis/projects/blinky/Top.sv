module Top (
	input logic CLK_48,
	output logic LED_A
);

	logic [26:0] counter = 0;

	assign LED_A = ~counter[23];

	always @(posedge CLK_48) begin
		counter <= counter + 1;
	end

endmodule
