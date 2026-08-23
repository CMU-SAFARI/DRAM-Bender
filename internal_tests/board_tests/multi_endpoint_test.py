#!/usr/bin/env python3
"""Qualify multiple independent DDR4 BDF/channel endpoints concurrently.

Each endpoint is owned by an independent spawned worker. Resets are serialized
between sibling channels on the same PCI function, then all workers execute
barrier-aligned write/read iterations with endpoint-specific patterns. Results
are keyed by the complete ``(PCI BDF, XDMA channel)`` identity.
"""

from __future__ import annotations

import argparse
import hashlib
import multiprocessing
import queue
import re
import sys
import time
from typing import Any


CACHELINES_PER_ROW = 128
WORDS_PER_CACHELINE = 16
COLUMN_STRIDE = 8
ROW_WORDS = CACHELINES_PER_ROW * WORDS_PER_CACHELINE
BASE_PATTERN = 0x13579BDF
DEFAULT_ITERATIONS = 25
DEFAULT_TIMEOUT_SECONDS = 120.0
MAX_ITERATIONS = 0x1000000
PCI_BDF_RE = re.compile(
    r"^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:"
    r"(?P<slot>[0-9a-fA-F]{2})\.[0-7]$"
)

Endpoint = tuple[str, int]


def parse_endpoint(text: str) -> Endpoint:
    try:
        bdf_text, channel_text = text.rsplit("/", 1)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            "endpoint must use dddd:bb:ss.f/CHANNEL form"
        ) from exc

    match = PCI_BDF_RE.fullmatch(bdf_text)
    if match is None or int(match.group("slot"), 16) > 0x1F:
        raise argparse.ArgumentTypeError(
            "PCI BDF must use complete dddd:bb:ss.f form"
        )
    try:
        channel = int(channel_text, 10)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("XDMA channel must be 0 or 1") from exc
    if channel not in (0, 1):
        raise argparse.ArgumentTypeError("XDMA channel must be 0 or 1")
    return bdf_text.lower(), channel


def positive_int(text: str) -> int:
    try:
        value = int(text, 10)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid positive integer: {text!r}") from exc
    if value <= 0:
        raise argparse.ArgumentTypeError("value must be greater than zero")
    return value


def positive_float(text: str) -> float:
    try:
        value = float(text)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid duration: {text!r}") from exc
    if value <= 0:
        raise argparse.ArgumentTypeError("duration must be greater than zero")
    return value


def pattern_for(endpoint_index: int, iteration: int) -> int:
    # The low byte is unique for every endpoint in one iteration; the upper
    # 24 bits identify the iteration. BASE_PATTERN keeps simple all-zero or
    # low-Hamming-weight values out of the test stream.
    return (BASE_PATTERN ^ (iteration << 8) ^ (endpoint_index + 1)) & 0xFFFFFFFF


def build_write_program(target: Any, bank: int, row: int, pattern: int) -> Any:
    from drambender.api import ProgramBuilder
    from drambender.api.program.instructions import ACT, NOP, PRE, WR

    program = ProgramBuilder(target=target)
    program.LI(bank, "BAR")
    program.LI(row, "RAR")
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


def build_read_program(target: Any, bank: int, row: int) -> Any:
    from drambender.api import ProgramBuilder
    from drambender.api.program.instructions import ACT, NOP, PRE, RD

    program = ProgramBuilder(target=target)
    program.LI(bank, "BAR")
    program.LI(row, "RAR")
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
    endpoint: Endpoint,
    endpoint_index: int,
    iterations: int,
    reset_lock: Any,
    execute_barrier: Any,
    result_queue: Any,
) -> None:
    pci_bdf, xdma_channel = endpoint
    bank = endpoint_index % 16
    row = 32 + endpoint_index
    phase = "initialization"
    board = None
    try:
        import numpy as np

        from drambender.api import DDR4Target, HostInterface, open_board

        target = DDR4Target(
            cachelines_per_row=CACHELINES_PER_ROW,
            column_stride=COLUMN_STRIDE,
            words_per_cacheline=WORDS_PER_CACHELINE,
        )
        read_program = build_read_program(target, bank, row)
        payload_digest = hashlib.sha256()

        phase = "open"
        board = open_board(
            target,
            pci_bdf=pci_bdf,
            xdma_channel=xdma_channel,
            host_interface=HostInterface.XDMA,
        )

        # A reset control packet is endpoint-local in the dual U200 RTL, but
        # serialize sibling setup anyway: this avoids simultaneous recovery
        # operations becoming a confounder in the subsequent isolation test.
        phase = "serialized full_reset"
        with reset_lock:
            board.full_reset()

        for iteration in range(iterations):
            pattern = pattern_for(endpoint_index, iteration)
            expected = np.full(ROW_WORDS, np.uint32(pattern), dtype=np.uint32)
            observed = np.empty_like(expected)
            write_program = build_write_program(target, bank, row, pattern)

            phase = f"iteration {iteration} pre-execute barrier"
            execute_barrier.wait()
            phase = f"iteration {iteration} write/read verification"
            board.execute([write_program, read_program])
            board.receive_into(observed)
            board.synchronize()

            mismatch_indices = np.flatnonzero(observed != expected)
            if mismatch_indices.size:
                first = int(mismatch_indices[0])
                raise RuntimeError(
                    f"{mismatch_indices.size}/{ROW_WORDS} words mismatched; first at "
                    f"word {first}: expected=0x{int(expected[first]):08x}, "
                    f"observed=0x{int(observed[first]):08x}"
                )
            payload_digest.update(observed.tobytes())
            phase = f"iteration {iteration} completion barrier"
            execute_barrier.wait()

        phase = "serialized final full_reset"
        with reset_lock:
            board.full_reset()
        phase = "close"
        board.close()
        board = None
        result_queue.put(
            {
                "endpoint": endpoint,
                "passed": True,
                "iterations": iterations,
                "bank": bank,
                "row": row,
                "first_pattern": pattern_for(endpoint_index, 0),
                "last_pattern": pattern_for(endpoint_index, iterations - 1),
                "words_verified": iterations * ROW_WORDS,
                "payload_sha256": payload_digest.hexdigest(),
                "detail": "all words matched",
            }
        )
    except BaseException as exc:
        try:
            execute_barrier.abort()
        except BaseException:
            pass
        if board is not None:
            try:
                board.close()
            except BaseException:
                pass
        error_text = str(exc) or "barrier was broken"
        result_queue.put(
            {
                "endpoint": endpoint,
                "passed": False,
                "iterations": iterations,
                "bank": bank,
                "row": row,
                "detail": f"{phase}: {type(exc).__name__}: {error_text}",
            }
        )


def stop_processes(processes: list[multiprocessing.Process]) -> None:
    for process in processes:
        if process.is_alive():
            process.terminate()
    deadline = time.monotonic() + 2.0
    for process in processes:
        process.join(timeout=max(0.0, deadline - time.monotonic()))
    for process in processes:
        if process.is_alive():
            process.kill()
    deadline = time.monotonic() + 2.0
    for process in processes:
        process.join(timeout=max(0.0, deadline - time.monotonic()))


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__.splitlines()[0],
        epilog=(
            "Example: %(prog)s --endpoint 0000:01:00.0/0 "
            "--endpoint 0000:01:00.0/1"
        ),
    )
    parser.add_argument(
        "--endpoint",
        action="append",
        required=True,
        type=parse_endpoint,
        metavar="dddd:bb:ss.f/CHANNEL",
        help="Complete BDF and channel 0 or 1; repeat once per endpoint.",
    )
    parser.add_argument(
        "--iterations",
        type=positive_int,
        default=DEFAULT_ITERATIONS,
        help=f"Barrier-aligned write/read iterations per endpoint (default: {DEFAULT_ITERATIONS}).",
    )
    parser.add_argument(
        "--timeout-seconds",
        type=positive_float,
        default=DEFAULT_TIMEOUT_SECONDS,
        help="Hard wall-clock limit for the complete qualification run.",
    )
    parser.add_argument(
        "--require-complete-dual",
        action="store_true",
        help="Require both channels 0 and 1 for every listed PCI BDF.",
    )
    args = parser.parse_args(argv)
    if len(set(args.endpoint)) != len(args.endpoint):
        parser.error("each (PCI BDF, XDMA channel) endpoint must be unique")
    if len(args.endpoint) > 255:
        parser.error("at most 255 endpoints are supported")
    if args.iterations > MAX_ITERATIONS:
        parser.error(f"--iterations must not exceed {MAX_ITERATIONS}")
    if args.require_complete_dual:
        channels_by_bdf: dict[str, set[int]] = {}
        for pci_bdf, channel in args.endpoint:
            channels_by_bdf.setdefault(pci_bdf, set()).add(channel)
        incomplete = sorted(
            pci_bdf
            for pci_bdf, channels in channels_by_bdf.items()
            if channels != {0, 1}
        )
        if incomplete:
            parser.error(
                "--require-complete-dual needs channels 0 and 1 for every BDF; "
                f"incomplete: {', '.join(incomplete)}"
            )
    return args


def endpoint_text(endpoint: Endpoint) -> str:
    return f"{endpoint[0]}/ch{endpoint[1]}"


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    context = multiprocessing.get_context("spawn")
    execute_barrier = context.Barrier(
        len(args.endpoint), timeout=args.timeout_seconds
    )
    result_queue = context.Queue()
    reset_locks = {
        pci_bdf: context.Lock() for pci_bdf in {item[0] for item in args.endpoint}
    }
    processes = [
        context.Process(
            target=worker,
            name=f"drambender-{pci_bdf}-ch{channel}",
            args=(
                (pci_bdf, channel),
                index,
                args.iterations,
                reset_locks[pci_bdf],
                execute_barrier,
                result_queue,
            ),
        )
        for index, (pci_bdf, channel) in enumerate(args.endpoint)
    ]

    print(
        f"Qualifying {len(processes)} endpoint(s), iterations={args.iterations}, "
        f"timeout={args.timeout_seconds:.1f}s"
    )
    for index, endpoint in enumerate(args.endpoint):
        print(
            f"  {endpoint_text(endpoint)}: bank={index % 16} row={32 + index} "
            f"first=0x{pattern_for(index, 0):08x} "
            f"last=0x{pattern_for(index, args.iterations - 1):08x}"
        )

    results: dict[Endpoint, dict[str, Any]] = {}
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
                results[result["endpoint"]] = result
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
        join_deadline = time.monotonic() + 2.0
        for process in processes:
            process.join(timeout=max(0.0, join_deadline - time.monotonic()))
        if any(process.is_alive() for process in processes):
            stop_processes(processes)

    while True:
        try:
            result = result_queue.get_nowait()
            results[result["endpoint"]] = result
        except queue.Empty:
            break

    all_passed = True
    print("\nPer-endpoint results:")
    for endpoint, process in zip(args.endpoint, processes):
        result = results.get(endpoint)
        label = endpoint_text(endpoint)
        if result is None:
            all_passed = False
            reason = "TIMEOUT" if timed_out else f"worker exitcode={process.exitcode}"
            print(f"  {label}: FAIL ({reason})")
        elif result["passed"] and process.exitcode == 0:
            print(
                f"  {label}: PASS ({result['iterations']} iterations, "
                f"{result['words_verified']} words, sha256={result['payload_sha256']})"
            )
        elif not result["passed"]:
            all_passed = False
            print(f"  {label}: FAIL ({result['detail']})")
        else:
            all_passed = False
            print(
                f"  {label}: FAIL (worker exitcode={process.exitcode} "
                "after reporting PASS)"
            )

    result_queue.close()
    result_queue.cancel_join_thread()
    return 0 if all_passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
