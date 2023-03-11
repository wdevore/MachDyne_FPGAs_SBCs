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
		if (pix_pos_x >= (x_pos + 100) && pix_pos_x < (x_pos + 200) && pix_pos_y >= (y_pos + 100) && (pix_pos_y < (y_pos + 200))) begin
			green_channel = 1;
			red_channel = 0;
			blue_channel = 0;
		end

		if (pix_pos_x >= 100 && pix_pos_x < 200 && pix_pos_y < 100) begin
			green_channel =  0;
			red_channel = 1;
			blue_channel =  0;
		end

		if (pix_pos_x >= 200 && pix_pos_x < 300 && pix_pos_y < 100) begin
			green_channel = 0;
			red_channel =  0;
			blue_channel = 1;
		end
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
