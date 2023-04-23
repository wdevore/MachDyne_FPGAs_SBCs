`ifndef NRV_RESET_ADDR
 `define NRV_RESET_ADDR 0
`endif

`ifndef NRV_ADDR_WIDTH
 `define NRV_ADDR_WIDTH 24
`endif

module SoC
(
	input  logic clk_48mhz,
	input  logic uart_rx_in,		// From client
	output logic uart_tx_out,		// To Client
	output logic [7:0] port_a,
	output logic port_lr,
	output logic port_lg,
	output logic port_lb
);

logic clk;
logic locked; // (Active high = locked)

// ------------------------------------------------------------------
// Clock
// ------------------------------------------------------------------
pll soc_pll (
    .clkin(clk_48mhz),
	.reset(reset),		// Expects Active High
    .clkout0(clk),		// ~10MHz
    .locked(locked)		// Active High
);

// ------------------------------------------------------------------
// Memory and Mapping
// ------------------------------------------------------------------
// (16384 * 4 =  64K) because each word is 32bits
// 16384 requires only 14 bits to address
localparam WORD = 4;
localparam NRV_RAM = 2**14 * WORD;
localparam BIT_WIDTH = $clog2(NRV_RAM);

logic mem_address_is_io  =  mem_address[22];
logic mem_address_is_ram = !mem_address[22];

// $clog2(`NRV_RAM)-1
// logic [19:0] ram_word_address = mem_address[21:2];
// logic [BIT_WIDTH-1:0] ram_word_address = mem_address[BIT_WIDTH+1:2];
logic [13:0] ram_word_address = mem_address[15:2];

// 256 IO addresses
logic [7:0] io_word_address = mem_address[7:0];
// 16 devices each with 16 address = 256
// The upper 4 bits selects the device.
logic [7:0] io_address = mem_address[7:0];

(* no_rw_check *)
logic [31:0] RAM[0:(NRV_RAM/4)-1];
logic [31:0] ram_rdata;

// The power of YOSYS: it infers BRAM primitives automatically ! (and recognizes
// masked writes, amazing ...)
always @(posedge clk) begin
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
	$readmemh("../binaries/firmware.hex",RAM);
	`endif
end


// ------------------------------------------------------------------
// IO
// ------------------------------------------------------------------
// Devices
localparam IO_PORT_A = 4'b0000;
localparam IO_UART = 4'b0001;

localparam LEDs = 0;
logic [31:0] io_rdata;
logic [3:0] io_device = io_address[7:4];

// -----------------------------------------------------------
// Port A
// -----------------------------------------------------------
logic port_a_wr = mem_address_is_io & (io_device == IO_PORT_A);
// assign port_lr = pllDelay[20];

always @(posedge clk) begin
	if (port_a_wr) begin
		// Write lower 8 bits to port A
		// port_a <= mem_wdata[7:0];

		// port_a <= {{reset, locked}, {state[1:0]}, mem_wdata[3:0]};
		port_a[7] <= pllLocked;
		port_a[6] <= state[2];
		port_a[5] <= state[1];
		port_a[4] <= state[0];
		port_a[3] <= mem_wdata[3];
		port_a[2] <= mem_wdata[2];
		port_a[1] <= mem_wdata[1];
		port_a[0] <= mem_wdata[0];
	end
end

// -----------------------------------------------------------
// UART Module
// -----------------------------------------------------------
logic uart_cs = mem_address_is_io & io_device == IO_UART;

// Address  |  Description
// --------- ---------------------------------
//   0      |  Control 1 register
//   1      |  Rx buffer (byte, read only)
//   2      |  Tx buffer (byte, write only)
logic [2:0] uart_addr = io_address[2:0]; // Only the lower 3 bits are needed

logic uart_wr = mem_wmask != 0 & mem_address_is_io;
logic uart_rd = mem_address_is_io;
logic [7:0] uart_out_data;
logic [7:0] uart_in_data;
logic uart_irq;
logic [2:0] uart_irq_id;

UART_Component uart_comp (
    .clock(clk),
    .reset(~reset),				// Active low
    .cs(~uart_cs),				// Active low
    .rd(~uart_rd),				// Active low
    .wr(~uart_wr),				// Active low
    .rx_in(uart_rx_in),         // From Client (bit)
    .tx_out(uart_tx_out),       // To Client (bit)
    .addr(uart_addr),
    .out_data(uart_out_data),	// Byte received
    .in_data(uart_in_data),		// Byte to transmit
    .irq(uart_irq),
    .irq_id(uart_irq_id)
);

// ----------- Reading -------------------
// Either reading from IO or Ram.
assign mem_rdata = mem_address_is_io ? io_rdata : ram_rdata;

// ------------------------------------------------------------------
// CPU
// ------------------------------------------------------------------
// The memory bus.
logic [31:0] mem_address; // 24 bits are used internally. The two LSBs are ignored (using word addresses)
logic  [3:0] mem_wmask;   // mem write mask and strobe /write Legal values are 000,0001,0010,0100,1000,0011,1100,1111
logic [31:0] mem_rdata;   // processor <- (mem and peripherals) 
logic [31:0] mem_wdata;   // processor -> (mem and peripherals)
logic        mem_rstrb;   // mem read strobe. Goes high to initiate memory write.
logic        mem_rbusy;   // processor <- (mem and peripherals). Stays high until a read transfer is finished.
logic        mem_wbusy;   // processor <- (mem and peripherals). Stays high until a write transfer is finished.
logic        interrupt_request = 0; // Active high

assign mem_wbusy = 0;
assign mem_rbusy = 0;
assign io_rdata = 0;
logic halt;

FemtoRV32 #(
	.ADDR_WIDTH(`NRV_ADDR_WIDTH),
	.RESET_ADDR(`NRV_RESET_ADDR)	      
) processor (
	.clk(clk),			
	.mem_addr(mem_address),		// (out) to Ram and peripherals
	.mem_wdata(mem_wdata),		// out
	.mem_wmask(mem_wmask),		// out
	.mem_rdata(mem_rdata),		// in
	.mem_rstrb(mem_rstrb),		// out
	.mem_rbusy(mem_rbusy),		// in
	.mem_wbusy(mem_wbusy),		// in
	.interrupt_request(interrupt_request),	// in
	.reset(~reset),				// (in) Active Low
	.halt(halt)
);

// ------------------------------------------------------------------
// SoC FSM
// ------------------------------------------------------------------
SynState state = SoCReset;
SynState next_state;
// PLL is active high
// CPU is active low
// UART is active low
// SoC reset is active high
logic reset;
logic [26:0] resetDelay;
logic [26:0] pllDelay;
logic pllLocked = 0;

always_comb begin
	next_state = SoCReset;
	reset = 1'b0;			// Reset disabled
	port_lr = 0;
	port_lb = 0;

	if (halt) 
		port_lr = 1;
	else
		port_lb = 1;

    case (state)
        SoCReset: begin
			reset = 1'b1;	// Start reset
            next_state = SoCResetting;
        end

		SoCResetting: begin
			next_state = SoCResetting;
			reset = 1'b1;

			// Hold reset for >(~1ms)
			if (resetDelay[15]) begin
				next_state = SoCDelayReset;
			end
		end

		SoCDelayReset: begin
			next_state = SoCDelayCnt;
		end

		SoCDelayCnt: begin
			next_state = SoCResetComplete;
		end

        SoCResetComplete: begin
			// The PLL needs ~16ms to lock so we wait.
			// The default Sticky state of the PLL is "unsticky"
			// which means the signal may simply pulse high.
			if (pllLocked) begin
				next_state = SoCIdle;
			end
			else
				next_state = SoCDelayCnt;
        end

        SoCIdle: begin
			next_state = SoCIdle;
        end

        default: begin
        end
    endcase
end

always_ff @(posedge clk_48mhz) begin
	resetDelay <= resetDelay + 1;
	pllDelay <= pllDelay + 1;

    case (state)
        SoCReset: begin
			resetDelay <= 0;
			pllDelay <= 0;
        end

		// SoCResetting: begin
		// end

		SoCDelayReset: begin
			pllDelay <= 0;
		end

		SoCDelayCnt: begin
			pllDelay <= pllDelay + 1;
		end

        SoCResetComplete: begin
			if (pllDelay[20]) begin
				pllLocked <= 1;
			end
        end

        SoCIdle: begin
        end

        default: begin
        end
    endcase

	state <= next_state;
end

endmodule
