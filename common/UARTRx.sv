`default_nettype none
`ifdef SIMULATE
`timescale 10ns/1ns
`endif

// UART receiver
// Receives a byte using 8N1 format
// The rx_start signal remains active for 1 baud

module UARTRx
(
    input  logic sourceClk,         // Source clock
    input  logic reset,             // Reset
    input  logic rx_in,             // Incoming bits
    input  logic rx_ack,            // Acknowledge the rx_complete signal
    output logic [7:0] rx_byte,     // Byte received
    output logic rx_start,          // Signal a byte has just arrived
    output logic rx_complete        // Signal a byte was received (active high) for 1 cycle.
);

RxState state = RxIdle;  // Default to 

// ----------------------------------------------------
// CDC Sync-ed signal for Rx
// ----------------------------------------------------
/* verilator lint_off UNUSED */
logic Rx_risingedge;
/* verilator lint_on UNUSED */
logic Rx_fallingedge;
logic Rx_sync;

CDCSynchron Rx_Sync (
    .sysClk_i(sourceClk),
    .async_i(rx_in),
    .sync_o(Rx_sync),
    .rising_o(Rx_risingedge),
    .falling_o(Rx_fallingedge)
);

// We want an extra bit for rollover therefore no "-1"
logic [`ACCUMULATOR_WIDTH:0] baud_counter;
logic baud_tick;
logic baud_half_tick;
logic baud_quarter_tick;

// A 3 bit counter to count the bits.
logic [2:0] bitCnt;
logic [7:0] rx_bits;

assign baud_tick = baud_counter[`ACCUMULATOR_WIDTH];
assign baud_half_tick = baud_counter[`ACCUMULATOR_WIDTH-1];
assign baud_quarter_tick = baud_counter[`ACCUMULATOR_WIDTH-2];

always_ff @(posedge sourceClk) begin
    baud_counter <= baud_counter + `ACCUM_INC;

    case (state)
        RxReset: begin
            rx_bits <= 0;
            rx_complete <= 0;
            rx_start <= 0;
            state <= RxIdle;
            baud_counter <= 0;
            rx_byte <= 0;
        end

        RxIdle: begin
            // Detect Start bit falling edge
            if (Rx_fallingedge) begin
                state <= RxStartBit;
                rx_start <= 1;          // Signal data is arriving
                rx_byte <= 0;
                rx_bits <= 0;
                baud_counter <= 0;
            end
        end

        RxStartBit: begin
            // hold for 1/2 bit period to shift to sample point position
            // which is half of a baud tick.
            if (baud_half_tick == 1'b1) begin
                state <= RxHalfBit;
                baud_counter <= 0;
            end
        end

        RxHalfBit: begin
            // hold for 1 bit period.
            if (baud_tick == 1'b1) begin
                state <= RxReceiving;
                rx_start <= 0;      // Signal no longer relevant
                baud_counter <= 0;
                // Sample first bit
                rx_bits <= {Rx_sync, rx_bits[7:1]};
                bitCnt <= 7;
            end
        end

        RxReceiving: begin
            // hold for 1 bit period
            if (baud_tick == 1'b1) begin
                if (bitCnt == 0) begin
                    state <= RxStopBit;
                end
                else begin
                    // Sample bit
                    rx_bits <= {Rx_sync, rx_bits[7:1]};
                    bitCnt <= bitCnt - 1;
                end

                baud_counter <= 0;
            end
        end

        RxStopBit: begin
            // Copy received byte into buffer
            rx_byte <= rx_bits;

            // Check for Idle state.
            // We wait for a 1/4 or full bit period.
            `ifdef ONE_STOP_BIT
            if (baud_quarter_tick == 1'b1 & Rx_sync == 1)
            `elsif TWO_STOP_BITS
            if (baud_tick == 1'b1 & Rx_sync == 1)
            `endif
            begin
                state <= RxComplete;
                baud_counter <= 0;
                bitCnt <= 0;
                // hold "complete" signal for at least 1 cycle
                rx_complete <= 1;
            end
        end

        RxComplete: begin
            // if (rx_ack) begin
                rx_complete <= 0;
                state <= RxIdle;
            // end
        end

        default: begin
        end
    endcase

    if (~reset)
        state <= RxReset;

end

endmodule

