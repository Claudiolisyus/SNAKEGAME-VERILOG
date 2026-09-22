// ============================================================
// tb_snake_game.v
// Simple testbench that drives the snake_game module directly
// (no VGA/PS2 needed) so you can verify movement, growth, and
// collision logic in simulation (Icarus Verilog / Vivado sim /
// ModelSim) before ever touching hardware.
//
// Run with Icarus Verilog, e.g.:
//   iverilog -o sim snake_game.v lfsr.v tb_snake_game.v
//   vvp sim
// ============================================================
`timescale 1ns/1ps

module tb_snake_game;

    reg clk = 0;
    reg reset = 1;
    reg game_tick = 0;
    reg up_p = 0, down_p = 0, left_p = 0, right_p = 0;

    wire [4:0] snake_x [0:63];
    wire [4:0] snake_y [0:63];
    wire [6:0] length;
    wire [4:0] food_x, food_y;
    wire       game_over;
    wire [7:0] score;

    snake_game #(.GRID_W(32), .GRID_H(24), .MAX_LEN(64)) dut (
        .clk_100mhz(clk),
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

    // 100 MHz clock
    always #5 clk = ~clk;

    task step_tick;
        begin
            @(posedge clk);
            game_tick = 1;
            @(posedge clk);
            game_tick = 0;
        end
    endtask

    integer i;
    initial begin
        $dumpfile("snake_tb.vcd");
        $dumpvars(0, tb_snake_game);

        // hold reset for a couple cycles
        repeat (4) @(posedge clk);
        reset = 0;

        $display("Initial head=(%0d,%0d) length=%0d food=(%0d,%0d)",
                   snake_x[0], snake_y[0], length, food_x, food_y);

        // move right a few steps
        for (i = 0; i < 5; i = i + 1) begin
            step_tick;
            $display("t=%0t head=(%0d,%0d) length=%0d score=%0d game_over=%b",
                       $time, snake_x[0], snake_y[0], length, score, game_over);
        end

        // turn down
        down_p = 1; step_tick; down_p = 0;
        for (i = 0; i < 3; i = i + 1) begin
            step_tick;
            $display("t=%0t head=(%0d,%0d) length=%0d score=%0d game_over=%b",
                       $time, snake_x[0], snake_y[0], length, score, game_over);
        end

        // turn left
        left_p = 1; step_tick; left_p = 0;
        for (i = 0; i < 3; i = i + 1) begin
            step_tick;
            $display("t=%0t head=(%0d,%0d) length=%0d score=%0d game_over=%b",
                       $time, snake_x[0], snake_y[0], length, score, game_over);
        end

        $display("Simulation finished.");
        $finish;
    end

endmodule
