// UART transmitter, 8N1 — GateLab's uart-echo template with a synchronous active-low reset instead of initial values.
// A pulse on `start` while not `busy` sends `data`.

module uart_transmitter #(
    parameter CLKS_PER_BIT = 104
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [7:0] data,
    output wire       tx,
    output wire       busy
);
    // Start bit, eight data bits (least significant first), stop bit.
    reg [9:0] shift;
    reg [3:0] bits_left;
    reg [$clog2(CLKS_PER_BIT)-1:0] clocks;

    assign busy = (bits_left != 4'd0);
    // The idle line is high.
    assign tx = busy ? shift[0] : 1'b1;

    always @(posedge clk) begin
        if (!rst_n) begin
            shift <= 10'h3FF;
            bits_left <= 4'd0;
            clocks <= 0;
        end else if (!busy) begin
            if (start) begin
                shift <= {1'b1, data, 1'b0};
                bits_left <= 4'd10;
                clocks <= 0;
            end
        end else if (clocks == CLKS_PER_BIT - 1) begin
            clocks <= 0;
            shift <= {1'b1, shift[9:1]};
            bits_left <= bits_left - 1'b1;
        end else begin
            clocks <= clocks + 1'b1;
        end
    end
endmodule
