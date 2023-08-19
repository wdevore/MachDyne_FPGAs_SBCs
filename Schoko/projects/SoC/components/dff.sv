module DBdff (
	input  logic Clk,
    input  logic enable,
	input  logic D,
	output logic Q
);
    always_ff @(posedge Clk) begin
        if (enable)
            Q <= D;
    end
endmodule
