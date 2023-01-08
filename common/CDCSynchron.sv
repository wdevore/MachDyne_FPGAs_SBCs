`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// This a typical 2-FF + Rising/Falling CDC synchronizer.
module CDCSynchron
(
    input  logic        sysClk_i,    // Destination clock domain
    input  logic        async_i,     // Signal outside of domain
    output logic        sync_o,      // Synchronized signal
    output logic        rising_o,
    output logic        falling_o
);

// ------------------------------------------------------
// Manual bit register approach
// ------------------------------------------------------
logic bit0;
logic bit1;
logic bit2;

always @(posedge sysClk_i) begin
    bit2 <= bit1;
    bit1 <= bit0;
    bit0 <= async_i;
end

// Rising/Falling are pulled from Bits 2 and 1
assign rising_o = ( bit2 == 0 && bit1 == 1 );
assign falling_o = ( bit2 == 1 && bit1 == 0 );

// Sync is delayed by passing through Bits 1 and 0
assign sync_o = bit1;

endmodule

