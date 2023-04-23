// SCHOKO SoC

module Top
(
	input logic sysClock
);

// A pretend port for visibility in Verilator
logic [7:0] port_a;

SoC soc(
	.clk_48mhz(sysClock),
	.port_a(port_a)
);

endmodule
