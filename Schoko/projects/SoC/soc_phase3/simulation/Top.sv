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
    // Reset button is Active Low
);

logic systemReset = 1;		// Default to non-active

// Femto
// ------------------------------------------------------------------
// CPU
// ------------------------------------------------------------------
/* verilator lint_off UNUSED */
logic halt;
// The memory bus.
logic [31:0] mem_address; // 24 bits are used internally. The two LSBs are ignored (using word addresses)
/* verilator lint_on UNUSED */
logic  [3:0] mem_wmask;   // mem write mask and strobe /write Legal values are 000,0001,0010,0100,1000,0011,1100,1111
logic [31:0] mem_rdata;   // processor <- (mem and peripherals) 
logic [31:0] mem_wdata;   // processor -> (mem and peripherals)
logic        mem_rstrb;   // mem read strobe. Goes high to initiate memory write.
logic        mem_rbusy;   // processor <- (mem and peripherals). Stays high until a read transfer is finished.
logic        mem_wbusy;   // processor <- (mem and peripherals). Stays high until a write transfer is finished.
logic        interrupt_request; // Active high
logic        irq_acknowledge;	// Active high
logic        mem_access;

// Both rbusy and wbusy are sourced by a single SDRAM "ready" flag.
// In the SoC they will need to be merged along with the other components,
// for example the UART's busy flag.

FemtoRV32 #(
	.ADDR_WIDTH(`NRV_ADDR_WIDTH),
	.RESET_ADDR(`NRV_RESET_ADDR)	      
) processor (
	.clk(sysClock),			
	.mem_addr(mem_address),					// (out) to Ram
	.mem_wdata(mem_wdata),					// out
	.mem_wmask(mem_wmask),					// out (DQM) = strobe
	.mem_rdata(mem_rdata),					// in
	.mem_rstrb(mem_rstrb),					// out
	.mem_rbusy(mem_rbusy),					// in
	.mem_wbusy(mem_wbusy),					// in
	.mem_access(mem_access),				// out (active high)
	.interrupt_request(interrupt_request),	// in
	.irq_acknowledge(irq_acknowledge),
	.reset(systemReset),					// (in) Active Low
	.halt(halt)
);

// SDRAM
logic  [2:0] sdram_state;

logic [24:0] sdram_addr;
// logic [31:0] sdram_din;
// logic [31:0] sdram_dout;
// logic  [3:0] sdram_wmask;

// The combination of "ready" and "valid" means: if the input signals
// area valid and the SDRAM is in a ready state then an activity can take
// place.
logic        sdram_ready;

// Strobes usually indicate validity. For example, mem_rstrb or mem_wmask
logic        sdram_valid;
assign sdram_valid = mem_rstrb | (|mem_wmask);

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

localparam SYSCLK = 50_000_000;

assign mem_wbusy = |mem_wmask ? sdram_ready : 0;
assign mem_rbusy = ~(|mem_wmask) ? sdram_ready : 0;

sdram #(
    .SDRAM_CLK_FREQ(SYSCLK / 1_000_000)
) sdram_i (
	// ------ For SDRAM module -----------
    .clk(sysClock),
    .resetn(reset),             // Active low

    .addr(sdram_addr),          // In:
    .din(mem_wdata),            // 32 bits
    .dout(mem_rdata),           // 32 bits
    .wmask(mem_wmask),          // In: Any bit that is set defines a write strobe
    .valid(sdram_valid),        // Indicates input signals are valid for use.
    .ready(sdram_ready),        // Out: Used for both read and write (Active Low)

	// ------ To SDRAM chip -----------
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
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = SMReset;
SimState next_state;
logic reset;
logic [15:0] delayCnt;
logic transmitted;

always_comb begin
	next_state = SMReset;
	reset = 1'b1;	 // Default as non-active

    case (state)
        SMReset: begin
            // Simulate pushing button
			reset = 1'b0;	// Start reset
            next_state = SimResetting;
        end

		SimResetting: begin
			reset = 1'b0;
			next_state = SMIdle;
		end

        SMIdle: begin
            next_state = SMIdle;
        end

        SMState0: begin
			next_state = SMState1;
        end

        SMState1: begin
			next_state = SMState2;
        end

        SMState2: begin
			next_state = SMState3;
        end

        SMState3: begin
            next_state = SMIdle;
        end

        default: ;
    endcase
end

// logic SDRAM_Selected;
// assign SDRAM_Selected = (mem_addr & 32'hf000_0000) == 32'h4000_0000;

always @(posedge sysClock) begin
//     delayCnt <= delayCnt + 1;

//     case (state)
//         SMReset: begin
// 			sdram_state <= 0;
// 			sdram_valid <= 0;
//         end

//         default: ;
//     endcase

//     if (SDRAM_Selected) begin
//         if (mem_wstrb) begin
//             case (sdram_state)
//                 RAMState0: begin
//                     if (~sdram_ready) begin
//                         sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
//                         sdram_din <= mem_wdata;
//                         sdram_wmask <= mem_wstrb;
//                         sdram_state <= RAMState1;
//                         sdram_valid <= 1;
//                     end
//                 end

//                 RAMState1: begin
//                     if (sdram_ready) begin
//                         sdram_wmask <= 0;
//                         sdram_valid <= 0;
//                         sdram_state <= RAMState2;
//                     end
//                 end

//                 RAMState2: begin
//                     if (~sdram_ready) begin
//                         mem_ready <= 1;
//                         sdram_state <= RAMState0;
//                     end
//                 end

//                 default: ;
//             endcase
//         end
//         else begin
//             case (sdram_state)
//                 RamState0: begin
//                     if (~sdram_ready) begin
//                         sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
//                         sdram_valid <= 1;
//                         sdram_state <= Ramtate1;
//                     end
//                 end

//                 Ramtate1: begin
//                     if (sdram_ready) begin
//                         mem_rdata <= sdram_dout;
//                         sdram_valid <= 0;
//                         sdram_state <= Ramtate2;
//                     end
//                 end

//                 Ramtate2: begin
//                     if (~sdram_ready) begin
//                         mem_ready <= 1;
//                         sdram_state <= RamState0;
//                     end
//                 end

//                 default: ;
//             endcase
//         end
//     end

	state <= next_state;
end
endmodule
