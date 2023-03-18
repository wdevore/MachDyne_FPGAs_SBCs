

module FemtoRV32(
   input  logic   clk,

   output logic [31:0] mem_addr  // address bus
);

logic [26:0] counter;

assign mem_addr = {{5{1'b0}}, counter};

always @(posedge clk) begin
	counter <= counter + 1;
end


endmodule

