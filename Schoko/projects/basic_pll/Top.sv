// SCHOKO PLL

module Top
(
	input logic CLK_48,
	output logic LED_R,
	output logic LED_G,
	output logic LED_B,
	output logic PMOD_A1	// 25MHz
);

logic reset;
logic clk_25MHz;
logic locked;

assign PMOD_A1 = clk_25MHz;

pll basic_pll (
	.reset(0),
    .clkin(CLK_48),
    .clkout0(clk_25MHz),
    .locked(locked)
);

logic [26:0] counter = 0;

assign LED_G = 1'b1;
assign LED_B = ~counter[21];//1'b1;
assign LED_R = ~counter[21];

always @(posedge clk_25MHz) begin
	counter <= counter + 1;
end

endmodule
