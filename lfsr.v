// ============================================================
// lfsr.v
// Simple free-running 16-bit Fibonacci LFSR used as a pseudo-random
// source for placing food on the grid. Runs every clock so that by
// the time we need a new food position, the value is unpredictable
// relative to player input.
// ============================================================
module lfsr(
    input  wire        clk,
    input  wire        reset,
    output wire [15:0] value
);

    reg [15:0] shift;

    // taps for a maximal-length 16-bit LFSR: 16,14,13,11
    wire feedback = shift[15] ^ shift[13] ^ shift[12] ^ shift[10];

    always @(posedge clk or posedge reset) begin
        if (reset)
            shift <= 16'hACE1;   // non-zero seed
        else
            shift <= {shift[14:0], feedback};
    end

    assign value = shift;

endmodule
