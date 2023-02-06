`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

module DeMux2
#(
    parameter DATA_WIDTH = 32
)
(
   input  logic select,
   input  logic [DATA_WIDTH-1:0]  data_i,
   output logic [DATA_WIDTH-1:0]  data0_o,
   output logic [DATA_WIDTH-1:0]  data1_o
);

always_comb begin
    case (select)
        0: begin
            data0_o = data_i;
            data1_o = 0;
        end
        1: begin
            data0_o = 0;
            data1_o = data_i;
        end
    endcase
end

endmodule

