// SCHOKO SoC

module Top
(
	input logic CLK_48,
	// Note: the default .lpf has the Red and Green backwards
	output logic LED_R,
	output logic LED_G,
	output logic LED_B
);

logic [26:0] counter = 0;

assign LED_R = ~counter[23];
assign LED_G = ~port_a[0];
assign LED_B = ~port_a[1];

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

logic reset = 1'b0;
logic [7:0] port_a;

SoC soc(
	.clk_48mhz(CLK_48),
	.reset(reset),
	.port_a(port_a)
);

endmodule
