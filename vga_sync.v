// ============================================================
// vga_sync.v
// Standard 640x480 @ 60Hz VGA timing generator.
// Drive this with a 25 MHz pixel clock.
// ============================================================
module vga_sync(
    input  wire       pixel_clk,
    input  wire       reset,
    output wire        hsync,
    output wire        vsync,
    output wire        video_on,   // high while inside the visible 640x480 area
    output reg  [9:0] hcount,     // 0..799
    output reg  [9:0] vcount      // 0..524
);

    // Horizontal timing (pixels)
    localparam H_DISPLAY    = 640;
    localparam H_FRONT      = 16;
    localparam H_SYNC       = 96;
    localparam H_BACK       = 48;
    localparam H_TOTAL      = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; // 800

    // Vertical timing (lines)
    localparam V_DISPLAY    = 480;
    localparam V_FRONT      = 10;
    localparam V_SYNC       = 2;
    localparam V_BACK       = 33;
    localparam V_TOTAL      = V_DISPLAY + V_FRONT + V_SYNC + V_BACK; // 525

    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            hcount <= 10'd0;
            vcount <= 10'd0;
        end else begin
            if (hcount == H_TOTAL - 1) begin
                hcount <= 10'd0;
                if (vcount == V_TOTAL - 1)
                    vcount <= 10'd0;
                else
                    vcount <= vcount + 10'd1;
            end else begin
                hcount <= hcount + 10'd1;
            end
        end
    end

    // sync pulses are active LOW for this standard timing
    assign hsync = ~((hcount >= H_DISPLAY + H_FRONT) &&
                      (hcount <  H_DISPLAY + H_FRONT + H_SYNC));

    assign vsync = ~((vcount >= V_DISPLAY + V_FRONT) &&
                      (vcount <  V_DISPLAY + V_FRONT + V_SYNC));

    assign video_on = (hcount < H_DISPLAY) && (vcount < V_DISPLAY);

endmodule
