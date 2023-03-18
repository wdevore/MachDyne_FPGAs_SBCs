// SCHOKO SoC

module Top
(
	input logic sysClock,
	// Note: the default .lpf has the Red and Green backwards
	output logic LED_R,
	output logic LED_G,
	output logic LED_B
);

logic [26:0] counter = 0;

assign LED_R = ~counter[23];
assign LED_G = ~port_a[0];
assign LED_B = ~port_a[1];

always @(posedge sysClock) begin
	counter <= counter + 1;
end

logic [7:0] port_a;

SoC soc(
	.clk_48mhz(sysClock),
	.port_a(port_a)
);

endmodule
