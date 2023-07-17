`default_nettype none
`ifdef SIMULATION
`timescale 1ns/1ns
`endif

// This modules emulates a 16MBx16 SDRAM chip
// It is designed to interface directly to the sdram.v module.
// It's actually a few bytes of BRAM.
// Once enabled, we inspect the "command" to see how many clocks to wait and
// memory data to return.
// We also emulate a burst of 2 (upper half-word and lower half-word)

typedef enum logic [4:0] {
    RamCMD,
    RamNOP1,
    RamNOP2,
    RamIdle
} RAMState; 

module emu_ram (
    input logic sdram_clk,              // Sync clock
    input logic sdram_cke,              // Enable (Active high)
    input logic [1:0] sdram_dqm,        // Read/Write mask
    input logic [12:0] sdram_addr,      // A0-A12 row address, A0-A8 column address
    input logic [1:0] sdram_ba,         // bank select A11,A12
    input logic sdram_csn,              // Chip select (Active low)
    input logic sdram_wen,              // Write enable (Active low)
    input logic sdram_rasn,             // RAS as part of the command parameter (Active low)
    input logic sdram_casn,             // ditto

    inout logic [15:0] sdram_dq        // Data bus
);

localparam DATA_WIDTH = 16;
localparam HALF_WORDS = 16;

// logic [15:0] ram_d_in;
// assign ram_d_in = sdram_wen ? sdram_dq : 16'bz;

// logic [15:0] ram_d_out;
// assign sdram_dq = ~sdram_wen ? ram_d_out : 16'bz;

// Small BRAM of 16 words x 16 bits
// Memory bank
//     #  of bits               # cells
logic [DATA_WIDTH-1:0] mem [(1<<HALF_WORDS)-1:0] /*verilator public*/;

initial begin
    mem[0] =    16'h1297;       // Low
    mem[1] =    16'h0000;       // High
    mem[2] =    16'h8293;
    mem[3] =    16'h4002;
    mem[4] =    16'h0073;
    mem[5] =    16'h0010;
end

// ------------------------------------------------------------------------
// SDRAM
// ------------------------------------------------------------------------
localparam CMD_READ = 4'b0101;  // to have read variant with autoprecharge set A10=H
localparam CMD_WRITE = 4'b0100;  // A10=H to have autoprecharge
  
// Command = {CS, RAS, CAS, WE}
logic [3:0] command;
assign command = {sdram_csn, sdram_rasn, sdram_casn, sdram_wen};

// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
RAMState state = RamReset;
RAMState next_state;
logic reset;

always_comb begin
	next_state = RamIdle;

    case (state)
        RamIdle: begin
            if (command == CMD_READ)
			    next_state = RamRead;       // 3 states to complete
            if (command == CMD_WRITE)
			    next_state = RamWrite;
        end

        RamRead: begin
			next_state = RamWait1;
        end

        RamWait1: begin
			next_state = RamWait2;
        end

        RamWait2: begin
			next_state = RamReadL;
        end

        RamReadL: begin
			next_state = RamReadH;
        end

        RamReadH: begin
            next_state = SDIdle;
        end

        default: ;
    endcase
end

always @(posedge sdram_clk) begin

    case (state)

        RamReadL: begin
			next_state = RamReadH;
            sdram_dq[15:0] <= mem[sdram_addr[3:0]];
        end

        RamReadH: begin
            next_state = SDIdle;
            sdram_addr = sdram_addr+1;
            sdram_dq[31:16] <= mem[sdram_addr[3:0]];
        end

        default: ;
    endcase

	state <= next_state;
end


endmodule

    // if (SDRAM_Selected) begin
    //     if (mem_wstrb) begin
    //         case (sdram_state)
    //             RAMState0: begin
    //                 if (~sdram_ready) begin
    //                     sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
    //                     sdram_din <= mem_wdata;
    //                     sdram_wmask <= mem_wstrb;
    //                     sdram_state <= RAMState1;
    //                     sdram_valid <= 1;
    //                 end
    //             end

    //             RAMState1: begin
    //                 if (sdram_ready) begin
    //                     sdram_wmask <= 0;
    //                     sdram_valid <= 0;
    //                     sdram_state <= RAMState2;
    //                 end
    //             end

    //             RAMState2: begin
    //                 if (~sdram_ready) begin
    //                     mem_ready <= 1;
    //                     sdram_state <= RAMState0;
    //                 end
    //             end

    //             default: ;
    //         endcase
    //     end
    //     else begin
    //         case (sdram_state)
    //             RamState0: begin
    //                 if (~sdram_ready) begin
    //                     sdram_addr <= { (mem_addr & 32'h0fff_ffff) >> 2, 2'b00 };
    //                     sdram_valid <= 1;
    //                     sdram_state <= Ramtate1;
    //                 end
    //             end

    //             Ramtate1: begin
    //                 if (sdram_ready) begin
    //                     mem_rdata <= sdram_dout;
    //                     sdram_valid <= 0;
    //                     sdram_state <= Ramtate2;
    //                 end
    //             end

    //             Ramtate2: begin
    //                 if (~sdram_ready) begin
    //                     mem_ready <= 1;
    //                     sdram_state <= RamState0;
    //                 end
    //             end

    //             default: ;
    //         endcase
    //     end
    // end
