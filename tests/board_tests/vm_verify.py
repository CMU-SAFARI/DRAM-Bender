#!/usr/bin/env python3
"""Compare VM-predicted execution time with measured board wall clock time.

Each test is a single program with DRAM reads so the receiver thread
terminates cleanly. A full_reset() is issued between tests to ensure
clean state.
"""

import sys
import time

import numpy as np

import drambender
from drambender.api import DDR4Target, FinalProgram, ProgramBuilder
from drambender.api.program.instructions import *

CACHELINES_PER_ROW = 128
BYTES_PER_CACHELINE = 64
ROW_BYTES = CACHELINES_PER_ROW * BYTES_PER_CACHELINE
DDR4_TARGET = DDR4Target(cachelines_per_row=CACHELINES_PER_ROW, column_stride=8)


def make_write_read_row(bank: int, row: int, pattern: int) -> FinalProgram:
    """Write a pattern to a row, then read it back."""
    p = ProgramBuilder(target=DDR4_TARGET)
    p.alloc_reg("PATTERN_REG")
    p.LI(bank, "BAR")
    p.LI(row, "RAR")
    p.LI(DDR4_TARGET.column_stride, "CASR")
    p.LI(pattern, "PATTERN_REG")
    for index in range(DDR4_TARGET.words_per_cacheline):
        p.LDWD("PATTERN_REG", index)

    # Write
    p.LI(0, "CAR")
    p.DRAMSEQ(PRE("BAR", delay=11), ACT("BAR", "RAR", delay=11), ALIGN())
    p.DRAMSEQ(
        *(WR("BAR", "CAR", icar=1, delay=7) for _ in range(CACHELINES_PER_ROW - 1)),
        WR("BAR", "CAR", icar=1, delay=15),
        PRE("BAR", delay=11),
        ALIGN(),
    )

    # Read
    p.LI(0, "CAR")
    p.DRAMSEQ(
        PRE("BAR", delay=11),
        ACT("BAR", "RAR", delay=11),
        *(RD("BAR", "CAR", icar=1, delay=7) for _ in range(CACHELINES_PER_ROW - 1)),
        RD("BAR", "CAR", icar=1, delay=11),
        PRE("BAR", delay=11),
        ALIGN(),
    )
    p.SLEEP(3)  # tRP cushion
    return p.conclude()


def make_hammer_read(bank: int, hammer_count: int) -> FinalProgram:
    """Init victim, hammer aggressor, read victim back."""
    p = ProgramBuilder(target=DDR4_TARGET)
    p.alloc_reg("PATTERN_REG")
    p.alloc_reg("CTR")
    p.alloc_reg("LIMIT")
    p.LI(bank, "BAR")
    p.LI(DDR4_TARGET.column_stride, "CASR")

    # Init victim row 0
    p.LI(0, "RAR")
    p.LI(0x00000000, "PATTERN_REG")
    for index in range(DDR4_TARGET.words_per_cacheline):
        p.LDWD("PATTERN_REG", index)
    p.LI(0, "CAR")
    p.DRAMSEQ(PRE("BAR", delay=11), ACT("BAR", "RAR", delay=11), ALIGN())
    p.DRAMSEQ(
        *(WR("BAR", "CAR", icar=1, delay=7) for _ in range(CACHELINES_PER_ROW - 1)),
        WR("BAR", "CAR", icar=1, delay=15),
        PRE("BAR", delay=11),
        ALIGN(),
    )

    # Hammer row 1
    p.LI(1, "RAR")
    p.LI(0, "CTR")
    p.LI(hammer_count, "LIMIT")
    p.DRAMSEQ(ACT("BAR", "RAR", delay=23), ALIGN())
    p.LABEL("HAMMER")
    p.DRAMSEQ(PRE("BAR", delay=3), ALIGN())
    p.ADDI("CTR", 1, "CTR")
    p.DRAMSEQ(ACT("BAR", "RAR", delay=3), ALIGN())
    p.BL("CTR", "LIMIT", "HAMMER")
    p.DRAMSEQ(PRE("BAR", delay=11), ALIGN())

    # Read victim row 0
    p.LI(0, "RAR")
    p.LI(0, "CAR")
    p.DRAMSEQ(
        PRE("BAR", delay=11),
        ACT("BAR", "RAR", delay=11),
        *(RD("BAR", "CAR", icar=1, delay=7) for _ in range(CACHELINES_PER_ROW - 1)),
        RD("BAR", "CAR", icar=1, delay=11),
        PRE("BAR", delay=11),
        ALIGN(),
    )
    p.SLEEP(3)  # tRP cushion
    return p.conclude()


def run_test(board, name: str, prog: FinalProgram):
    """Execute one test program, measure wall time, compare with VM."""
    vm_result = prog.dry_run(100_000_000)
    vm_us = vm_result.total_ns / 1000

    t0 = time.perf_counter()
    board.execute(prog)
    board.receive_into(np.empty(ROW_BYTES, dtype=np.uint8))
    board.synchronize()
    hw_us = (time.perf_counter() - t0) * 1e6

    ratio = hw_us / vm_us if vm_us > 0 else float('inf')
    print(f"{name:<25s} "
          f"{vm_result.total_cycles:>12,} "
          f"{vm_us:>10.1f}us "
          f"{hw_us:>10.1f}us "
          f"{ratio:>7.2f}x")


def main() -> int:
    board = drambender.api.DDR4(0, 0)
    board.reset_fpga()
    print("Board reset complete.\n")

    print(f"{'Test':<25s} {'VM cycles':>12s} {'VM time':>12s} {'HW wall':>12s} {'Ratio':>8s}")
    print("-" * 72)

    tests = [
        ("write+read 1 row",     make_write_read_row(1, 0, 0xDEADBEEF)),
        ("write+read 1 row (2)", make_write_read_row(1, 1, 0xAAAAAAAA)),
        ("hammer 100 + read",    make_hammer_read(1, 100)),
        ("hammer 1K + read",     make_hammer_read(1, 1000)),
        ("hammer 10K + read",    make_hammer_read(1, 10000)),
        ("hammer 100K + read",   make_hammer_read(1, 100000)),
    ]

    for name, prog in tests:
        board.reset_fpga()
        run_test(board, name, prog)

    print("\nNote: HW wall includes PCIe round-trip (~100-200us fixed overhead).")
    print("For longer programs (hammer 100K), ratio approaches 1x as FPGA time dominates.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
