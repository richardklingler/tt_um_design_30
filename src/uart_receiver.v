// UART receiver, 8N1 — GateLab's uart-echo template made into chip logic: the same behaviour, with a synchronous
// active-low reset instead of initial values (an ASIC's flip-flops power up in no defined state). Samples each bit in
// its middle; `valid` is high for one clock cycle when a byte with a correct stop bit has arrived.

module uart_receiver #(
    parameter CLKS_PER_BIT = 104
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid
);
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    // Two flip-flops bring the asynchronous input into the clock domain. The idle line is high.
    reg [1:0] sync;
    always @(posedge clk)
        if (!rst_n) sync <= 2'b11;
        else        sync <= {sync[0], rx};
    wire rx_sync = sync[1];

    // A start bit begins with a falling edge: a line that is still low after a framing error
    // (or a break) isn't a new byte.
    reg rx_last;
    always @(posedge clk)
        if (!rst_n) rx_last <= 1'b1;
        else        rx_last <= rx_sync;
    wire rx_fell = rx_last && !rx_sync;

    reg [1:0] state;
    reg [$clog2(CLKS_PER_BIT)-1:0] clocks;
    reg [2:0] bit_index;

    always @(posedge clk) begin
        if (!rst_n) begin
            data <= 8'd0;
            valid <= 1'b0;
            state <= IDLE;
            clocks <= 0;
            bit_index <= 3'd0;
        end else begin
            valid <= 1'b0;
            case (state)
                IDLE:
                    if (rx_fell) begin
                        clocks <= 0;
                        state <= START;
                    end

                // Check the middle of the start bit; a short glitch goes back to idle.
                START:
                    if (clocks == CLKS_PER_BIT / 2 - 1) begin
                        clocks <= 0;
                        bit_index <= 3'd0;
                        state <= rx_sync ? IDLE : DATA;
                    end else begin
                        clocks <= clocks + 1'b1;
                    end

                // Least significant bit first.
                DATA:
                    if (clocks == CLKS_PER_BIT - 1) begin
                        clocks <= 0;
                        data[bit_index] <= rx_sync;
                        bit_index <= bit_index + 1'b1;
                        if (bit_index == 3'd7)
                            state <= STOP;
                    end else begin
                        clocks <= clocks + 1'b1;
                    end

                // A low stop bit is a framing error: the byte is dropped.
                STOP:
                    if (clocks == CLKS_PER_BIT - 1) begin
                        clocks <= 0;
                        valid <= rx_sync;
                        state <= IDLE;
                    end else begin
                        clocks <= clocks + 1'b1;
                    end
            endcase
        end
    end
endmodule
