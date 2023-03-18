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
// Memory
// ------------------------------------------------------------------
`define NRV_RAM 65536

logic mem_address_is_io  =  mem_address[22];
logic mem_address_is_ram = !mem_address[22];
logic [19:0] ram_word_address = mem_address[21:2];

(* no_rw_check *)
logic [31:0] RAM[0:(`NRV_RAM/4)-1];
logic [31:0] ram_rdata;

// The power of YOSYS: it infers BRAM primitives automatically ! (and recognizes
// masked writes, amazing ...)
/* verilator lint_off WIDTH */
always @(posedge clk) begin
	if (mem_address_is_ram) begin
		if (mem_wmask[0]) RAM[ram_word_address][ 7:0 ] <= mem_wdata[ 7:0 ];
		if (mem_wmask[1]) RAM[ram_word_address][15:8 ] <= mem_wdata[15:8 ];
		if (mem_wmask[2]) RAM[ram_word_address][23:16] <= mem_wdata[23:16];
		if (mem_wmask[3]) RAM[ram_word_address][31:24] <= mem_wdata[31:24];	 
	end 
	ram_rdata <= RAM[ram_word_address];
end
/* verilator lint_on WIDTH */

initial begin
	// $readmemh("FIRMWARE/firmware.hex",RAM);
	RAM[0] = 32'h00000001;
	RAM[1] = 32'h00000002;

end

// ------------------------------------------------------------------
// CPU
// ------------------------------------------------------------------
FemtoRV32 #(
	.ADDR_WIDTH(`NRV_ADDR_WIDTH),
	.RESET_ADDR(`NRV_RESET_ADDR)	      
) processor (
	.clk(clk),
	.mem_addr(mem_address),
	.mem_wdata(mem_wdata),
	.mem_wmask(mem_wmask),
	.mem_rdata(mem_rdata),
	.mem_rstrb(mem_rstrb),
	.mem_rbusy(mem_rbusy),
	.mem_wbusy(mem_wbusy),
	.interrupt_request(interrupt_request),	      
	.reset(reset)				// Active Low
);

SimState state = SMReset;
SimState next_state = SMReset;
logic reset;

always_ff @(posedge clk) begin
    case (state)
        SMReset: begin
            // Hold CPU in reset while Top module starts up.
            reset <= 1'b0;
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

			port_a = mem_wdata[7:0];
        end

        default: begin
        end
    endcase
end

endmodule
