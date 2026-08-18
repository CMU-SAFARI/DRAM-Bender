#!/usr/bin/env python3
"""Minimal HBM2 read/write check for the Alveo U50 and U55C.

Writes `pattern` to every word of one HBM2 row, reads the row back, and
verifies the readback. Useful as a first-run check after bringing up a new
board or after a code change that could affect the read/write pipeline.
"""

import argparse
import sys

import numpy as np

import drambender
from drambender.api import HBM2U50, HBM2U50Target, HBM2U55C, HBM2U55Target


BYTES_PER_COLUMN_READ = 64     # one RD returns a 64-byte cacheline...
BYTES_PER_PSEUDO_CHANNEL = 32  # ...split between pseudo-channels 0 and 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--pci-bdf", required=True)
    parser.add_argument("--board", choices=("u50", "u55c"), default="u55c")
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument("--channel", type=int, default=0)
    parser.add_argument("--pseudo-channel", type=int, default=0)
    parser.add_argument("--sid", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--row", type=int, default=0)
    parser.add_argument("--pattern", type=lambda v: int(v, 0), default=0xDEADBEEF,
                        help="32-bit data word to write and verify (decimal or 0x-hex).")
    args = parser.parse_args()

    target_cls, board_cls = (
        (HBM2U50Target, HBM2U50) if args.board == "u50" else (HBM2U55Target, HBM2U55C)
    )
    target = target_cls(
        channel=args.channel,
        pseudo_channel=args.pseudo_channel,
        sid=args.sid,
    )
    builtin_progs = drambender.builtin_programs.configure(target=target)

    # Broadcast the scalar pattern to every word of a single cacheline; the
    # write_row template loads this wide register and writes every column
    # in the row.
    pattern_words = (args.pattern,) * target.words_per_cacheline

    write_program = builtin_progs.write_row(args.bank, args.row, pattern_words)
    read_program  = builtin_progs.read_row(args.bank, args.row)

    readback = np.empty(target.columns_per_row * BYTES_PER_COLUMN_READ, dtype=np.uint8)

    with board_cls(args.pci_bdf, args.xdma_channel) as board:
        board.full_reset()
        # A previous session may have left the FPGA discarding readback data.
        board.discard_readback_data(False)
        board.execute([write_program, read_program])
        board.receive_into(readback)
        board.synchronize()

    # Each 64-byte column readback carries both pseudo-channels; only the
    # 32-byte half of the selected pseudo-channel holds this program's data.
    chunks = readback.reshape(target.columns_per_row, BYTES_PER_COLUMN_READ)
    offset = args.pseudo_channel * BYTES_PER_PSEUDO_CHANNEL
    useful = (
        np.ascontiguousarray(chunks[:, offset:offset + BYTES_PER_PSEUDO_CHANNEL])
        .view(np.uint32)
        .reshape(-1)
    )
    expected = np.full_like(useful, np.uint32(args.pattern))

    if np.array_equal(useful, expected):
        print(f"PASS: {useful.size} words matched (pattern=0x{args.pattern:08x})")
        return 0

    mismatched = int(np.count_nonzero(useful != expected))
    print(f"FAIL: {mismatched}/{useful.size} words mismatched")
    return 1


if __name__ == "__main__":
    sys.exit(main())
