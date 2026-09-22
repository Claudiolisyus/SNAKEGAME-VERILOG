// ============================================================
// clock_divider.v
// Takes the 100 MHz board clock and produces:
//   pixel_clk  - 25 MHz, toggled every 2 cycles (for 640x480@60Hz VGA)
//   game_tick  - a single-cycle pulse at an adjustable game speed
// ============================================================
module clock_divider #(
    parameter TICK_DIV = 27'd8_000_000   // ~12.5 game steps/sec at 100MHz.
                                          // Lower = faster snake. Try
                                          // 12_000_000 for a slower / easier game,
                                          // 4_000_000 for a faster / harder game.
)(
    input  wire clk_100mhz,
    input  wire reset,
    output reg  pixel_clk,     // 25 MHz VGA pixel clock
    output reg  game_tick      // 1-cycle pulse used to advance the snake
);

    // ---- 25 MHz pixel clock (divide by 4) ----
    reg [1:0] pixel_cnt;
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            pixel_cnt <= 2'd0;
            pixel_clk <= 1'b0;
        end else begin
            pixel_cnt <= pixel_cnt + 2'd1;
            if (pixel_cnt == 2'd1) begin
                pixel_clk <= ~pixel_clk;
                pixel_cnt <= 2'd0;
            end
        end
    end

    // ---- game tick pulse ----
    reg [26:0] tick_cnt;
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            tick_cnt  <= 27'd0;
            game_tick <= 1'b0;
        end else if (tick_cnt == TICK_DIV) begin
            tick_cnt  <= 27'd0;
            game_tick <= 1'b1;      // one-cycle pulse
        end else begin
            tick_cnt  <= tick_cnt + 27'd1;
            game_tick <= 1'b0;
        end
    end

endmodule
