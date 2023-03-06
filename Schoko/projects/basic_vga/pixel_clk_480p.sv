// Pixel clock generator
// Statically built against a 48MHz clock

// See readme.md for PLL generation via icepll

module pixel_clk_480p
#(
)
(
	input  logic clk_48mhz,
	input  logic reset, 
	output logic clk_pixel,
	output logic clk_locked		// PLL locked
);

	logic [26:0] counter = 0;

	assign LED_G = 1'b1;//~counter[23];
	assign LED_B = 1'b1;//~counter[23];
	assign LED_R = ~counter[23];

	always @(posedge CLK_48) begin
		counter <= counter + 1;
	end

endmodule
