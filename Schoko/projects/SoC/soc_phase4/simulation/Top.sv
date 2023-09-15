// Bring together the CPU and UART.

module Top
(
	input logic sysClock
    // Reset button is Active Low
);

// -----------------------------------------------------------
// Simulate a "Go" client sending data to our SoC using
// a transmitter.
// -----------------------------------------------------------
logic ctx_cs;
logic ctx_en;
logic [7:0] ctx_buffer;
logic ctx_out;
logic ctx_complete;

UARTTx uart_tx (
    .sourceClk(sysClock),
    .reset(~reset),             // Active low
	.cs(ctx_cs),                // Active high
    .tx_en(ctx_en),
    .tx_byte(ctx_buffer),
    .tx_out(ctx_out),           // routed to SoC's UARTRx rx_in
    .tx_complete(ctx_complete)
);

// --------------- IO -------------------
/* verilator lint_off UNUSEDSIGNAL */
logic uart_tx_out;          // Don't care
logic [7:0] port_a;
logic port_lr;              // Don't care
logic port_lg;              // Don't care
logic port_lb;              // Don't care
logic [7:0] debug;          // Don't care
/* verilator lint_on UNUSEDSIGNAL */

logic halt;

SoC soc(
    .clk_48mhz(sysClock),
	.manualReset(reset),        // Active high
    .halt(halt),                 // Active high
    // ------------------------------------------------
    // IO interface to external devices
    // ------------------------------------------------
    .uart_rx_in(ctx_out),
    .uart_tx_out(uart_tx_out),
    .port_a(port_a),
    .port_lr(port_lr),
    .port_lg(port_lg),
    .port_lb(port_lb),
    .debug(debug)
);


// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = SMReset;
SimState next_state;
logic reset;
logic [15:0] delayCnt;
logic transmitted;

always_comb begin
	next_state = SMReset;
	reset = 1'b0;	 // Default as non-active
    ctx_en = 1;      // Disable transmitting
    ctx_cs = 0;      // Deselect Tx

    case (state)
        SMReset: begin
            // Simulate pushing button
			reset = 1'b1;	// Start reset
            next_state = SimResetting;
        end

		SimResetting: begin
			reset = 1'b1;
			next_state = SMIdle;
		end

        SMIdle: begin
            next_state = SMIdle;

            if (halt)
			    next_state = SMReset;
            else begin
                // 224 = 70
                // 256 = 80
                if (delayCnt == 16'h0080 & ~transmitted) begin
                    next_state = SMState0;
                end
            end
        end

        SMState0: begin
			next_state = SMState1;
        end

        SMState1: begin
            // Data is loaded
            ctx_cs = 1;
			next_state = SMState2;
        end

        SMState2: begin
            ctx_cs = 1;
            ctx_en = 0;      // Start transmitting
			next_state = SMState3;
        end

        SMState3: begin
            ctx_cs = 1;
			next_state = SMState3;
            if (ctx_complete) begin
    			next_state = SMIdle;
            end
        end

        default: ;
    endcase
end

always @(posedge sysClock) begin
    delayCnt <= delayCnt + 1;

    case (state)
        SMReset: begin
            transmitted <= 0;
        end

        SMState0: begin
            // Load client transmitter
			ctx_buffer <= 8'h62;
        end

        SMState3: begin
            if (ctx_complete) begin
                transmitted <= 1;
            end
        end

        default: ;
    endcase

	state <= next_state;
end
endmodule
