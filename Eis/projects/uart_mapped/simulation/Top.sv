`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// This module simulates a CPU driving a UART module in a memory mapped arrangement.

// Simulate sending several bytes by following the Tx workflow.

module Top
(
    input logic  pllClk_i      // System High Freq Clock (PLL)
);

// -----------------------------------------------------------
// Memory mapped UART Module
// -----------------------------------------------------------
UART_Component uart_uut (
    .clock(pllClk_i),
    .reset(reset),
    .rd(),
    .wr(),
    .rx_in(),
    .tx_out(),
    .addr(),
    .out_data(),
    .in_data()
);

// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = SMReset0;
SimState next_state;

/* verilator lint_off UNUSED */
logic reset_complete;
logic [3:0] reset_cnt;
logic reset;
logic rd;
logic wr;

/* verilator lint_on UNUSED */

always_comb begin
    next_state = SMReset0;
    reset = 1;

    // --------------------------------
    // Reset
    // --------------------------------
    case (state)
        SMReset0: begin
            // $display("SMReset");
            reset = 0;
            next_state = SMReset1;
        end

        SMReset1: begin
            next_state = SMReset1;

            // $display("SMReset1");
            if (reset_cnt == 4'b1111) begin
                next_state = SMResetComplete;
            end
            else
                reset = 0;
        end

        SMResetComplete: begin
            // $display("SMResetComplete");
            next_state = SMResetComplete;
        end

        default: begin
            $display("********* UNKNOWN STATE ***********");
        end

    endcase
end

always_ff @(posedge pllClk_i) begin
    // --------------------------------
    // Reset
    // --------------------------------
    case (state)
        SMReset0: begin
            // $display("SMReset");
            reset_complete <= 0;
            reset_cnt <= 0;
        end

        SMReset1: begin
            // $display("SMReset1");
            if (reset_cnt == 4'b1111) begin
                reset_complete <= 1;
            end
            reset_cnt <= reset_cnt + 1;
        end

        SMResetComplete: begin
            // $display("SMResetComplete");
            // next_state <= SMReset0;
        end

        default: begin
            $display("********* UNKNOWN STATE ***********");
        end

    endcase

    state <= next_state;
end

endmodule
