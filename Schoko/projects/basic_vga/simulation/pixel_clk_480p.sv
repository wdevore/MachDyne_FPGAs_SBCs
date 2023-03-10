`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ns
`endif

// Pixel clock generator
// Statically built against a 48MHz clock


module pixel_clk_480p
(
	input  logic sysClock,
	input  logic reset, 
	output logic clk_out,
	output logic clk_pixel_locked
);

logic clk_locked;

// period(ns) = 1/f * 1000000000
// 1÷48000000×1000000000

// fake a 25.175MHz clock from 47MHz
//
//  ______|------______|------______|------
//        |-- period --|
//             20.8ns  <- 48MHz
//             39.7.8ns  <- 25.175MHz


// 25.175MHz = 39.7219464ns period
// 48MHz = 20.8333333ns period

// The Cpp testbench already generates ~25MHz clock
// Just reflect it back.
assign clk_out = sysClock;
assign clk_pixel_locked = 1;


endmodule
