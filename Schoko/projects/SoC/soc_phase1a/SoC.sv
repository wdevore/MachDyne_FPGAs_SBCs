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
	input  logic uart_rx_in,	// From client
	output logic uart_tx_out,	// To Client
	output logic [7:0] port_a,
	output logic port_lr,
	output logic port_lg,
	output logic port_lb
);

logic clk;
/* verilator lint_off UNUSEDSIGNAL */
logic locked; // (Active high = locked)
/* verilator lint_on UNUSEDSIGNAL */

// ------------------------------------------------------------------
// Clock. For testing
// ------------------------------------------------------------------
pll soc_pll (
    .clkin(clk_48mhz),
	.reset(0),		// It is not proper to reset the PLL after power up
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
// localparam BIT_WIDTH = $clog2(NRV_RAM);

// $clog2(`NRV_RAM)-1
// logic [19:0] ram_word_address = mem_address[21:2];
// logic [BIT_WIDTH-1:0] ram_word_address = mem_address[BIT_WIDTH+1:2];
logic [13:0] ram_word_address;
assign ram_word_address = mem_address[15:2];


// ----------- 0x00400000 ----------------
// 0000_0000_0100_0000_0000_0000_0000_0000
//            |                          |
//            \--- Bit 22                 \--- Bit 0
//
logic mem_address_is_io;
assign mem_address_is_io =  mem_address[22] & data_access;
logic mem_address_is_ram;
assign mem_address_is_ram = !mem_address[22] & !data_access;

(* no_rw_check *)
logic [31:0] RAM[0:(NRV_RAM/4)-1];
logic [31:0] ram_rdata;

// The power of YOSYS: it infers BRAM primitives automatically ! (and recognizes
// masked writes, amazing ...)
always_ff @(posedge clk) begin
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
// IO
// ------------------------------------------------------------------
// Devices
localparam IO_PORT_A = 8'h00;
localparam IO_UART = 8'h01;

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


// -----------------------------------------------------------
// Port A
// -----------------------------------------------------------
logic port_a_wr;
assign port_a_wr = mem_address_is_io & (io_device == IO_PORT_A);

// ------- Debug ------------
// assign port_a[0] = powerUpDelay[25];
// assign port_a[1] = systemReset;
// assign port_a[2] = 0;
// assign port_a[3] = 0;
// assign port_a[4] = 0;
// assign port_a[5] = 0;
// assign port_a[6] = 0;
// assign port_a[7] = 0;

always_ff @(posedge clk) begin
	if (port_a_wr) begin
		// Write lower 8 bits to port A
		port_a <= mem_wdata[7:0];
	end
end

// -----------------------------------------------------------
// UART Module
// -----------------------------------------------------------
logic uart_cs;
assign uart_cs = mem_address_is_io & (io_device == IO_UART);

// Address  |  Description
// --------- ---------------------------------
//   0      |  Control 1 register
//   1      |  Rx buffer (byte, read only)
//   2      |  Tx buffer (byte, write only)
logic [2:0] uart_addr; // Only the lower 3 bits are needed
assign uart_addr = io_address[2:0];


logic uart_wr;
assign uart_wr = uart_cs & (mem_wmask != 0);

logic [7:0] uart_out_data;
logic [7:0] uart_in_data;
/* verilator lint_off UNUSEDSIGNAL */
logic uart_irq;
logic [2:0] uart_irq_id;
logic [7:0] debug;
/* verilator lint_on UNUSEDSIGNAL */

UART_Component uart_comp (
    .clock(clk_48mhz),
    .reset(systemReset),		// Active low
    .cs(~uart_cs),				// Active low
    .rd_busy(mem_rbusy),		// (out) Active High
	.rd_strobe(mem_rstrb),		// Pulse High
    .wr(~uart_wr),				// Active low
    .rx_in(uart_rx_in),         // From Client (bit)
    .tx_out(uart_tx_out),       // To Client (bit)
    .addr(uart_addr),
    .out_data(uart_out_data),	// Byte received
    .in_data(uart_in_data),		// Byte to transmit
    .irq(uart_irq),
    .irq_id(uart_irq_id),
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

	if (uart_cs) begin
		io_rdata = {{24{1'b0}}, uart_out_data};
	end
end

// ----------- Reading -------------------
// Either reading from IO or Ram.
assign mem_rdata = mem_address_is_io ? io_rdata : ram_rdata;

// ------------------------------------------------------------------
// CPU
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
logic        interrupt_request = 0; // Active high
logic        data_access;

assign mem_wbusy = 0;
// logic halt;

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
	.data_access(data_access),	// out (active high)
	.interrupt_request(interrupt_request),	// in
	.reset(systemReset),					// (in) Active Low
	.halt(halt)
);

// ------------------------------------------------------------------
// SoC FSM
// ------------------------------------------------------------------
SynState state = SoCReset;
SynState next_state;

// systemReset starts active (low) and deactivates after a few milliseconds delay
logic systemReset = 1;		// Default to non-active
logic [26:0] powerUpDelay;

// PLL is active high
// CPU is active low
// UART is active low

always_comb begin
	next_state = SoCReset;
	port_lr = 0;
	port_lg = 0;
	port_lb = 0;
	
	if (halt) 
		port_lr = 1;
	else
		port_lg = 1;

    case (state)
        SoCReset: begin
            next_state = SoCResetting;
        end

		SoCResetting: begin
			port_lb = 1;
			next_state = SoCResetting;
`ifdef SIMULATION
			if (powerUpDelay[3]) begin
`else
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
