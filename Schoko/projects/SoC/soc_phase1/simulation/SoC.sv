`ifndef NRV_RESET_ADDR
 `define NRV_RESET_ADDR 0
`endif

`ifndef NRV_ADDR_WIDTH
 `define NRV_ADDR_WIDTH 24
`endif

module SoC
(
	input  logic clk_48mhz,
	output logic [7:0] port_a
);

// The memory bus.
logic [31:0] mem_address; // 24 bits are used internally. The two LSBs are ignored (using word addresses)
logic  [3:0] mem_wmask;   // mem write mask and strobe /write Legal values are 000,0001,0010,0100,1000,0011,1100,1111
logic [31:0] mem_rdata;   // processor <- (mem and peripherals) 
logic [31:0] mem_wdata;   // processor -> (mem and peripherals)
logic        mem_rstrb;   // mem read strobe. Goes high to initiate memory write.
logic        mem_rbusy;   // processor <- (mem and peripherals). Stays high until a read transfer is finished.
logic        mem_wbusy;   // processor <- (mem and peripherals). Stays high until a write transfer is finished.
logic        interrupt_request;

logic clk;
logic locked;

// ------------------------------------------------------------------
// Clock
// ------------------------------------------------------------------
assign clk = clk_48mhz;

// ------------------------------------------------------------------
// IO
// ------------------------------------------------------------------
localparam LEDs = 0;

logic [31:0] io_rdata; 

// ------------------------------------------------------------------
// Memory and Mapping
// ------------------------------------------------------------------
`define NRV_RAM 65536

logic mem_address_is_io  =  mem_address[22];	// Mapped to 0x00400000
logic mem_address_is_ram = !mem_address[22];
logic [19:0] ram_word_address = mem_address[21:2];
// 256 IO addresses
logic [7:0] io_word_address = mem_address[7:0];

(* no_rw_check *)
logic [31:0] RAM[0:(`NRV_RAM/4)-1];
logic [31:0] ram_rdata;
// logic read_mem;

// The power of YOSYS: it infers BRAM primitives automatically ! (and recognizes
// masked writes, amazing ...)
/* verilator lint_off WIDTH */
always_ff @(posedge clk) begin
	if (mem_address_is_io) begin
		case (io_word_address)
			LEDs: begin
				// $display("Writing to IO: %h", mem_wdata);
				port_a <= mem_wdata[7:0];
			end
		endcase
	end
end

// Dual port RAM
always_ff @(posedge clk) begin
	if (mem_address_is_ram) begin
		// if (mem_wmask != 0) begin
		// 	read_mem <= 1;
		// 	$display("Writing '%h' at 0x%h : mask: %b", mem_wdata, ram_word_address, mem_wmask);
		// end
		if (mem_wmask[0]) RAM[ram_word_address][ 7:0 ] <= mem_wdata[ 7:0 ];
		if (mem_wmask[1]) RAM[ram_word_address][15:8 ] <= mem_wdata[15:8 ];
		if (mem_wmask[2]) RAM[ram_word_address][23:16] <= mem_wdata[23:16];
		if (mem_wmask[3]) RAM[ram_word_address][31:24] <= mem_wdata[31:24];	 
	end

	ram_rdata <= RAM[ram_word_address];
end
/* verilator lint_on WIDTH */

// ----------- Reading -------------------
// Either reading from IO or Ram.
assign mem_rdata = mem_address_is_io ? io_rdata : ram_rdata;

initial begin
	`ifdef PRELOAD_MEMORY
	$display("Preloading memory");
	$readmemh("../../binaries/firmware.hex",RAM);
	`endif

	`ifdef SHOW_MEMORY
	for (int i=0; i<20; i++) $display("%h: 0x%h",i*4, RAM[i]);
	`endif
end

// ------------------------------------------------------------------
// CPU
// ------------------------------------------------------------------
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
	.reset(reset),				// (in) Active Low
	.halt(halt)
);

// ------------------------------------------------------------------
// SoC FSM
// ------------------------------------------------------------------
SimState state = SMReset;
SimState next_state = SMReset;
logic reset;

always_ff @(posedge clk) begin
    case (state)
        SMReset: begin
            // Hold CPU in reset while Top module starts up.
            reset <= 1'b0;
			// read_mem <= 0;
        end

        SMResetComplete: begin
            reset <= 1'b1;
        end

        SMIdle: begin
        end

        default: begin
			$display("default............");
        end
    endcase

	state <= next_state;

end

always_comb begin
	next_state = SMReset;

    case (state)
        SMReset: begin
            next_state = SMResetComplete;
        end

        SMResetComplete: begin
			next_state = SMIdle;
        end

        SMIdle: begin
			next_state = SMIdle;
        end

        default: begin
        end
    endcase
end

endmodule
