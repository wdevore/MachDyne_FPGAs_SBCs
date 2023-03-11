// SCHOKO VGA

module Top
(
	input logic CLK_48,
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
assign LED_G = ~counter[22];
assign LED_B = ~counter[21];
assign LED_R = ~counter[20];

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

logic pix_clk;
logic clock_locked;
logic display_en;
logic reset = 0;

logic green_channel;
logic red_channel;
logic blue_channel;

assign vga_r = red_channel;
assign vga_g = green_channel;
assign vga_b = blue_channel;

logic [9:0] x_pos = 1;
logic [9:0] y_pos = 1;
logic [7:0] cnt = 0;

logic flip = 1;

always_comb begin
	green_channel = 0;
	red_channel = 0;
	blue_channel = 0;

	if (display_en) begin
		// if (pix_pos_x < 100 && pix_pos_y < 100)
		if (pix_pos_x >= (x_pos + 100) && pix_pos_x < (x_pos + 200) && pix_pos_y >= (y_pos + 100) && (pix_pos_y < (y_pos + 200)))
			green_channel = 1;

		if (pix_pos_x >= 100 && pix_pos_x < 200 && pix_pos_y < 100)
			red_channel = 1;

		if (pix_pos_x >= 200 && pix_pos_x < 300 && pix_pos_y < 100)
			blue_channel = 1;
	end
end

always_ff @(posedge counter[20]) begin
	cnt <= cnt + 1;

	if (cnt > 25) begin
		flip = ~flip;
		cnt <= 0;
	end

	x_pos <= x_pos + (flip ? 1 : -1);
	y_pos <= y_pos + (flip ? 1 : -1);
end

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

endmodule
