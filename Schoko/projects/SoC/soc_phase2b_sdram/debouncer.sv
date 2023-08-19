// https://www.digikey.com/en/articles/how-to-debounce-a-button-input-using-programmable-logic?article_name=how_to_debounce_a_button_&utm_campaign=techzone&utm_content=digikey&utm_medium=social&utm_source=twitter
// https://verilogguide.readthedocs.io/en/latest/verilog/vvd.html

module modeN_ctr #(
    parameter N = 10,
    parameter WIDTH = 5
) (
	input  logic Clk,
	input  logic clear,             // Active high
    input  logic enable,            // Active low
	output logic [WIDTH-1:0] cout
);
    always_ff @(posedge Clk) begin
        if (clear) begin
            out <= 0;
        end
        else begin
            if (out == N-1)
                out <= 0;
            else if (~enable)
                out <= out + 1;
        end
    end
endmodule

module Debouncer (
	input  logic Clk,
    input  logic in,
    output logic out
);
    logic cout;
    logic ff1q_to_ff2d;
    logic ff2_out;
    
    logic exor;
    assign exor = ff1q_to_ff2d ^ ff2_out;
    
    modeN_ctr counter (
        .Clk(clk_48mhz),
        .clear(exor),
        .enable(cout),
        .cout(cout)
    );

    DBdff ff1(
        .Clk(clk_48mhz),
        .enable(1),
        .D(in),
        .Q(ff1q_to_ff2d)
    );

    DBdff ff2(
        .Clk(clk_48mhz),
        .enable(1),
        .D(ff1q_to_ff2d),
        .Q(ff2_out)
    );

    DBdff ff3(
        .Clk(clk_48mhz),
        .enable(cout),
        .D(ff2_out),
        .Q(out)
    );

endmodule