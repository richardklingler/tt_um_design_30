// UART echo: the logic of GateLab's UART echo chip. Every byte received at 115200 baud, 8N1, is sent back; `count` counts the
// bytes (eight output pins, for LEDs on the chip's board). GateLab's uart-echo template made into chip logic: an ASIC's
// flip-flops power up in no defined state, so every register has a reset instead of an initial value.

module uart_echo #(
    // The chip's clock: 50 MHz from an external oscillator (constraints/chip.sdc says the same).
    parameter CLK_HZ = 50_000_000
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx,
    output wire       uart_tx,
    output wire [7:0] count
);
    localparam BAUD = 115200;

    // Clock cycles per bit, rounded to the nearest whole number.
    localparam CLKS_PER_BIT = (CLK_HZ + BAUD / 2) / BAUD;

    // rst_n comes from a pin: synchronise its release so every flip-flop leaves reset on the same clock edge.
    reg [1:0] reset_sync;
    always @(posedge clk or negedge rst_n)
        if (!rst_n) reset_sync <= 2'b00;
        else        reset_sync <= {reset_sync[0], 1'b1};
    wire rst_n_sync = reset_sync[1];

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       tx_busy;

    uart_receiver #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) receiver (
        .clk(clk),
        .rst_n(rst_n_sync),
        .rx(uart_rx),
        .data(rx_data),
        .valid(rx_valid)
    );

    // A one-byte buffer: a byte can arrive while the previous one is still being sent.
    reg [7:0] pending_data;
    reg       pending;
    reg [7:0] received;
    wire      send = pending && !tx_busy;

    always @(posedge clk) begin
        if (!rst_n_sync) begin
            pending_data <= 8'd0;
            pending <= 1'b0;
            received <= 8'd0;
        end else if (rx_valid) begin
            pending_data <= rx_data;
            pending <= 1'b1;
            received <= received + 1'b1;
        end else if (send) begin
            pending <= 1'b0;
        end
    end

    uart_transmitter #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) transmitter (
        .clk(clk),
        .rst_n(rst_n_sync),
        .start(send),
        .data(pending_data),
        .tx(uart_tx),
        .busy(tx_busy)
    );

    assign count = received;
endmodule
