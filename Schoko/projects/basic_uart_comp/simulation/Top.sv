
module Top
(
	input logic sysClock
);

logic reset;
logic uart_cs;
logic mem_rbusy; // (to cpu) active to initiate memory read (used by IO)
logic mem_rstrb; // (from cpu) asserted if memory is busy reading value
logic uart_wr;
logic [2:0] uart_addr;
/* verilator lint_off UNUSED */
logic [7:0] uart_out_data;
logic uart_irq;
logic [2:0] uart_irq_id;
logic tx_out;
logic [7:0] debug;
/* verilator lint_on UNUSED */
logic [7:0] uart_in_data;
logic rx_in;

UART_Component uart_comp (
    .clock(sysClock),
    .reset(reset),				// Active low
    .cs(uart_cs),				// Active low
    .rd_busy(mem_rbusy),		// (out) Active High
	.rd_strobe(mem_rstrb),		// Pulse High
    .wr(uart_wr),				// Active low
    .rx_in(rx_in),         	// From Client (bit)
    .tx_out(tx_out),       	// To Client (bit)
    .addr(uart_addr),
    .out_data(uart_out_data),	// Byte received
    .in_data(uart_in_data),		// Byte to transmit
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
	uart_wr = 1;
	rx_in = 1;			// Hold line high
	uart_cs = 1; 		// Disable
	uart_addr = 3'b000;	// Default to Control reg
    mem_rstrb = 1; // Deassert strobe

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
			// Load byte
			next_state = SMState1;
        end

        SMState1: begin
			uart_cs = 0; // Chip Enable
			uart_addr = 3'b010;	// Tx buffer
			next_state = SMState2;
        end

        SMState2: begin
			uart_cs = 0; // Chip Enable
			uart_wr = 0;	// Write to tx_buf
			uart_addr = 3'b010;	// Tx buffer
			next_state = SMState3;
        end

		// ------------------------------------------
        // Poll the busy bit in Control register
        SMState3: begin
			uart_cs = 0; // Chip Enable
            mem_rstrb = 0; // Assert strobe
			// Control reg address = default
			next_state = SMState4;
            if (~uart_out_data[1]) begin
    			next_state = SMIdle;
            end
        end

        SMState4: begin
			next_state = SMState3;
			uart_cs = 0; // Chip Enable
            mem_rstrb = 1; // Deassert strobe
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
			uart_in_data <= 8'h4F;  // Ascii "O"
        end

		// ------------------------------------------

        default: ;
    endcase

	state <= next_state;
end
endmodule
