module pll
(
	input  logic clkin,
	input  logic reset,			// Active high
	output logic clkout0,
	output logic locked
);

logic ff;
assign clkout0 = ff; // mirror
assign locked = 1;

always_ff @(posedge clkin) begin
	ff <= ~ff;
end

endmodule