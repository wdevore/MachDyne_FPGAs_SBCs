`default_nettype none
`ifdef SIMULATE
`timescale 1ns/1ps
`endif

// This module simulates a CPU driving a UART module in a memory mapped arrangement.

// Simulate sending several bytes by following the Tx workflow.

module Top
(
    input logic  sysClock      // System High Freq Clock
);

// -----------------------------------------------------------
// Memory mapped UART Module
// -----------------------------------------------------------
UART_Component uart_uut (
    .clock(sysClock),
    .reset(reset),
    .cs(cs),
    .rd(rd),
    .wr(wr),
    .rx_in(rx_in[0]),           // Generally interfacing to hardware ports
    .tx_out(tx_out),         // Generally interfacing to hardware ports
    .addr(addr),
    .out_data(out_data),
    .in_data(in_data),
    .irq(irq),
    .irq_id(irq_id)
);

// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = SMReset0;
SimState next_state;

/* verilator lint_off UNUSED */
logic reset_complete;
logic [3:0] reset_cnt;
logic reset = 0;
logic rd;
logic wr;
logic irq;
logic [2:0] irq_id;
// Toggle this to simulate data in coming bits from a fake client
logic [7:0] rx_in;
logic tx_out;
logic [1:0] addr;
logic [7:0] out_data;
logic [7:0] in_data;
logic cs;
/* verilator lint_on UNUSED */

always_ff @(posedge sysClock) begin
    // --------------------------------
    // Reset
    // --------------------------------
    case (state)
        SMReset0: begin
            // $display("SMReset");
            reset_complete <= 0;
            reset_cnt <= 0;
            rd <= 1'b1;  // disable
            wr <= 1'b1;  // disable
            rx_in <= 0;
            addr <= 0;
            in_data <= 0;
            reset <= 0;
            cs <= 1;
        end

        SMReset1: begin
            // $display("SMReset1");
            if (reset_cnt == 4'b1111) begin
                reset_complete <= 1;
                reset <= 1;
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

always_comb begin
    next_state = SMReset0;

    // --------------------------------
    // Reset
    // --------------------------------
    case (state)
        SMReset0: begin
            // $display("SMReset");
            next_state = SMReset1;
        end

        SMReset1: begin
            next_state = SMReset1;

            // $display("SMReset1");
            if (reset_cnt == 4'b1111) begin
                next_state = SMResetComplete;
            end
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


endmodule
