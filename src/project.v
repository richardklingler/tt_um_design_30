// design 30: GateLab's UART echo as a Tiny Tapeout tile. Every byte received at 115200 baud, 8N1, is sent back; seven
// outputs count the bytes. The UART is on the pins the Tiny Tapeout demo board wires to its RP2040 (ui_in[3] = RX,
// uo_out[4] = TX). A tile has exactly Tiny Tapeout's ports; ena is always 1 while the tile is selected.
`default_nettype none

module tt_um_design_30 #(
    // The tile's clock: 25 MHz, as Project Settings ▸ Build ▸ Tiny Tapeout says (the testbench runs a slower one).
    parameter CLK_HZ = 25000000
) (
    input  wire [7:0] ui_in,    // dedicated inputs
    output wire [7:0] uo_out,   // dedicated outputs
    input  wire [7:0] uio_in,   // bidirectional pins: input path
    output wire [7:0] uio_out,  // bidirectional pins: output path
    output wire [7:0] uio_oe,   // bidirectional pins: 1 = output
    input  wire       ena,      // 1 while the tile is selected
    input  wire       clk,
    input  wire       rst_n     // low to reset
);
    wire       tx;
    wire [7:0] count;

    uart_echo #(
        .CLK_HZ(CLK_HZ)
    ) echo (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(ui_in[3]),
        .uart_tx(tx),
        .count(count)
    );

    // Every output is driven: the count on bits 0-3 and 5-7, the UART's TX on bit 4; the bidirectional pins stay inputs.
    assign uo_out  = {count[6:4], tx, count[3:0]};
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Inputs the design doesn't use (Verilator and Tiny Tapeout's linter want them named).
    wire _unused = &{ena, ui_in[7:4], ui_in[2:0], uio_in, count[7], 1'b0};
endmodule
