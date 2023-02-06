`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// --------------------------------------------------------------------------
// Nx32 BRAM memory
// --------------------------------------------------------------------------
// The path to the data file is relative to the test bench (TB).
// If the TB is run from this directory then the path would be "ROM.dat"
// `define MEM_CONTENTS "ROM.dat"
// Otherwise it is relative to the TB.

// Use this define starting the ranger_console. It's just a dummy
// because you can simply "ld" what ever code you need via the simulation.
// `define MEM_CONTENTS "itype_csrs/intr1"

// Use this define to preload a specific ram during synthesis.

// OR
// `define ROM_PATH "/media/RAMDisk/"
// `define MEM_CONTENTS "code"

module Memory
#(
    parameter WORDS = 6,    // 32 cells
    parameter DATA_WIDTH = 32)
(
    input  logic                  clk_i,     // pos-edge
    input  logic [DATA_WIDTH-1:0] data_i,    // Memory data input
    input  logic [WORDS-1:0]      addr_i,    // Memory addr_i
    input  logic                  wr_i,      // Write enable (Active Low)
    input  logic                  rd_i,      // Read enable (Active Low)
    output logic [DATA_WIDTH-1:0] data_o     // Memory data output
);

/*verilator public_module*/

// Memory bank
//     #  of bits               # cells
logic [DATA_WIDTH-1:0] mem [(1<<WORDS)-1:0] /*verilator public*/;

initial begin
    // I can explicitly specify the start/end addr_i in order to avoid the
    // warning: "WARNING: memory.v:23: $readmemh: Standard inconsistency, following 1364-2005."
    //     $readmemh (`MEM_CONTENTS, mem, 'h00, 'h04);
    `ifdef USE_ROM
        // This only works with BRAM. It generally doesn't work with SPRAM constructs.
        // $display("Using ROM: %s", `MEM_CONTENTS);
        $readmemh ({`ROM_PATH, `MEM_CONTENTS, `ROM_EXTENSION}, mem);  // , 0, 6
    `elsif USE_STATIC
        $display("Using STATIC content");
        mem[0] =    32'h00000000;
        mem[1] =    32'h00000000;
        mem[2] =    32'h00000000;
        mem[3] =    32'h00000000;
        mem[4] =    32'h00000000;
        mem[5] =    32'h00000000;
        mem[6] =    32'h00000000;
        mem[7] =    32'h00000000;
        mem[8] =    32'h00000000;
        mem[9] =    32'h00000000;
        mem[10] =   32'h00000000;
        mem[11] =   32'h00000000;
        mem[12] =   32'h00000000;
        mem[13] =   32'h00000000;
        mem[14] =   32'h00000000;
        mem[15] =   32'h00000000;
        mem[16] =   32'h00000000;
        mem[17] =   32'h00000000;
        mem[18] =   32'h00000000;
        mem[19] =   32'h00000000;
        mem[20] =   32'h00000000;
        mem[21] =   32'h00000000;
        mem[22] =   32'h00000000;
    `endif

    `ifdef SHOW_MEMORY
        // Example of displaying contents
        $display("------- Top MEM contents ------");
        for(integer index = 0; index < 32; index = index + 1)
            $display("memory[%d] = %b <- %h", index[7:0], mem[index], mem[index]);
    `endif
end

// --------------------------------
// Dual Port RAM --  LP/HX and Ultra+ classes
// --------------------------------
always_ff @(posedge clk_i) begin
    if (~wr_i) begin
        mem[addr_i] <= data_i;
    end
end

always_ff @(posedge clk_i) begin
    if (~rd_i) begin
        data_o <= mem[addr_i];
    end
end

endmodule

