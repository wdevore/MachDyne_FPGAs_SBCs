`include "boards.vh"

localparam SYSCLK = 50_000_000;

module sysctl #()
(
	input CLK_48,
	output [12:0] sdram_a,
	inout [15:0] sdram_dq,
	output sdram_cs_n,
	output sdram_cke,
	output sdram_ras_n,
	output sdram_cas_n,
	output sdram_we_n,
	output [1:0] sdram_dm,
	output [1:0] sdram_ba,
	output sdram_clock,
);
	// CLOCKS
	// ------

	wire clk;

	wire clk25mhz;
	wire clk50mhz;
	wire clk100mhz;
	wire clk125mhz;

	wire pll_locked;

	pll0 #() ecp5_pll0 (
		.clkin(CLK_48),
		.clkout0(clk100mhz),
		.clkout1(clk50mhz),
	);
	pll1 #() ecp5_pll1 (
		.clkin(clk100mhz),
		.clkout0(clk125mhz),
		.clkout1(clk25mhz),
		.locked(pll_locked),
	);
	assign clk = clk50mhz;

reg [2:0] sdram_state;

reg [24:0] sdram_addr;
reg [31:0] sdram_din;
wire [31:0] sdram_dout;
reg [3:0] sdram_wmask;
wire sdram_ready;
reg sdram_valid;

sdram #(
	.SDRAM_CLK_FREQ(SYSCLK / 1_000_000)
) sdram_i (
	.clk(clk),
	.resetn(resetn),
	.addr(sdram_addr),
	.din(sdram_din),
	.dout(sdram_dout),
	.wmask(sdram_wmask),
	.ready(sdram_ready),

	// ------ To SDRAM device -----------
	.sdram_clk(sdram_clock),
	.sdram_cke(sdram_cke),
	.sdram_csn(sdram_cs_n),
	.sdram_rasn(sdram_ras_n),
	.sdram_casn(sdram_cas_n),
	.sdram_wen(sdram_we_n),
	.sdram_addr(sdram_a),
	.sdram_ba(sdram_ba),
	.sdram_dq(sdram_dq),
	.sdram_dqm(sdram_dm),
	// -----------------------------------
	.valid(sdram_valid)
);

sdram_state <= 0;
sdram_valid <= 0;

((mem_addr & 32'hf000_0000) == 32'h4000_0000): begin

	if (mem_wstrb) begin

		if (sdram_state == 0 && !sdram_ready) begin
			sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
			sdram_din <= mem_wdata;
			sdram_wmask <= mem_wstrb;
			sdram_state <= 1;
			sdram_valid <= 1;
		end else if (sdram_state == 1 && sdram_ready) begin
			sdram_wmask <= 0;
			sdram_valid <= 0;
			sdram_state <= 2;
		end else if (sdram_state == 2 && !sdram_ready) begin
			mem_ready <= 1;
			sdram_state <= 0;
		end

	end else begin

		if (sdram_state == 0 && !sdram_ready) begin
			sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
			sdram_valid <= 1;
			sdram_state <= 1;
		end else if (sdram_state == 1 && sdram_ready) begin
			mem_rdata <= sdram_dout;
			sdram_valid <= 0;
			sdram_state <= 2;
		end else if (sdram_state == 2 && !sdram_ready) begin
			mem_ready <= 1;
			sdram_state <= 0;
		end

	end
end

	// CPU
	// ---

	wire cpu_trap;
	wire [31:0] cpu_irq;

	wire mem_valid;
	wire mem_instr;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;	// A 4 bit pattern mask

	reg mem_ready;
	reg [31:0] mem_rdata;

	picorv32 #(
		.STACKADDR(BRAM_WORDS * 4),		// end of BRAM
		.PROGADDR_RESET(32'h0000_0000),
		.PROGADDR_IRQ(32'h0000_0010),
		.BARREL_SHIFTER(1),
		.COMPRESSED_ISA(0),
		.ENABLE_MUL(0),
		.ENABLE_DIV(0),
		.ENABLE_IRQ(0)
	) cpu (
		.clk(clk),
		.resetn(resetn),
		.trap(cpu_trap),
		.mem_valid(mem_valid),
		.mem_instr(mem_instr),
		.mem_ready(mem_ready),
		.mem_addr(mem_addr),
		.mem_wdata(mem_wdata),
		.mem_wstrb(mem_wstrb),
		.mem_rdata(mem_rdata),
		.irq(cpu_irq)
	);


endmodule
