/*
 *  mt48lc16m16a2_ctrl - A sdram controller
 *
 *  Copyright (C) 2022  Hirosh Dabui <hirosh@dabui.de>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
`default_nettype none `timescale 1ns / 1ns

// ###################################################################
// Note: excellent article about SDRAM chip (8 bit version which applies)
// to N bits version: https://alchitry.com/sdram-verilog
// ###################################################################

// Usage example: trunc_32_to_13'(TRP)
// typedef logic [12:0] trunc_32_to_13;
`ifdef SIMULATION
localparam WAIT_100US = 1 * ONE_MICROSECOND;
`else
localparam WAIT_100US = 100 * ONE_MICROSECOND;  // 64 * 1/64e6 = 1us => 100 * 1us
`endif

localparam ONE_MICROSECOND = `SDRAM_CLK_FREQ;
localparam WAIT_WIDTH = $clog2(WAIT_100US);

/* verilator lint_off WIDTH */
/* verilator lint_off UNUSED */
`ifdef SIMULATION
function [WAIT_WIDTH-1:0] trunc_32_to(input [31:0] val32);
  trunc_32_to = val32[WAIT_WIDTH-1:0];
endfunction
`else
function [WAIT_WIDTH-1:0] trunc_32_to(input [31:0] val32);
  trunc_32_to = val32[WAIT_WIDTH-1:0];
endfunction
`endif
/* verilator lint_on UNUSED */
/* verilator lint_on WIDTH */

// ===============================
// 16Mx16 = 32MByte
// Row addressing 8k (A0-A12)
// Bank Switching 4 (BA0, BA1)
// Column Addressing 512 (A0-A8)
// ===============================
module sdram #(
    parameter TRP_NS = 20,
    parameter TRC_NS = 66,
    parameter TRCD_NS = 20,
    parameter TCH_NS = 2,
    parameter CAS = 3'd2
) (
    input  logic clk,
    input  logic resetn,

    /* verilator lint_off UNUSED */
    input  logic [24:0] addr,
    /* verilator lint_on UNUSED */
    input  logic [31:0] din,
    input  logic [3:0] wmask,
    input  logic valid,               // Indicates all signals and data are valid for use.
    output logic [31:0] dout,
    output logic ready,               // ???Low = Ready/(not busy), High = busy
    output logic initialized,         // Active high when device is initialized
    output logic busy,                // Active high (1 = busy)

    output logic sdram_clk,
    output logic sdram_cke,          // Active High
    output logic [1:0] sdram_dqm,
    output logic [12:0] sdram_addr,  // A0-A12 row address, A0-A8 column address
    output logic [1:0] sdram_ba,     // bank select A11,A12
    //  ------------- Command -----------------------
    output logic sdram_csn,          // Active Low
    output logic sdram_wen,
    output logic sdram_rasn,
    output logic sdram_casn,
    //  ----------------------------------------------
    inout  logic [15:0] sdram_dq
);

  logic sdram_initialized_nxt;

  // command period; PRE to ACT in ns, e.g. 20ns
  localparam TRP = $rtoi((TRP_NS * ONE_MICROSECOND / 1000) + 1);
  // tRC command period (REF to REF/ACT TO ACT) in ns
  localparam TRC = $rtoi((TRC_NS * ONE_MICROSECOND / 1000) + 1);  //
  // tRCD active command to read/write command delay; row-col-delay in ns
  localparam TRCD = $rtoi((TRCD_NS * ONE_MICROSECOND / 1000) + 1);
  // tCH command hold time
  localparam TCH = $rtoi((TCH_NS * ONE_MICROSECOND / 1000) + 1);

  initial begin
    $display("Clk frequence: %d MHz", `SDRAM_CLK_FREQ);
    $display("WAIT_100US: %d cycles", WAIT_100US);
    $display("TRP: %d cycles", TRP);
    $display("TRC: %d cycles", TRC);
    $display("TRCD: %d cycles", TRCD);
    $display("TCH: %d cycles", TCH);
    $display("CAS_LATENCY: %d cycles", CAS_LATENCY);
  end

  localparam BURST_LENGTH   = 3'b001; // 000=1, 001=2, 010=4, 011=8
  localparam ACCESS_TYPE    = 1'b0;   // 0=sequential, 1=interleaved
  localparam CAS_LATENCY    = CAS;    // 2/3 allowed, tRCD=20ns -> 3 cycles@128MHz
  localparam OP_MODE        = 2'b00;  // only 00 (standard operation) allowed
  localparam NO_WRITE_BURST = 1'b0;   // 0= write burst enabled, 1=only single access write
  localparam sdram_mode = {1'b0, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};
  //
  logic [3:0] command;
  logic [3:0] command_nxt;
  logic cke;
  logic cke_nxt;
  logic [1:0] dqm;
  logic [12:0] saddr;
  logic [12:0] saddr_nxt;
  logic [1:0] ba;
  logic [1:0] ba_nxt;

  assign sdram_clk = clk;
  assign sdram_cke = cke;
  assign sdram_addr = saddr;
  assign sdram_dqm = dqm;
  assign {sdram_csn, sdram_rasn, sdram_casn, sdram_wen} = command;
  assign sdram_ba = ba;

  SDRAMState state;
  SDRAMState state_nxt;
  SDRAMState ret_state;
  SDRAMState ret_state_nxt;

  localparam WAIT_STATE_WIDTH = $clog2(WAIT_100US);
  logic [WAIT_STATE_WIDTH -1:0] wait_states;
  logic [WAIT_STATE_WIDTH -1:0] wait_states_nxt;

  logic ready_nxt;
  logic [31:0] dout_nxt;
  logic [1:0] dqm_nxt;

  logic update_ready;
  logic update_ready_nxt;

  assign busy = update_ready;

  logic [15:0] dq;
  logic [15:0] dq_nxt;
  assign sdram_dq = oe ? dq : 16'hz;

  logic oe;
  logic oe_nxt;
  /* verilator lint_off UNUSED */
  logic valid_q;
  logic valid_d1;
  /* verilator lint_on UNUSED */
  
  logic initiate_activity;
  logic initiate_activity_nxt;

  always_ff @(posedge clk) begin
    if (~resetn) begin
      state <= RESET;
      ret_state <= RESET;
      ready <= 1'b1;      // Busy
      wait_states <= 0;
      dout <= 0;
      command <= CMD_NOP;
      dqm <= 2'b11;
      dq <= 0;
      ba <= 2'b11;
      oe <= 1'b0;
      saddr <= 0;
      update_ready <= 1'b0;
      initialized <= 1'b0;  // Not initialized (not ready)
      initiate_activity <= 0;
    end else begin
      dq <= dq_nxt;
      dout <= dout_nxt;
      state <= state_nxt;
      ready <= ready_nxt;
      dqm <= dqm_nxt;
      cke <= cke_nxt;
      command <= command_nxt;
      wait_states <= wait_states_nxt;
      ret_state <= ret_state_nxt;
      ba <= ba_nxt;
      oe <= oe_nxt;
      saddr <= saddr_nxt;
      update_ready <= update_ready_nxt;
      initialized <= sdram_initialized_nxt;
      initiate_activity <= initiate_activity_nxt;
    end
  end

  always_comb begin
    wait_states_nxt  = wait_states;
    state_nxt        = state;
    ready_nxt        = ready;
    ret_state_nxt    = ret_state;
    dout_nxt         = dout;
    command_nxt      = command;

    cke_nxt          = cke;
    saddr_nxt        = saddr;
    ba_nxt           = ba;
    dqm_nxt          = dqm;
    oe_nxt           = oe;
    dq_nxt           = dq;
    update_ready_nxt = update_ready;

    sdram_initialized_nxt = initialized;    // Device initialized
    
    if (valid) begin
      initiate_activity_nxt = 1'b1;
    end
    else
      initiate_activity_nxt = initiate_activity;
    
    case (state)
      // --------- RESET ---------------------
      RESET: begin
        cke_nxt         = 1'b0;
        wait_states_nxt = trunc_32_to(WAIT_100US);
        state_nxt       = RESET_WAIT;
      end

      RESET_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = ASSERT_CKE;
        end
      end

      // --------- ASSERT_CKE ---------------------
      ASSERT_CKE: begin
        cke_nxt         = 1'b1;
        wait_states_nxt = 2;
        state_nxt       = ASSERT_CKE_WAIT;
      end

      ASSERT_CKE_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = INIT_SEQ_PRE_CHARGE_ALL;
        end
      end

      // --------- INIT_SEQ_PRE_CHARGE_ALL ---------------------
      INIT_SEQ_PRE_CHARGE_ALL: begin
        command_nxt     = CMD_PRE;
        saddr_nxt[10]   = 1'b1;
        wait_states_nxt = trunc_32_to(TRP);
        state_nxt       = INIT_SEQ_PRE_CHARGE_ALL_WAIT;
      end

      INIT_SEQ_PRE_CHARGE_ALL_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = INIT_SEQ_AUTO_REFRESH0;
        end
      end

      // --------- INIT_SEQ_AUTO_REFRESH0 ---------------------
      INIT_SEQ_AUTO_REFRESH0: begin
        command_nxt = CMD_REF;
        wait_states_nxt = trunc_32_to(TRC);
        state_nxt = INIT_SEQ_AUTO_REFRESH0_WAIT;
      end

      INIT_SEQ_AUTO_REFRESH0_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = INIT_SEQ_AUTO_REFRESH1;
        end
      end

      // --------- INIT_SEQ_AUTO_REFRESH1 ---------------------
      INIT_SEQ_AUTO_REFRESH1: begin
        wait_states_nxt = trunc_32_to(TRC);
        state_nxt = INIT_SEQ_AUTO_REFRESH1_WAIT;
      end

      INIT_SEQ_AUTO_REFRESH1_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = INIT_SEQ_LOAD_MODE;
        end
      end

      // --------- INIT_SEQ_LOAD_MODE ---------------------
      INIT_SEQ_LOAD_MODE: begin
        command_nxt = CMD_MRS;
        saddr_nxt = {2'b0, sdram_mode};
        wait_states_nxt = trunc_32_to(TCH);
        state_nxt = INIT_SEQ_LOAD_MODE_WAIT;
      end

      INIT_SEQ_LOAD_MODE_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = IDLE;
          sdram_initialized_nxt = 1'b1;    // Device initialized
        end
      end

// @audit-issue idle
      // --------- IDLE ---------------------
      IDLE: begin
        oe_nxt = 1'b0;        // Disable output
        dqm_nxt = 2'b11;      // Default to Read Disable for all data output
        ready_nxt = 1'b0;     // Ready

        if (initiate_activity && ~ready) begin
          // Begin an Activity (aka Read or Write)
          command_nxt     = CMD_ACT;
          ba_nxt          = addr[22:21];
          saddr_nxt       = {addr[24:23], addr[20:10]}; // Select Active Row
          wait_states_nxt = trunc_32_to(TRCD);
          update_ready_nxt = 1'b1;
          state_nxt       = READY_WAIT;
        end else begin
          /* autorefresh */
          command_nxt = CMD_REF;
          saddr_nxt = 0;
          ba_nxt = 0;
          wait_states_nxt = 3;  //TRC;
          update_ready_nxt = 1'b0;
          state_nxt = AUTO_REFRESH_WAIT;
        end
      end

      AUTO_REFRESH_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          if (update_ready) begin
            update_ready_nxt = 1'b0;
            ready_nxt = 1'b1;   // Busy
          end
          state_nxt = IDLE;
        end
      end

      READY_WAIT: begin
        command_nxt = CMD_NOP;
        initiate_activity_nxt = 1'b0;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = |wmask ? COL_WRITEL : COL_READ;
        end
      end

      // --------- COL_READ ---------------------
      COL_READ: begin
        command_nxt     = CMD_READ;
        dqm_nxt         = 2'b00;        // Zero's drive the outputs
        saddr_nxt       = {3'b001, addr[10:2], 1'b0};  // autoprecharge and column
        ba_nxt          = addr[22:21];
        `ifdef SIMULATION
        wait_states_nxt = {3'b0, CAS_LATENCY};
        `else
        wait_states_nxt = CAS_LATENCY;
        `endif
        state_nxt       = COL_READ_WAIT;
      end

      COL_READ_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = COL_READL;
        end
      end

      // --------- COL_READL ---------------------
      COL_READL: begin
        command_nxt    = CMD_NOP;
        dqm_nxt        = 2'b00;
        dout_nxt[15:0] = sdram_dq;
        state_nxt      = COL_READH;
      end

      COL_READH: begin
        command_nxt      = CMD_NOP;
        dqm_nxt          = 2'b00;
        dout_nxt[31:16]  = sdram_dq;
        wait_states_nxt  = trunc_32_to(TRP);
        update_ready_nxt = 1'b1;
        state_nxt        = COL_READH_WAIT;
      end

      COL_READH_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = IDLE;
          if (update_ready) begin
            update_ready_nxt = 1'b0;
            ready_nxt = 1'b1;
          end
        end
      end

      // --------- COL_WRITEL ---------------------
      COL_WRITEL: begin
        command_nxt = CMD_WRITE;
        dqm_nxt     = ~wmask[1:0];
        saddr_nxt   = {3'b001, addr[10:2], 1'b0};  // autoprecharge and column
        ba_nxt      = addr[22:21];
        dq_nxt      = din[15:0];
        oe_nxt      = 1'b1;
        state_nxt   = COL_WRITEH;
      end

      COL_WRITEH: begin
        command_nxt      = CMD_NOP;
        dqm_nxt          = ~wmask[3:2];
        saddr_nxt        = {3'b001, addr[10:2], 1'b0};  // autoprecharge and column
        ba_nxt           = addr[22:21];
        dq_nxt           = din[31:16];
        oe_nxt           = 1'b1;
        wait_states_nxt  = trunc_32_to(TRP);
        update_ready_nxt = 1'b1;
        state_nxt        = COL_WRITEH_WAIT;
      end

      COL_WRITEH_WAIT: begin
        command_nxt = CMD_NOP;
        wait_states_nxt = wait_states - 1;
        if (wait_states == 1) begin
          state_nxt = IDLE;
          if (update_ready) begin
            update_ready_nxt = 1'b0;
            ready_nxt = 1'b1;
          end
        end
      end

      default: begin
        state_nxt = state;
      end
    endcase
  end

endmodule
