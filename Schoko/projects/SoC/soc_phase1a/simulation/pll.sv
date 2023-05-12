module pll
(
	input  logic clkin,
	/* verilator lint_off UNUSEDSIGNAL */
	input  logic reset,			// Active high
	/* verilator lint_on UNUSEDSIGNAL */
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
