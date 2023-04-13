// https://github.com/imuguruza/alhambra_II_test/blob/master/vga/vga_test/vga_sync.v
// http://javiervalcarce.eu/html/vga-signal-format-timming-specs-en.html

module hvsync_generator(
    input  logic clk,
    input  logic reset,     // Active low
    output logic h_sync,
    output logic v_sync,
    output logic [9:0] h_count,
    output logic [9:0] v_count,
    output logic display_en
  );
localparam  h_pixel_total              = 800;
localparam  h_pixel_display            = 640;
localparam  h_pixel_front_porch_amount = 16;
localparam  h_pixel_sync_amount        = 96;
localparam  h_pixel_back_porch_amount  = 48;

localparam  v_pixel_total              = 525;
localparam  v_pixel_display            = 480;
localparam  v_pixel_front_porch_amount = 10;
localparam  v_pixel_sync_amount        = 2;
localparam  v_pixel_back_porch_amount  = 33;

// Pixel counters
logic [9:0] h_counter = 0;
logic [9:0] v_counter = 0;

always_ff @(posedge clk) begin
  if (reset) begin
    //Reset counter values
    h_counter <= 0;
    v_counter <= 0;
  end
  else begin
    // Check if horizontal has arrived at the end
    if (h_counter >= h_pixel_total) begin
        h_counter <= 0;
        v_counter <= v_counter + 1;
    end
    else
        //horizontal increment pixel value
        h_counter <= h_counter + 1;

    // check if vertical has arrived at the end
    if (v_counter >= v_pixel_total)
        v_counter <= 0;
  end
end

always_comb begin
    // Generate display enable signal
    if (h_counter < h_pixel_display && v_counter < v_pixel_display && ~reset)
        display_en = 1;
    else
        display_en = 0;

    // Check if sync_pulse needs to be created
    if (h_counter >= (h_pixel_display + h_pixel_front_porch_amount)
        && h_counter < (h_pixel_display + h_pixel_front_porch_amount + h_pixel_sync_amount))
        h_sync = 0;
    else
        h_sync = 1;

    // Check if sync_pulse needs to be created
    if (v_counter >= (v_pixel_display + v_pixel_front_porch_amount)
        && v_counter < (v_pixel_display + v_pixel_front_porch_amount + v_pixel_sync_amount))
        v_sync = 0;
    else
        v_sync = 1;
end

assign h_count = h_counter;
assign v_count = v_counter;

endmodule
