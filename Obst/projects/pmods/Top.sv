// Obst PMOD-A test using LEDS

module Top
#(
)
(
	input logic CLK_48,
	output logic led_r,
	output logic led_g,
	output logic led_b,

	// This project uses SIPEED's led strips
	// pmod A
	output logic PMOD_A1, // D4
	output logic PMOD_A2, // D5
	output logic PMOD_A3, // D6
	output logic PMOD_A4, // D7
	output logic PMOD_A7, // D0
	output logic PMOD_A8, // D1
	output logic PMOD_A9, // D2
	output logic PMOD_A10, // D3

	// LED strip B strutured like A
	output logic PMOD_B1,
	output logic PMOD_B2,
	output logic PMOD_B3,
	output logic PMOD_B4,
	output logic PMOD_B7,
	output logic PMOD_B8,
	output logic PMOD_B9,
	output logic PMOD_B10
);

localparam LED_ON = 0;
localparam LED_OFF = 1;

logic [28:0] counter = 0;

assign led_g = LED_OFF;
assign led_b = LED_OFF;
assign led_r = ~counter[23];

assign PMOD_A1 =  ~counter[22];
assign PMOD_A2 =  ~counter[21];
assign PMOD_A3 =  ~counter[20];
assign PMOD_A4 =  ~counter[19];
assign PMOD_A7 =  ~counter[26];
assign PMOD_A8 =  ~counter[25];
assign PMOD_A9 =  ~counter[24];
assign PMOD_A10 = ~counter[23];

assign PMOD_B1 =  ~counter[24];
assign PMOD_B2 =  ~counter[23];
assign PMOD_B3 =  ~counter[22];
assign PMOD_B4 =  ~counter[21];
assign PMOD_B7 =  ~counter[28];
assign PMOD_B8 =  ~counter[27];
assign PMOD_B9 =  ~counter[26];
assign PMOD_B10 = ~counter[25];

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

endmodule
