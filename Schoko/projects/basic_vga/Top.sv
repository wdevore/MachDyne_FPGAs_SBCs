// SCHOKO VGA

module Top
(
	input logic CLK_48,
	// Note: the default .lpf has the Red and Green backwards
	output logic LED_R,
	output logic LED_G,
	output logic LED_B,
	output logic vga_r,
	output logic vga_g,
	output logic vga_b,
	output logic vga_hsync,
	output logic vga_vsync
);

logic [26:0] counter = 0;
assign LED_R = ~counter[24];
assign LED_G = ~counter[23];
assign LED_B = ~counter[22];

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

logic pix_clk;
logic clock_locked;
logic display_en;
logic reset = 0;

pixel_clk_480p clk_480p (
	.clk_48mhz(CLK_48),
	.reset(reset),
	.clk_pixel(pix_clk),
	.clk_locked(clock_locked)
);

logic [9:0] pix_pos_x;
logic [9:0] pix_pos_y;

hvsync_generator sync_gen (
	.clk(pix_clk),
	.reset(reset),
	.h_sync(vga_hsync),
	.v_sync(vga_vsync),
	.h_count(pix_pos_x),
	.v_count(pix_pos_y),
	.display_en(display_en)
);

// ---------------------------------------------------------------
// Fun stuff below ;-)
// ---------------------------------------------------------------
logic green_channel;
logic red_channel;
logic blue_channel;

assign vga_r = red_channel;
assign vga_g = green_channel;
assign vga_b = blue_channel;

// `include "white_background.sv"
// `include "black_background.sv"
`include "modulo.sv"

endmodule
