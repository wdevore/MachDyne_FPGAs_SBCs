`ifndef NRV_RESET_ADDR
 `define NRV_RESET_ADDR 0
`endif

`ifndef NRV_ADDR_WIDTH
 `define NRV_ADDR_WIDTH 24
`endif

module SoC
(
	input  logic clk_48mhz,
	input  logic reset,			// Active Low
	output logic [7:0] port_a//,
	// input  logic [26:0] counter
);

assign port_a = {{6{1'b1}},mem_address[20]};

// The memory bus.
logic [31:0] mem_address; // 24 bits are used internally. The two LSBs are ignored (using word addresses)

logic clk;
logic locked;
// logic [26:0] counter;

pll soc_pll (
    .clkin(clk_48mhz),
	.reset(~reset),		// Expects Active High
    .clkout0(clk),		// ~10MHz
    .locked(locked)
);

// always @(posedge clk) begin
// 	counter <= counter + 1;
// end

FemtoRV32 #(
) processor (
	.clk(clk),			
	.mem_addr(mem_address)
);

// Memory maps
// logic mem_address_is_io = mem_address[22];

// always_ff @(posedge clk) begin
// 	port_a[2] <= mem_address_is_io;
// end


endmodule
