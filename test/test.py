# SPDX-License-Identifier: Apache-2.0
# Written by GateLab: after a reset every output of the tile is a defined 0 or 1. In Tiny Tapeout's gate-level test this
# runs on the routed netlist, where a register without a reset stays unknown. Replace it with a test of what the design
# does; GateLab's own testbench checks that in GateLab.

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def outputs_are_defined_after_reset(dut):
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 100)
    for name in ("uo_out", "uio_out", "uio_oe"):
        value = getattr(dut, name).value
        assert value.is_resolvable, f"{name} is {value} after reset: a register without a reset?"
