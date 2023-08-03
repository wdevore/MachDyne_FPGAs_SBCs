`default_nettype none
`ifdef SIMULATION
`timescale 1ns/1ns
`endif

// Simulate driving the SDRAM module
// We may partially simulate the Chip enough so that module
// can move though its states properly.

`ifndef NRV_RESET_ADDR
 `define NRV_RESET_ADDR 0
`endif

`ifndef NRV_ADDR_WIDTH
 `define NRV_ADDR_WIDTH 32
`endif


module Top
(
	input logic sysClock
);

// ------------------------------------------------------------------
// Simulated BRAM Memory and Mapping
// ------------------------------------------------------------------
// (16384 * 4 =  64K) because each word is 32bits
// 16384 requires only 14 bits to address
localparam WORD = 4;
localparam NRV_RAM = 2**14 * WORD;
// localparam BIT_WIDTH = $clog2(NRV_RAM);

// $clog2(`NRV_RAM)-1
// logic [19:0] ram_word_address = mem_addr[21:2];
// logic [BIT_WIDTH-1:0] ram_word_address = mem_addr[BIT_WIDTH+1:2];
logic [13:0] ram_word_address;
assign ram_word_address = mem_addr[15:2];


// ----------- 0x00400000 ----------------
// 0000_0000_0100_0000_0000_0000_0000_0000
//            |                          |
//            \--- Bit 22                 \--- Bit 0
//
logic mem_address_is_ram;
assign mem_address_is_ram = !mem_addr[22] & mem_access;

(* no_rw_check *)
logic [31:0] RAM[0:(NRV_RAM/4)-1];
logic [31:0] ram_rdata;

// The power of YOSYS: it infers BRAM primitives automatically ! (and recognizes
// masked writes, amazing ...)
always_ff @(posedge sysClock) begin
	if (mem_address_is_ram) begin
		if (mem_wmask[0]) RAM[ram_word_address][ 7:0 ] <= mem_wdata[ 7:0 ];
		if (mem_wmask[1]) RAM[ram_word_address][15:8 ] <= mem_wdata[15:8 ];
		if (mem_wmask[2]) RAM[ram_word_address][23:16] <= mem_wdata[23:16];
		if (mem_wmask[3]) RAM[ram_word_address][31:24] <= mem_wdata[31:24];
	end

	ram_rdata <= RAM[ram_word_address];
end

initial begin
	`ifdef PRELOAD_MEMORY
		// FIRMWARE is defined in defines.sv
		$display("Using firmware: %s", `FIRMWARE);
		// $readmemh("../binaries/firmware.hex", RAM);
		$readmemh(`FIRMWARE, RAM);
	`endif
end

// Femto
// ------------------------------------------------------------------
// CPU
// ------------------------------------------------------------------
/* verilator lint_off UNUSED */
logic halt;

/* verilator lint_on UNUSED */
logic  [3:0] mem_wmask;   // mem write mask and strobe /write Legal values are 000,0001,0010,0100,1000,0011,1100,1111
logic [31:0] mem_rdata;   // processor <- (mem and peripherals) 
logic [31:0] mem_wdata;   // processor -> (mem and peripherals)
logic        mem_rstrb;   // Out: mem read strobe. Goes high to initiate memory reads.
logic        mem_rbusy;   // processor <- (mem and peripherals). Stays high until a read transfer is finished.
logic        mem_wbusy;   // processor <- (mem and peripherals). Stays high until a write transfer is finished.
logic        mem_wstrb;   // Validity strobes

assign mem_rdata = SDRAM_Selected ? sdram_rdata : ram_rdata;

/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */
logic        interrupt_request; // Active high
/* verilator lint_on UNDRIVEN */
logic        irq_acknowledge;	// Active high
logic        mem_access;
logic [31:0] mem_addr;      // Only 25 bits are used
/* verilator lint_on UNUSED */

// Both rbusy and wbusy are sourced by a single SDRAM "ready" flag.
// In the SoC they will need to be merged along with the other components,
// for example the UART's busy flag.

FemtoRV32 #(
	.ADDR_WIDTH(`NRV_ADDR_WIDTH),
	.RESET_ADDR(`NRV_RESET_ADDR)	      
) processor (
	.clk(clkDivider[0]),			
	.mem_addr(mem_addr),					// (out) to Ram
	.mem_wdata(mem_wdata),					// out
	.mem_wmask(mem_wmask),					// out (DQM) = strobe
	.mem_rdata(mem_rdata),					// in
	.mem_rstrb(mem_rstrb),					// out (Active high) = strobe
	.mem_rbusy(mem_rbusy),					// in: (High = busy)
	.mem_wbusy(mem_wbusy),					// in: (High = busy)
	.mem_access(mem_access),				// out (active high)
	.interrupt_request(interrupt_request),	// in
	.irq_acknowledge(irq_acknowledge),
	.reset(cpuReset),					// (in) Active Low
	.halt(halt)
);

// The combination of "ready" and "valid" means: if the input signals
// area valid and the SDRAM is in a ready state then an activity can take
// place.
/* verilator lint_off UNUSED */
logic sdram_ready;
/* verilator lint_on UNUSED */

logic sdram_initialized;
logic sdram_busy;

// -------------- Validity ---------------------------------------------------
assign mem_wstrb = |mem_wmask;      // Write strobe

// The busy flags indicate that a particular Activity (Read/Write) in progress.
// The boolean chart below is for SDRAM only.
// State: Ready = Low, Busy = High
//
// Sel  State | flag            == AND function
// 0     0    |  0  = Ready
// 0     1    |  0  = Ready
// 1     0    |  0  = Ready
// 1     1    |  1  = Busy
assign mem_wbusy = sdram_busy; //SDRAM_Selected & sdram_ready;
assign mem_rbusy = sdram_busy; //SDRAM_Selected & sdram_ready;  // High = busy

logic SDRAM_Selected;
assign SDRAM_Selected = (sdram_addr & 25'h00f0_0000) == 25'h0080_0000;

logic initiate_activity;
assign initiate_activity = mem_wstrb | mem_rstrb;

// Valid is used to signal that the client is ready for an Activity.
// The strobe signals will drive this as the strobes indicate that
// the IO signals are setup.
logic sdram_valid;
assign sdram_valid = initiate_activity & SDRAM_Selected;

// logic sdram_valid_nxt;

// ----------------------------------------------------------------------------

logic [24:0] sdram_addr;
assign sdram_addr = mem_addr[24:0];

logic [31:0] sdram_rdata;

// --------------- SDRAM outputs ------------------------
/* verilator lint_off UNUSED */
logic [12:0] sdram_a;
logic [15:0] sdram_dq;
logic        sdram_cs_n;
logic        sdram_cke;
logic        sdram_ras_n;
logic        sdram_cas_n;
logic        sdram_we_n;
logic  [1:0] sdram_dm;
logic  [1:0] sdram_ba;
logic        sdram_clock;
/* verilator lint_on UNUSED */
// -------------------------------------------------------

// 50000000 MHz = 20 ns(period)
//  100     100_000
// ----- = --------
//  us       ns
// SDRAM_CLK = 50_000_000Hz / 1_000_000 = 50

logic [1:0] clkDivider;     // Used only for Simulation, not good for synth.

sdram #() sdram_i (
	// ------ For SDRAM module -----------
    .clk(sysClock),
    .resetn(sdramReset),             // Active low

    .addr(sdram_addr),          // In:
    .din(mem_wdata),            // In: 32 bits
    .dout(sdram_rdata),         // Out: 32 bits
    .wmask(mem_wmask),          // In: Any bit that is set defines a write strobe
    .valid(sdram_valid),        // In: Indicates input signals are valid for use. Generally strobes
    .ready(sdram_ready),        // Out: Used for both read and write (High = busy)
    .initialized(sdram_initialized),
    .busy(sdram_busy),
    
	// ------ To SDRAM emu chip -----------
    .sdram_clk(sdram_clock),
    .sdram_cke(sdram_cke),
    .sdram_csn(sdram_cs_n),
    .sdram_rasn(sdram_ras_n),
    .sdram_casn(sdram_cas_n),
    .sdram_wen(sdram_we_n),
    .sdram_addr(sdram_a),
    .sdram_ba(sdram_ba),
    .sdram_dq(sdram_dq),            // In-out
    .sdram_dqm(sdram_dm)
	// -----------------------------------
);

// ------------------------------------------------------------------------
// SDRAM Emulation
// ------------------------------------------------------------------------
emu_ram #() emu_sdram (
    .sdram_clk(sdram_clock),
    .sdram_cke(sdram_cke),
    .sdram_csn(sdram_cs_n),
    .sdram_rasn(sdram_ras_n),
    .sdram_casn(sdram_cas_n),
    .sdram_wen(sdram_we_n),
    .sdram_addr(sdram_a),
    .sdram_ba(sdram_ba),
    .sdram_dq(sdram_dq),            // In-out
    .sdram_dqm(sdram_dm)
);

// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = SMReset;
SimState state_nxt;
logic sdramReset;
logic cpuReset = 0;

always_ff @(posedge sysClock) begin
    clkDivider <= clkDivider + 1;

    case (state)
        SMReset: begin
        end

        default: ;
    endcase

    state <= state_nxt;
end

always_comb begin
	sdramReset = 1'b1;	// Default as non-active
    cpuReset = 0;       // CPU is defaulted Reset

    case (state)
        SMReset: begin
			sdramReset = 1'b0;   // Reset SDRAM properly prior to init sequence.
            state_nxt = SimResetting;
        end

		SimResetting: begin
			sdramReset = 1'b0;
			state_nxt = SMState0;
		end

        SMState0: begin
			state_nxt = SMState0;
            if (sdram_initialized) begin
			    state_nxt = SMIdle;
            end
        end

        SMIdle: begin
            cpuReset = 1;    // Allow CPU to run
			state_nxt = SMIdle;
        end

        default: begin
            state_nxt = state;
        end
    endcase
end

endmodule
