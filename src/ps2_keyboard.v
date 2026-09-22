// ============================================================
// ps2_keyboard.v
// Receives raw PS/2 frames (11 bits: start, 8 data, odd parity, stop)
// and decodes arrow-key MAKE codes (Set-2 scan codes):
//   Up    = E0 75
//   Down  = E0 72
//   Left  = E0 6B
//   Right = E0 74
// Break codes are prefixed with F0 and are ignored here since we
// only care about "key was pressed" edges for changing direction.
//
// Outputs a single-cycle pulse on the matching *_pressed line each
// time a new arrow key make-code is fully received.
// ============================================================
module ps2_keyboard(
    input  wire clk_100mhz,
    input  wire reset,
    input  wire ps2_clk,
    input  wire ps2_data,
    output reg  up_pressed,
    output reg  down_pressed,
    output reg  left_pressed,
    output reg  right_pressed
);

    // ---- synchronize PS/2 clock into our clock domain & find falling edges ----
    reg [2:0] ps2_clk_sync;
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset)
            ps2_clk_sync <= 3'b111;
        else
            ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
    end
    wire ps2_clk_falling = (ps2_clk_sync[2:1] == 2'b10);

    reg ps2_data_sync0, ps2_data_sync1;
    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            ps2_data_sync0 <= 1'b1;
            ps2_data_sync1 <= 1'b1;
        end else begin
            ps2_data_sync0 <= ps2_data;
            ps2_data_sync1 <= ps2_data_sync0;
        end
    end

    // ---- shift in 11-bit frame on each falling edge of ps2_clk ----
    reg [10:0] shift_reg;
    reg [3:0]  bit_cnt;
    reg [7:0]  scan_code;
    reg        frame_ready;

    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            shift_reg   <= 11'd0;
            bit_cnt     <= 4'd0;
            frame_ready <= 1'b0;
        end else begin
            frame_ready <= 1'b0;
            if (ps2_clk_falling) begin
                shift_reg <= {ps2_data_sync1, shift_reg[10:1]};
                if (bit_cnt == 4'd10) begin
                    bit_cnt     <= 4'd0;
                    frame_ready <= 1'b1;
                end else begin
                    bit_cnt <= bit_cnt + 4'd1;
                end
            end
        end
    end

    // frame bit layout once fully shifted in (bit0 received first):
    // [0]=start(0) [8:1]=data [9]=parity [10]=stop(1)
    wire [7:0] rx_byte = shift_reg[8:1];

    // ---- scan-code interpreter state machine ----
    // Tracks whether we've seen an E0 (extended) prefix and/or an F0
    // (break/release) prefix so we only fire on arrow-key MAKE codes.
    reg extended;
    reg breaking;

    always @(posedge clk_100mhz or posedge reset) begin
        if (reset) begin
            extended     <= 1'b0;
            breaking     <= 1'b0;
            up_pressed   <= 1'b0;
            down_pressed <= 1'b0;
            left_pressed <= 1'b0;
            right_pressed<= 1'b0;
        end else begin
            up_pressed   <= 1'b0;
            down_pressed <= 1'b0;
            left_pressed <= 1'b0;
            right_pressed<= 1'b0;

            if (frame_ready) begin
                case (rx_byte)
                    8'hE0: extended <= 1'b1;                  // extended prefix
                    8'hF0: breaking <= 1'b1;                  // break prefix
                    default: begin
                        if (extended && !breaking) begin
                            case (rx_byte)
                                8'h75: up_pressed    <= 1'b1;
                                8'h72: down_pressed  <= 1'b1;
                                8'h6B: left_pressed  <= 1'b1;
                                8'h74: right_pressed <= 1'b1;
                                default: ; // not an arrow key, ignore
                            endcase
                        end
                        // any non-prefix byte clears the prefix flags
                        extended <= 1'b0;
                        breaking <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule
