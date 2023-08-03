`default_nettype none
`ifdef SIMULATION
`timescale 1ns/1ns
`endif

// This modules very partially emulates a 16MBx16 SDRAM chip
// It is designed to interface directly to the sdram.v module.
// In reality it's actually a few bytes of BRAM.
// Once enabled, we inspect the "command" to see how many clocks to wait and
// memory data to return.
// We emulate a burst of 2 (upper half-word and lower half-word)

typedef enum logic [4:0] {
    RamRead,
    RamReadL,
    RamReadH,
    RamWrite,
    RamReset,
    RamIdle
} RAMState; 

module emu_ram (
    input logic sdram_clk,              // Sync clock
    /* verilator lint_off UNUSED */
    input logic sdram_cke,              // Enable (Active high)
    /* verilator lint_on UNUSED */
    input logic sdram_csn,              // Chip select (Active low)
    input logic sdram_rasn,             // RAS as part of the command parameter (Active low)
    input logic sdram_casn,             // ditto
    input logic sdram_wen,              // Write enable (Active low)
    /* verilator lint_off UNUSED */
    input logic [12:0] sdram_addr,      // A0-A12 row address, A0-A8 column address
    input logic [1:0] sdram_ba,         // bank select A11,A12
    /* verilator lint_on UNUSED */
    output logic [15:0] sdram_dq,        // Data bus
    /* verilator lint_off UNUSED */
    input logic [1:0] sdram_dqm         // Read/Write mask
    /* verilator lint_on UNUSED */
);

localparam DATA_WIDTH = 16;
localparam HALF_WORDS = 16;

logic [15:0] sdram_dq_nxt;        // Data bus

// logic [15:0] ram_d_in;
// assign ram_d_in = sdram_wen ? sdram_dq : 16'bz;

// logic [15:0] ram_d_out;
// assign sdram_dq = ~sdram_wen ? sdram_dq_nxt : 16'bz;

// Small BRAM of 16 words x 16 bits
// Memory bank
//     #  of bits               # cells
logic [DATA_WIDTH-1:0] mem [(1<<HALF_WORDS)-1:0] /*verilator public*/;

logic reset = 1;

initial begin
    mem[0] =    16'h1297;       // Low
    mem[1] =    16'h0000;       // High
    mem[2] =    16'h8293;
    mem[3] =    16'h4002;
    mem[4] =    16'h0073;
    mem[5] =    16'h0010;
end

// Command = {CS, RAS, CAS, WE}
logic [3:0] command;
assign command = {sdram_csn, sdram_rasn, sdram_casn, sdram_wen};

logic [12:0] address;
logic [12:0] address_nxt;

// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
RAMState state = RamIdle;
RAMState state_nxt;

logic [3:0] wait_states;
logic [3:0] wait_states_nxt;

always @(posedge sdram_clk) begin
    if (~reset) begin
        // wait_states <= 0;
        // address <= 0;
    end
    else begin
        state <= state_nxt;
        address <= address_nxt;
        wait_states <= wait_states_nxt;
        sdram_dq <= sdram_dq_nxt;
    end
end

// assign sdram_dq = state == RamReadL ? sdram_dq_nxt : 16'bz;
// assign sdram_dq = mem[{12'b0, address[3:0]}];
// assign sdram_dq = 16'h66;

always_comb begin
	state_nxt = state;
    address_nxt = address;
    wait_states_nxt = wait_states;
    sdram_dq_nxt = sdram_dq;
    // sdram_dq = 16'bz;

    case (state)
        RamIdle: begin
            if (command == CMD_READ) begin
                wait_states_nxt = 1; // TRCD + CAS  = 2 + 2 = 4
                address_nxt = {9'b0,sdram_addr[3:0]};
			    state_nxt = RamRead;       // 3 states to complete
            end
            if (command == CMD_WRITE)
			    state_nxt = RamWrite;
        end

        RamRead: begin
            wait_states_nxt = wait_states - 1;
            if (wait_states == 1) begin
                wait_states_nxt = 1; // TTRP  = 2 = 2
                state_nxt = RamReadL;
            end
        end

        RamReadL: begin
            wait_states_nxt = wait_states - 1;
            if (wait_states == 1) begin
                sdram_dq_nxt = mem[{12'b0, address[3:0]}];
                $display("RamReadL: %h at: %h", mem[{12'b0, address[3:0]}], address);
                address_nxt = address_nxt + 1;
                state_nxt = RamReadH;
            end
        end

        RamReadH: begin
            sdram_dq_nxt = mem[{12'b0, address[3:0]}];
            $display("RamReadH: %h at: %h", mem[{12'b0, address[3:0]}], address);
            state_nxt = RamIdle;
        end

        default: ;
    endcase
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
