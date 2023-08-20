// This is technically the Top module

// From SYSCLK50 define
localparam SYSCLK = 50_000_000;

localparam UART0_BAUDRATE = 115200; 

module sysctl #()
(
    input logic CLK_48,

    // ------------- ONBOARD R,G,B LEDs -------------------
	// Note: the default .lpf has the Red and Green backwards (fixed)
	// The LEDs are negative logic (i.e. 1 = off, 0 = on)
	output logic LED_R,
	output logic LED_G,
	output logic LED_B,

    // ------------- UART -------------------
	input  logic UART0_RTS,
	output logic UART0_RX,
	input  logic UART0_TX,
	output logic UART0_CTS,

    // ------------- SDRAM -------------------
	output logic [12:0] sdram_a,
	inout  logic [15:0] sdram_dq,
	output logic sdram_cs_n,
	output logic sdram_cke,
	output logic sdram_ras_n,
	output logic sdram_cas_n,
	output logic sdram_we_n,
	output logic [1:0] sdram_dm,
	output logic [1:0] sdram_ba,
	output logic sdram_clock,
);

    // -----------------------------------------------------
    // ------------ PLLs for the Clocks -----------------
    // -----------------------------------------------------
    logic clk25mhz;
    logic clk50mhz;         // Output from PLL
    logic clk100mhz;
	logic clk125mhz;        // Not used because no video selected

	logic pll_locked;

	pll0 #() ecp5_pll0 (
		.clkin(CLK_48),
		.clkout0(clk100mhz),
		.clkout1(clk50mhz),
	);
	pll1 #() ecp5_pll1 (
		.clkin(clk100mhz),
		.clkout0(clk125mhz),
		.clkout1(clk25mhz),
		.locked(pll_locked),    // Active high
	);

    // -----------------------------------------------------
    // ------------ Clocks -----------------
    // -----------------------------------------------------
    logic clk;
    assign clk = clk50mhz;

    // ------------ Reset Generation -----------------
	logic [11:0] resetn_counter = 0;
    // Reset is active is any bit of the counter is 0
    // Once the counter reaches max value (all 1's), reset
    // is disabled and the counter stops.
	logic resetn = &resetn_counter;     // Active low

	always_ff @(posedge clk) begin
        // The PLL has priority over Reset.
        // Once the PLL is locked the counter can begin counting.
		if (!pll_locked)
			resetn_counter <= 0;
		else if (!resetn)
			resetn_counter <= resetn_counter + 1;
	end

    // -----------------------------------------------------
    // ------------ BRAM -----------------
    // -----------------------------------------------------
    localparam BRAM_WORDS = 1536;
	logic [31:0] bram [0:BRAM_WORDS-1];
    // BRAM as 32bit words. Possibly associated with vram
	logic [13:0] bsram_word = mem_addr[14:2];
	logic [10:0] bram_word = mem_addr[14:2];    // BRAM

	initial begin
        // In out version this could be simple code or a Monitor
        $readmemh("firmware/firmware_seed.hex", bram);
    end

    // -----------------------------------------------------
    // ------------ SDRAM -----------------
    // -----------------------------------------------------
    logic [2:0] sdram_state;
	logic [24:0] sdram_addr;
	logic [31:0] sdram_din;
	logic [31:0] sdram_dout;
	logic [3:0] sdram_wmask;
	logic sdram_ready;
	logic sdram_valid;

	sdram #(
		.SDRAM_CLK_FREQ(SYSCLK / 1_000_000)
	) sdram_i (
		.clk(clk),
		.resetn(resetn),

        // ----- Interface -------------
		.addr(sdram_addr),
		.din(sdram_din),
		.dout(sdram_dout),
		.wmask(sdram_wmask),
		.ready(sdram_ready),

        // ----- To SDRAM device -------
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
		.valid(sdram_valid)
	);

    always_ff @(posedge clk) begin
        mem_ready <= 0;

		if (uart0_received) begin
			uart0_dr <= 1;
			UART0_CTS <= 1;
		end

		if (!uart0_transmit && !uart0_is_transmitting && !UART0_RTS) begin
			uart0_txbusy <= 0;
		end

		if (!resetn) begin
			uart0_dr <= 0;
			uart0_txbusy <= 0;
			UART0_CTS <= 0;

			sram_state <= 0;
			sdram_state <= 0;
			sdram_valid <= 0;
		end else if (mem_valid && !mem_ready) begin
			(* parallel_case *)
			case (1)

				// BLOCK RAM
				(mem_addr < 8192): begin
					if (mem_wstrb[0]) bram[bram_word][7:0] <= mem_wdata[7:0];
					if (mem_wstrb[1]) bram[bram_word][15:8] <= mem_wdata[15:8];
					if (mem_wstrb[2]) bram[bram_word][23:16] <= mem_wdata[23:16];
					if (mem_wstrb[3]) bram[bram_word][31:24] <= mem_wdata[31:24];

					mem_rdata <= bram[bram_word];
					mem_ready <= 1;
				end

				// BLOCK RAM AS 32-bit SRAM
				(((mem_addr & 32'hf000_0000) == 32'h2000_0000)): begin
					sram_state <= 1;

					if (mem_wstrb[0]) bsram[bsram_word][7:0] <= mem_wdata[7:0];
					if (mem_wstrb[1]) bsram[bsram_word][15:8] <= mem_wdata[15:8];
					if (mem_wstrb[2]) bsram[bsram_word][23:16] <= mem_wdata[23:16];
					if (mem_wstrb[3]) bsram[bsram_word][31:24] <= mem_wdata[31:24];

					mem_rdata <= bsram[bsram_word];

					if (sram_state == 1) begin
						sram_state <= 0;
						mem_ready <= 1;
					end
				end

				((mem_addr & 32'hf000_0000) == 32'h1000_0000): begin
                    mem_ready <= 1;
				end

				(((mem_addr & 32'hf000_0000) == 32'h2000_0000)): begin
					if (mem_wstrb) begin
						if (sram_state == 0) begin
							sram_addr <= (mem_addr & 32'h0fff_ffff) >> 2;
							sram_dout <= mem_wdata;
							sram1_wrub <= mem_wstrb[3];
							sram1_wrlb <= mem_wstrb[2];
							sram0_wrub <= mem_wstrb[1];
							sram0_wrlb <= mem_wstrb[0];
							sram_state <= 1;
						end else if (sram_state == 1) begin
							mem_ready <= 1;
							sram_state <= 0;
						end
					end else begin

						if (sram_state == 0) begin
							sram_addr <= (mem_addr & 32'h0fff_ffff) >> 2;
							sram_state <= 1;
						end else if (sram_state == 1) begin
							mem_rdata <= sram_din;
							mem_ready <= 1;
							sram_state <= 0;
						end
					end
				end

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

				((mem_addr & 32'hf000_0000) == 32'hf000_0000): begin
					(* parallel_case *)
					case (mem_addr[15:0])

						16'h0000: begin
							if (mem_wstrb && !uart0_txbusy) begin
								uart0_tx_byte <= mem_wdata[7:0];
								uart0_txbusy <= 1;
								uart0_transmit <= 1;
								mem_ready <= 1;
							end else if (!mem_wstrb) begin
								mem_rdata[7:0] <= uart0_rx_byte;
								uart0_dr <= 0;
								UART0_CTS <= 0;
								mem_ready <= 1;
							end
						end

						16'h0004: begin
							if (!mem_wstrb) begin
								mem_rdata[7:0] <= { 6'b0, uart0_txbusy, uart0_dr };
							end
							mem_ready <= 1;
						end

						16'h1000: begin
							if (mem_wstrb)
								LED_A <= ~mem_wdata[0];
							else
								mem_rdata[0] <= ~LED_A;
							mem_ready <= 1;
						end

						16'h1100: begin
							if (!mem_wstrb) mem_rdata <= clock_secs;
							mem_ready <= 1;
						end

						16'h3000: begin
							mem_ready <= 1;
						end

						16'h3004: begin
							if (!mem_wstrb) begin
								mem_rdata[7:0] <= 0;
							end
							mem_ready <= 1;
						end

						default: begin
							mem_ready <= 1;
						end
					endcase
                end
			endcase
        end
    end

    // -----------------------------------------------------
    // ------------ PicoRV23 -----------------
    // -----------------------------------------------------
	logic cpu_trap;
	logic [31:0] cpu_irq;

	logic mem_valid;
	logic mem_instr;
	logic [31:0] mem_addr;
	logic [31:0] mem_wdata;
	logic [3:0] mem_wstrb;

	logic mem_ready;
	logic [31:0] mem_rdata;

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

    // -----------------------------------------------------
    // ------------ UART 0 -----------------
    // -----------------------------------------------------
	logic uart0_transmit;
	logic [7:0] uart0_tx_byte;
	logic uart0_received;
	logic [7:0] uart0_rx_byte;
	logic uart0_is_receiving;
	logic uart0_is_transmitting;
	logic uart0_recv_error;

	logic uart0_dr;
	logic uart0_txbusy;

	logic uart0_rx;

	uart #(
		.baud_rate(UART0_BAUDRATE),
		.sys_clk_freq(SYSCLK)
	)
	uart0 (
		.clk(clk),
		.rst(~resetn),
		.rx(UART0_TX),
		.tx(UART0_RX),
		.transmit(uart0_transmit),
		.tx_byte(uart0_tx_byte),
		.received(uart0_received),
		.rx_byte(uart0_rx_byte),
		.is_receiving(uart0_is_receiving),
		.is_transmitting(uart0_is_transmitting),
		.recv_error(uart0_recv_error)
	);

endmodule