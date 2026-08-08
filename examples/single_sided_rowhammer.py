#!/usr/bin/env python3
"""Single-sided RowHammer — minimal reference.

For each victim row in [start_row, start_row + num_victims):

  1. Write the victim row with 0x00000000.
  2. Write the aggressor row (victim + 1) with 0xFFFFFFFF.
  3. Hammer the aggressor `hammer_count` times.
  4. Read the victim back and count any bit flips (1 bits in the readback).

The physical↔logical row mapping is MI1 — see `drambender.rows.mappings.mi1`.
"""

import argparse
import sys

import numpy as np

import drambender
from drambender.api import DDR4Target, HostInterface, open_board

ROW_BYTES = 8192
ROW_WORDS = ROW_BYTES // 4


def count_bitflips(mask: np.ndarray) -> int:
    return int(np.unpackbits(mask.view(np.uint8), bitorder="little").sum())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--pci-bdf", required=True)
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--start-row", type=int, default=81,
                        help="First victim row (physical).")
    parser.add_argument("--num-victims", type=int, default=30,
                        help="Number of consecutive victim rows to test.")
    parser.add_argument("--hammer-count", type=int, default=500000)
    args = parser.parse_args()

    # Bind the shipped templates to an explicit target. Geometry values are
    # board-specific facts and must be stated explicitly.
    target = DDR4Target(
        cachelines_per_row=128,
        column_stride=8,
        words_per_cacheline=16,
    )
    builtin_progs = drambender.builtin_programs.configure(target=target)

    board = open_board(
        target,
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

        # `Row` applies the named row mapping and carries the write pattern
        # through any bitline/DQ swizzling the DRAM module may expose.
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

        # Four back-to-back FPGA programs: init the two rows, hammer the
        # aggressor, read the victim. `board.execute([...])` submits them as
        # a sequence; `receive_into(...)` drains the victim row back into the
        # numpy buffer, which we XOR against the expected pattern.
        board.execute([
            builtin_progs.write_row(args.bank, victim.logical_id, victim.write_pattern),
            builtin_progs.write_row(args.bank, aggressor.logical_id, aggressor.write_pattern),
            builtin_progs.single_sided_rowhammer(
                args.bank, aggressor.logical_id, args.hammer_count,
            ),
            builtin_progs.read_row(args.bank, victim.logical_id),
        ])
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
