`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ns
`endif

// SCHOKO VGA

module Top
(
	input logic sysClock		// 20.8333ns
);

logic clk_out;
/* verilator lint_off UNUSED */
logic clk_locked;
logic display_en;
/* verilator lint_on UNUSED */

pixel_clk_480p pix_clk (
	.sysClock(sysClock),
    .reset(0),
    .clk_out(clk_out),
    .clk_pixel_locked(clk_locked)
);

logic vga_h_sync;
logic vga_v_sync;
logic [9:0] counter_x = 0;
logic [9:0] counter_y = 0;

hvsync_generator sync_gen (
	.clk(clk_out),
	.reset(0),
	.h_sync(vga_h_sync),
	.v_sync(vga_v_sync),
	.h_count(counter_x),
	.v_count(counter_y),
	.display_en(display_en)
);

endmodule
