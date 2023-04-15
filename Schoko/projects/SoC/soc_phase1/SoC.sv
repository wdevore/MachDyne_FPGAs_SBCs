`ifndef NRV_RESET_ADDR
 `define NRV_RESET_ADDR 0
`endif

`ifndef NRV_ADDR_WIDTH
 `define NRV_ADDR_WIDTH 24
`endif

module SoC
(
	input  logic clk_48mhz,
	output logic [7:0] port_a,
	output logic [7:0] port_b
);

// The memory bus.
logic [31:0] mem_address; // 24 bits are used internally. The two LSBs are ignored (using word addresses)
logic  [3:0] mem_wmask;   // mem write mask and strobe /write Legal values are 000,0001,0010,0100,1000,0011,1100,1111
logic [31:0] mem_rdata;   // processor <- (mem and peripherals) 
logic [31:0] mem_wdata;   // processor -> (mem and peripherals)
logic        mem_rstrb;   // mem read strobe. Goes high to initiate memory write.
logic        mem_rbusy;   // processor <- (mem and peripherals). Stays high until a read transfer is finished.
logic        mem_wbusy;   // processor <- (mem and peripherals). Stays high until a write transfer is finished.
logic        interrupt_request; // Active high

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
// IO
// ------------------------------------------------------------------
localparam LEDs = 0;
logic [31:0] io_rdata;

// ------------------------------------------------------------------
// Memory and Mapping
// ------------------------------------------------------------------
`define NRV_RAM 16384

logic mem_address_is_io  =  mem_address[22];
logic mem_address_is_ram = !mem_address[22];
logic [19:0] ram_word_address = mem_address[21:2];

// 256 IO addresses
logic [7:0] io_word_address = mem_address[7:0];

(* no_rw_check *)
logic [31:0] RAM[0:(`NRV_RAM/4)-1];
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

	if (mem_address_is_io) begin
		case (io_word_address)
			8'b00000000: begin
				// $display("Writing to IO: %h", mem_wdata);
				port_a <= mem_wdata[7:0];
			end
		endcase
	end

	ram_rdata <= RAM[ram_word_address];
end

initial begin
	`ifdef PRELOAD_MEMORY
	$readmemh("../binaries/firmware.hex",RAM);
	`endif
end

// ----------- Reading -------------------
// Either reading from IO or Ram.
assign mem_rdata = mem_address_is_io ? io_rdata : ram_rdata;
assign interrupt_request = 0;
assign mem_wbusy = 0;
assign mem_rbusy = 0;
assign io_rdata = 0;

// ------------------------------------------------------------------
// CPU
// ------------------------------------------------------------------
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
	.reset(reset)				// (in) Active Low
);

// assign port_a[0] = 1;
// assign port_a[1] = 1;
// assign port_a[2] = 1;
// assign port_a[3] = 1;
// assign port_a[4] = 1;
// assign port_a[5] = 1;
// assign port_a[6] = 1;
// assign port_a[7] = clk;

// ------------------------------------------------------------------
// SoC FSM
// ------------------------------------------------------------------
SynState state = SoCReset;
SynState next_state;
logic reset;

always_ff @(posedge clk_48mhz) begin
	// port_a[3] <= 0;

    case (state)
        SoCReset: begin
            // Hold CPU in reset while Top module starts up.
            reset <= 1'b0;
			// port_a[0] <= 1;
        end

		SoCResetting: begin
            reset <= 1'b0;
			// port_a[1] <= 1;
		end

        SoCResetComplete: begin
            reset <= 1'b1;
			// port_a[2] <= 1;
        end

        SoCIdle: begin
			// port_a[3] <= 1;
        end

        default: begin
        end
    endcase


	state <= next_state;

end

always_comb begin
	next_state = SoCReset;

	// port_a[0] = 0;
	// port_a[1] = 0;
	// port_a[2] = 0;
	// port_a[3] = 0;
	// port_a[4] = 0;
	// port_a[5] = 0;
	// port_a[6] = 0;
	// port_a[7] = 0;

    case (state)
        SoCReset: begin
			// port_a[0] = 1;
            next_state = SoCResetting;
        end

		SoCResetting: begin
			next_state = SoCResetComplete;
			// port_a[1] = 1;
		end

        SoCResetComplete: begin
			next_state = SoCResetComplete;
			// port_a[2] = 1;
			if (locked)
				next_state = SoCIdle;
        end

        SoCIdle: begin
			// port_a[3] = 1;

			next_state = SoCIdle;
        end

        default: begin
        end
    endcase
end

endmodule
