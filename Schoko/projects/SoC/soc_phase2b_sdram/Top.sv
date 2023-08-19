// SCHOKO SoC


module Top
(
	input logic CLK_48,
	// Note: the default .lpf has the Red and Green backwards (fixed)
	// The LEDs are negative logic (i.e. 1 = off, 0 = on)
	output logic LED_R,
	output logic LED_G,
	output logic LED_B,
	// ------------ PMOD A ---------------------
	// I have LEDs connected to pmod A
	// Positive logic (i.e. 1 = on)
	output logic PMOD_A1,
	output logic PMOD_A2,
	output logic PMOD_A3,
	output logic PMOD_A4,
	output logic PMOD_A7,
	output logic PMOD_A8,
	output logic PMOD_A9,
	output logic PMOD_A10,
	// ------------ PMOD B ---------------------
	// B1 is connected to a switch that idles High
	// Pushing the button pulls it Low
	input  logic PMOD_B1,		// Manual reset (active low)
	// output logic PMOD_B2,
	// B3 sends to the Client which is the USB/UART's Rx (brown)
	// output logic PMOD_B3,
	// B4 receive from the Client which is the USB/UART's Tx (orange)
	// input  logic PMOD_B4,
	// B5 = GRD, B6 = VSS
	// output logic PMOD_B7,
	// output logic PMOD_B8,
	// output logic PMOD_B9,
	// output logic PMOD_B10

	// ------------ SDRAM ---------------------
	output [12:0] sdram_a,
	inout [15:0] sdram_dq,
	output sdram_cs_n,
	output sdram_cke,
	output sdram_ras_n,
	output sdram_cas_n,
	output sdram_we_n,
	output [1:0] sdram_dm,
	output [1:0] sdram_ba,
	output sdram_clock
);

logic [26:0] counter = 0;

// assign LED_R = ~counter[23];
// assign LED_G = 1'b1;
// assign LED_B = 1'b1;
assign LED_R = ~port_lr;	// Invert for Positive logic
assign LED_G = ~port_lg;
assign LED_B = ~port_lb;

// If connected to LED bar then a 1 = ON
assign PMOD_A1  =  port_a[7];
assign PMOD_A2  =  port_a[6];
assign PMOD_A3  =  port_a[5];
assign PMOD_A4  =  port_a[4];
assign PMOD_A7  =  port_a[3];
assign PMOD_A8  =  port_a[2];
assign PMOD_A9  =  port_a[1];
assign PMOD_A10 =  port_a[0];

// assign PMOD_A1  =  counter[7];
// assign PMOD_A2  =  counter[6];
// assign PMOD_A3  =  counter[5];
// assign PMOD_A4  =  counter[4];
// assign PMOD_A7  =  counter[3];
// assign PMOD_A8  =  counter[2];
// assign PMOD_A9  =  counter[1];
// assign PMOD_A10 =  counter[0];

logic button;
DebounceSimp bouncer(
	.Clk(slowClk),
	.in(~PMOD_B1),
	.out(button)
);

logic slowClk;
logic [25:0] slowCounter;

// Slow clock for debouncer
always @(posedge CLK_48) begin
	if (slowCounter[20]) begin
		slowCounter <= 0;
		slowClk <= ~slowClk;
	end
	else
		slowCounter <= slowCounter + 1;
end

always @(posedge button) begin
	counter <= counter + 1;
end

logic [7:0] port_a;
logic port_lr;
logic port_lg;
logic port_lb;

logic halt;

SoC soc(
	.clk_48mhz(CLK_48),
	.button_b1(button),
	// .uart_rx_in(PMOD_B4),  // From client
	// .uart_tx_out(PMOD_B3), // To client
	.port_a(port_a),
	.port_lr(port_lr),
	.port_lg(port_lg),
	.port_lb(port_lb),

	// --------------- SDRAM ---------------------
	.sdram_a(sdram_a),
	.sdram_dq(sdram_dq),
	.sdram_cs_n(sdram_cs_n),
	.sdram_cke(sdram_cke),
	.sdram_ras_n(sdram_ras_n),
	.sdram_cas_n(sdram_cas_n),
	.sdram_we_n(sdram_we_n),
	.sdram_dm(sdram_dm),
	.sdram_ba(sdram_ba),
	.sdram_clock(sdram_clock),

	// .port_b(port_b)
);

endmodule
