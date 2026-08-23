#!/usr/bin/env python3
"""Read and write one row on an Alveo U200, U50, or U55C.

The same target-aware DRAM Bender programs are used for DDR4 and HBM2. The
selected board changes the memory target and, for HBM2, how the paired
pseudo-channel readback is unpacked.
"""

import argparse
import sys

import numpy as np

import drambender
from drambender.api import (
    DDR4Target,
    HBM2,
    HBM2Target,
    HBM2U50Target,
    HBM2U55CTarget,
    HostInterface,
    open_board,
)


BYTES_PER_WORD = np.dtype(np.uint32).itemsize
BYTES_PER_HBM2_COLUMN_READ = 64
BYTES_PER_HBM2_PSEUDO_CHANNEL = 32


def parse_u32(value: str) -> int:
    try:
        parsed = int(value, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            "expected a decimal or 0x-prefixed integer"
        ) from exc
    if not 0 <= parsed <= 0xFFFFFFFF:
        raise argparse.ArgumentTypeError("value must fit in 32 bits")
    return parsed


def make_target(args: argparse.Namespace) -> DDR4Target | HBM2Target:
    """Create the memory target selected on the command line."""
    if args.board == "u200":
        return DDR4Target(
            cachelines_per_row=128,
            column_stride=8,
            words_per_cacheline=16,
        )

    target_type = HBM2U50Target if args.board == "u50" else HBM2U55CTarget
    return target_type(
        channel=args.channel,
        pseudo_channel=args.pseudo_channel,
        sid=args.sid,
    )


def normalize_readback(
    raw_readback: np.ndarray, target: DDR4Target | HBM2Target
) -> np.ndarray:
    """Return the selected target's useful readback as 32-bit words."""
    if not isinstance(target, HBM2Target):
        return raw_readback.view(np.uint32)

    # An HBM2 read returns a 64-byte pair containing both pseudo-channels.
    # Keep the 32-byte half selected by the target.
    columns = raw_readback.reshape(
        target.columns_per_row, BYTES_PER_HBM2_COLUMN_READ
    )
    start = target.pseudo_channel * BYTES_PER_HBM2_PSEUDO_CHANNEL
    useful = np.ascontiguousarray(
        columns[:, start : start + BYTES_PER_HBM2_PSEUDO_CHANNEL]
    )
    return useful.view(np.uint32).reshape(-1)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--board", required=True, choices=("u200", "u50", "u55c")
    )
    parser.add_argument(
        "--pci-bdf", required=True, help="Complete PCI BDF, dddd:bb:ss.f"
    )
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--row", type=int, default=0)
    parser.add_argument(
        "--pattern",
        type=parse_u32,
        default=0xDEADBEEF,
        help="32-bit word to write and verify (decimal or 0x-hex)",
    )

    hbm2 = parser.add_argument_group("HBM2 coordinates (U50 and U55C)")
    hbm2.add_argument("--channel", type=int, default=0)
    hbm2.add_argument("--pseudo-channel", type=int, default=0)
    hbm2.add_argument("--sid", type=int, default=0)
    args = parser.parse_args()

    target = make_target(args)
    builtin_programs = drambender.builtin_programs.configure(target=target)

    pattern_words = (args.pattern,) * target.words_per_cacheline
    write_program = builtin_programs.write_row(args.bank, args.row, pattern_words)
    read_program = builtin_programs.read_row(args.bank, args.row)

    # Every issued column read returns one 64-byte FPGA readback block. HBM2
    # carries both pseudo-channels in that block; normalize_readback selects
    # the requested half after execution.
    raw_readback_bytes = (
        target.receive_bytes_per_row
        if isinstance(target, HBM2Target)
        else target.columns_per_row * target.words_per_cacheline * BYTES_PER_WORD
    )
    raw_readback = np.empty(raw_readback_bytes, dtype=np.uint8)

    with open_board(
        target,
        pci_bdf=args.pci_bdf,
        xdma_channel=args.xdma_channel,
        host_interface=HostInterface.XDMA,
    ) as board:
        board.full_reset()
        if isinstance(target, HBM2Target):
            if not isinstance(board, HBM2):
                raise RuntimeError("the selected HBM2 target did not open an HBM2 board")
            # HBM2 readback can be disabled by an earlier experiment. A full
            # reset does not define that experiment setting, so enable it
            # explicitly before issuing reads.
            board.discard_readback_data(False)

        board.execute([write_program, read_program])
        board.receive_into(raw_readback)
        board.synchronize()

    readback = normalize_readback(raw_readback, target)
    expected = np.full_like(readback, np.uint32(args.pattern))
    mismatched = int(np.count_nonzero(readback != expected))

    if mismatched == 0:
        print(
            f"PASS: {readback.size} words matched "
            f"(board={args.board}, pattern=0x{args.pattern:08x})"
        )
        return 0

    print(f"FAIL: {mismatched}/{readback.size} words mismatched")
    return 1


if __name__ == "__main__":
    sys.exit(main())
