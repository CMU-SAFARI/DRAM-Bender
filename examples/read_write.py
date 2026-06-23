#!/usr/bin/env python3
"""Minimal read/write check.

Writes `pattern` to every word of one DRAM row, reads the row back, and
verifies the readback matches. Useful as a first-run check after bringing
up a new board or after a code change that could affect the read/write
pipeline.
"""

import argparse
import sys

import numpy as np

import drambender
from drambender.api import BoardType, HostInterface, open_board


CACHELINES_PER_ROW  = 128
WORDS_PER_CACHELINE = 16


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--board-id", type=int, default=0)
    parser.add_argument("--instance-id", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--row", type=int, default=0)
    parser.add_argument("--pattern", type=lambda v: int(v, 0), default=0xDEADBEEF,
                        help="32-bit data word to write and verify (decimal or 0x-hex).")
    args = parser.parse_args()

    board = open_board(
        BoardType.DDR4,
        board_id=args.board_id,
        instance_id=args.instance_id,
        host_interface=HostInterface.XDMA,
    )
    board.reset_fpga()

    builtin_progs = drambender.builtin_programs.configure(
        cachelines_per_row=CACHELINES_PER_ROW,
        column_stride=8,
        words_per_cacheline=WORDS_PER_CACHELINE,
    )

    # Broadcast the scalar pattern to every word of a single cacheline; the
    # write_row template loads this wide register and writes every cacheline
    # in the row.
    pattern_words = (args.pattern,) * WORDS_PER_CACHELINE

    write_program = builtin_progs.write_row(args.bank, args.row, pattern_words)
    read_program  = builtin_progs.read_row(args.bank, args.row)

    expected = np.full(
        CACHELINES_PER_ROW * WORDS_PER_CACHELINE,
        np.uint32(args.pattern),
        dtype=np.uint32,
    )
    readback = np.empty_like(expected)

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
