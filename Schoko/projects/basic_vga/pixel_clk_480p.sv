// Pixel clock generator
// Statically built against a 48MHz clock

// See readme.md for PLL generation via icepll

module pixel_clk_480p
(
	input  logic clk_48mhz,
	input  logic reset, 
	output logic clk_pixel,
	output logic clk_locked		// PLL locked
);

pll basic_pll (
    .clkin(clk_48mhz),
	.reset(reset),
    .clkout0(clk_pixel),
    .locked(clk_locked)
);

endmodule
