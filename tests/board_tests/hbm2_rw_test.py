#!/usr/bin/env python3
"""HBM2 read/write test for the latest U55 SID bitstream.

The latest U55 HBM2 image exposes 16 channels, uses the command rank bit as
the pseudo-channel selector, and uses BAR[4] as the stack ID bit. This
diagnostic writes and reads one 32-column HBM row, then verifies the useful
pseudo-channel half of each 64-byte readback chunk.
"""

import argparse
import sys

import numpy as np

from drambender.api import FinalProgram, HBM2, HBM2Target, ProgramBuilder
from drambender.api.program.instructions import ACT, NOP, PRE, RD, SEL_CH, WR


NUM_COLUMNS = 32
BYTES_PER_HBM_COLUMN_PAIR = 64
BYTES_PER_PSEUDO_CHANNEL_CHUNK = 32
DEFAULT_PATTERN = 0xDEADBEEF


def parse_u32(text: str) -> int:
    try:
        value = int(text, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid 32-bit pattern: {text!r}") from exc
    if not 0 <= value <= 0xFFFFFFFF:
        raise argparse.ArgumentTypeError("pattern must be in range 0..0xffffffff")
    return value


def build_hbm2_rw_program(
    *,
    target: HBM2Target,
    bank: int,
    row: int,
    pattern: int,
) -> FinalProgram:
    p = ProgramBuilder(target=target)
    p.LI(target.physical_bank(bank), "BAR")
    p.LI(row, "RAR")
    p.LI(target.column_stride, "CASR")
    p.LI(1, "BASR")
    p.LI(1, "RASR")

    p.LI(pattern, "PATTERN_REG")
    for index in range(target.words_per_cacheline):
        p.LDWD("PATTERN_REG", index)

    p.DRAM(SEL_CH(target), NOP(), NOP(), NOP())
    p.SLEEP(10)

    p.LI(0, "CAR")
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)

    for _ in range(target.columns_per_row):
        p.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)

    p.SLEEP(3)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(5)

    p.LI(0, "CAR")
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)

    for _ in range(target.columns_per_row):
        p.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)

    p.SLEEP(3)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    return p.conclude()


def verify_static_trace(
    program: FinalProgram,
    *,
    target: HBM2Target,
    physical_bank: int,
    quiet: bool = False,
) -> None:
    trace = program.trace_dram_commands()
    events = trace.events
    sel_events = [event for event in events if event.command == "SEL_CH"]
    wr_events = [event for event in events if event.command == "WR"]
    rd_events = [event for event in events if event.command == "RD"]
    row_events = [
        event
        for event in events
        if event.command in ("PRE", "ACT", "WR", "RD")
    ]

    errors: list[str] = []
    if len(sel_events) != 1:
        errors.append(f"expected 1 SEL_CH event, saw {len(sel_events)}")
    elif (
        sel_events[0].channel != target.channel
        or sel_events[0].pseudo_channel != target.pseudo_channel
    ):
        errors.append(
            "SEL_CH mismatch: "
            f"channel={sel_events[0].channel} pch={sel_events[0].pseudo_channel}"
        )

    if len(wr_events) != target.columns_per_row:
        errors.append(f"expected {target.columns_per_row} WR events, saw {len(wr_events)}")
    if len(rd_events) != target.columns_per_row:
        errors.append(f"expected {target.columns_per_row} RD events, saw {len(rd_events)}")

    expected_columns = list(range(target.columns_per_row))
    wr_columns = [event.column for event in wr_events]
    rd_columns = [event.column for event in rd_events]
    if wr_columns != expected_columns:
        errors.append(f"WR columns are {wr_columns}, expected {expected_columns}")
    if rd_columns != expected_columns:
        errors.append(f"RD columns are {rd_columns}, expected {expected_columns}")

    if any(event.rank != target.pseudo_channel for event in wr_events + rd_events):
        errors.append("at least one WR/RD event used the wrong pseudo-channel rank")
    if any(event.bank != physical_bank for event in row_events):
        errors.append(
            f"at least one row command used the wrong physical bank/BAR; "
            f"expected {physical_bank}"
        )

    if errors:
        raise RuntimeError("; ".join(errors))

    if not quiet:
        print(
            "PASS: static trace "
            f"SEL_CH channel={target.channel} pch={target.pseudo_channel}, "
            f"physical_bar={physical_bank}, "
            f"{len(wr_events)} WR, {len(rd_events)} RD, CASR=1 inferred from columns"
        )


def expected_useful_bytes(pattern: int, *, columns_per_row: int) -> np.ndarray:
    words_per_half = BYTES_PER_PSEUDO_CHANNEL_CHUNK // np.dtype(np.uint32).itemsize
    return np.full(
        columns_per_row * words_per_half,
        np.uint32(pattern),
        dtype=np.uint32,
    ).view(np.uint8)


def extract_useful_bytes(
    readback: np.ndarray,
    *,
    target: HBM2Target,
) -> np.ndarray:
    chunks = []
    offset = target.pseudo_channel * BYTES_PER_PSEUDO_CHANNEL_CHUNK
    for column in range(target.columns_per_row):
        start = column * BYTES_PER_HBM_COLUMN_PAIR + offset
        stop = start + BYTES_PER_PSEUDO_CHANNEL_CHUNK
        chunks.append(readback[start:stop])
    return np.concatenate(chunks)


def verify_readback(readback: np.ndarray, *, target: HBM2Target, pattern: int) -> None:
    useful = extract_useful_bytes(readback, target=target)
    expected = expected_useful_bytes(pattern, columns_per_row=target.columns_per_row)
    mismatches = np.flatnonzero(useful != expected)
    if mismatches.size == 0:
        return

    first = int(mismatches[0])
    column = first // BYTES_PER_PSEUDO_CHANNEL_CHUNK
    byte_in_column = first % BYTES_PER_PSEUDO_CHANNEL_CHUNK
    raw_offset = (
        column * BYTES_PER_HBM_COLUMN_PAIR
        + target.pseudo_channel * BYTES_PER_PSEUDO_CHANNEL_CHUNK
        + byte_in_column
    )
    raise AssertionError(
        f"{mismatches.size} useful-byte mismatch(es); first at column={column} "
        f"byte={byte_in_column} raw_offset={raw_offset}: "
        f"expected=0x{int(expected[first]):02x} read=0x{int(useful[first]):02x}"
    )


def run_once(
    board: HBM2,
    program: FinalProgram,
    *,
    receive_bytes: int,
    target: HBM2Target,
    pattern: int,
    iteration: int,
    quiet: bool = False,
) -> None:
    board.full_reset()
    board.discard_readback_data(False)
    board.execute(program)
    readback = np.empty(receive_bytes, dtype=np.uint8)
    board.receive_into(readback)
    board.synchronize()
    verify_readback(readback, target=target, pattern=pattern)
    if not quiet:
        print(f"PASS: iteration {iteration}: {receive_bytes} readback bytes verified")


def execute_and_verify(
    board: HBM2,
    program: FinalProgram,
    *,
    receive_bytes: int,
    target: HBM2Target,
    pattern: int,
) -> None:
    board.execute(program)
    readback = np.empty(receive_bytes, dtype=np.uint8)
    board.receive_into(readback)
    board.synchronize()
    verify_readback(readback, target=target, pattern=pattern)


def run_row_sweep(
    board: HBM2,
    *,
    target: HBM2Target,
    bank: int,
    start_row: int,
    row_count: int,
    pattern: int,
    receive_bytes: int,
    progress_interval: int,
) -> None:
    board.full_reset()
    board.discard_readback_data(False)

    for row_offset in range(row_count):
        row = start_row + row_offset
        program = build_hbm2_rw_program(
            target=target,
            bank=bank,
            row=row,
            pattern=pattern,
        )
        if row_offset == 0:
            verify_static_trace(
                program,
                target=target,
                physical_bank=target.physical_bank(bank),
            )

        execute_and_verify(
            board,
            program,
            receive_bytes=receive_bytes,
            target=target,
            pattern=pattern,
        )

        rows_done = row_offset + 1
        if (
            rows_done == row_count
            or (progress_interval > 0 and rows_done % progress_interval == 0)
        ):
            print(
                f"PASS: rows {start_row}..{row}: "
                f"{rows_done}/{row_count} rows verified"
            )


def main() -> int:
    parser = argparse.ArgumentParser(description="HBM2 latest-U55-SID read/write test")
    parser.add_argument("--pci-bdf", required=True)
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument("--channel", type=int, default=0)
    parser.add_argument("--pseudo-channel", type=int, default=0)
    parser.add_argument("--sid", type=int, default=1)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--row", type=int, default=0)
    parser.add_argument("--row-count", type=int, default=1)
    parser.add_argument("--pattern", type=parse_u32, default=DEFAULT_PATTERN)
    parser.add_argument("--receive-bytes", type=int, default=2048)
    parser.add_argument("--iterations", type=int, default=2)
    parser.add_argument(
        "--progress-interval",
        type=int,
        default=256,
        help="rows between progress messages in row-count mode; 0 prints only at the end",
    )
    parser.add_argument(
        "--static-only",
        action="store_true",
        help="only build and validate the instruction trace; do not open XDMA",
    )
    parser.add_argument(
        "--skip-temperature",
        action="store_true",
        help="skip the best-effort HBM temperature read before read/write",
    )
    args = parser.parse_args()

    min_receive_bytes = NUM_COLUMNS * BYTES_PER_HBM_COLUMN_PAIR
    if args.receive_bytes < min_receive_bytes:
        print(
            f"receive-bytes must be at least {min_receive_bytes} "
            "for 32 HBM column reads",
            file=sys.stderr,
        )
        return 2
    if not 0 <= args.channel <= 15:
        print("channel must be in range 0..15 for the latest U55 HBM2 image", file=sys.stderr)
        return 2
    if args.pseudo_channel not in (0, 1):
        print("pseudo-channel must be 0 or 1 for HBM2", file=sys.stderr)
        return 2
    if args.sid not in (0, 1):
        print("sid must be 0 or 1 for the latest U55 SID bitstream", file=sys.stderr)
        return 2
    if not 0 <= args.bank <= 15:
        print("bank must be in range 0..15; sid is encoded separately in BAR[4]", file=sys.stderr)
        return 2
    if args.row < 0:
        print("row must be non-negative", file=sys.stderr)
        return 2
    if args.row_count <= 0:
        print("row-count must be greater than 0", file=sys.stderr)
        return 2
    if args.progress_interval < 0:
        print("progress-interval must be non-negative", file=sys.stderr)
        return 2
    if args.iterations <= 0:
        print("iterations must be greater than 0", file=sys.stderr)
        return 2

    target = HBM2Target(
        channel=args.channel,
        pseudo_channel=args.pseudo_channel,
        sid=args.sid,
    )
    physical_bank = target.physical_bank(args.bank)
    program = build_hbm2_rw_program(
        target=target,
        bank=args.bank,
        row=args.row,
        pattern=args.pattern,
    )
    verify_static_trace(
        program,
        target=target,
        physical_bank=physical_bank,
        quiet=args.row_count > 1,
    )
    if args.static_only:
        return 0

    print(
        "hbm2_rw_test: "
        f"pci_bdf={args.pci_bdf} xdma_channel={args.xdma_channel} "
        f"channel={args.channel} pch={args.pseudo_channel} "
        f"sid={args.sid} bank={args.bank} physical_bar={physical_bank} "
        f"rows={args.row}..{args.row + args.row_count - 1} "
        f"pattern=0x{args.pattern:08x} "
        f"receive_bytes={args.receive_bytes}"
    )

    try:
        with HBM2(args.pci_bdf, args.xdma_channel) as board:
            if not args.skip_temperature:
                try:
                    temp = board.read_temperature()
                    print(
                        "HBM temperature: "
                        f"stack0={temp.stack0_celsius}C stack1={temp.stack1_celsius}C"
                    )
                except Exception as exc:
                    print(f"WARN: HBM temperature read failed: {exc}", file=sys.stderr)

            if args.row_count == 1:
                for iteration in range(1, args.iterations + 1):
                    run_once(
                        board,
                        program,
                        receive_bytes=args.receive_bytes,
                        target=target,
                        pattern=args.pattern,
                        iteration=iteration,
                    )
            else:
                run_row_sweep(
                    board,
                    target=target,
                    bank=args.bank,
                    start_row=args.row,
                    row_count=args.row_count,
                    pattern=args.pattern,
                    receive_bytes=args.receive_bytes,
                    progress_interval=args.progress_interval,
                )
        return 0
    except Exception as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
