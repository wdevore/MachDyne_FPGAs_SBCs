// SCHOKO SoC

module Top
(
	input logic CLK_48,
	// Note: the default .lpf has the Red and Green backwards
	output logic LED_R,
	output logic LED_G,
	output logic LED_B
);

// logic [26:0] counter = 0;

assign LED_R = ~port_a[0];//~counter[23];
assign LED_G = 1'b1;//~port_a[1];
assign LED_B = 1'b1;//~port_a[2];

// always @(posedge CLK_48) begin
// 	counter <= counter + 1;
// end

logic reset = 1'b1;
logic [7:0] port_a;

SoC soc(
	.clk_48mhz(CLK_48),
	.reset(reset),
	.port_a(port_a)//,
	// .counter(counter)
);

endmodule
