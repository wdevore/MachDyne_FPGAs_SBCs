module hvsync_generator(
    input  logic clk,
    output logic vga_h_sync,
    output logic vga_v_sync,
    output logic inDisplayArea,
    output logic [9:0] counter_x,
    output logic [9:0] counter_y
  );
logic vga_HS, vga_VS;

// logic CounterXmaxed = (counter_x == 800); // 16 + 48 + 96 + 640
// logic CounterYmaxed = (counter_y == 525); // 10 + 2 + 33 + 480
logic CounterXmaxed;
logic CounterYmaxed;

always_ff @(posedge clk) begin
        CounterXmaxed <= 0;
        CounterYmaxed <= 0;

    if (counter_x == 800)
        CounterXmaxed <= 1;

    if (counter_y == 525)
        CounterYmaxed <= 1;

    if (CounterXmaxed) begin
        counter_x <= 0;
    end
    else
        counter_x <= counter_x + 1;
end

always_ff @(posedge clk) begin
    if (CounterXmaxed) begin
        if (CounterYmaxed)
            counter_y <= 0;
        else
            counter_y <= counter_y + 1;
    end
end

// always @(posedge clk) begin
assign vga_HS = (counter_x > (640 + 16) && (counter_x < (640 + 16 + 96)));   // active for 96 clocks
assign vga_VS = (counter_y > (480 + 10) && (counter_y < (480 + 10 + 2)));   // active for 2 clocks
// end

// always @(posedge clk) begin
assign inDisplayArea = (counter_x < 640) && (counter_y < 480);
// end

assign vga_h_sync = ~vga_HS;
assign vga_v_sync = ~vga_VS;

endmodule