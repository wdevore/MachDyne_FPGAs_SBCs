`ifndef NRV_RESET_ADDR
 `define NRV_RESET_ADDR 0
`endif

`ifndef NRV_ADDR_WIDTH
 `define NRV_ADDR_WIDTH 32
`endif

module SoC
(
	input  logic clk_48mhz,
	input  logic manualReset,	// Active high
	output logic halt,			// Active high
	// The USB-UART pins are connected as:
	// Orange = B3 = Tx
	// Brown  = B4 = Rx
	// These pins are respective to the USB-UART and thus
	// Tx should be connected to UART-Module's Rx input
	// and Rx should be connected to Tx output.
	input  logic uart_rx_in,	// From client, B3 connect to this
	output logic uart_tx_out,	// To Client	B4 connects to this
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

	// Debug ----------------------------
    output logic [7:0] debug
);

// ------------------------------------------------------------------
//  @audit-info Clocks and PLLs
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
// logic vga_clk;
// logic vga_locked;

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

// vgaPLL vgasync_pll (
//  .clkin(high_clk),
// 	.reset(1'b0),				// It is not proper to reset the PLL after power up
//  .vgaClk(vga_clk),			// 25.1748 MHz
//  .locked(vga_locked)		// Active High
// );

// ------------------------------------------------------------------
//  @audit-info Memory and Mapping
// ------------------------------------------------------------------
// (16384 * 4 =  64K) because each word is 32bits
// 16384 requires only 14 bits to address
localparam WORD = 4;
localparam NRV_RAM = 2**14 * WORD;
// localparam BIT_WIDTH = $clog2(NRV_RAM);

// $clog2(`NRV_RAM)-1
// logic [19:0] ram_word_address = mem_address[21:2];
// logic [BIT_WIDTH-1:0] ram_word_address = mem_address[BIT_WIDTH+1:2];
logic [13:0] ram_word_address;
assign ram_word_address = mem_address[15:2];

// Bit 21->0     is BRAM
// Bit 22        is IO
// Bit 24,23     is SDRAM

localparam IO_MEM_MASK = 25'h01C00000;

// ------------------------------------------------------------------
//  @audit-info Mapping of IO
// ------------------------------------------------------------------
// ----------- 0x00400000 ----------------
// 0000_0001_1100_0000_0000_0000_0000_0000 = Mask = 1C
// 0000_0000_0100_0000_0000_0000_0000_0000
//            |                          |
//            \--- Bit 22                \--- Bit 0
logic mem_address_is_io;
// assign mem_address_is_io =  mem_address[22] & mem_access;
assign mem_address_is_io = ((mem_address & IO_MEM_MASK) == 25'h0040_0000) & mem_access;

// ------------------------------------------------------------------
//  @audit-info Mapping of sdram
// ------------------------------------------------------------------
logic mem_address_is_sdram;
// ----------- 0x00800000 -> 0x01800000 ----------------
// 0000_0001_1000_0000_0000_0000_0000_0000 = mask = 0x01800000
//         |-|                           |
//         \--- Bits 24,23               \--- Bit 0
// assign mem_address_is_sdram = ((sdram_addr & 25'h00f0_0000) == 25'h0080_0000) & mem_access;
// assign mem_address_is_sdram = ((mem_address & 25'h0180_0000) != 0) & mem_access;
// assign mem_address_is_sdram = (|mem_address[24:23]) & mem_access;
// ----------- 0x00800000  -> 0x01800000  ----------------
// 0000_0000_1000_0000_0000_0000_0000_0000
//         | |                           |
//         \-\--- Bit 24, 23             \--- Bit 0
assign mem_address_is_sdram = (mem_address[24] | mem_address[23]) & mem_access;

// ------------------------------------------------------------------
//  @audit-info Mapping of Ram
// ------------------------------------------------------------------
// ----------- 0x00400000 ----------------
// 0000_0000_0000_0000_0000_0000_0000_0000 = Mask
// 0000_0000_0010_0000_0000_0000_0000_0000
//             |                         |
//             \--- Bit 21    ->         \--- Bit 0
logic mem_address_is_ram;
// assign mem_address_is_ram = !mem_address[22] & mem_access;
assign mem_address_is_ram = ~mem_address_is_sdram & ~mem_address_is_io & mem_access;

(* no_rw_check *)
logic [31:0] RAM[0:(NRV_RAM/4)-1];
logic [31:0] ram_rdata;

// The power of YOSYS: it infers BRAM primitives automatically ! (and recognizes
// masked writes, amazing ...)
always_ff @(posedge cpu_clk) begin
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


// ------------------------------------------------------------------
// @audit-info IO
// ------------------------------------------------------------------
// Devices
localparam IO_PORT_A = 8'h00;
localparam IO_UART = 8'h01;
localparam IO_BLUE_LED = 8'h02;

logic [31:0] io_rdata;

// +++++++++++++++++++++++++++++++
// 256 devices each with 16 address = 4K locations
// +++++++++++++++++++++++++++++++
// 0000_0000_0100_0000_0000_0000_0000_0000
//                     ---------
//                       device
logic [7:0] io_device;
assign io_device = mem_address[15:8];

// 0000_0000_0100_0000_0000_0000_0000_0000
//                               ------+++
//                                address
logic [2:0] io_address;
assign io_address = mem_address[2:0];

// ------------------------------------------------------------------
// @audit-info LEDs
// ------------------------------------------------------------------
logic blue_led_wr;
assign blue_led_wr = mem_address_is_io & (io_device == IO_BLUE_LED);

always_ff @(posedge cpu_clk) begin
	if (blue_led_wr) begin
		// Write 1 bit to LED
		if (mem_wmask[0])
			port_lb = mem_wdata[0];
		else if (mem_wmask[1])
			port_lb = mem_wdata[8];
		else if (mem_wmask[2])
			port_lb = mem_wdata[16];
		else if (mem_wmask[3])
			port_lb = mem_wdata[24];
		else
			port_lb = mem_wdata[0];
	end
end

// ------------------------------------------------------------------
// @audit-info Port A
// ------------------------------------------------------------------
logic port_a_wr;
assign port_a_wr = mem_address_is_io & (io_device == IO_PORT_A);

// assign port_a[0] = powerUpDelay[25];
// assign port_a[1] = systemReset;
// assign port_a[2] = 0;
// assign port_a[3] = 0;
// assign port_a[4] = 0;
// assign port_a[5] = 0;
// assign port_a[6] = 0;
// assign port_a[7] = 0;

always_ff @(posedge cpu_clk) begin
	if (port_a_wr) begin
		// Write 8 bits to port A
		if (mem_wmask[0])
			port_a = mem_wdata[7:0];
		else if (mem_wmask[1])
			port_a = mem_wdata[15:8];
		else if (mem_wmask[2])
			port_a = mem_wdata[23:16];
		else if (mem_wmask[3])
			port_a = mem_wdata[31:24];
		else
			port_a = mem_wdata[7:0];
	end
end

// -------------- Validity ---------------------------------------------------
assign mem_wstrb = |mem_wmask;      // Write strobe

// logic SDRAM_Selected;
// assign SDRAM_Selected = (sdram_addr & 25'h00f0_0000) == 25'h0080_0000;

// ------------------------------------------------------------------
// @audit-info SDRAM
// ------------------------------------------------------------------

// The combination of "ready" and "valid" means: if the input signals
// area valid and the SDRAM is in a ready state then an activity can take
// place.
/* verilator lint_off UNUSED */
// logic sdram_ready;
// /* verilator lint_on UNUSED */

// logic sdram_initialized;		// Sourced by SDRAM
// logic sdram_busy;

// logic [24:0] sdram_addr;
// assign sdram_addr = mem_address[24:0];

// logic [31:0] sdram_rdata;

// logic initiate_activity;
// assign initiate_activity = mem_wstrb | mem_rstrb;

// // Valid is used to signal that the client is ready for an Activity.
// // The strobe signals will drive this as the strobes indicate that
// // the IO signals are setup.
// logic sdram_valid;
// assign sdram_valid = initiate_activity & mem_address_is_sdram;

// sdram #() sdram_i (
// 	// ------ For SDRAM module -----------
//     .clk(sdram_clk),
//     .resetn(sdramReset),             	// Active low

// 	// ------------ To CPU ----------------
//     .addr(sdram_addr),          		// In:
//     .din(mem_wdata),            		// In: 32 bits
//     .dout(sdram_rdata),         		// Out: 32 bits
// 	// In: Any bit that is set defines a write strobe
//     .wmask(mem_wmask),          		
// 	// In: Indicates input signals are valid for use.
//     .valid(sdram_valid),        		
// 	// Out: Used for both read and write (High = busy)
//     .ready(sdram_ready),        		
// 	// Out: Active High. To SoC to exit Initialization
//     .initialized(sdram_initialized),	
//     .busy(sdram_busy),					// Out: Active high
    
// 	// ------ To SDRAM chip -----------
//     .sdram_clk(sdram_clock),
//     .sdram_cke(sdram_cke),
//     .sdram_csn(sdram_cs_n),
//     .sdram_rasn(sdram_ras_n),
//     .sdram_casn(sdram_cas_n),
//     .sdram_wen(sdram_we_n),
//     .sdram_addr(sdram_a),
//     .sdram_ba(sdram_ba),
//     .sdram_dq(sdram_dq),            // In-out
//     .sdram_dqm(sdram_dm)
// 	// -----------------------------------
// );

// ------------------------------------------------------------------
// @audit-info UART
// ------------------------------------------------------------------
logic uart_cs;
assign uart_cs = mem_address_is_io & (io_device == IO_UART);

// Address  |  Description
// --------- ---------------------------------
//   0      |  Control 1 register
//   1      |  Rx buffer (byte, read only)
//   2      |  Tx buffer (byte, write only)
logic [2:0] uart_addr; // Only the lower 3 bits are needed
assign uart_addr = io_address[2:0];


logic uart_rbusy;
logic uart_wr;
assign uart_wr = uart_cs & (mem_wmask != 0);

logic [7:0] uart_out_data;
logic [7:0] uart_in_data;
/* verilator lint_off UNUSEDSIGNAL */
logic [2:0] uart_irq_id;
/* verilator lint_on UNUSEDSIGNAL */

UART_Component uart_comp (
    .clock(clk_48mhz),
    .reset(systemReset),		// Active low
    .cs(~uart_cs),				// Active low
    .rd_busy(uart_rbusy),		// (out) Active High
	.rd_strobe(mem_rstrb),		// Pulse High
    .wr(~uart_wr),				// Active low
    .rx_in(uart_rx_in),         // From Client (bit)
    .tx_out(uart_tx_out),       // To Client (bit)
    .addr(uart_addr),
    .out_data(uart_out_data),	// Byte received
    .in_data(uart_in_data),		// Byte to transmit
    .irq(interrupt_request),	// Routed to femto (active high)
    .irq_id(uart_irq_id),
	.irq_acknowledge(irq_acknowledge),	// Active high
	.debug(debug)
);

always_comb begin
	uart_in_data = 0;
	io_rdata = 0;

	if (uart_wr) begin
		// Select the appropriate byte wdata Word.
		if (mem_wmask[0])
			uart_in_data = mem_wdata[7:0];
		else if (mem_wmask[1])
			uart_in_data = mem_wdata[15:8];
		else if (mem_wmask[2])
			uart_in_data = mem_wdata[23:16];
		else
			uart_in_data = mem_wdata[31:24];
	end

	// Even though the UART component is 8bits it still must be
	// presented to Femto as 32bits and the byte must be positioned
	// in the correct byte location such that Femto's LOAD_byte
	// selects it based on the lower 2bits of the address.
	if (uart_cs) begin
		if (uart_addr[1:0] == 2'b00)
			io_rdata = {{24{1'b0}}, uart_out_data};
		else if (uart_addr[1:0] == 2'b01)
			io_rdata = {{16{1'b0}}, uart_out_data, {8{1'b0}}};
		else if (uart_addr[1:0] == 2'b10)
			io_rdata = {{8{1'b0}}, uart_out_data, {16{1'b0}}};
		else
			io_rdata = {uart_out_data, {24{1'b0}}};
	end
end

// ------------------------------------------------------------------
// @audit-info CPU
// ------------------------------------------------------------------
// The memory bus.
/* verilator lint_off UNUSEDSIGNAL */
logic [31:0] mem_address; // 24 bits are used internally. The two LSBs are ignored (using word addresses)
/* verilator lint_on UNUSEDSIGNAL */
logic  [3:0] mem_wmask;   // mem write mask and strobe /write Legal values are 000,0001,0010,0100,1000,0011,1100,1111
logic [31:0] mem_rdata;   // processor <- (mem and peripherals) 
logic [31:0] mem_wdata;   // processor -> (mem and peripherals)
logic        mem_rstrb;   // mem read strobe. Goes high to initiate memory write.
logic        mem_rbusy;   // processor <- (mem and peripherals). Stays high until a read transfer is finished.
logic        mem_wbusy;   // processor <- (mem and peripherals). Stays high until a write transfer is finished.
logic        interrupt_request; // Active high
logic        irq_acknowledge;	// Active high
logic        mem_access;
logic        mem_wstrb;   // Validity strobes

// ### ----------- Reading ------------------- ###
// Either reading from IO or Ram.
// assign mem_rdata = mem_address_is_io ? io_rdata : ram_rdata;
assign mem_rdata = mem_address_is_io ? io_rdata : mem_address_is_sdram ? sdram_rdata : ram_rdata;
// assign mem_rdata = mem_address_is_sdram ? sdram_rdata : ram_rdata;

// assign mem_rbusy = uart_rbusy;
assign mem_rbusy = ~uart_cs ? uart_rbusy : mem_address_is_sdram ? sdram_busy : 0;

// assign mem_wbusy = 0;
assign mem_wbusy = mem_address_is_sdram ? sdram_busy : 0;

FemtoRV32 #(
	.ADDR_WIDTH(`NRV_ADDR_WIDTH),
	.RESET_ADDR(`NRV_RESET_ADDR)	      
) processor (
	.clk(cpu_clk),			
	.mem_addr(mem_address),					// (out) to Ram and peripherals
	.mem_wdata(mem_wdata),					// out
	.mem_wmask(mem_wmask),					// out
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

// ------------------------------------------------------------------
// @audit-info Resets
// ------------------------------------------------------------------
logic sdramReset;
// systemReset starts active (low) and deactivates after a few milliseconds delay
logic systemReset = 1;		// Default to non-active
logic [26:0] powerUpDelay;


// ------------------------------------------------------------------
//  @audit-info SoC FSM
// ------------------------------------------------------------------
SynState state = SoCReset;
SynState next_state;

// PLL is active high
// CPU is active low
// UART is active low

always_comb begin
	sdramReset = 1'b1;	// Default as non-active
	next_state = SoCReset;
	port_lr = 0;
	port_lg = 0;
	
	if (halt) 
		port_lr = 1;
	else
		port_lg = 1;

    case (state)
        SoCReset: begin
			sdramReset = 1'b0;   // Reset SDRAM properly prior to init sequence.
            next_state = SoCResetting;
        end

		SoCResetSDRAM: begin
			sdramReset = 1'b0;
            next_state = SoCResetting;
		end

		SoCResetting: begin
			next_state = SoCResetting;
`ifdef SIMULATION
			if (powerUpDelay[3]) begin
`else
			// if (powerUpDelay[25] & sdram_initialized) begin // Hold reset for >(~250ms)
			if (powerUpDelay[25]) begin // Hold reset for >(~250ms)
`endif
				next_state = SoCResetComplete;
			end
		end

        SoCResetComplete: begin
			next_state = SoCSystemResetComplete;
        end

        SoCSystemResetComplete: begin
			next_state = SoCIdle;
        end

        SoCIdle: begin
			next_state = SoCIdle;
        end

        default: begin
        end
    endcase
end

always_ff @(posedge clk_48mhz) begin
	powerUpDelay <= powerUpDelay + 1;

    case (state)
        SoCReset: begin
			powerUpDelay <= 0;
			systemReset <= 0;
        end

        SoCResetComplete: begin
        end

        SoCSystemResetComplete: begin
			systemReset <= 1;
        end

        SoCIdle: begin
        end

        default: begin
        end
    endcase

	if (manualReset)
		state <= SoCReset;
	else
		state <= next_state;
end

endmodule