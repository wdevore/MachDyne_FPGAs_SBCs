// KONFEKT BLINKY

module Top
#(
)
(
	input logic clk48,
	output logic led_r,
	output logic led_g,
	output logic led_b
);

	logic [26:0] counter = 0;

	assign led_r = 1'b1;//~counter[23];
	assign led_g = 1'b1;//~counter[23];
	assign led_b = ~counter[23];

	always @(posedge clk48) begin
		counter <= counter + 1;
	end

endmodule
