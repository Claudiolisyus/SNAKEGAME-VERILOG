// ============================================================
// top_snake.v
// Top-level Snake game for an FPGA board with:
//   - 100 MHz system clock
//   - VGA output (4-bit R/G/B, standard on boards like Basys3)
//   - PS/2 keyboard port (clk + data)
//   - one push-button for reset
//
// Grid: 32 columns x 24 rows, 20x20 pixel cells -> exactly fills
// a 640x480 VGA frame.
// ============================================================
module top_snake(
    input  wire clk_100mhz,
    input  wire btn_reset,      // active-high reset button
    input  wire ps2_clk,
    input  wire ps2_data,

    output wire vga_hsync,
    output wire vga_vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b
);

    localparam GRID_W  = 32;
    localparam GRID_H  = 24;
    localparam CELL    = 20;
    localparam MAX_LEN = 64;

    wire reset = btn_reset;

    // ---- clocking ----
    wire pixel_clk;
    wire game_tick;
    clock_divider clkdiv(
        .clk_100mhz(clk_100mhz),
        .reset(reset),
        .pixel_clk(pixel_clk),
        .game_tick(game_tick)
    );

    // ---- VGA timing ----
    wire hsync_i, vsync_i, video_on;
    wire [9:0] hcount, vcount;
    vga_sync vga(
        .pixel_clk(pixel_clk),
        .reset(reset),
        .hsync(hsync_i),
        .vsync(vsync_i),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount)
    );
    assign vga_hsync = hsync_i;
    assign vga_vsync = vsync_i;

    // ---- keyboard ----
    wire up_p, down_p, left_p, right_p;
    ps2_keyboard kbd(
        .clk_100mhz(clk_100mhz),
        .reset(reset),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .up_pressed(up_p),
        .down_pressed(down_p),
        .left_pressed(left_p),
        .right_pressed(right_p)
    );

    // ---- game engine ----
    wire [4:0] snake_x [0:MAX_LEN-1];
    wire [4:0] snake_y [0:MAX_LEN-1];
    wire [6:0] length;
    wire [4:0] food_x, food_y;
    wire       game_over;
    wire [7:0] score;

    snake_game #(
        .GRID_W(GRID_W), .GRID_H(GRID_H), .MAX_LEN(MAX_LEN)
    ) game (
        .clk_100mhz(clk_100mhz),
        .reset(reset),
        .game_tick(game_tick),
        .up_pressed(up_p),
        .down_pressed(down_p),
        .left_pressed(left_p),
        .right_pressed(right_p),
        .snake_x(snake_x),
        .snake_y(snake_y),
        .length(length),
        .food_x(food_x),
        .food_y(food_y),
        .game_over(game_over),
        .score(score)
    );

    // ---- pixel -> grid cell mapping ----
    wire [4:0] col = hcount / CELL;   // 0..31 while in the visible area
    wire [4:0] row = vcount / CELL;   // 0..23 while in the visible area

    // is the current cell part of the snake?
    reg on_snake;
    integer k;
    always @(*) begin
        on_snake = 1'b0;
        for (k = 0; k < MAX_LEN; k = k + 1) begin
            if (k < length) begin
                if (snake_x[k] == col && snake_y[k] == row)
                    on_snake = 1'b1;
            end
        end
    end

    wire on_food   = (col == food_x) && (row == food_y);
    wire on_border = (col == 0) || (col == GRID_W-1) ||
                      (row == 0) || (row == GRID_H-1);

    // simple flashing "game over" background using vcount[4] as a slow blink
    reg [3:0] r, g, b;
    always @(*) begin
        if (!video_on) begin
            r = 4'h0; g = 4'h0; b = 4'h0;
        end else if (game_over) begin
            if (vcount[4])
                begin r = 4'hF; g = 4'h0; b = 4'h0; end   // flashing red
            else
                begin r = 4'h4; g = 4'h0; b = 4'h0; end
        end else if (on_food) begin
            r = 4'hF; g = 4'hF; b = 4'h0;                  // yellow food
        end else if (on_snake) begin
            r = 4'h0; g = 4'hE; b = 4'h2;                  // green snake
        end else if (on_border) begin
            r = 4'hF; g = 4'hF; b = 4'hF;                  // white border
        end else begin
            r = 4'h0; g = 4'h0; b = 4'h0;                  // black background
        end
    end

    assign vga_r = r;
    assign vga_g = g;
    assign vga_b = b;

endmodule
