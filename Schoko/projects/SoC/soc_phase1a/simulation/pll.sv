module pll
(
	input  logic clkin,
	input  logic reset,			// Active high
	output logic clkout0,
	output logic locked
);

assign clkout0 = clkin; // mirror
assign locked = 1;

endmodule