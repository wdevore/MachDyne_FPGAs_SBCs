// Interface to the SDRAM
// This module will request two half-words and assemble into a Word that
// is compatible with the 32bit Femto
//
// The module is has a mapping address. When the incoming address is within
// the address range the module will respond.

module SDRAM_Component
(
    input  logic clock,
    input  logic reset,             // Reset (active low)

    input  logic [31:0] mem_addr
    input  logic [31:0] mem_wdata,   // data to be written
    input  logic  [3:0] mem_wmask,   // write mask for the 4 bytes of each word
    output logic [31:0] mem_rdata,   // input lines for both data and instr
    input  logic        mem_rstrb,   // active to initiate memory read (used by IO)
    output logic        mem_rbusy,   // asserted if memory is busy reading value
    output logic        mem_wbusy,   // asserted if memory is busy writing value
);

// ----------------- SDRAM module --------------------------------
logic [2:0] sdram_state;

logic [24:0] sdram_addr;
logic [31:0] sdram_din;
logic [31:0] sdram_dout;
logic [3:0] sdram_wmask;
logic sdram_ready;
logic sdram_valid;

logic [12:0] sdram_a;
logic [15:0] sdram_dq;
logic sdram_cs_n;
logic sdram_cke;
logic sdram_ras_n;
logic sdram_cas_n;
logic sdram_we_n;
logic [1:0] sdram_dm;
logic [1:0] sdram_ba;
logic sdram_clock;

localparam SYSCLK = 50_000_000;

sdram #(
    .SDRAM_CLK_FREQ(SYSCLK / 1_000_000)
) sdram_i (
    .clk(clock),
    .resetn(reset),             // Active low
    .addr(sdram_addr),
    .din(sdram_din),
    .dout(sdram_dout),
    .wmask(sdram_wmask),
    .ready(sdram_ready),

	// ------ To SDRAM device -----------
    .sdram_clk(sdram_clock),
    .sdram_cke(sdram_cke),
    .sdram_csn(sdram_cs_n),
    .sdram_rasn(sdram_ras_n),
    .sdram_casn(sdram_cas_n),
    .sdram_wen(sdram_we_n),
    .sdram_addr(sdram_a),
    .sdram_ba(sdram_ba),
    .sdram_dq(sdram_dq),
    .sdram_dqm(sdram_dm),
	// -----------------------------------
    .valid(sdram_valid)
);

// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SDRAMState state = SDReset;
SDRAMState next_state;
logic reset;

always_comb begin
	next_state = SDReset;
	reset = 1'b1;	 // Default as non-active

    case (state)
        SDReset: begin
            // Simulate pushing button
			reset = 1'b0;	// Start reset
            next_state = SDResetting;
        end

		SDResetting: begin
			reset = 1'b0;
			next_state = SDIdle;
		end

        SDIdle: begin
            next_state = SDIdle;
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
            next_state = SDIdle;
        end

        default: ;
    endcase
end

logic SDRAM_Selected;
assign SDRAM_Selected = (mem_addr & 32'hf000_0000) == 32'h4000_0000;

always @(posedge sysClock) begin
    delayCnt <= delayCnt + 1;

    case (state)
        SMReset: begin
			sdram_state <= 0;
			sdram_valid <= 0;
        end

        default: ;
    endcase

    if (SDRAM_Selected) begin
        if (mem_wstrb) begin
            case (sdram_state)
                RAMState0: begin
                    if (~sdram_ready) begin
                        sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
                        sdram_din <= mem_wdata;
                        sdram_wmask <= mem_wstrb;
                        sdram_state <= RAMState1;
                        sdram_valid <= 1;
                    end
                end

                RAMState1: begin
                    if (sdram_ready) begin
                        sdram_wmask <= 0;
                        sdram_valid <= 0;
                        sdram_state <= RAMState2;
                    end
                end

                RAMState2: begin
                    if (~sdram_ready) begin
                        mem_ready <= 1;
                        sdram_state <= RAMState0;
                    end
                end

                default: ;
            endcase
        end
        else begin
            case (sdram_state)
                RamState0: begin
                    if (~sdram_ready) begin
                        sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
                        sdram_valid <= 1;
                        sdram_state <= Ramtate1;
                    end
                end

                Ramtate1: begin
                    if (sdram_ready) begin
                        mem_rdata <= sdram_dout;
                        sdram_valid <= 0;
                        sdram_state <= Ramtate2;
                    end
                end

                Ramtate2: begin
                    if (~sdram_ready) begin
                        mem_ready <= 1;
                        sdram_state <= RamState0;
                    end
                end

                default: ;
            endcase
        end
    end

	state <= next_state;
end

endmodule
