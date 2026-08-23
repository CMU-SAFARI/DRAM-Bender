#!/usr/bin/env python3
"""Qualify channel 0 on multiple DDR4 FPGA cards concurrently.

The parent process never opens a board. It uses the ``spawn`` start method to
create one independent worker per explicit PCI BDF. Each worker performs
``full_reset()``, waits at a shared barrier, and verifies a one-row write/read
with a card-specific pattern. This checks correctness and isolation only; it
does not benchmark performance.
"""

from __future__ import annotations

import argparse
import multiprocessing
import queue
import re
import sys
import time
from typing import Any


XDMA_CHANNEL = 0
BANK = 0
ROW = 32
CACHELINES_PER_ROW = 128
WORDS_PER_CACHELINE = 16
COLUMN_STRIDE = 8
ROW_WORDS = CACHELINES_PER_ROW * WORDS_PER_CACHELINE
BASE_PATTERN = 0x13579BDF
PATTERN_STEP = 0x1F123BB5
DEFAULT_TIMEOUT_SECONDS = 60.0
PCI_BDF_RE = re.compile(
    r"^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:"
    r"(?P<slot>[0-9a-fA-F]{2})\.[0-7]$"
)


def parse_pci_bdf(text: str) -> str:
    match = PCI_BDF_RE.fullmatch(text)
    if match is None or int(match.group("slot"), 16) > 0x1F:
        raise argparse.ArgumentTypeError(
            "PCI BDF must use complete dddd:bb:ss.f form, for example 0000:01:00.0"
        )
    return text.lower()


def positive_float(text: str) -> float:
    try:
        value = float(text)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid duration: {text!r}") from exc
    if value <= 0:
        raise argparse.ArgumentTypeError("duration must be greater than zero")
    return value


def build_write_program(target: Any, pattern: int) -> Any:
    from drambender.api import ProgramBuilder
    from drambender.api.program.instructions import ACT, NOP, PRE, WR

    program = ProgramBuilder(target=target)
    program.LI(BANK, "BAR")
    program.LI(ROW, "RAR")
    program.LI(target.column_stride, "CASR")
    for word in range(target.words_per_cacheline):
        program.LI(pattern, "PATTERN_REG")
        program.LDWD("PATTERN_REG", word)
    program.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    program.LI(0, "CAR")
    program.SLEEP(2)
    program.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    program.SLEEP(2)
    for _ in range(target.columns_per_row):
        program.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    program.SLEEP(8)
    program.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    program.SLEEP(3)
    return program.conclude()


def build_read_program(target: Any) -> Any:
    from drambender.api import ProgramBuilder
    from drambender.api.program.instructions import ACT, NOP, PRE, RD

    program = ProgramBuilder(target=target)
    program.LI(BANK, "BAR")
    program.LI(ROW, "RAR")
    program.LI(target.column_stride, "CASR")
    program.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    program.LI(0, "CAR")
    program.SLEEP(2)
    program.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    program.SLEEP(2)
    for _ in range(target.columns_per_row):
        program.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    program.SLEEP(4)
    program.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    program.SLEEP(3)
    return program.conclude()


def worker(
    pci_bdf: str,
    card_index: int,
    execute_barrier: Any,
    result_queue: Any,
) -> None:
    pattern = (BASE_PATTERN + card_index * PATTERN_STEP) & 0xFFFFFFFF
    phase = "initialization"
    try:
        # Imports stay in the spawned worker. In particular, the parent never
        # constructs a Board that could be inherited by another process.
        import numpy as np

        from drambender.api import DDR4Target, HostInterface, open_board

        target = DDR4Target(
            cachelines_per_row=CACHELINES_PER_ROW,
            column_stride=COLUMN_STRIDE,
            words_per_cacheline=WORDS_PER_CACHELINE,
        )
        write_program = build_write_program(target, pattern)
        read_program = build_read_program(target)
        expected = np.full(ROW_WORDS, np.uint32(pattern), dtype=np.uint32)
        readback = np.empty_like(expected)

        phase = "open/full_reset"
        with open_board(
            target,
            pci_bdf=pci_bdf,
            xdma_channel=XDMA_CHANNEL,
            host_interface=HostInterface.XDMA,
        ) as board:
            board.full_reset()
            phase = "concurrent-execute barrier"
            execute_barrier.wait()
            phase = "write/read verification"
            board.execute([write_program, read_program])
            board.receive_into(readback)
            board.synchronize()

        mismatch_indices = np.flatnonzero(readback != expected)
        if mismatch_indices.size:
            first = int(mismatch_indices[0])
            raise RuntimeError(
                f"{mismatch_indices.size}/{ROW_WORDS} words mismatched; first at "
                f"word {first}: expected=0x{int(expected[first]):08x}, "
                f"observed=0x{int(readback[first]):08x}"
            )

        result_queue.put(
            {
                "pci_bdf": pci_bdf,
                "passed": True,
                "pattern": pattern,
                "detail": f"{ROW_WORDS} words matched",
            }
        )
    except BaseException as exc:
        try:
            execute_barrier.abort()
        except BaseException:
            pass
        error_text = str(exc) or "barrier was broken"
        result_queue.put(
            {
                "pci_bdf": pci_bdf,
                "passed": False,
                "pattern": pattern,
                "detail": f"{phase}: {type(exc).__name__}: {error_text}",
            }
        )


def stop_processes(processes: list[multiprocessing.Process]) -> None:
    for process in processes:
        if process.is_alive():
            process.terminate()
    deadline = time.monotonic() + 1.0
    for process in processes:
        process.join(timeout=max(0.0, deadline - time.monotonic()))
    for process in processes:
        if process.is_alive():
            process.kill()
    deadline = time.monotonic() + 1.0
    for process in processes:
        process.join(timeout=max(0.0, deadline - time.monotonic()))


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__.splitlines()[0],
        epilog=(
            "Example: %(prog)s --pci-bdf 0000:01:00.0 "
            "--pci-bdf 0000:21:00.0"
        ),
    )
    parser.add_argument(
        "--pci-bdf",
        action="append",
        required=True,
        type=parse_pci_bdf,
        metavar="dddd:bb:ss.f",
        help="Complete PCI address of one FPGA; repeat once per card.",
    )
    parser.add_argument(
        "--timeout-seconds",
        type=positive_float,
        default=DEFAULT_TIMEOUT_SECONDS,
        help="Hard wall-clock limit for the complete qualification run.",
    )
    args = parser.parse_args(argv)
    if len(set(args.pci_bdf)) != len(args.pci_bdf):
        parser.error("each --pci-bdf value must be unique")
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    context = multiprocessing.get_context("spawn")
    execute_barrier = context.Barrier(
        len(args.pci_bdf), timeout=args.timeout_seconds
    )
    result_queue = context.Queue()
    processes = [
        context.Process(
            target=worker,
            name=f"drambender-{pci_bdf}-ch0",
            args=(pci_bdf, index, execute_barrier, result_queue),
        )
        for index, pci_bdf in enumerate(args.pci_bdf)
    ]

    print(
        f"Qualifying {len(processes)} endpoint(s), fixed xdma_channel={XDMA_CHANNEL}, "
        f"bank={BANK}, row={ROW}, timeout={args.timeout_seconds:.1f}s"
    )
    for index, pci_bdf in enumerate(args.pci_bdf):
        pattern = (BASE_PATTERN + index * PATTERN_STEP) & 0xFFFFFFFF
        print(f"  {pci_bdf}: pattern=0x{pattern:08x}")

    results: dict[str, dict[str, Any]] = {}
    deadline = time.monotonic() + args.timeout_seconds
    try:
        for process in processes:
            process.start()
        while len(results) < len(processes):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break
            try:
                result = result_queue.get(timeout=min(0.25, remaining))
                results[result["pci_bdf"]] = result
            except queue.Empty:
                if all(not process.is_alive() for process in processes):
                    break
    except KeyboardInterrupt:
        stop_processes(processes)
        result_queue.close()
        result_queue.cancel_join_thread()
        print("Interrupted; child processes were terminated.", file=sys.stderr)
        return 130

    timed_out = time.monotonic() >= deadline and len(results) < len(processes)
    if timed_out:
        stop_processes(processes)
    else:
        join_deadline = time.monotonic() + 1.0
        for process in processes:
            process.join(timeout=max(0.0, join_deadline - time.monotonic()))
        if any(process.is_alive() for process in processes):
            stop_processes(processes)

    while True:
        try:
            result = result_queue.get_nowait()
            results[result["pci_bdf"]] = result
        except queue.Empty:
            break

    all_passed = True
    print("\nPer-card results:")
    for pci_bdf, process in zip(args.pci_bdf, processes):
        result = results.get(pci_bdf)
        if result is None:
            all_passed = False
            reason = "TIMEOUT" if timed_out else f"worker exitcode={process.exitcode}"
            print(f"  {pci_bdf} ch0: FAIL ({reason})")
        elif result["passed"] and process.exitcode == 0:
            print(
                f"  {pci_bdf} ch0: PASS ({result['detail']}, "
                f"pattern=0x{result['pattern']:08x})"
            )
        elif not result["passed"]:
            all_passed = False
            print(
                f"  {pci_bdf} ch0: FAIL ({result['detail']}, "
                f"pattern=0x{result['pattern']:08x})"
            )
        else:
            all_passed = False
            print(
                f"  {pci_bdf} ch0: FAIL (worker exitcode={process.exitcode} "
                "after reporting PASS)"
            )

    result_queue.close()
    result_queue.cancel_join_thread()
    return 0 if all_passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
