# Verilog Snake Game (VGA + Keyboard)

A classic grid-based Snake game written in synthesizable Verilog, meant to run
on an FPGA dev board and be played on a monitor via VGA, using arrow keys on
a keyboard plugged into the board.

**Important:** this needs real FPGA hardware (or a simulator, for logic
verification only — you won't get a visible game without a board+monitor).
It will not run "as is" in a browser or on a PC by itself.

## Files

| File                | Purpose |
|---------------------|---------|
| `top_snake.v`        | Top-level module — wires everything together |
| `clock_divider.v`   | Derives 25 MHz VGA pixel clock + slow game-tick pulse from 100 MHz |
| `vga_sync.v`         | 640x480@60Hz VGA timing generator |
| `ps2_keyboard.v`     | Decodes PS/2 scan codes into arrow-key pulses |
| `lfsr.v`              | Pseudo-random generator, used to place food |
| `snake_game.v`       | Core game logic: movement, growth, collisions |
| `snake_basys3.xdc`   | Example pin constraints for a Digilent Basys3 |
| `tb_snake_game.v`    | Testbench to verify game logic in simulation, no hardware needed |

## Hardware assumptions

- 100 MHz system clock input
- VGA output port, 4 bits each for R/G/B (12-bit color) — this matches most
  Digilent boards (Basys3, Nexys, etc.)
- A keyboard input that speaks the PS/2 clock+data protocol. On the
  **Basys3**, the board doesn't have a literal PS/2 port — it has a USB HID
  host port serviced by an onboard companion microcontroller that translates
  a plugged-in USB keyboard into PS/2-style signals on two FPGA pins. So a
  normal USB keyboard works fine; you just wire up the same two pins
  (`ps2_clk`, `ps2_data`) as any PS/2 design would.
- A push button for reset

If your board is different (Nexys, Arty, Cmod, etc.), reuse the RTL as-is and
just rewrite `snake_basys3.xdc` with your board's actual pin names — that's
the only board-specific file.

## Building

1. Create a new project in Vivado (or your toolchain of choice) targeting
   your board's FPGA part.
2. Add all the `.v` files above except `tb_snake_game.v` as design sources.
3. Add `snake_basys3.xdc` (edited for your board) as a constraints file.
4. Set `top_snake` as the top module.
5. Synthesize, implement, generate bitstream, program the board.
6. Connect VGA to a monitor, plug a keyboard into the USB HID port, hit the
   reset button, and play with the arrow keys.

## Simulating the logic first (recommended)

Before touching hardware, you can sanity-check the core game logic
(movement, direction changes, collisions) with the included testbench:

```
iverilog -o sim snake_game.v lfsr.v tb_snake_game.v
vvp sim
```

This prints the snake's head position each tick as it moves right, then
down, then left, so you can confirm turning and movement behave correctly
before wiring up VGA/keyboard hardware.

## Gameplay

- 32x24 grid of 20x20 pixel cells, exactly filling a 640x480 frame
- White border = wall (hitting it ends the game)
- Green = snake, Yellow = food
- Eating food grows the snake by one segment and increments the score
- Hitting the wall or your own body ends the game (screen flashes red)
- Press the reset button to start a new game
- Game speed is set by `TICK_DIV` in `clock_divider.v` — lower it for a
  faster/harder game, raise it for a slower/easier one

## Known simplifications (things to improve if you extend this)

- **Max snake length is capped** at `MAX_LEN` (64 by default, set in
  `top_snake.v` / `snake_game.v`) to keep resource usage and the per-pixel
  comparator logic reasonable. Raise it if your FPGA has room; the grid
  itself holds up to 32*24 = 768 cells.
- **Food placement doesn't check for overlap with the snake's body.** With
  a 32x24 grid this is a small-probability edge case, but for a more
  polished version you'd want to re-roll the LFSR if the candidate food
  cell coincides with any snake segment.
- **No score display on the board itself** (e.g., on 7-segment displays) —
  `score` is computed and available as an output; wire it to your board's
  seven-segment driver if you want it visible without a debugger.
- **Unpacked array ports** (`output reg [4:0] snake_x [0:MAX_LEN-1]`) are
  used to pass the snake's coordinate arrays between modules. Vivado and
  Icarus Verilog handle this fine, but some older/stricter toolchains only
  support this in SystemVerilog. If your tool complains, just rename the
  `.v` files to `.sv` — no other changes needed.
