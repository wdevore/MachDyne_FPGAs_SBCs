
// Transmit a byte into rx_in

module Top
(
	input logic sysClock
);

// This is used to send a byte to our UART component
logic ctx_cs;
logic ctx_en;
logic [7:0] ctx_buffer;
logic ctx_out;
logic ctx_complete;

UARTTx uart_tx (
    .sourceClk(sysClock),
    .reset(reset),              // Active low
	.cs(ctx_cs),
    .tx_en(ctx_en),
    .tx_byte(ctx_buffer),
    .tx_out(ctx_out),           // routed to UART's rx_in
    .tx_complete(ctx_complete)
);

logic reset;
logic uart_cs;
/* verilator lint_off UNUSED */
logic mem_rbusy; // (to cpu) active to initiate memory read (used by IO)
/* verilator lint_on UNUSED */
logic mem_rstrb; // (from cpu) asserted if memory is busy reading value
logic uart_wr;
logic [2:0] uart_addr;
logic [7:0] uart_out_data;
/* verilator lint_off UNUSED */
logic uart_irq;
logic [2:0] uart_irq_id;
logic tx_out;
logic [7:0] debug;
/* verilator lint_on UNUSED */
// logic [7:0] uart_in_data;
// logic rx_in;

UART_Component uart_comp (
    .clock(sysClock),
    .reset(reset),				// Active low
    .cs(uart_cs),				// Active low
    .rd_busy(mem_rbusy),		// (out) Active High
	.rd_strobe(mem_rstrb),		// Pulse High
    .wr(uart_wr),				// Active low
    .rx_in(ctx_out),       	    // From Client (bit)
    .tx_out(tx_out),       	    // To Client (bit)
    .addr(uart_addr),
    .out_data(uart_out_data),	// Byte received or Control reg
    .in_data(0),		// Byte to transmit
    .irq(uart_irq),
    .irq_id(uart_irq_id),
	.debug(debug)
);


// ------------------------------------------------------------------------
// State machine controlling simulation
// ------------------------------------------------------------------------
SimState state = SMReset;
SimState next_state;

always_comb begin
	next_state = SMReset;
	reset = 1'b1;		// Reset disabled
	uart_wr = 1;        // No writing just reading
	// rx_in = 1;			// Hold line high
	uart_cs = 1; 		// Disable
	uart_addr = 3'b000;	// Default to Control reg
    mem_rstrb = 0; // Deassert strobe
    ctx_en = 1;
    ctx_cs = 1;

    case (state)
        SMReset: begin
			reset = 1'b0;	// Start reset
            next_state = SimResetting;
        end

		SimResetting: begin
			reset = 1'b0;
			next_state = SMResetComplete;
		end

        SMResetComplete: begin
			next_state = SMState0;
        end

		// ------------------------------------------
        SMState0: begin
            // Load client transmitter

			// Begin "sending" bits to the component
			next_state = SMState1;
        end

        SMState1: begin
            next_state = SMState1;

            // Start transmitting
            ctx_en = 0;

            // We should poll the component's control register.
			// uart_cs = 0; // Chip Enable
			// uart_addr = 3'b000;	// Control reg
			// mem_rstrb = 1;	// Pulse the rd strobe (high)
			next_state = SMState2;

            // Wait for Trx to complete
            // if (ctx_complete) begin
            //     next_state = SMState2;
            // end
        end

        SMState2: begin
			uart_cs = 0; // Chip Enable
			next_state = SMState3;
        end

		// ------------------------------------------
        // Poll the busy bit in Control register
        SMState3: begin
			uart_cs = 0; // Chip Enable
            mem_rstrb = 1; // Assert strobe (pulse high)
			// Control reg address = default
			next_state = SMState4;
            // Bit 2 is the Byte-arrived flag
            if (uart_out_data[2]) begin
                // Now read the byte out of the component
    			next_state = SMState5;
            end
        end

        SMState4: begin
			next_state = SMState3;
			uart_cs = 1;
            mem_rstrb = 0; // Deassert strobe
        end

        SMState5: begin
			next_state = SMState6;
			uart_cs = 0; // Chip Enable
            mem_rstrb = 1; // Pulse high
            uart_addr = 3'b001;	// Rx buffer
        end

        SMState6: begin
			next_state = SMIdle;
			uart_cs = 0; // Chip Enable
            mem_rstrb = 0; // Deassert strobe
        end

        SMIdle: begin
			next_state = SMIdle;
        end

        default: ;
    endcase
end

always @(posedge sysClock) begin
    case (state)
		// ------------------------------------------
        SMState0: begin
            // Load client transmitter
			ctx_buffer <= 8'h3B;
        end

		// ------------------------------------------

        default: ;
    endcase

	state <= next_state;
end
endmodule
