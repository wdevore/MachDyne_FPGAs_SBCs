// Bring together the CPU and UART.

module Top
(
	input logic sysClock
    // Reset button is Active Low
);

// --------------- IO -------------------
logic uart_rx_in;
logic uart_tx_out;
logic [7:0] port_a;
logic port_lr;
logic port_lg;
logic port_lb;

SoC soc(
    .clk_48mhz(sysClock),
	.manualReset(~reset),        // Active high
    // ------------------------------------------------
    // IO interface to external devices
    // ------------------------------------------------
    .uart_rx_in(uart_rx_in),
    .uart_tx_out(uart_tx_out),
    .port_a(port_a),
    .port_lr(port_lr),
    .port_lg(port_lg),
    .port_lb(port_lb)
);


// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = SMReset;
SimState next_state;
logic reset;

always_comb begin
	next_state = SMReset;
	reset = 1'b1;	// Default to disabled

    case (state)
        SMReset: begin
            // Simulate pushing button
			reset = 1'b0;	// Start reset
            next_state = SimResetting;
        end

		SimResetting: begin
			reset = 1'b0;
			next_state = SMIdle;
		end

        SMIdle: begin
			next_state = SMIdle;
        end

        default: ;
    endcase
end

always @(posedge sysClock) begin
	state <= next_state;
end
endmodule
