module SoC
(
	input  logic clk_48mhz,
	input  logic button_b1,
	// input  logic uart_rx_in,	// From client
	// output logic uart_tx_out,	// To Client
	output logic [7:0] port_a,
	output logic port_lr,
	output logic port_lg,
	output logic port_lb,

	// --------------- SDRAM ---------------------
	output [12:0] sdram_a,	// Address
	inout [15:0] sdram_dq,	// Data
	output sdram_cs_n,		// Chip select
	output sdram_cke,		// Clock enable
	output sdram_ras_n,
	output sdram_cas_n,
	output sdram_we_n,		// Write enable
	output [1:0] sdram_dm,	// Write strobe mask
	output [1:0] sdram_ba,	// Bank select
	output sdram_clock,
);

// ------------------------------------------------------------------
//  @audit-info Clocks.
// ------------------------------------------------------------------
// logic clk;
/* verilator lint_off UNUSED */
logic cpu_locked; // (Active high = cpu_locked)
/* verilator lint_on UNUSED */

logic high_clk;
/* verilator lint_off UNUSED */
logic high_locked;
/* verilator lint_on UNUSED */
logic sdram_clk;
logic cpu_clk;

ramPLL ram_pll (
    .clkin(clk_48mhz),
	.reset(1'b0),				// It is not proper to reset the PLL after power up
    .highClk(high_clk),			// 100MHz
	.sdramClk(sdram_clk),		// 50MHz
    .locked(high_locked)	// Active High
);

cpuPLL femto_pll (
    .clkin(high_clk),
	.reset(1'b0),				// It is not proper to reset the PLL after power up
    .cpuClk(cpu_clk),			// 10MHz
    .locked(cpu_locked)		// Active High
);

// ------------------------------------------------------------------
// @audit-info Port A
// ------------------------------------------------------------------
logic [7:0] port_a_nxt;
// assign port_a[0] = 0;
// assign port_a[1] = 0;
// assign port_a[2] = 0;
// assign port_a[3] = 0;
// assign port_a[4] = 0;
// assign port_a[5] = 0;
// assign port_a[6] = 0;
// assign port_a[7] = 0;


// ------------------------------------------------------------------
// @audit-info Simulated CPU signals
// ------------------------------------------------------------------
// logic mem_wstrb;
// logic mem_wstrb_nxt;
logic mem_rstrb;
logic mem_rstrb_nxt;

logic [31:0] mem_wdata;
logic [31:0] mem_wdata_nxt;
logic [3:0] mem_wmask;
logic [3:0] mem_wmask_nxt;

// ------------------------------------------------------------------
// @audit-info SDRAM
// ------------------------------------------------------------------
// The combination of "ready" and "valid" means: if the input signals
// area valid and the SDRAM is in a ready state then an activity can take
// place.
/* verilator lint_off UNUSED */
logic sdram_ready;
/* verilator lint_on UNUSED */

logic sdram_initialized;		// Sourced by SDRAM
logic sdram_busy;

logic [24:0] sdram_addr;
logic [24:0] sdram_addr_nxt;

logic [31:0] sdram_rdata;

logic initiate_activity;
assign initiate_activity = (|mem_wmask) | mem_rstrb;

logic mem_address_is_sdram = 1;
// Valid is used to signal that the client is ready for an Activity.
// The strobe signals will drive this as the strobes indicate that
// the IO signals are setup.
logic sdram_valid;
assign sdram_valid = initiate_activity & mem_address_is_sdram;

sdram #() sdram_i (
	// ------ For SDRAM module -----------
    .clk(sdram_clk),
    .resetn(sdramReset),             	// Active low

	// ------------ To CPU ----------------
    .addr(sdram_addr),          		// In:
    .din(mem_wdata),            		// In: 32 bits
    .dout(sdram_rdata),         		// Out: 32 bits
	// In: Any bit that is set defines a write strobe
    .wmask(mem_wmask),          		
	// In: Indicates input signals are valid for use.
    .valid(sdram_valid),        		
	// Out: Used for both read and write (High = busy)
    .ready(sdram_ready),        		
	// Out: Active High. To SoC to exit Initialization
    .initialized(sdram_initialized),	
    .busy(sdram_busy),					// Out: Active high
    
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

// ------------------------------------------------------------------
// @audit-info Resets
// ------------------------------------------------------------------
logic sdramReset;
// The SDRAM only requires 100us to initialize, but we wait 1ms
// At 10MHz a period is 100ns
// 1ms = 1_000_000ns. This means we need a counter size of 20+1 bits
// When the 21 bit becomes one we weould have waited a little over 1.5ms
//
// However, we can just wait for the module to signal us it has initialized


// ------------------------------------------------------------------
//  @audit-info SoC FSM
// ------------------------------------------------------------------
SynState state = SoCReset;
SynState state_nxt;

logic [31:0] dout;
logic [31:0] dout_nxt;

logic lock;
logic lock_nxt;

always_ff @(posedge sdram_clk) begin

	// if (~resetn) begin
	// 	state <= SoCReset;
	// end else begin
		state <= state_nxt;
		port_a[0] <= port_a_nxt[0];
		port_a[1] <= port_a_nxt[1];
		port_a[2] <= port_a_nxt[2];
		port_a[3] <= port_a_nxt[3];
		port_a[4] <= port_a_nxt[4];
		port_a[5] <= port_a_nxt[5];
		port_a[6] <= port_a_nxt[6];
		port_a[7] <= port_a_nxt[7];

		sdram_addr <= sdram_addr_nxt;
		mem_wdata <= mem_wdata_nxt;
		mem_wmask <= mem_wmask_nxt;
		mem_rstrb <= mem_rstrb_nxt;
		// mem_wstrb <= mem_wstrb_nxt;
		dout <= dout_nxt;

		if (button_b1)
			lock <= 0;		// Unlock
		else
			lock <= lock_next;
	// end

end

always_comb begin
    state_nxt = state;

	sdramReset = 1'b1;	// Default as non-active

	port_lr = 0;	// Default to off
	port_lg = 0;	
	port_lb = 0;	

	port_a_nxt[0] = port_a[0];
	port_a_nxt[1] = port_a[1];
	port_a_nxt[2] = port_a[2];
	port_a_nxt[3] = port_a[3];
	port_a_nxt[4] = port_a[4];
	port_a_nxt[5] = port_a[5];
	port_a_nxt[6] = port_a[6];
	port_a_nxt[7] = port_a[7];

	sdram_addr_nxt = sdram_addr;
	mem_wdata_nxt = mem_wdata;
	mem_wmask_nxt = mem_wmask;
	mem_rstrb_nxt = mem_rstrb;
	// mem_wstrb_nxt = mem_wstrb;

	dout_nxt = dout;
	lock_next = lock;

    case (state)
        SoCReset: begin
			sdramReset = 1'b0;   // Reset SDRAM properly prior to init sequence.
			port_a_nxt[0] = 0;
			port_a_nxt[1] = 0;
			port_a_nxt[2] = 0;
			port_a_nxt[3] = 0;
			port_a_nxt[4] = 0;
			port_a_nxt[5] = 0;
			port_a_nxt[6] = 0;
			port_a_nxt[7] = 0;
			mem_rstrb_nxt =  1'b0;
            state_nxt = SoCResetting;
			lock_next = 0;		// Next step not locked out
        end

		SoCResetting: begin
			sdramReset = 1'b0;
            state_nxt = SoCResetComplete;
		end

        SoCResetComplete: begin
			state_nxt = SoCResetComplete;
			// Wait for SDRAM to init.
			if (sdram_initialized)
				state_nxt = SoCSetupRead1;
        end

		// ---------------------------------------------
		// --------- Read Address 0 --------------------
		// ---------------------------------------------
        SoCSetupRead1: begin
			// port_a_nxt[0] = 1;
			// port_a_nxt[1] = 1;

			// sdram_addr_nxt = 25'b0;		// Address zero
			sdram_addr_nxt = 25'h00_0000;	// Address 1 (WA), 4 (BA)
			mem_wdata_nxt = 32'bz;			// Not writing
			mem_wmask_nxt = 4'b0000;		// No write mask either
			// mem_wstrb_nxt = 1'b0;		// Nor a write strobe
			// We set strobe on next cycle
			mem_rstrb_nxt = 1'b0;
			state_nxt = SoCSetupRead2;
        end

        SoCSetupRead2: begin
			// Generate strobe. This will initiate the activity which
			// will cause a the Valid signal to activate.
			mem_rstrb_nxt = 1'b1;
			state_nxt = SoCSetupRead3;
        end

        SoCSetupRead3: begin
			// Release strobe.
			mem_rstrb_nxt = 1'b0;
			state_nxt = SoCSetupRead4;
        end

        SoCSetupRead4: begin
			// Wait for the Ready signal (active high) go high
			// or Busy signal (active high) to go low.
			if (sdram_ready) begin
				// Data should be available
				dout_nxt = sdram_rdata;
				state_nxt = SoCSetupRead5;
			end
        end

        SoCSetupRead5: begin
			// Address 0 = 21305555
			//         4 = 51595451
			//         8 = 71531515
			// port_a_nxt[0] = 1;
			// port_a_nxt[1] = 0;

			port_a_nxt[0] = dout[24];
			port_a_nxt[1] = dout[25];
			port_a_nxt[2] = dout[26];
			port_a_nxt[3] = dout[27];
			port_a_nxt[4] = dout[28];
			port_a_nxt[5] = dout[29];
			port_a_nxt[6] = dout[30];
			port_a_nxt[7] = dout[31];

			// port_a_nxt[2] = button_b1;
			// port_a_nxt[3] = lock;

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead6;
			end
			else
				state_nxt = SoCSetupRead5;
        end

        SoCSetupRead6: begin
			// port_a_nxt[0] = 0;
			// port_a_nxt[1] = 1;

			port_a_nxt[0] = dout[16];
			port_a_nxt[1] = dout[17];
			port_a_nxt[2] = dout[18];
			port_a_nxt[3] = dout[19];
			port_a_nxt[4] = dout[20];
			port_a_nxt[5] = dout[21];
			port_a_nxt[6] = dout[22];
			port_a_nxt[7] = dout[23];

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead7;
			end
			else
				state_nxt = SoCSetupRead6;
        end

        SoCSetupRead7: begin
			// port_a_nxt[0] = 1;
			// port_a_nxt[1] = 1;

			port_a_nxt[0] = dout[08];
			port_a_nxt[1] = dout[09];
			port_a_nxt[2] = dout[10];
			port_a_nxt[3] = dout[11];
			port_a_nxt[4] = dout[12];
			port_a_nxt[5] = dout[13];
			port_a_nxt[6] = dout[14];
			port_a_nxt[7] = dout[15];

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead8;
			end
			else
				state_nxt = SoCSetupRead7;
        end

        SoCSetupRead8: begin
			// port_a_nxt[0] = 0;
			// port_a_nxt[1] = 0;
			// port_a_nxt[2] = 1;

			port_a_nxt[0] = dout[0]; // 0 08 16 24
			port_a_nxt[1] = dout[1]; // 1 09 17 25
			port_a_nxt[2] = dout[2]; // 2 10 18 26
			port_a_nxt[3] = dout[3]; // 3 11 19 27
			port_a_nxt[4] = dout[4]; // 4 12 20 28
			port_a_nxt[5] = dout[5]; // 5 13 21 29
			port_a_nxt[6] = dout[6]; // 6 14 22 30
			port_a_nxt[7] = dout[7]; // 7 15 23 31

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead9;
			end
			else
				state_nxt = SoCSetupRead8;
        end

		// ---------------------------------------------
		// --------- Read Address 4 --------------------
		// ---------------------------------------------
        SoCSetupRead9: begin
			// port_a_nxt[0] = 1;
			// port_a_nxt[1] = 1;

			sdram_addr_nxt = 25'h00_0004;	// Address 1 (WA), 4 (BA)
			mem_wdata_nxt = 32'bz;			// Not writing
			mem_wmask_nxt = 4'b0000;		// No write mask either (aka strobe)
			// mem_wstrb_nxt = 1'b0;		// Nor a write strobe
			// We set strobe on next cycle
			mem_rstrb_nxt = 1'b0;
			state_nxt = SoCSetupRead10;
        end

        SoCSetupRead10: begin
			// Generate strobe. This will initiate the activity which
			// will cause a the Valid signal to activate.
			mem_rstrb_nxt = 1'b1;
			state_nxt = SoCSetupRead11;
        end

        SoCSetupRead11: begin
			// Release strobe.
			mem_rstrb_nxt = 1'b0;
			state_nxt = SoCSetupRead12;
        end

        SoCSetupRead12: begin
			// Wait for the Ready signal (active high) go high
			// or Busy signal (active high) to go low.
			if (sdram_ready) begin
				// Data should be available
				dout_nxt = sdram_rdata;
				state_nxt = SoCSetupRead13;
			end
        end

        SoCSetupRead13: begin
			port_a_nxt[0] = dout[24];
			port_a_nxt[1] = dout[25];
			port_a_nxt[2] = dout[26];
			port_a_nxt[3] = dout[27];
			port_a_nxt[4] = dout[28];
			port_a_nxt[5] = dout[29];
			port_a_nxt[6] = dout[30];
			port_a_nxt[7] = dout[31];

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead14;
			end
			else
				state_nxt = SoCSetupRead13;
        end

        SoCSetupRead14: begin
			port_a_nxt[0] = dout[16];
			port_a_nxt[1] = dout[17];
			port_a_nxt[2] = dout[18];
			port_a_nxt[3] = dout[19];
			port_a_nxt[4] = dout[20];
			port_a_nxt[5] = dout[21];
			port_a_nxt[6] = dout[22];
			port_a_nxt[7] = dout[23];

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead15;
			end
			else
				state_nxt = SoCSetupRead14;
        end

        SoCSetupRead15: begin
			port_a_nxt[0] = dout[08];
			port_a_nxt[1] = dout[09];
			port_a_nxt[2] = dout[10];
			port_a_nxt[3] = dout[11];
			port_a_nxt[4] = dout[12];
			port_a_nxt[5] = dout[13];
			port_a_nxt[6] = dout[14];
			port_a_nxt[7] = dout[15];

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead16;
			end
			else
				state_nxt = SoCSetupRead15;
        end

        SoCSetupRead16: begin
			port_a_nxt[0] = dout[0]; // 0 08 16 24
			port_a_nxt[1] = dout[1]; // 1 09 17 25
			port_a_nxt[2] = dout[2]; // 2 10 18 26
			port_a_nxt[3] = dout[3]; // 3 11 19 27
			port_a_nxt[4] = dout[4]; // 4 12 20 28
			port_a_nxt[5] = dout[5]; // 5 13 21 29
			port_a_nxt[6] = dout[6]; // 6 14 22 30
			port_a_nxt[7] = dout[7]; // 7 15 23 31

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCIdle;
			end
			else
				state_nxt = SoCSetupRead17;
        end

		// ---------------------------------------------
		// --------- Write to Address 8 ----------------
		// ---------------------------------------------
        SoCSetupRead17: begin
			sdram_addr_nxt = 25'h00_0008;	// Address 1 (WA), 4 (BA)
			mem_wdata_nxt = 32'h1234_5678;	// Data to Write
			// The mask IS the strobe
			mem_wmask_nxt = 4'b0000;		// Start with 0's
			mem_rstrb_nxt = 1'b0;			// No read stobe
			// We set strobe on next cycle
			state_nxt = SoCSetupRead18;
        end

        SoCSetupRead18: begin
			// Generate strobe. This will initiate the activity which
			// will cause a the Valid signal to activate.
			mem_wmask_nxt = 4'b1111;
			state_nxt = SoCSetupRead19;
        end

        SoCSetupRead19: begin
			// Release strobe.
			mem_wmask_nxt = 4'b0000;
			state_nxt = SoCSetupRead20;
        end

        SoCSetupRead20: begin
			// Wait for the Ready signal (active high) go high
			// or Busy signal (active high) to go low.
			if (sdram_ready) begin
				// Data should have been written
				dout_nxt = sdram_rdata;
				state_nxt = SoCSetupRead21;
			end
        end

		// ---------------------------------------------
		// --------- Read Address 8 --------------------
		// ---------------------------------------------
        SoCSetupRead21: begin
			sdram_addr_nxt = 25'h00_0008;	// Address 1 (WA), 4 (BA)
			mem_wdata_nxt = 32'bz;			// Not writing
			mem_wmask_nxt = 4'b0;			// No write mask either (aka strobe)
			// mem_wstrb_nxt = 1'b0;			// Nor a write strobe
			// We set strobe on next cycle
			mem_rstrb_nxt = 1'b0;
			// state_nxt = SoCSetupRead22;
			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead22;
			end
			else
				state_nxt = SoCSetupRead21;
        end

        SoCSetupRead22: begin
			// Generate strobe. This will initiate the activity which
			// will cause a the Valid signal to activate.
			mem_rstrb_nxt = 1'b1;
			state_nxt = SoCSetupRead23;
        end

        SoCSetupRead23: begin
			// Release strobe.
			mem_rstrb_nxt = 1'b0;
			state_nxt = SoCSetupRead24;
        end

        SoCSetupRead24: begin
			// Wait for the Ready signal (active high) go high
			// or Busy signal (active high) to go low.
			if (sdram_ready) begin
				// Data should be available
				dout_nxt = sdram_rdata;
				state_nxt = SoCSetupRead25;
			end
        end

        SoCSetupRead25: begin
			port_a_nxt[0] = dout[24];
			port_a_nxt[1] = dout[25];
			port_a_nxt[2] = dout[26];
			port_a_nxt[3] = dout[27];
			port_a_nxt[4] = dout[28];
			port_a_nxt[5] = dout[29];
			port_a_nxt[6] = dout[30];
			port_a_nxt[7] = dout[31];

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead26;
			end
			else
				state_nxt = SoCSetupRead25;
        end

        SoCSetupRead26: begin
			port_a_nxt[0] = dout[16];
			port_a_nxt[1] = dout[17];
			port_a_nxt[2] = dout[18];
			port_a_nxt[3] = dout[19];
			port_a_nxt[4] = dout[20];
			port_a_nxt[5] = dout[21];
			port_a_nxt[6] = dout[22];
			port_a_nxt[7] = dout[23];

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead27;
			end
			else
				state_nxt = SoCSetupRead26;
        end

        SoCSetupRead27: begin
			port_a_nxt[0] = dout[08];
			port_a_nxt[1] = dout[09];
			port_a_nxt[2] = dout[10];
			port_a_nxt[3] = dout[11];
			port_a_nxt[4] = dout[12];
			port_a_nxt[5] = dout[13];
			port_a_nxt[6] = dout[14];
			port_a_nxt[7] = dout[15];

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCSetupRead28;
			end
			else
				state_nxt = SoCSetupRead27;
        end

        SoCSetupRead28: begin
			port_a_nxt[0] = dout[0]; // 0 08 16 24
			port_a_nxt[1] = dout[1]; // 1 09 17 25
			port_a_nxt[2] = dout[2]; // 2 10 18 26
			port_a_nxt[3] = dout[3]; // 3 11 19 27
			port_a_nxt[4] = dout[4]; // 4 12 20 28
			port_a_nxt[5] = dout[5]; // 5 13 21 29
			port_a_nxt[6] = dout[6]; // 6 14 22 30
			port_a_nxt[7] = dout[7]; // 7 15 23 31

			if (~button_b1 & ~lock) begin
				lock_next = 1;		// Prevent next step from moving forward.
				state_nxt = SoCIdle;
			end
			else
				state_nxt = SoCSetupRead28;
        end

		// ---------- IDLE ---------------------
        SoCIdle: begin
			port_a_nxt[0] = 1;
			port_a_nxt[1] = 0;
			port_a_nxt[2] = 0;
			port_a_nxt[3] = 0;
			port_a_nxt[4] = 0;
			port_a_nxt[5] = 0;
			port_a_nxt[6] = 0;
			port_a_nxt[7] = 1;

			state_nxt = SoCIdle;
        end

        default: begin
        end
    endcase
end

endmodule
