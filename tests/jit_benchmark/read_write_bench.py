#!/usr/bin/env python3
"""Minimal read/write check using ad hoc Python-side DRAM Bender programs."""

import argparse
import sys
import time

import numpy as np

from draminspector.api import (
    BoardType,
    FinalProgram,
    HostInterface,
    ProgramBuilder,
    open_board,
)
from draminspector.api.program.instructions import *


CACHELINES_PER_ROW = 128
WORDS_PER_CACHELINE = 16
COLUMN_STRIDE = 8


def build_write_program(bank: int, row: int, pattern: int) -> FinalProgram:
    p = ProgramBuilder()
    p.LI(bank, "BAR")
    p.LI(row, "RAR")
    p.LI(COLUMN_STRIDE, "CASR")

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


def build_read_program(bank: int, row: int) -> FinalProgram:
    p = ProgramBuilder()
    p.LI(bank, "BAR")
    p.LI(row, "RAR")
    p.LI(COLUMN_STRIDE, "CASR")

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
    parser = argparse.ArgumentParser(description="Minimal DRAM read/write check.")
    parser.add_argument("--instance-id", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--row", type=int, default=0)
    parser.add_argument("--pattern", type=lambda value: int(value, 0), default=0xDEADBEEF)
    args = parser.parse_args()

    board = open_board(
        BoardType.DDR4,
        instance_id=args.instance_id,
        host_interface=HostInterface.XDMA,
    )
    board.reset_fpga()

    print(
        f"read_write: instance={args.instance_id} bank={args.bank} "
        f"row={args.row} pattern=0x{args.pattern:08x}"
    )

    expected = np.full(
        CACHELINES_PER_ROW * WORDS_PER_CACHELINE,
        np.uint32(args.pattern),
        dtype=np.uint32,
    )
    readback = np.empty_like(expected)

    t_start = time.perf_counter()
    write_program = build_write_program(args.bank, args.row, args.pattern)
    t_build_w = time.perf_counter()
    read_program = build_read_program(args.bank, args.row)
    t_build_r = time.perf_counter()
    board.execute([write_program, read_program])
    t_execute = time.perf_counter()
    board.receive_into(readback)
    t_recv = time.perf_counter()
    board.synchronize()
    t_sync = time.perf_counter()
    matches = np.array_equal(readback, expected)
    mismatched_words = 0 if matches else int(np.count_nonzero(readback != expected))
    t_verify = time.perf_counter()

    if matches:
        print(f"PASS: {readback.size} words matched")
    else:
        print(f"FAIL: {mismatched_words} words mismatched")

    t_total = t_verify - t_start
    phases = [
        ("build_write",   t_build_w - t_start),
        ("build_read",    t_build_r - t_build_w),
        ("execute",       t_execute - t_build_r),
        ("receive",       t_recv    - t_execute),
        ("synchronize",   t_sync    - t_recv),
        ("verify",        t_verify  - t_sync),
    ]
    print("\nRuntime breakdown:")
    for name, dt in phases:
        print(f"  {name:<16} {dt*1e6:9.3f} us {100*dt/t_total:6.2f}%")
    print(f"  {'TOTAL':<16} {t_total*1e6:9.3f} us")

    return 0 if matches else 1


if __name__ == "__main__":
    sys.exit(main())
