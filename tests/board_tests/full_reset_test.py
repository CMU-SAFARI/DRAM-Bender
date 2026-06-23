#!/usr/bin/env python3
"""Full-reset recovery test for DRAM Bender.

Python equivalent of tests/board_tests/full_reset_test.cpp.
"""

import argparse
import sys
import time

import numpy as np

from drambender.api import (
    Board,
    BoardType,
    FinalProgram,
    HostInterface,
    ProgramBuilder,
    open_board,
)
from drambender.api.program.instructions import ACT, NOP, PRE, RD, WR


CACHELINES_PER_ROW = 128
WORDS_PER_CACHELINE = 16
COLUMN_STRIDE = 8
ROW_WORDS = CACHELINES_PER_ROW * WORDS_PER_CACHELINE
DEFAULT_PATTERN = 0x13579BDF


def parse_u32(text: str) -> int:
    try:
        value = int(text, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid 32-bit pattern: {text!r}") from exc
    if not 0 <= value <= 0xFFFFFFFF:
        raise argparse.ArgumentTypeError("pattern must be in range 0..0xffffffff")
    return value


def build_long_no_read_program() -> FinalProgram:
    p = ProgramBuilder()
    p.SLEEP(100000000)
    return p.conclude()


def build_write_program(bank: int, row: int, pattern: int) -> FinalProgram:
    p = ProgramBuilder()
    p.LI(bank, "BAR")
    p.LI(row, "RAR")
    p.LI(COLUMN_STRIDE, "CASR")

    for word in range(WORDS_PER_CACHELINE):
        p.LI(pattern, "PATTERN_REG")
        p.LDWD("PATTERN_REG", word)

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


def run_verified_read_write(board: Board, bank: int, row: int, pattern: int) -> bool:
    readback = np.empty(ROW_WORDS, dtype=np.uint32)
    expected = np.full(ROW_WORDS, np.uint32(pattern), dtype=np.uint32)

    board.execute(build_write_program(bank, row, pattern))
    board.execute(build_read_program(bank, row))
    board.receive_into(readback)
    board.synchronize()

    mismatches = int(np.count_nonzero(readback != expected))
    if mismatches:
        print(
            f"read/write verification failed: {mismatches}/{ROW_WORDS} words mismatched",
            file=sys.stderr,
        )
        return False

    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Full-reset recovery test")
    parser.add_argument("--board-id", type=int, default=0)
    parser.add_argument("--instance-id", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--row", type=int, default=32)
    parser.add_argument("--pattern", type=parse_u32, default=DEFAULT_PATTERN)
    args = parser.parse_args()

    print(
        f"full_reset_test: board={args.board_id} instance={args.instance_id} "
        f"bank={args.bank} row={args.row} pattern=0x{args.pattern:08x}"
    )

    try:
        with open_board(
            BoardType.DDR4,
            board_id=args.board_id,
            instance_id=args.instance_id,
            host_interface=HostInterface.XDMA,
        ) as board:
            board.reset_fpga()

            board.execute(build_long_no_read_program())
            time.sleep(0.020)
            board.full_reset()
            print("PASS: full_reset canceled active no-read receiver")

            board.execute(build_read_program(args.bank, args.row))
            time.sleep(0.020)
            board.full_reset()
            print("PASS: full_reset cleared stale readback")

            if not run_verified_read_write(board, args.bank, args.row + 1, args.pattern):
                return 1
            print(
                "PASS: read/write works after full_reset "
                f"(pattern=0x{args.pattern:08x})"
            )

        return 0
    except Exception as exc:
        print(f"runtime failure: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
