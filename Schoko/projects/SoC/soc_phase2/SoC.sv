`ifndef NRV_RESET_ADDR
 `define NRV_RESET_ADDR 0
`endif

`ifndef NRV_ADDR_WIDTH
 `define NRV_ADDR_WIDTH 24
`endif

module SoC
(
	input  logic clk_48mhz,
	// input  logic uart_rx_in,		// From client
	// output logic uart_tx_out,		// To Client
	output logic [7:0] port_a
);

logic clk;
logic locked;

// ------------------------------------------------------------------
// Clock
// ------------------------------------------------------------------
pll soc_pll (
    .clkin(clk_48mhz),
	.reset(~reset),		// Expects Active High
    .clkout0(clk),		// ~10MHz
    .locked(locked)		// Active High
);

// ------------------------------------------------------------------
// Memory and Mapping
// ------------------------------------------------------------------
`define NRV_RAM 16384

logic mem_address_is_io  =  mem_address[22];
logic mem_address_is_ram = !mem_address[22];
logic [19:0] ram_word_address = mem_address[21:2];


(* no_rw_check *)
logic [31:0] RAM[0:(`NRV_RAM/4)-1];
logic [31:0] ram_rdata;

// logic [7:0] io_word_address = mem_address[7:0];

// The power of YOSYS: it infers BRAM primitives automatically ! (and recognizes
// masked writes, amazing ...)
always @(posedge clk) begin
	if (mem_address_is_ram) begin
		if (mem_wmask[0]) RAM[ram_word_address][ 7:0 ] <= mem_wdata[ 7:0 ];
		if (mem_wmask[1]) RAM[ram_word_address][15:8 ] <= mem_wdata[15:8 ];
		if (mem_wmask[2]) RAM[ram_word_address][23:16] <= mem_wdata[23:16];
		if (mem_wmask[3]) RAM[ram_word_address][31:24] <= mem_wdata[31:24];	 
	end

	// Unconditionally reading memory is part of the inference of dual-port memory
	ram_rdata <= RAM[ram_word_address];
end

initial begin
	// This will eventually be the boot Monitor.
	`ifdef PRELOAD_MEMORY
	$readmemh("binaries/firmware.hex",RAM);
	`endif
end


// ------------------------------------------------------------------
// IO
// ------------------------------------------------------------------
// Devices
localparam IO_PORT_A = 4'b0000;
localparam IO_UART = 4'b0001;

logic [31:0] io_rdata;
logic [3:0] io_device = io_address[7:4];

logic [7:0] io_word_address = mem_address[7:0];

always @(posedge clk) begin
	if (mem_address_is_io) begin
		case (io_word_address)
			8'b00000000: begin
				// $display("Writing to IO: %h", mem_wdata);
				port_a <= mem_wdata[7:0];
			end
		endcase
	end

	// if (port_a_cs) begin
	// 	port_a <= mem_wdata[7:0];
	// end
	
	// if (uart_cs & uart_rd) begin
	// 	// UART is only 8 bits, thus needing expanding
	// 	io_rdata <= {{24{1'b0}}, uart_out_data};
	// end

	// if (uart_cs & uart_wr) begin
	// 	uart_in_data <= mem_wdata[ 7:0 ];
	// end
end


// -----------------------------------------------------------
// Port A
// -----------------------------------------------------------
logic port_a_cs = mem_address_is_io & io_device == IO_PORT_A;

// -----------------------------------------------------------
// Memory mapped UART Module
// -----------------------------------------------------------
logic uart_cs = mem_address_is_io & io_device == IO_UART;

// Address  |  Description
// --------- ---------------------------------
//   0      |  Control 1 register
//   1      |  Rx buffer (byte, read only)
//   2      |  Tx buffer (byte, write only)
// logic [2:0] uart_addr = io_address[2:0]; // Only the lower 3 bits are needed

// logic uart_wr = mem_wmask != 0 & mem_address_is_io;
// logic uart_rd = mem_address_is_io;
// logic [7:0] uart_out_data;
// logic [7:0] uart_in_data;
// logic uart_irq;
// logic [2:0] uart_irq_id;

// UART_Component uart_comp (
//     .clock(clk),
//     .reset(reset),
//     .cs(~uart_cs),				// Active low
//     .rd(~uart_rd),				// Active low
//     .wr(~uart_wr),				// Active low
//     .rx_in(uart_rx_in),         // From Client (bit)
//     .tx_out(uart_tx_out),       // To Client (bit)
//     .addr(uart_addr),
//     .out_data(uart_out_data),	// Byte received
//     .in_data(uart_in_data),		// Byte to transmit
//     .irq(uart_irq),
//     .irq_id(uart_irq_id)
// );


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

assign mem_rbusy = 1;	// Never busy (at least for now)

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
	.mem_rbusy(mem_rbusy),		// in (Active low)
	.mem_wbusy(mem_wbusy),		// in
	.interrupt_request(interrupt_request),	// in
	.reset(reset)				// (in) Active Low
);

// ------------------------------------------------------------------
// SoC FSM
// ------------------------------------------------------------------
SynState state = SoCReset;
SynState next_state;
logic reset;  // Active low

always_comb begin
	next_state = SoCReset;
	reset = 1'b1;

    case (state)
        SoCReset: begin
			reset = 1'b0;
            next_state = SoCResetting;
        end

		SoCResetting: begin
			reset = 1'b0;
			next_state = SoCResetComplete;
		end

        SoCResetComplete: begin
			reset = 1'b0;
			next_state = SoCResetComplete;
			if (locked)
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

    // case (state)
    //     SoCReset: begin
    //     end

	// 	SoCResetting: begin
	// 	end

    //     SoCResetComplete: begin
    //     end

    //     SoCIdle: begin
    //     end

    //     default: begin
    //     end
    // endcase


	state <= next_state;

end

endmodule