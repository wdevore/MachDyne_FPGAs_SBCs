
module Soc
#(
)
(
	input logic CLK_48,
	output logic LED_R,
	output logic LED_G,
	output logic LED_B
);

logic [26:0] counter = 0;

assign LED_G = 1'b1;//~counter[23];
assign LED_B = 1'b1;//~counter[23];
assign LED_R = ~counter[23];

always @(posedge CLK_48) begin
	counter <= counter + 1;
end

endmodule
