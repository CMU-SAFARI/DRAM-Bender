#!/usr/bin/env python3
"""Single-sided RowHammer — using @program_template for your own JIT-compiled
template.

This example defines ONE fused program (init victim, init aggressor, hammer,
read victim) as a `@program_template`. On the first call, the decorator
traces the builder sequence, generates a C++ plugin, and loads it; every
subsequent call just patches the scalar arguments into the already-compiled
plugin. For a sweep of N victim rows, you pay the compile cost once and the
remaining N-1 iterations run at native speed.

Compare with `examples/single_sided_rowhammer.py`, which achieves the
same effect by calling the (already @program_template-decorated) shipped
templates via `drambender.builtin_programs.configure(target=...)`. This file shows
you how to write one yourself.
"""

import argparse
import sys

import numpy as np

import drambender
from drambender.api import (
    DDR4Target,
    HostInterface,
    ProgramBuilder,
    open_board,
    program_template,
)
from drambender.api.program.instructions import *


CACHELINES_PER_ROW  = 128
WORDS_PER_CACHELINE = 16
COLUMN_STRIDE       = 8
ROW_BYTES           = 8192
ROW_WORDS           = ROW_BYTES // 4
DDR4_TARGET = DDR4Target(
    cachelines_per_row=CACHELINES_PER_ROW,
    column_stride=COLUMN_STRIDE,
    words_per_cacheline=WORDS_PER_CACHELINE,
)


def count_bitflips(mask: np.ndarray) -> int:
    return int(np.unpackbits(mask.view(np.uint8), bitorder="little").sum())


# ----------------------------------------------------------------------------
# JIT-compiled template. Scalar parameters (int) are patchable across calls;
# loops with constant trip counts are unrolled at trace time.
# ----------------------------------------------------------------------------
@program_template
def build_rowhammer_program(
    bank: int,
    victim_row: int,
    aggressor_row: int,
    victim_pattern: int,
    aggressor_pattern: int,
    hammer_count: int,
):
    p = ProgramBuilder(target=DDR4_TARGET)
    p.alloc_reg("NUM_HMR")
    p.alloc_reg("HMR_COUNTER")

    p.LI(bank, "BAR")
    p.LI(DDR4_TARGET.column_stride, "CASR")

    # --- Initialize victim row ---
    p.LI(victim_row, "RAR")
    for index in range(WORDS_PER_CACHELINE):
        p.LI(victim_pattern, "PATTERN_REG")
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
    p.SLEEP(2)
    # --- Initialize aggressor row ---
    p.LI(aggressor_row, "RAR")
    for index in range(WORDS_PER_CACHELINE):
        p.LI(aggressor_pattern, "PATTERN_REG")
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
    p.SLEEP(2)
    # --- Hammer the aggressor row ---
    p.LI(aggressor_row, "RAR")
    p.LI(0, "HMR_COUNTER")
    p.LI(hammer_count, "NUM_HMR")
    p.LABEL("HMR_BEGIN")
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.ADDI("HMR_COUNTER", 1, "HMR_COUNTER")
    p.DRAM(NOP(), NOP(), NOP(), ACT("BAR", "RAR"))
    p.BL("HMR_COUNTER", "NUM_HMR", "HMR_BEGIN")

    # --- Read the victim row back ---
    p.LI(victim_row, "RAR")
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
    p.SLEEP(3)  # tRP cushion
    return p.conclude()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--pci-bdf", required=True)
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--start-row", type=int, default=81)
    parser.add_argument("--num-victims", type=int, default=30)
    parser.add_argument("--hammer-count", type=int, default=500000)
    args = parser.parse_args()

    board = open_board(
        DDR4_TARGET,
        pci_bdf=args.pci_bdf,
        xdma_channel=args.xdma_channel,
        host_interface=HostInterface.XDMA,
    )
    board.reset_fpga()

    total_vulnerable = 0
    total_bitflips = 0

    for v in range(args.num_victims):
        victim_physical = args.start_row + v
        aggressor_physical = victim_physical + 1

        victim = drambender.rows.Row(
            physical_id=victim_physical,
            row_mapping="MI1",
            data_pattern=0x00000000,
        )
        aggressor = drambender.rows.Row(
            physical_id=aggressor_physical,
            row_mapping="MI1",
            data_pattern=0xFFFFFFFF,
        )

        # First call compiles + loads the plugin (~few hundred ms); all
        # subsequent calls with the same scalar shape just patch the args
        # into the loaded plugin (~microseconds).
        program = build_rowhammer_program(
            bank=args.bank,
            victim_row=victim.logical_id,
            aggressor_row=aggressor.logical_id,
            victim_pattern=0x00000000,
            aggressor_pattern=0xFFFFFFFF,
            hammer_count=args.hammer_count,
        )

        board.execute(program)
        rb = np.empty(ROW_WORDS, dtype=np.uint32)
        board.receive_into(rb)
        board.synchronize()
        pattern = np.asarray(victim.write_pattern, dtype=np.uint32)
        expected = np.tile(pattern, ROW_WORDS // len(pattern))
        mask = rb ^ expected

        n_flips = count_bitflips(mask)
        total_bitflips += n_flips
        if n_flips > 0:
            total_vulnerable += 1
            print(
                f"  row {victim_physical:5d} -> {victim.logical_id:5d} "
                f"(aggressor {aggressor_physical} -> {aggressor.logical_id}): "
                f"{n_flips} bitflips"
            )

    print(f"\nResult: {total_vulnerable}/{args.num_victims} rows vulnerable, "
          f"{total_bitflips} total bitflips")
    return 1 if total_vulnerable > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
