#!/usr/bin/env python3
"""Seeded channel-0 DDR4 readback and retention-transport qualification.

This is a correctness test, not a performance benchmark.  It exercises
metadata-v1 framing over many payload sizes, caller receive partitions,
program shapes, and silent intervals.  Refresh-off retention observations are
reported separately: receiving the exact number of bytes is mandatory, while
bit mismatches after a retention delay are measurements rather than transport
failures.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import random
import subprocess
import sys
import time
from typing import Any, Iterable

import numpy as np

import drambender
from drambender.api import DDR4Target, HostInterface, ProgramBuilder, open_board
from drambender.api.program.instructions import ACT, NOP, PRE, RD, WR


BYTES_PER_CACHELINE = 64
WORDS_PER_CACHELINE = 16
CACHELINES_PER_ROW = 128
COLUMN_STRIDE = 8
FABRIC_CYCLE_NS = 6
TARGET = DDR4Target(
    cachelines_per_row=CACHELINES_PER_ROW,
    column_stride=COLUMN_STRIDE,
    words_per_cacheline=WORDS_PER_CACHELINE,
)

DEFAULT_SEED = 0x44524631
DEFAULT_BDF = "0000:01:00.0"

PROFILES = {
    "quick": {
        "payload_cachelines": [1, 2, 7, 8, 31, 63, 64, 65, 127, 128, 129],
        "short_sessions": 12,
        "large_cachelines": [149, 257],
        "gap_seconds": [0.150],
        "host_retention_seconds": [0.0, 0.150],
    },
    "standard": {
        "payload_cachelines": [
            1, 2, 3, 4, 7, 8, 15, 16, 31, 32, 47, 48, 49,
            63, 64, 65, 95, 96, 97, 127, 128, 129,
        ],
        "short_sessions": 50,
        "large_cachelines": [149, 150, 151, 255, 256, 257, 299, 300, 301, 511, 512, 513],
        "gap_seconds": [0.150, 1.0, 6.0],
        "host_retention_seconds": [0.0, 0.150, 1.0, 6.0],
    },
    "soak": {
        "payload_cachelines": [
            1, 2, 3, 4, 7, 8, 15, 16, 31, 32, 47, 48, 49,
            63, 64, 65, 95, 96, 97, 127, 128, 129,
        ],
        "short_sessions": 500,
        "large_cachelines": [149, 150, 151, 255, 256, 257, 299, 300, 301, 511, 512, 513],
        "gap_seconds": [0.150, 1.0, 6.0, 12.0],
        "host_retention_seconds": [0.0, 0.150, 1.0, 6.0, 12.0],
    },
}


def parse_int(text: str) -> int:
    return int(text, 0)


def normalize_bdf(text: str) -> str:
    fields = text.lower().split(":")
    if len(fields) != 3 or len(fields[0]) != 4 or "." not in fields[2]:
        raise argparse.ArgumentTypeError("PCI BDF must use dddd:bb:ss.f form")
    try:
        domain = int(fields[0], 16)
        bus = int(fields[1], 16)
        slot_text, function_text = fields[2].split(".", 1)
        slot = int(slot_text, 16)
        function = int(function_text, 16)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("PCI BDF contains a non-hex field") from exc
    if not (0 <= domain <= 0xFFFF and 0 <= bus <= 0xFF and 0 <= slot <= 0x1F and 0 <= function <= 7):
        raise argparse.ArgumentTypeError("PCI BDF field is out of range")
    return f"{domain:04x}:{bus:02x}:{slot:02x}.{function}"


def git_value(*args: str) -> str:
    try:
        return subprocess.check_output(
            ["git", *args],
            cwd=Path(__file__).resolve().parents[2],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def file_sha256(path: str | os.PathLike[str]) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def case_rng(suite_seed: int, case_id: str) -> random.Random:
    material = f"{suite_seed:016x}:{case_id}".encode()
    derived = int.from_bytes(hashlib.sha256(material).digest()[:8], "little")
    return random.Random(derived)


def lane_words(family: str, seed: int, bank: int, row: int, case_index: int) -> np.ndarray:
    if family == "zero":
        return np.zeros(WORDS_PER_CACHELINE, dtype=np.uint32)
    if family == "ones":
        return np.full(WORDS_PER_CACHELINE, np.uint32(0xFFFFFFFF), dtype=np.uint32)
    if family == "checker":
        return np.array(
            [0xAAAAAAAA if lane % 2 == 0 else 0x55555555 for lane in range(WORDS_PER_CACHELINE)],
            dtype=np.uint32,
        )
    if family == "walking":
        return np.array(
            [(1 << lane) if lane < 16 else 0 for lane in range(WORDS_PER_CACHELINE)],
            dtype=np.uint32,
        )

    tag = (seed ^ (bank << 28) ^ (row << 8) ^ case_index) & 0xFFFFFFFF
    words = []
    value = tag or 0x9E3779B9
    for lane in range(WORDS_PER_CACHELINE):
        value ^= (value << 13) & 0xFFFFFFFF
        value ^= value >> 17
        value ^= (value << 5) & 0xFFFFFFFF
        words.append((value ^ (lane * 0x45D9F3B)) & 0xFFFFFFFF)
    return np.asarray(words, dtype=np.uint32)


def stage_wide_pattern(program: ProgramBuilder, words: np.ndarray) -> None:
    if words.shape != (WORDS_PER_CACHELINE,):
        raise ValueError("wide pattern must contain exactly 16 words")
    for lane, value in enumerate(words):
        program.LI(int(value), "PATTERN_REG")
        program.LDWD("PATTERN_REG", lane)


def begin_row(program: ProgramBuilder, bank: int, row: int) -> None:
    program.LI(bank, "BAR")
    program.LI(row, "RAR")
    program.LI(COLUMN_STRIDE, "CASR")
    program.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    program.LI(0, "CAR")
    program.SLEEP(2)
    program.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    program.SLEEP(2)


def end_row(program: ProgramBuilder, *, write: bool) -> None:
    program.SLEEP(8 if write else 4)
    program.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    program.SLEEP(3)


def build_write_program(bank: int, row: int, cachelines: int, words: np.ndarray):
    program = ProgramBuilder(target=TARGET)
    stage_wide_pattern(program, words)
    begin_row(program, bank, row)
    for _ in range(cachelines):
        program.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=True)
    return program.conclude()


def build_read_program(
    bank: int,
    row: int,
    cachelines: int,
    *,
    split_after: int | None = None,
    gap_cycles: int = 0,
):
    if split_after is not None and not (0 < split_after < cachelines):
        raise ValueError("split_after must divide the read into two nonempty groups")
    program = ProgramBuilder(target=TARGET)
    begin_row(program, bank, row)
    for cacheline in range(cachelines):
        program.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
        if split_after is not None and cacheline + 1 == split_after:
            program.SLEEP(gap_cycles)
    end_row(program, write=False)
    return program.conclude()


def build_delayed_write_read_program(
    bank: int,
    row: int,
    cachelines: int,
    words: np.ndarray,
    delay_cycles: int,
):
    program = ProgramBuilder(target=TARGET)
    stage_wide_pattern(program, words)
    # Delay data production, rather than delaying an already-written DRAM
    # value.  This makes the transport check independent of real retention
    # failures when the FPGA's periodic auto-refresh source is disabled.
    program.SLEEP(delay_cycles)
    begin_row(program, bank, row)
    for _ in range(cachelines):
        program.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=True)

    begin_row(program, bank, row)
    for _ in range(cachelines):
        program.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=False)
    return program.conclude()


def build_scalar_branch_program(iterations: int):
    program = ProgramBuilder(target=TARGET)
    program.LI(0, "FUZZ_COUNTER")
    program.LI(iterations, "FUZZ_LIMIT")
    program.LI(0xA5A5A5A5, "FUZZ_VALUE")
    program.LABEL("FUZZ_LOOP")
    program.ADDI("FUZZ_COUNTER", 1, "FUZZ_COUNTER")
    program.SRC("FUZZ_VALUE", "FUZZ_VALUE")
    program.XOR("FUZZ_VALUE", "FUZZ_COUNTER", "FUZZ_VALUE")
    program.BL("FUZZ_COUNTER", "FUZZ_LIMIT", "FUZZ_LOOP")
    program.SLEEP(3)
    return program.conclude()


def row_slices(total_cachelines: int, start_row: int) -> list[tuple[int, int]]:
    result = []
    remaining = total_cachelines
    row = start_row
    while remaining:
        count = min(CACHELINES_PER_ROW, remaining)
        result.append((row, count))
        row += 1
        remaining -= count
    return result


def build_multirow_program(
    bank: int,
    rows: Iterable[tuple[int, int]],
    *,
    write: bool,
    words: np.ndarray | None = None,
):
    program = ProgramBuilder(target=TARGET)
    if write:
        if words is None:
            raise ValueError("write program requires a pattern")
        stage_wide_pattern(program, words)
    for row, cachelines in rows:
        begin_row(program, bank, row)
        for _ in range(cachelines):
            command = WR("BAR", "CAR", icar=1) if write else RD("BAR", "CAR", icar=1)
            program.DRAM(command, NOP(), NOP(), NOP())
            program.SLEEP(1)
        end_row(program, write=write)
    return program.conclude()


def validate_program(program: Any, expected_reads: int) -> None:
    result = program.dry_run(2_000_000)
    observed_reads = int(result.dram_cmd_counts["RD"])
    if observed_reads != expected_reads:
        raise AssertionError(
            f"offline program validation expected {expected_reads} RD commands, got {observed_reads}"
        )


def make_chunk_plan(total_words: int, rng: random.Random, style: str) -> list[int]:
    if style == "whole":
        return [total_words]
    if style == "wordwise":
        return [1] * total_words

    boundary_words = [1, 7, 8, 9, 15, 16, 17, 63, 64, 65, 255, 256, 257, 1023, 1024, 1025]
    plan = []
    remaining = total_words
    while remaining:
        if style == "boundary":
            requested = boundary_words[len(plan) % len(boundary_words)]
        else:
            requested = rng.randint(1, min(2048, remaining))
        count = min(requested, remaining)
        plan.append(count)
        remaining -= count
    return plan


def receive_chunks(board: Any, total_words: int, plan: list[int]) -> np.ndarray:
    if sum(plan) != total_words:
        raise ValueError("receive chunk plan does not cover the requested output")
    observed = np.empty(total_words, dtype=np.uint32)
    offset = 0
    for count in plan:
        board.receive_into(observed[offset : offset + count])
        offset += count
    return observed


def mismatch_summary(observed: np.ndarray, expected: np.ndarray) -> dict[str, Any]:
    mismatch = np.flatnonzero(observed != expected)
    result: dict[str, Any] = {"mismatched_words": int(mismatch.size)}
    if mismatch.size:
        first = int(mismatch[0])
        result.update(
            first_mismatch_word=first,
            expected=f"0x{int(expected[first]):08x}",
            observed=f"0x{int(observed[first]):08x}",
        )
    return result


class Suite:
    def __init__(self, board: Any, args: argparse.Namespace, output) -> None:
        self.board = board
        self.args = args
        self.output = output
        self.case_count = 0
        self.failure_count = 0
        self.retention_observations: list[dict[str, Any]] = []

    def record(self, record: dict[str, Any]) -> None:
        self.output.write(json.dumps(record, sort_keys=True) + "\n")
        self.output.flush()

    def run_strict(
        self,
        case_id: str,
        spec: dict[str, Any],
        operation,
        expected: np.ndarray,
    ) -> None:
        started = time.monotonic()
        record = {"case_id": case_id, "spec": spec, "status": "running"}
        self.case_count += 1
        try:
            observed = operation()
            comparison = mismatch_summary(observed, expected)
            if comparison["mismatched_words"]:
                raise AssertionError(json.dumps(comparison, sort_keys=True))
            record.update(
                status="pass",
                elapsed_seconds=time.monotonic() - started,
                bytes=int(observed.nbytes),
                sha256=hashlib.sha256(observed.tobytes()).hexdigest(),
            )
            print(f"PASS {case_id}: {observed.nbytes} bytes")
        except BaseException as exc:
            self.failure_count += 1
            record.update(
                status="fail",
                elapsed_seconds=time.monotonic() - started,
                error=f"{type(exc).__name__}: {exc}",
            )
            print(f"FAIL {case_id}: {record['error']}", file=sys.stderr)
            try:
                self.board.full_reset()
                record["full_reset"] = "pass"
            except BaseException as reset_error:
                record["full_reset"] = f"fail: {type(reset_error).__name__}: {reset_error}"
                self.record(record)
                raise
        self.record(record)

    def run_payload_case(self, case_index: int, cachelines: int) -> None:
        case_id = f"payload-{case_index:03d}-{cachelines}cl"
        rng = case_rng(self.args.seed, case_id)
        bank = [0, 1, 7, 8, 15][case_index % 5]
        row = [0, 1, 31, 32, 32767, 32768, 65534, 65535][case_index % 8]
        family = ["zero", "ones", "checker", "walking", "tagged"][case_index % 5]
        words = lane_words(family, self.args.seed, bank, row, case_index)
        rows = row_slices(cachelines, row if row + (cachelines // 128) <= 65535 else 64000)
        write = build_multirow_program(bank, rows, write=True, words=words)
        read = build_multirow_program(bank, rows, write=False)
        validate_program(read, cachelines)
        expected = np.tile(words, cachelines)
        style = ["whole", "boundary", "random", "wordwise"][case_index % 4]
        if style == "wordwise" and expected.size > 512:
            style = "boundary"
        plan = make_chunk_plan(expected.size, rng, style)
        variant = ["separate", "queued", "sync_before_receive"][case_index % 3]

        def operation() -> np.ndarray:
            if variant == "queued":
                self.board.execute([write, read])
            else:
                self.board.execute(write)
                self.board.synchronize()
                self.board.execute(read)
            if variant == "sync_before_receive":
                self.board.synchronize()
            observed = receive_chunks(self.board, expected.size, plan)
            self.board.synchronize()
            return observed

        self.run_strict(
            case_id,
            {
                "kind": "payload",
                "cachelines": cachelines,
                "bank": bank,
                "rows": rows,
                "pattern_family": family,
                "receive_words": plan,
                "variant": variant,
            },
            operation,
            expected,
        )

    def run_short_session(self, case_index: int) -> None:
        case_id = f"short-session-{case_index:04d}"
        rng = case_rng(self.args.seed, case_id)
        bank = rng.choice([0, 1, 7, 8, 15])
        row = rng.choice([0, 1, 31, 32, 255, 1023, 32767, 32768, 65534, 65535])
        words = lane_words("tagged", self.args.seed, bank, row, 10_000 + case_index)
        write = build_write_program(bank, row, 1, words)
        read = build_read_program(bank, row, 1)
        validate_program(read, 1)
        expected = words.copy()

        def operation() -> np.ndarray:
            if case_index % 3 == 0:
                scalar = build_scalar_branch_program(3 + case_index % 29)
                scalar_result = scalar.dry_run(10_000)
                if int(scalar_result.dram_cmd_counts["RD"]) != 0:
                    raise AssertionError("scalar-only fuzz program unexpectedly contains a read")
                self.board.execute(scalar)
                self.board.synchronize()
            self.board.execute(write)
            self.board.execute(read)
            if case_index % 4 == 0:
                time.sleep(0.001)
            observed = np.empty_like(expected)
            self.board.receive_into(observed)
            self.board.synchronize()
            return observed

        self.run_strict(
            case_id,
            {"kind": "short_session", "bank": bank, "row": row},
            operation,
            expected,
        )

    def run_delayed_consumption(self, delay_seconds: float) -> None:
        case_id = f"host-delayed-consumption-{delay_seconds:.3f}s"
        bank = 6
        row = 12288
        words = lane_words("tagged", self.args.seed, bank, row, 40_000)
        write = build_write_program(bank, row, 128, words)
        read = build_read_program(bank, row, 128)
        validate_program(read, 128)
        expected = np.tile(words, 128)

        def operation() -> np.ndarray:
            self.board.execute(write)
            self.board.synchronize()
            self.board.execute(read)
            # The receiver thread must safely queue a complete result while
            # the Python application is not consuming it.
            time.sleep(delay_seconds)
            observed = np.empty_like(expected)
            self.board.receive_into(observed)
            self.board.synchronize()
            return observed

        self.run_strict(
            case_id,
            {"kind": "host_delayed_consumption", "delay_seconds": delay_seconds},
            operation,
            expected,
        )

    def run_receive_timeout_semantics(self) -> None:
        bank = 5
        row = 16384
        delay_seconds = 6.0
        delay_cycles = round(delay_seconds * 1_000_000_000 / FABRIC_CYCLE_NS)
        words = lane_words("tagged", self.args.seed, bank, row, 50_000)
        delayed_write_read = build_delayed_write_read_program(
            bank, row, 1, words, delay_cycles
        )
        validate_program(delayed_write_read, 1)

        default_case_id = "default-unbounded-receive-after-6s"
        default_spec: dict[str, Any] = {
            "kind": "default_unbounded_receive",
            "delay_seconds": delay_seconds,
            "delay_cycles": delay_cycles,
            "minimum_receive_wait_seconds": 5.0,
        }

        def default_operation() -> np.ndarray:
            self.board.execute(delayed_write_read)
            observed = np.empty_like(words)
            receive_started = time.monotonic()
            self.board.receive_into(observed)
            default_spec["observed_receive_wait_seconds"] = (
                time.monotonic() - receive_started
            )
            if default_spec["observed_receive_wait_seconds"] <= 5.0:
                raise AssertionError(
                    "default receive did not actually wait beyond the old five-second boundary"
                )
            self.board.synchronize()
            return observed

        self.run_strict(
            default_case_id,
            default_spec,
            default_operation,
            words,
        )

        case_id = "explicit-receive-timeout-and-reuse"
        explicit_timeout_seconds = 0.250
        record: dict[str, Any] = {
            "case_id": case_id,
            "spec": {
                "kind": "explicit_receive_timeout",
                "delay_seconds": delay_seconds,
                "delay_cycles": delay_cycles,
                "timeout_seconds": explicit_timeout_seconds,
                "expected_error": "Timed out while waiting for readback data from the platform.",
            },
            "status": "running",
        }
        self.case_count += 1
        started = time.monotonic()
        try:
            self.board.execute(delayed_write_read)
            observed = np.empty(WORDS_PER_CACHELINE, dtype=np.uint32)
            receive_started = time.monotonic()
            try:
                self.board.receive_into(
                    observed,
                    timeout=explicit_timeout_seconds,
                )
            except RuntimeError as error:
                if str(error) != record["spec"]["expected_error"]:
                    raise
                record["timeout_return_seconds"] = time.monotonic() - receive_started
            else:
                raise AssertionError("receive_into ignored its explicit timeout")

            # The explicit-timeout path promises an automatic full_reset and
            # immediate reuse.  Do not issue another reset before this canary.
            recovery_words = lane_words("tagged", self.args.seed, bank, row + 1, 50_001)
            recovery_write = build_write_program(bank, row + 1, 1, recovery_words)
            recovery_read = build_read_program(bank, row + 1, 1)
            self.board.execute(recovery_write)
            self.board.execute(recovery_read)
            recovered = np.empty_like(recovery_words)
            self.board.receive_into(recovered)
            self.board.synchronize()
            comparison = mismatch_summary(recovered, recovery_words)
            if comparison["mismatched_words"]:
                raise AssertionError(f"timeout recovery canary failed: {comparison}")

            record.update(
                status="pass",
                elapsed_seconds=time.monotonic() - started,
                recovery="pass",
            )
            print(f"PASS {case_id}: explicit timeout and automatic full_reset reuse passed")
        except BaseException as exc:
            self.failure_count += 1
            record.update(
                status="fail",
                elapsed_seconds=time.monotonic() - started,
                error=f"{type(exc).__name__}: {exc}",
            )
            print(f"FAIL {case_id}: {record['error']}", file=sys.stderr)
            self.board.full_reset()
        self.record(record)

    def run_in_program_gap(self, case_index: int, gap_seconds: float) -> None:
        case_id = f"fpga-gap-{gap_seconds:.3f}s"
        bank = case_index % 4
        row = 4096 + case_index
        words = lane_words("tagged", self.args.seed, bank, row, 20_000 + case_index)
        write = build_write_program(bank, row, 8, words)
        gap_cycles = max(3, round(gap_seconds * 1_000_000_000 / FABRIC_CYCLE_NS))
        read = build_read_program(bank, row, 8, split_after=4, gap_cycles=gap_cycles)
        validate_program(read, 8)
        expected = np.tile(words, 8)

        def operation() -> np.ndarray:
            self.board.execute(write)
            self.board.synchronize()
            self.board.execute(read)
            observed = np.empty_like(expected)
            self.board.receive_into(observed[: 4 * WORDS_PER_CACHELINE])
            # The second default receive must remain blocked across even a
            # gap longer than five seconds; metadata, not silence, ends it.
            self.board.receive_into(observed[4 * WORDS_PER_CACHELINE :])
            self.board.synchronize()
            return observed

        self.run_strict(
            case_id,
            {
                "kind": "in_program_read_gap",
                "gap_seconds_requested": gap_seconds,
                "gap_cycles": gap_cycles,
                "receive_order": "receive_first_unbounded",
            },
            operation,
            expected,
        )

    def run_host_retention(self, case_index: int, delay_seconds: float) -> None:
        case_id = f"host-retention-{delay_seconds:.3f}s"
        bank = 12 + (case_index % 4)
        row = 8192 + case_index
        words = lane_words("tagged", self.args.seed, bank, row, 30_000 + case_index)
        write = build_write_program(bank, row, 128, words)
        read = build_read_program(bank, row, 128)
        validate_program(read, 128)
        expected = np.tile(words, 128)

        started = time.monotonic()
        record: dict[str, Any] = {
            "case_id": case_id,
            "spec": {
                "kind": "host_retention",
                "delay_seconds": delay_seconds,
                "bank": bank,
                "row": row,
                "refresh_note": "current FPGA defaults auto-refresh off",
            },
            "status": "running",
        }
        self.case_count += 1
        try:
            self.board.execute(write)
            self.board.synchronize()
            retention_start = time.monotonic()
            time.sleep(delay_seconds)
            actual_delay = time.monotonic() - retention_start
            self.board.execute(read)
            observed = np.empty_like(expected)
            self.board.receive_into(observed)
            self.board.synchronize()
            comparison = mismatch_summary(observed, expected)
            record.update(
                status="observation",
                elapsed_seconds=time.monotonic() - started,
                actual_retention_seconds=actual_delay,
                bytes=int(observed.nbytes),
                **comparison,
            )
            self.retention_observations.append(record.copy())
            print(
                f"OBS  {case_id}: {observed.nbytes} bytes, "
                f"{comparison['mismatched_words']} mismatched words"
            )
        except BaseException as exc:
            self.failure_count += 1
            record.update(
                status="transport_fail",
                elapsed_seconds=time.monotonic() - started,
                error=f"{type(exc).__name__}: {exc}",
            )
            print(f"FAIL {case_id}: {record['error']}", file=sys.stderr)
            self.board.full_reset()
        self.record(record)


def environment_record(args: argparse.Namespace) -> dict[str, Any]:
    core_path = Path(drambender._core.__file__).resolve()
    return {
        "type": "environment",
        "schema": 1,
        "seed": args.seed,
        "profile": args.profile,
        "pci_bdf": args.pci_bdf,
        "xdma_channel": args.xdma_channel,
        "hostname": platform.node(),
        "kernel": platform.release(),
        "git_head": git_value("rev-parse", "HEAD"),
        "git_status": git_value("status", "--porcelain=v1"),
        "python": sys.version,
        "package": str(Path(drambender.__file__).resolve()),
        "extension": str(core_path),
        "extension_sha256": file_sha256(core_path),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--pci-bdf", type=normalize_bdf, default=DEFAULT_BDF)
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument("--profile", choices=sorted(PROFILES), default="standard")
    parser.add_argument("--seed", type=parse_int, default=DEFAULT_SEED)
    parser.add_argument("--results", type=Path)
    args = parser.parse_args()
    if args.xdma_channel != 0:
        parser.error("this qualification harness intentionally supports only xdma_channel=0")
    if not 0 <= args.seed <= 0xFFFFFFFFFFFFFFFF:
        parser.error("seed must fit in an unsigned 64-bit integer")
    return args


def main() -> int:
    args = parse_args()
    profile = PROFILES[args.profile]
    results_path = args.results or Path(
        f"ddr4-readback-fuzz-{platform.node()}-{int(time.time())}.jsonl"
    )
    print(
        f"DDR4 metadata-v1 fuzz: bdf={args.pci_bdf} channel=0 "
        f"profile={args.profile} seed=0x{args.seed:016x}"
    )
    print(f"Results: {results_path}")

    with results_path.open("x", encoding="utf-8") as output:
        output.write(json.dumps(environment_record(args), sort_keys=True) + "\n")
        output.flush()
        with open_board(
            TARGET,
            pci_bdf=args.pci_bdf,
            xdma_channel=0,
            host_interface=HostInterface.XDMA,
        ) as board:
            board.full_reset()
            suite = Suite(board, args, output)
            try:
                all_payloads = list(profile["payload_cachelines"])
                all_payloads.extend(profile["large_cachelines"])
                for index, cachelines in enumerate(all_payloads):
                    suite.run_payload_case(index, cachelines)

                for index in range(profile["short_sessions"]):
                    suite.run_short_session(index)

                for index, gap_seconds in enumerate(profile["gap_seconds"]):
                    suite.run_in_program_gap(index, gap_seconds)

                suite.run_delayed_consumption(6.0 if args.profile != "quick" else 0.150)

                if args.profile != "quick":
                    suite.run_receive_timeout_semantics()

                for index, delay_seconds in enumerate(profile["host_retention_seconds"]):
                    suite.run_host_retention(index, delay_seconds)
            finally:
                # Establish a clean readback boundary regardless of outcome.
                # Do not claim to restore auto-refresh here: the current RTL
                # defaults it off and does not assert its periodic REF request.
                board.full_reset()

            summary = {
                "type": "summary",
                "cases": suite.case_count,
                "failures": suite.failure_count,
                "retention_observations": len(suite.retention_observations),
            }
            output.write(json.dumps(summary, sort_keys=True) + "\n")
            output.flush()

    print(
        f"SUMMARY cases={suite.case_count} failures={suite.failure_count} "
        f"retention_observations={len(suite.retention_observations)}"
    )
    return 0 if suite.failure_count == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
