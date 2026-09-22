// ============================================================
// snake_game.v
// Grid-based snake engine. Grid is GRID_W x GRID_H cells.
// Snake body is stored as two parallel arrays of grid coordinates,
// index 0 = head. Every game_tick the whole array shifts by one
// (each segment takes the position of the segment ahead of it) and
// a new head position is written to index 0. Eating food increases
// `length`, which simply means more of the array is drawn/checked -
// the tail segment that would otherwise be dropped is kept.
// ============================================================
module snake_game #(
    parameter GRID_W  = 32,
    parameter GRID_H  = 24,
    parameter MAX_LEN = 64
)(
    input  wire clk_100mhz,
    input  wire reset,
    input  wire game_tick,

    input  wire up_pressed,
    input  wire down_pressed,
    input  wire left_pressed,
    input  wire right_pressed,

    output reg  [4:0] snake_x [0:MAX_LEN-1],
    output reg  [4:0] snake_y [0:MAX_LEN-1],
    output reg  [6:0] length,

    output reg  [4:0] food_x,
    output reg  [4:0] food_y,

    output reg         game_over,
    output reg  [7:0]  score
);

    localparam UP    = 2'b00;
    localparam DOWN  = 2'b01;
    localparam LEFT  = 2'b10;
    localparam RIGHT = 2'b11;

    reg [1:0] dir;          // direction currently in effect
    reg [1:0] next_dir;     // buffered direction request (applied on next tick)

    integer i;

    // ---- pseudo-random source for food placement ----
    wire [15:0] rand_val;
    lfsr rng(.clk(clk_100mhz), .reset(reset), .value(rand_val));

    wire [4:0] rand_x = rand_val[4:0];                              // 0-31, matches GRID_W=32
    wire [4:0] rand_y_raw = rand_val[9:5];                          // 0-31
    wire [4:0] rand_y = (rand_y_raw >= GRID_H) ? (rand_y_raw - GRID_H) : rand_y_raw;

    // ---- latch direction requests, ignoring 180-degree reversals ----
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            next_dir <= RIGHT;
        end else begin
            if (up_pressed    && dir != DOWN)  next_dir <= UP;
            if (down_pressed  && dir != UP)    next_dir <= DOWN;
            if (left_pressed  && dir != RIGHT) next_dir <= LEFT;
            if (right_pressed && dir != LEFT)  next_dir <= RIGHT;
        end
    end

    // ---- compute candidate next head position & collisions (combinational) ----
    wire [4:0] head_x = snake_x[0];
    wire [4:0] head_y = snake_y[0];

    wire [4:0] next_head_x = (next_dir == LEFT)  ? head_x - 5'd1 :
                              (next_dir == RIGHT) ? head_x + 5'd1 : head_x;
    wire [4:0] next_head_y = (next_dir == UP)    ? head_y - 5'd1 :
                              (next_dir == DOWN)  ? head_y + 5'd1 : head_y;

    wire wall_hit = (next_dir == LEFT  && head_x == 5'd0)            ||
                    (next_dir == RIGHT && head_x == GRID_W - 1)      ||
                    (next_dir == UP    && head_y == 5'd0)            ||
                    (next_dir == DOWN  && head_y == GRID_H - 1);

    reg self_hit;
    always @(*) begin
        self_hit = 1'b0;
        // Skip index 0 (current head) and the tail segment (index length-1),
        // since the tail vacates its cell the same tick the head moves in
        // (unless we're growing, in which case a same-tick tail collision
        // isn't physically possible anyway).
        if (length >= 3) begin
            for (i = 1; i < MAX_LEN; i = i + 1) begin
                if (i < length - 1) begin
                    if (snake_x[i] == next_head_x && snake_y[i] == next_head_y)
                        self_hit = 1'b1;
                end
            end
        end
    end

    wire food_eaten = (next_head_x == food_x) && (next_head_y == food_y);

    // ---- main sequential update ----
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            dir       <= RIGHT;
            length    <= 7'd3;
            game_over <= 1'b0;
            score     <= 8'd0;
            food_x    <= 5'd20;
            food_y    <= 5'd12;
            // start the snake in the middle of the grid, laid out horizontally
            snake_x[0] <= (GRID_W/2);
            snake_y[0] <= (GRID_H/2);
            snake_x[1] <= (GRID_W/2) - 1;
            snake_y[1] <= (GRID_H/2);
            snake_x[2] <= (GRID_W/2) - 2;
            snake_y[2] <= (GRID_H/2);
            for (i = 3; i < MAX_LEN; i = i + 1) begin
                snake_x[i] <= (GRID_W/2) - 2;
                snake_y[i] <= (GRID_H/2);
            end
        end else if (game_tick && !game_over) begin
            dir <= next_dir;

            if (wall_hit || self_hit) begin
                game_over <= 1'b1;
            end else begin
                // shift body: every segment takes the position ahead of it
                for (i = MAX_LEN - 1; i >= 1; i = i - 1) begin
                    snake_x[i] <= snake_x[i-1];
                    snake_y[i] <= snake_y[i-1];
                end
                snake_x[0] <= next_head_x;
                snake_y[0] <= next_head_y;

                if (food_eaten) begin
                    if (length < MAX_LEN)
                        length <= length + 7'd1;
                    score  <= score + 8'd1;
                    food_x <= rand_x;
                    food_y <= rand_y;
                end
            end
        end
    end

endmodule
