// https://www.fpga4student.com/2017/04/simple-debouncing-verilog-code-for.html
// Note: this actually generates a pulse based on the input.

module DebounceSimp (
	input  logic Clk,       // Slow clock
    input  logic in,
    output logic out
);
    logic ff1q_to_ff2d;
    logic ff2_out;
    
    assign out = ff1q_to_ff2d & ~ff2_out;
    
    DBdff ff1(
        .Clk(Clk),
        .enable(1),
        .D(in),
        .Q(ff1q_to_ff2d)
    );

    DBdff ff2(
        .Clk(Clk),
        .enable(1),
        .D(ff1q_to_ff2d),
        .Q(ff2_out)
    );

endmodule