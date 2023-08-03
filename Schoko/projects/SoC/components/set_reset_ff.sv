`default_nettype none
`ifdef SIMULATION
`timescale 1ns/1ns
`endif

module set_reset_ff(
    output logic q,
    input  logic d1,
    input  logic clk,
    input  logic reset,
    input  logic set
);

always_ff @(posedge clk or posedge set or posedge reset) begin
    if (reset)
        q <= 1'b0;
    else if (set)
        q <= 1'b1;
    else
        q <= d1;
end

endmodule
