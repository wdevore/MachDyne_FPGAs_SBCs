`default_nettype none
`ifdef SIMULATE
`timescale 10ns/1ns
`endif

// UART Component
// It is mapped into memory. You only interact via memory mapped addresses.

// Control register is address 0
// Input/Output Data is address 1

module UART_Component
(
    input  logic clock,             // System clock
    input  logic reset,             // Reset
    input  logic cs,                // Chip select
    input  logic rd,
    input  logic wr,
    input  logic rx_in,             // Incoming bits
    output logic tx_out,            // Outgoing bits
    input  logic [3:0] addr,        // Address: controls or buffers
    output logic [7:0] out_data,    // Ouput data port
    /* verilator lint_off UNUSED */
    input  logic [7:0] in_data,     // Input data port (routed to DeMux)
    /* verilator lint_on UNUSED */
    output logic irq,               // Active high
    output logic [2:0] irq_id       // ID. 8 possible ids.
);

localparam Component_ID = 3'b000;

// ------------------------------------------------------------------
// Control register N-bits
// ------------------------------------------------------------------
localparam CONTROL_SIZE = 12;
/* verilator lint_off UNUSED */
logic [CONTROL_SIZE-1:0] control;
/* verilator lint_on UNUSED */

// ------------------------------------------------------------------
// Signals
// ------------------------------------------------------------------
// Signals are broken into 2 parts:
// |---3bits---|------5bits------|
// |  Signal   |    Data Count   |

//                         
localparam RGC_Signal = 8'b000_00000;
// localparam CRC_Signal = 8'b001_00000;   // Signal sent from Client
localparam SEC_Signal = 8'b010_00000;

// ------------------------------------------------------------------------
// Buffers
// ------------------------------------------------------------------------
// 2 BRAM buffer(s) each 0x00 -> 0x19
localparam WORDS = 5; // 32 bytes each = 2^5
localparam DATA_WIDTH = 8;

// The control register is at address 2 or greater which means
// we can shift the address right in order to target bits starting at 0
logic [3:0] ctrl_addr;
assign ctrl_addr = addr >> 2;


// --------------------------------
// Tx buffer
// --------------------------------
// The System can only write bytes to the buffer if it has
// control via a grant.
logic tx_buff_wr;   // Active (low) write signal
assign tx_buff_wr = ~(~cs & ~wr & (addr == 4'b0000) & control[CTL_SYS_GRNT]);

// This signal is active for each byte that is to be sent
logic tx_buff_rd;       // Tx loop drives this signal
logic [DATA_WIDTH-1:0] tx_storage_in;
logic [DATA_WIDTH-1:0] tx_byte;
logic [DATA_WIDTH-1:0] src_to_tx;
logic [1:0] tx_src_sel;

Mux4 #(.DATA_WIDTH(DATA_WIDTH)) tx_mux
(
    .select_i(tx_src_sel),
    .data0_i(RGC_Signal),
    .data1_i(SEC_Signal),
    .data2_i(0),
    .data3_i(tx_byte),
    .data_o(src_to_tx)
);

// assign src_to_tx = tx_src_sel ? tx_byte : RGC_Signal;

// Address counter:
// At each posedge of the tx_buff_wr we increment this address
logic [WORDS-1:0] buff_tx_address;
logic [WORDS-1:0] addr_idx;

Memory #(
    .WORDS(WORDS),
    .DATA_WIDTH(DATA_WIDTH)
) tx_buff(
    .clk_i(clock),
    .data_i(tx_storage_in),
    .addr_i(buff_tx_address),
    .wr_i(tx_buff_wr),
    .rd_i(tx_buff_rd),
    .data_o(tx_byte)
);

// --------------------------------
// Rx buffer
// --------------------------------
logic rx_buff_rd;       // active (low)
assign rx_buff_rd = ~(~cs & ~rd & (addr == 4'b0001) & control[CTL_CLI_GRNT]);

logic [DATA_WIDTH-1:0] rx_storage_out;  // To Memory map interface Mux

// Rx Address counter. This is reset 
logic [WORDS-1:0] buff_rx_address;

// Only the device writes to the Rx buffer and it uses a address counter
// as reference.
// rx_buff_wr is active when the Client is in control and bytes are
// arriving.
// When rx_complete is active (for 1 cycle) it means a byte has completely
// arrived and should be stored.
// The System will not attempt to read from the buffer until the
// the System has control.
logic rx_buff_wr;

Memory #(
    .WORDS(WORDS),
    .DATA_WIDTH(DATA_WIDTH)
) rx_buff(
    .clk_i(clock),
    .data_i(rx_byte),
    .addr_i(buff_rx_address),
    .wr_i(rx_buff_wr),
    .rd_i(rx_buff_rd),
    .data_o(rx_storage_out)     // to DeMux Device output
);

// ------------------------------------------------------------------------
// Data Ports
// ------------------------------------------------------------------------
/* verilator lint_off UNUSED */
logic [DATA_WIDTH-1:0] control_in;   // From Interface port
/* verilator lint_on UNUSED */

logic [DATA_WIDTH-1:0] control_out;  // From control bits

// Addresses 0=Tx and 1=Rx are the buffers. Anything higher are controls.
logic route_select;
assign route_select = (addr == 0 | addr == 1) ? 1 : 0;

// Outgoing interface data
assign out_data = route_select ? rx_storage_out : control_out;

// Incoming interface data
DeMux2 #(
    .DATA_WIDTH(DATA_WIDTH)
) in_demux (
    .select(route_select),
    .data_i(in_data),
    .data0_o(tx_storage_in),
    .data1_o(control_in)
);

// ------------------------------------------------------------------------
// IO channels
// ------------------------------------------------------------------------
// UART Transmitter reads from the Tx buffer
logic tx_en;
logic tx_complete;

UARTTx uart_tx (
    .sourceClk(clock),
    .reset(reset),
    .tx_en(tx_en),
    .tx_byte(src_to_tx),
    .tx_out(tx_out),
    .tx_complete(tx_complete)
);

// UART Receiver writes to the Rx buffer
logic [DATA_WIDTH-1:0] rx_byte;
logic rx_complete;

UARTRx uart_rx (
    .sourceClk(clock),
    .reset(reset),
    .rx_in(rx_in),
    .rx_byte(rx_byte),
    .rx_complete(rx_complete)
);

// ------------------------------------------------------------------------
// State machine controlling device
// ------------------------------------------------------------------------
UARTState state = UAReset0;
UARTState next_state;

logic neither_have_control;  // Neither granted control
assign neither_have_control = control[CTL_SYS_GRNT] == 0 || control[CTL_CLI_GRNT] == 0;

always_ff @(posedge clock) begin
    // --------------------------------
    // Control registers
    // --------------------------------
    if (~cs) begin
        if (~wr)
            control[ctrl_addr] <= control_in[0];
        else if (~rd)
            control_out <= {7'b0, control[ctrl_addr]};
    end

    case (state)
        // --------------------------------
        // Reset
        // --------------------------------
        UAReset0: begin
            control <= 0;
            buff_tx_address <= 0;
            buff_rx_address <= 0;
            tx_src_sel <= 2'b11;

            // Temp
            irq <= 1;       // Non-active
            irq_id <= Component_ID;    // UART component id
        end

        UAResetComplete: begin
            next_state <= UAIdle;
        end

        UAIdle: begin
            // ------------------------------------------------------
            // Main core. Determine what sequence to enter.
            // ------------------------------------------------------

            // Check if System is requesting control.
            if (control[CTL_SYS_SRC]) begin
                // It or the Client may already have it and if so skip.
                if (neither_have_control) begin
                    // Neither have control, so Grant control.
                    // The System is either polling this bit
                    // TODO or will receive an interrupt if it's enabled.
                    control[CTL_SYS_GRNT] <= 1;

                    // Transition to System idle.
                    next_state <= UASystemEnter;
                end
            end
            // Check if Client is requesting control.
            else if (control[CTL_CLI_CRC]) begin
                // It or the System may already have it and if so skip.
                if (neither_have_control) begin
                    // Neither have control, so Grant control.
                    control[CTL_CLI_GRNT] <= 1;
                    // Clear request bit too
                    control[CTL_CLI_CRC] <= 0;
                    // Send Request-Granted-Control (RGC) byte to Client
                    next_state <= UABeginCRCSignal;
                end
            end
            // Check if the System wants to transmit the Tx buffer.
            else if (control[CTL_SYS_GRNT] && control[CTL_TX_BUFF_RDY]) begin
                next_state <= UATransmitEnter;
            end
            
        end

        // -----------------------------------------------------------------
        // Send Grant signal to Client
        // -----------------------------------------------------------------
        // Write RGC byte directly to UART sub-module because we
        // are sending only 1 byte.
        UABeginCRCSignal: begin
            tx_src_sel <= 2'b00;        // Select the signal value
            next_state <= UASendCRCSignal;
        end

        UASendCRCSignal: begin
            tx_en <= 0; // Enable tx_en
            next_state <= UASendingCRCSignal;
        end

        UASendingCRCSignal: begin
            tx_en <= 1; // Disable tx_en
            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                tx_src_sel <= 2'b11;  // Switch back to Tx buffer
                next_state <= UAIdle;
            end
        end

        // -----------------------------------------------------------------
        // System control sequence.
        // -----------------------------------------------------------------
        UASystemEnter: begin
            // System now has control, clear the request signal.
            control[CTL_SYS_SRC] <= 0;
        end

        // We won't leave this sequence until the System relinquishes control.
        // (Optional) The Client could send a Ctrl-C key-code. This state could
        // monitor the rx_complete flag.
        UASystemIdle: begin
            // TODO may need to add extra state for inc.
            // In this state the System can write data to the Tx buffer.
            // Writing to the Tx buffer is done on the
            // rising-edge (High). On the next clock we increment the address.
            if (~tx_buff_wr) begin
                buff_tx_address <= buff_tx_address + 1;
            end

            // Check for the relinquish signal. The System Sets this bit when
            // it wants to give up control.
            if (control[CTL_SYS_SEC] == 1) begin
                control[CTL_SYS_SEC] <= 0;
                // Notify Client that the System has giving up control
                // by sending SEC signal.
                next_state <= UASystemRelinquish;
            end
        end

        UASystemRelinquish: begin
            // To relinquish control includes notifying the Client.
            // The Client is always listening for at least one byte.
            tx_src_sel <= 2'b01;        // Select the SEC_Signal value
            next_state <= UASendSECSignal;
        end

        UASendSECSignal: begin
            tx_en <= 0; // Enable tx_en
            next_state <= UASendingSECSignal;
        end

        UASendingSECSignal: begin
            tx_en <= 1; // Disable tx_en
            // Wait for the byte to finish transmitting.
            if (tx_complete) begin
                tx_src_sel <= 2'b11;  // Switch back to Tx buffer
                next_state <= UAIdle;
            end
        end

        // -----------------------------------------------------------------
        // System Transmit from Tx buffer
        // -----------------------------------------------------------------
        // Read 1 byte at a time from Tx buffer memory
        UATransmitEnter: begin
            addr_idx <= 0;
            tx_src_sel <= 2'b11;    // Select the tx_byte source
            control[CTL_SYS_SDS] <= 0;      // Data not sent yet.
            control[CTL_TX_BUFF_RDY] <= 0;  // Don't need signal set anymore
            next_state <= UATransmitRead;
        end

        UATransmitRead: begin
            tx_buff_rd <= 0;        // Enable reading
            next_state <= UATransmitEnable;
        end

        UATransmitEnable: begin
            // buffer output, tx_byte, is now present.
            tx_en <= 0;             // Enable byte load
            tx_buff_rd <= 1;        // Disable reading
            addr_idx <= addr_idx + 1;
            next_state <= UATransmitSending;
        end

        UATransmitSending: begin
            // byte loaded into UARTTx
            tx_en <= 1; // Disable byte load
            // Wait for loaded byte to finish transmitting.
            if (tx_complete) begin
                // TODO When the System finished writing to the Tx buffer the
                // buff_tx_address points just after the last byte written.
                // we need to be careful of rollover. Writing to the 31st
                // byte will lead to zero.
                if (addr_idx == buff_tx_address) begin
                    buff_tx_address <= 0;
                    // TODO if interrupts are enabled we would trigger.
                    // Otherwise the system polls the SDS bit.
                    control[CTL_SYS_SDS] <= 1;  // Data sent
                    next_state <= UASystemIdle;
                end
                else begin
                    next_state <= UATransmitRead;
                end
            end
        end

        // -----------------------------------------------------------------
        // System reads Rx buffer
        // -----------------------------------------------------------------
        // System has gained control and can now read the Rx buffer.
        // To do so you must "Start" the read sequence by setting CTL_STR_RD
        // bit. Once the Device is ready the CTL_RD_RDY is Set and then
        // the System can read the buffer.
        // Once a buffer is read, the Client is notified.
        // The first byte's lower 5 bits indicate how many bytes to read.
        // Eventually the last buffer will arrive. This is indicated by the
        // EOT_Signal (upper 3 bits) and a final count (lower 5 bits).
        // The CTL_EOT is also set.
        UASystemReadEnter: begin
            buff_rx_address <= 0;
            next_state <= UASystemRead;
        end

        UASystemRead: begin
            // The Device is ready for the System to begin reading.

        end

        UASystemRead: begin
            // Each read advances the address pointer.
            if (~rx_buff_rd) begin
                buff_rx_address <= buff_rx_address + 1;
            end

            // We stay in this state until all bytes have been read.

            next_state <= UASystemRead;
        end

        // UASystemRead: begin
        //     // rx_storage_out now has data
        //     rx_buff_rd <= 0;        // Enable reading
        //     next_state <= UASystemRead;
        // end

        // -----------------------------------------------------------------
        // Unknown State
        // -----------------------------------------------------------------
        default: begin
            `ifdef SIMULATE
                $display("********* UNKNOWN STATE ***********");
            `endif
        end

    endcase

    if (~reset)
        state <= UAReset0;
    else
        state <= next_state;
end

endmodule

