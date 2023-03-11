logic [2:0] color = 0;

always_comb begin
	green_channel = 0;
	red_channel = 0;
	blue_channel = 0;
	color = 0;

	if (display_en) begin
		if (pix_pos_x < 79)
			color = 0;
		else if (pix_pos_x >= 80 && pix_pos_x < 159)
			color = 1;
		else if (pix_pos_x >= 160 && pix_pos_x < 239)
			color = 2;
		else if (pix_pos_x >= 240 && pix_pos_x < 319)
			color = 3;
		else if (pix_pos_x >= 320 && pix_pos_x < 399)
			color = 4;
		else if (pix_pos_x >= 400 && pix_pos_x < 479)
			color = 5;
		else if (pix_pos_x >= 480 && pix_pos_x < 559)
			color = 6;
		else if (pix_pos_x >= 560 && pix_pos_x < 639)
			color = 7;

		green_channel = color[0];
		red_channel = color[1];
		blue_channel = color[2];
	end
end

