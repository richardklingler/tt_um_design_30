<!---
This file is the tile's datasheet page in Tiny Tapeout's documentation (GateLab copies it into the repository). Keep the
three sections; Tiny Tapeout's docs check fails while "How it works" or "How to test" still holds the template's placeholder.
-->

## How it works

A UART echo: every byte received at 115200 baud (8 data bits, no parity, one stop bit) on `ui_in[3]` is sent back on
`uo_out[4]`, and a counter of the bytes received shows on the other seven outputs (`uo_out[0]`–`uo_out[3]` and
`uo_out[5]`–`uo_out[7]`). The tile runs at 25 MHz; a reset (`rst_n` low) clears the counter. A byte with a framing error
(a low stop bit) is dropped.

## How to test

Set the demo board's clock to 25 MHz and select the tile. Open a terminal on the RP2040's serial port at 115200 baud, 8N1:
every character typed comes back, and the LEDs on `uo_out` count up by one for each byte.

## External hardware

None: the demo board's RP2040 is the other end of the UART.
