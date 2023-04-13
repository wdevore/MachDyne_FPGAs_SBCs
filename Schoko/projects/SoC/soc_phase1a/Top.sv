// SCHOKO SoC

module Top
(
	input logic CLK_48,
	// Note: the default .lpf has the Red and Green backwards (fixed)
	output logic LED_R,
	output logic LED_G,
	output logic LED_B,
	// ------------ PMOD A ---------------------
	// I have LEDs connected to pmod A
	output logic PMOD_A1,
	output logic PMOD_A2,
	output logic PMOD_A3,
	output logic PMOD_A4,
	output logic PMOD_A7,
	output logic PMOD_A8,
	output logic PMOD_A9,
	output logic PMOD_A10,
	// ------------ PMOD B ---------------------
	// output logic PMOD_B1,
	// output logic PMOD_B2,
	output logic PMOD_B3,		// Tx  (from client)
	output logic PMOD_B4 		// Rx  (to client)
	// B5 = GRD, B6 = VSS
	// output logic PMOD_B7,
	// output logic PMOD_B8,
	// output logic PMOD_B9,
	// output logic PMOD_B10
);

logic [26:0] counter = 0;

assign LED_R = ~counter[23];
assign LED_G = 1'b1;
assign LED_B = 1'b1;

assign PMOD_A1  =  port_a[7];
assign PMOD_A2  =  port_a[6];
assign PMOD_A3  =  port_a[5];
assign PMOD_A4  =  port_a[4];
assign PMOD_A7  =  port_a[3];
assign PMOD_A8  =  port_a[2];
assign PMOD_A9  =  port_a[1];
assign PMOD_A10 =  port_a[0];

// assign PMOD_B1  =  port_b[7];
// assign PMOD_B2  =  port_b[6];
// assign PMOD_B3  =  port_b[5];
// assign PMOD_B4  =  port_b[4];
// assign PMOD_B7  =  port_b[3];
// assign PMOD_B8  =  port_b[2];
// assign PMOD_B9  =  port_b[1];
// assign PMOD_B10 =  port_b[0];

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

logic [7:0] port_a;
// logic [7:0] port_b;

SoC soc(
	.clk_48mhz(CLK_48),
	.uart_rx_in(PMOD_B3),			// Cross Tx with Rx
	.uart_tx_out(PMOD_B4),
	.port_a(port_a)//,
	// .port_b(port_b)
);

endmodule
