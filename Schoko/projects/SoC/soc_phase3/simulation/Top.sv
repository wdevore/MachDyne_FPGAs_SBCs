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
logic        mem_wstrb;   // Validity strobes

/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */
logic        interrupt_request; // Active high
/* verilator lint_on UNDRIVEN */
logic        irq_acknowledge;	// Active high
logic        mem_access;
/* verilator lint_on UNUSED */
logic [31:0] mem_addr;

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

logic mem_valid;          // Indicates input signals are valid for use.

// The combination of "ready" and "valid" means: if the input signals
// area valid and the SDRAM is in a ready state then an activity can take
// place.
logic        sdram_ready;
logic        sdram_valid;
logic [24:0] sdram_addr;
assign sdram_addr = mem_addr[24:0];

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

localparam SYSCLK = 50_000_000;

assign mem_wstrb = |mem_wmask;
assign mem_wbusy = mem_wstrb ? sdram_ready : 0;
assign mem_rbusy = ~(mem_wstrb) ? sdram_ready : 0;

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

// logic SDRAM_Selected;
// assign SDRAM_Selected = (sdram_addr & 25'h00f0_0000) == 25'h0080_0000;


// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state;
SimState state_nxt;
logic reset;

always_ff @(posedge sysClock) begin
    if (~reset) begin
        state <= SMReset;
        sdram_addr <= 0;        
    end
    else begin
        sdram_addr <= sdram_addr_nxt;
        mem_wdata <= sdram_din_nxt;
        mem_wmask <= sdram_wmask_nxt;
        sdram_valid <= sdram_valid_nxt;

        // sdram_state <= sdram_state_nxt;
    	state <= state_nxt;
    end
end

always_comb begin
    state_nxt = state;
	reset = 1'b1;	 // Default as non-active

    case (state)
        SMReset: begin
			reset = 1'b0;
            state_nxt = SimResetting;
        end

		SimResetting: begin
			reset = 1'b0;
			state_nxt = SMIdle;
		end

        SMState0: begin
			state_nxt = SMState0;
            if (~sdram_ready) begin
                // Setup for a Read cycle by preparing for the next clock
                sdram_addr_nxt = 25'h0080_0000;
                sdram_din_nxt = 0;
                sdram_wmask_nxt = mem_wstrb;
                sdram_state_nxt = SMState1;
                // Strobes usually indicate validity or readiness.
                sdram_valid_nxt = 1;
    			state_nxt = SMState1;
            end
        end

        SMState1: begin
			state_nxt = SMState2;
        end

        SMState2: begin
			state_nxt = SMState3;
        end

        SMState3: begin
            state_nxt = SMIdle;
        end

        default: begin
            state_nxt = state;
        end
    endcase
end

endmodule


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
