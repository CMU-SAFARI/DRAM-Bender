#!/usr/bin/env python3
"""Minimal read/write check — using @program_template for your own
JIT-compiled templates.

Decorating a program-build function with `@program_template` makes it trace
its builder calls on the first invocation, generate and compile a C++ plugin
in the JIT cache, and call the compiled plugin on every subsequent call.
Scalar arguments (`int`) are patchable across calls at microsecond cost.

Compare with `examples/read_write.py`, which uses the
(already-decorated) shipped templates via
`drambender.builtin_programs.configure(target=...)`. This file shows you how to
write one yourself.
"""

import argparse
import sys

import numpy as np

from drambender.api import (
    DDR4Target,
    FinalProgram,
    HostInterface,
    ProgramBuilder,
    open_board,
    program_template,
)
from drambender.api.program.instructions import *


CACHELINES_PER_ROW  = 128
WORDS_PER_CACHELINE = 16
COLUMN_STRIDE       = 8
DDR4_TARGET = DDR4Target(
    cachelines_per_row=CACHELINES_PER_ROW,
    column_stride=COLUMN_STRIDE,
    words_per_cacheline=WORDS_PER_CACHELINE,
)


@program_template
def build_write_program(bank: int, row: int, pattern: int) -> FinalProgram:
    p = ProgramBuilder(target=DDR4_TARGET)
    p.LI(bank, "BAR")
    p.LI(row, "RAR")
    p.LI(DDR4_TARGET.column_stride, "CASR")

    # Broadcast the scalar pattern word into every lane of the wide register.
    for index in range(WORDS_PER_CACHELINE):
        p.LI(pattern, "PATTERN_REG")
        p.LDWD("PATTERN_REG", index)

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(2)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    for _ in range(CACHELINES_PER_ROW):
        p.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)
    p.SLEEP(8)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)  # tRP cushion
    return p.conclude()


@program_template
def build_read_program(bank: int, row: int) -> FinalProgram:
    p = ProgramBuilder(target=DDR4_TARGET)
    p.LI(bank, "BAR")
    p.LI(row, "RAR")
    p.LI(DDR4_TARGET.column_stride, "CASR")

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(2)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    for _ in range(CACHELINES_PER_ROW):
        p.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)
    p.SLEEP(4)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    return p.conclude()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--pci-bdf", required=True)
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--row", type=int, default=0)
    parser.add_argument("--pattern", type=lambda v: int(v, 0), default=0xDEADBEEF)
    args = parser.parse_args()

    board = open_board(
        DDR4_TARGET,
        pci_bdf=args.pci_bdf,
        xdma_channel=args.xdma_channel,
        host_interface=HostInterface.XDMA,
    )
    board.reset_fpga()

    expected = np.full(
        CACHELINES_PER_ROW * WORDS_PER_CACHELINE,
        np.uint32(args.pattern),
        dtype=np.uint32,
    )
    readback = np.empty_like(expected)

    # Each of these calls returns a FinalProgram. The first call per template
    # compiles + loads a plugin; subsequent calls patch scalar args in-place.
    write_program = build_write_program(args.bank, args.row, args.pattern)
    read_program  = build_read_program(args.bank, args.row)

    board.execute([write_program, read_program])
    board.receive_into(readback)
    board.synchronize()

    if np.array_equal(readback, expected):
        print(f"PASS: {readback.size} words matched (pattern=0x{args.pattern:08x})")
        return 0

    mismatched = int(np.count_nonzero(readback != expected))
    print(f"FAIL: {mismatched}/{readback.size} words mismatched")
    return 1


if __name__ == "__main__":
    sys.exit(main())
