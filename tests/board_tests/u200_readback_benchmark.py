#!/usr/bin/env python3
"""Reproducible U200 host/readback performance benchmark.

The timed region starts immediately before ``board.execute()`` and ends after
``board.synchronize()``.  DRAM initialization and correctness checking are
outside that region.  Every payload iteration is nevertheless checked against
deterministic row- and lane-distinct data before the next iteration starts.

This benchmark is deliberately restricted to an explicit PCI BDF and XDMA
channel 0.  It emits JSON Lines containing provenance, every warm-up and
measurement sample, and aggregate latency/throughput statistics.  Use
``--dry-run-only`` to validate all generated FPGA programs without opening a
board.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import socket
import subprocess
import sys
import time
from typing import Any, TextIO
import uuid

import numpy as np

import drambender
from drambender.api import DDR4Target, HostInterface, ProgramBuilder, open_board
from drambender.api.program.instructions import ACT, NOP, PRE, RD, WR


SCHEMA = "drambender.u200-readback-benchmark.v1"
BYTES_PER_CACHELINE = 64
WORDS_PER_CACHELINE = 16
CACHELINES_PER_ROW = 128
COLUMN_STRIDE = 8
MAX_DDR4_BANK = 15
MAX_DDR4_ROW = 65535
DEFAULT_WORKLOADS = ("completion", "64B", "8KiB", "64KiB", "512KiB")
WORKLOAD_CACHELINES = {
    "completion": 0,
    "64B": 1,
    "8KiB": 128,
    "64KiB": 1024,
    "512KiB": 8192,
}
TARGET = DDR4Target(
    cachelines_per_row=CACHELINES_PER_ROW,
    column_stride=COLUMN_STRIDE,
    words_per_cacheline=WORDS_PER_CACHELINE,
)
REPO_ROOT = Path(__file__).resolve().parents[2]


def utc_now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


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
    if not (
        0 <= domain <= 0xFFFF
        and 0 <= bus <= 0xFF
        and 0 <= slot <= 0x1F
        and 0 <= function <= 7
    ):
        raise argparse.ArgumentTypeError("PCI BDF field is out of range")
    return f"{domain:04x}:{bus:02x}:{slot:02x}.{function}"


def parse_workloads(text: str) -> tuple[str, ...]:
    names = tuple(part.strip() for part in text.split(",") if part.strip())
    if not names:
        raise argparse.ArgumentTypeError("at least one workload is required")
    unknown = [name for name in names if name not in WORKLOAD_CACHELINES]
    if unknown:
        raise argparse.ArgumentTypeError(
            f"unknown workload(s) {', '.join(unknown)}; choose from "
            + ", ".join(DEFAULT_WORKLOADS)
        )
    if len(names) != len(set(names)):
        raise argparse.ArgumentTypeError("workload names must not be repeated")
    return names


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def git_output(*args: str) -> str:
    try:
        return subprocess.check_output(
            ["git", *args],
            cwd=REPO_ROOT,
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def read_text(path: Path) -> str | None:
    try:
        return path.read_text().strip()
    except OSError:
        return None


def sysfs_device_provenance(bdf: str) -> dict[str, Any]:
    root = Path("/sys/bus/pci/devices") / bdf
    fields = (
        "vendor",
        "device",
        "subsystem_vendor",
        "subsystem_device",
        "current_link_speed",
        "current_link_width",
        "numa_node",
    )
    result: dict[str, Any] = {
        "sysfs_path": str(root),
        "present": root.exists(),
    }
    for field in fields:
        value = read_text(root / field)
        if value is not None:
            result[field] = value
    try:
        result["driver"] = (root / "driver").resolve(strict=True).name
    except OSError:
        result["driver"] = None
    return result


def module_provenance(name: str) -> dict[str, Any]:
    root = Path("/sys/module") / name
    return {
        "name": name,
        "loaded": root.exists(),
        "srcversion": read_text(root / "srcversion"),
        "version": read_text(root / "version"),
    }


def package_provenance() -> dict[str, Any]:
    package_path = Path(drambender.__file__).resolve()
    core_module = getattr(drambender, "_core", None)
    core_name = getattr(core_module, "__file__", None)
    core_path = Path(core_name).resolve() if core_name else None
    return {
        "package_path": str(package_path),
        "core_path": str(core_path) if core_path else None,
        "core_sha256": sha256_file(core_path) if core_path and core_path.is_file() else None,
    }


def lane_pattern(seed: int, bank: int, row: int) -> np.ndarray:
    """Generate deterministic row- and lane-distinct 32-bit words."""
    state = (seed ^ (bank << 27) ^ row ^ 0x9E3779B9) & 0xFFFFFFFF
    if state == 0:
        state = 0xA341316C
    words = []
    for lane in range(WORDS_PER_CACHELINE):
        state ^= (state << 13) & 0xFFFFFFFF
        state ^= state >> 17
        state ^= (state << 5) & 0xFFFFFFFF
        words.append((state ^ ((lane + 1) * 0x45D9F3B)) & 0xFFFFFFFF)
    return np.asarray(words, dtype=np.uint32)


def stage_wide_pattern(program: ProgramBuilder, words: np.ndarray) -> None:
    if words.shape != (WORDS_PER_CACHELINE,):
        raise ValueError("wide pattern must contain exactly 16 words")
    for lane, value in enumerate(words):
        program.LI(int(value), "PATTERN_REG")
        program.LDWD("PATTERN_REG", lane)


def begin_row(program: ProgramBuilder) -> None:
    program.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    program.LI(0, "CAR")
    program.SLEEP(2)
    program.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    program.SLEEP(2)


def end_row(program: ProgramBuilder, *, write: bool) -> None:
    program.SLEEP(8 if write else 4)
    program.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    program.SLEEP(3)


def build_completion_program():
    program = ProgramBuilder(target=TARGET)
    program.SLEEP(1)
    return program.conclude()


def build_write_row_program(bank: int, row: int, cachelines: int, words: np.ndarray):
    program = ProgramBuilder(target=TARGET)
    stage_wide_pattern(program, words)
    program.LI(bank, "BAR")
    program.LI(row, "RAR")
    program.LI(COLUMN_STRIDE, "CASR")
    program.LI(cachelines, "COLUMN_LIMIT")
    program.LI(0, "COLUMN_COUNTER")
    begin_row(program)
    program.LABEL("WRITE_CACHELINE")
    program.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
    program.SLEEP(1)
    program.ADDI("COLUMN_COUNTER", 1, "COLUMN_COUNTER")
    program.BL("COLUMN_COUNTER", "COLUMN_LIMIT", "WRITE_CACHELINE")
    end_row(program, write=True)
    return program.conclude()


def build_read_rows_program(bank: int, start_row: int, cachelines: int):
    """Build one compact, looped program for 64 B through 512 KiB."""
    rows = math.ceil(cachelines / CACHELINES_PER_ROW)
    final_row_cachelines = cachelines - (rows - 1) * CACHELINES_PER_ROW
    if rows > 1 and final_row_cachelines != CACHELINES_PER_ROW:
        raise ValueError("multirow read workloads must contain only whole rows")
    program = ProgramBuilder(target=TARGET)
    program.LI(bank, "BAR")
    program.LI(start_row, "RAR")
    program.LI(start_row + rows, "ROW_LIMIT")
    program.LI(COLUMN_STRIDE, "CASR")

    program.LABEL("READ_ROW")
    begin_row(program)
    # Unroll one row so the generated SMC_INFO reserves one 64 B or 8 KiB read
    # segment per loop iteration. The RBE packetizes that data independently
    # according to FIFO occupancy and its batching timer. The outer row loop
    # keeps even 512 KiB safely below the FPGA's static instruction-memory
    # limit while exercising sustained readback.
    for _ in range(final_row_cachelines):
        program.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=False)
    program.ADDI("RAR", 1, "RAR")
    program.BL("RAR", "ROW_LIMIT", "READ_ROW")
    return program.conclude()


def validate_program(program: Any, expected_reads: int) -> dict[str, Any]:
    result = program.dry_run(2_000_000)
    observed_reads = int(result.dram_cmd_counts["RD"])
    if observed_reads != expected_reads:
        raise AssertionError(
            f"offline validation expected {expected_reads} RD commands, got {observed_reads}"
        )
    return {
        "static_instructions": int(program.instruction_count),
        "dynamic_instructions": int(result.instructions_executed),
        "cycles": int(result.total_cycles),
        "reads": observed_reads,
        "writes": int(result.dram_cmd_counts["WR"]),
    }


def build_workload(name: str, bank: int, start_row: int, seed: int) -> dict[str, Any]:
    cachelines = WORKLOAD_CACHELINES[name]
    if cachelines == 0:
        program = build_completion_program()
        return {
            "name": name,
            "payload_bytes": 0,
            "cachelines": 0,
            "rows": 0,
            "program": program,
            "program_validation": validate_program(program, 0),
            "setup_programs": [],
            "expected": None,
        }

    rows = math.ceil(cachelines / CACHELINES_PER_ROW)
    setup_programs = []
    expected_parts = []
    remaining = cachelines
    for row_offset in range(rows):
        row = start_row + row_offset
        row_cachelines = min(CACHELINES_PER_ROW, remaining)
        words = lane_pattern(seed, bank, row)
        write_program = build_write_row_program(bank, row, row_cachelines, words)
        write_validation = validate_program(write_program, 0)
        if write_validation["writes"] != row_cachelines:
            raise AssertionError(
                f"offline validation expected {row_cachelines} WR commands, "
                f"got {write_validation['writes']}"
            )
        setup_programs.append(write_program)
        expected_parts.append(np.tile(words, row_cachelines))
        remaining -= row_cachelines

    read_program = build_read_rows_program(bank, start_row, cachelines)
    expected = np.concatenate(expected_parts).astype(np.uint32, copy=False)
    if expected.nbytes != cachelines * BYTES_PER_CACHELINE:
        raise AssertionError("internal expected-payload sizing error")
    return {
        "name": name,
        "payload_bytes": int(expected.nbytes),
        "cachelines": cachelines,
        "rows": rows,
        "program": read_program,
        "program_validation": validate_program(read_program, cachelines),
        "setup_programs": setup_programs,
        "expected": expected,
        "expected_sha256": hashlib.sha256(expected.tobytes()).hexdigest(),
    }


def percentile_linear(samples: list[int], percentile: float) -> float:
    if not samples:
        raise ValueError("cannot calculate a percentile of no samples")
    ordered = sorted(samples)
    rank = (len(ordered) - 1) * percentile / 100.0
    lower = math.floor(rank)
    upper = math.ceil(rank)
    if lower == upper:
        return float(ordered[lower])
    weight = rank - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def distribution(samples: list[int]) -> dict[str, Any]:
    mean = sum(samples) / len(samples)
    variance = sum((value - mean) ** 2 for value in samples) / len(samples)
    return {
        "min": min(samples),
        "mean": mean,
        "p50": percentile_linear(samples, 50),
        "p95": percentile_linear(samples, 95),
        "p99": percentile_linear(samples, 99),
        "max": max(samples),
        "population_stddev": math.sqrt(variance),
    }


def summarize(samples: list[dict[str, Any]], payload_bytes: int) -> dict[str, Any]:
    elapsed = [int(sample["elapsed_ns"]) for sample in samples]
    total_ns = sum(elapsed)
    total_seconds = total_ns / 1e9
    return {
        "samples": len(elapsed),
        "percentile_method": "linear_r7",
        "latency_ns": distribution(elapsed),
        "phase_latency_ns": {
            phase: distribution([int(sample[f"{phase}_ns"]) for sample in samples])
            for phase in ("execute", "receive", "synchronize")
        },
        "total_elapsed_ns": total_ns,
        "runs_per_second": len(elapsed) / total_seconds,
        "payload_gib_per_second": (
            len(elapsed) * payload_bytes / total_seconds / (1024**3)
            if payload_bytes
            else 0.0
        ),
    }


class JsonlWriter:
    def __init__(self, stream: TextIO, run_id: str) -> None:
        self.stream = stream
        self.run_id = run_id

    def write(self, record_type: str, **fields: Any) -> None:
        record = {
            "schema": SCHEMA,
            "record_type": record_type,
            "run_id": self.run_id,
            "timestamp_utc": utc_now(),
            **fields,
        }
        self.stream.write(json.dumps(record, sort_keys=True) + "\n")
        self.stream.flush()


def mismatch_details(observed: np.ndarray, expected: np.ndarray) -> dict[str, Any]:
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


def run_iteration(board: Any, workload: dict[str, Any]) -> tuple[dict[str, Any], np.ndarray | None]:
    expected = workload["expected"]
    observed = np.empty_like(expected) if expected is not None else None
    if observed is not None:
        observed.fill(np.uint32(0x0D15EA5E))

    started = time.perf_counter_ns()
    board.execute(workload["program"])
    after_execute = time.perf_counter_ns()
    if observed is not None:
        received = board.receive_into(observed)
        if received != observed.nbytes:
            raise RuntimeError(f"short receive: expected {observed.nbytes}, got {received}")
        after_receive = time.perf_counter_ns()
    else:
        after_receive = after_execute
    board.synchronize()
    finished = time.perf_counter_ns()
    return (
        {
            "execute_ns": after_execute - started,
            "receive_ns": after_receive - after_execute,
            "synchronize_ns": finished - after_receive,
            "elapsed_ns": finished - started,
        },
        observed,
    )


def execute_checked_sample(
    board: Any,
    workload: dict[str, Any],
    writer: JsonlWriter,
    phase: str,
    iteration: int,
) -> dict[str, Any]:
    timing, observed = run_iteration(board, workload)
    expected = workload["expected"]
    if observed is None:
        correctness = {"mismatched_words": 0, "sha256": None}
    else:
        correctness = mismatch_details(observed, expected)
        correctness["sha256"] = hashlib.sha256(observed.tobytes()).hexdigest()

    record = {
        "workload": workload["name"],
        "phase": phase,
        "iteration": iteration,
        "payload_bytes": workload["payload_bytes"],
        **timing,
        **correctness,
    }
    writer.write("sample", **record)
    if correctness["mismatched_words"]:
        raise AssertionError(
            f"{workload['name']} {phase} iteration {iteration} failed correctness: "
            + json.dumps(correctness, sort_keys=True)
        )
    return record


def output_path_for_now() -> Path:
    stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
    return Path(f"u200-readback-benchmark-{stamp}.jsonl")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pci-bdf", type=normalize_bdf, required=True)
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--start-row", type=int, default=4096)
    parser.add_argument("--seed", type=lambda value: int(value, 0), default=0x55423230)
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--iterations", type=int, default=100)
    parser.add_argument(
        "--workloads",
        type=parse_workloads,
        default=DEFAULT_WORKLOADS,
        help="comma-separated subset of completion,64B,8KiB,64KiB,512KiB",
    )
    parser.add_argument(
        "--stack-label",
        required=True,
        help="user-declared stack identifier, e.g. new-repo-metadata-v1",
    )
    parser.add_argument(
        "--driver-label",
        required=True,
        help="user-declared driver build/configuration identifier",
    )
    parser.add_argument(
        "--bitstream-label",
        required=True,
        help="user-declared identifier for the image believed to be programmed",
    )
    parser.add_argument(
        "--bitstream-file",
        type=Path,
        help="optional local image file to hash as declared bitstream provenance",
    )
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument(
        "--dry-run-only",
        action="store_true",
        help="build and VM-validate programs without opening hardware or writing JSONL",
    )
    args = parser.parse_args()

    if args.xdma_channel != 0:
        parser.error("this benchmark is intentionally restricted to XDMA channel 0")
    if not 0 <= args.bank <= MAX_DDR4_BANK:
        parser.error(f"--bank must be in range 0..{MAX_DDR4_BANK}")
    if args.warmups < 0:
        parser.error("--warmups cannot be negative")
    if args.iterations < 1:
        parser.error("--iterations must be at least 1")
    if not 0 <= args.seed <= 0xFFFFFFFF:
        parser.error("--seed must fit in an unsigned 32-bit integer")
    max_rows = max(
        math.ceil(WORKLOAD_CACHELINES[name] / CACHELINES_PER_ROW)
        for name in args.workloads
    )
    if not 0 <= args.start_row <= MAX_DDR4_ROW or (
        max_rows and args.start_row + max_rows - 1 > MAX_DDR4_ROW
    ):
        parser.error(
            f"--start-row must leave room for {max_rows} rows within 0..{MAX_DDR4_ROW}"
        )
    if args.bitstream_file is not None and not args.bitstream_file.is_file():
        parser.error(f"--bitstream-file is not a readable file: {args.bitstream_file}")
    return args


def print_program_table(workloads: list[dict[str, Any]]) -> None:
    print("workload    bytes       rows  static-inst  dynamic-inst  VM RD")
    for workload in workloads:
        validation = workload["program_validation"]
        print(
            f"{workload['name']:<11} {workload['payload_bytes']:>8} "
            f"{workload['rows']:>6} {validation['static_instructions']:>12} "
            f"{validation['dynamic_instructions']:>13} {validation['reads']:>6}"
        )


def main() -> int:
    args = parse_args()
    workloads = [
        build_workload(name, args.bank, args.start_row, args.seed)
        for name in args.workloads
    ]
    print_program_table(workloads)
    if args.dry_run_only:
        print("PASS: all generated programs passed VM command-count validation")
        return 0

    output_path = args.output or output_path_for_now()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    run_id = str(uuid.uuid4())
    bitstream_file = args.bitstream_file.resolve() if args.bitstream_file else None
    affinity_cpus = (
        sorted(os.sched_getaffinity(0)) if hasattr(os, "sched_getaffinity") else None
    )
    provenance = {
        "argv": sys.argv,
        "hostname": socket.gethostname(),
        "platform": platform.platform(),
        "kernel": platform.release(),
        "python": platform.python_version(),
        "numpy": np.__version__,
        "pid": os.getpid(),
        "sched_affinity_cpus": affinity_cpus,
        "sched_affinity_list": (
            ",".join(str(cpu) for cpu in affinity_cpus)
            if affinity_cpus is not None
            else None
        ),
        "git_commit": git_output("rev-parse", "HEAD"),
        "git_branch": git_output("branch", "--show-current"),
        "git_dirty": bool(git_output("status", "--porcelain") not in ("", "unknown")),
        "package": package_provenance(),
        "pci_device": sysfs_device_provenance(args.pci_bdf),
        "xdma_module": module_provenance("xdma"),
        "adapter": "new_repo_python_nanobind",
        "stack_label": args.stack_label,
        "driver_label": args.driver_label,
        "bitstream": {
            "label": args.bitstream_label,
            "declared_file": str(bitstream_file) if bitstream_file else None,
            "declared_file_sha256": sha256_file(bitstream_file) if bitstream_file else None,
            "qualification": "user-declared; the host cannot attest the programmed image",
        },
        "pci_bdf": args.pci_bdf,
        "xdma_channel": args.xdma_channel,
        "bank": args.bank,
        "start_row": args.start_row,
        "seed": args.seed,
        "warmups": args.warmups,
        "iterations": args.iterations,
        "workloads": list(args.workloads),
        "timed_region": "immediately before execute through return from synchronize",
        "correctness_region": "outside timed region, after every payload sample",
        "binding_overhead": "Python-to-C++ binding overhead is included in every phase",
        "payload_definition": (
            "one execute of a looped read program; 64 B is one cacheline and larger "
            "workloads use contiguous complete 8 KiB rows"
        ),
        "pattern_definition": (
            "32-bit xorshift row/lane pattern from seed, bank, and logical row; "
            "each row repeats its 16 lane words across its cachelines"
        ),
    }

    board = None
    status = "fail"
    cleanup_error: str | None = None
    summaries: list[dict[str, Any]] = []
    # Refuse accidental overwrite: separate runs must remain separate artifacts.
    with output_path.open("x", encoding="utf-8") as stream:
        writer = JsonlWriter(stream, run_id)
        writer.write("run_start", provenance=provenance)
        try:
            board = open_board(
                TARGET,
                pci_bdf=args.pci_bdf,
                xdma_channel=args.xdma_channel,
                host_interface=HostInterface.XDMA,
            )
            board.full_reset()
            for workload in workloads:
                writer.write(
                    "workload_start",
                    workload=workload["name"],
                    payload_bytes=workload["payload_bytes"],
                    cachelines=workload["cachelines"],
                    rows=workload["rows"],
                    program_validation=workload["program_validation"],
                    setup_programs=len(workload["setup_programs"]),
                    expected_sha256=workload.get("expected_sha256"),
                )
                board.full_reset()
                for setup_program in workload["setup_programs"]:
                    board.execute(setup_program)
                board.synchronize()

                # A dedicated preflight is always run, even with --warmups=0.
                execute_checked_sample(board, workload, writer, "preflight", 0)
                for iteration in range(args.warmups):
                    execute_checked_sample(board, workload, writer, "warmup", iteration)

                measured = [
                    execute_checked_sample(board, workload, writer, "measurement", iteration)
                    for iteration in range(args.iterations)
                ]
                summary = {
                    "workload": workload["name"],
                    "payload_bytes": workload["payload_bytes"],
                    **summarize(measured, workload["payload_bytes"]),
                }
                summaries.append(summary)
                writer.write("summary", **summary)
                latency = summary["latency_ns"]
                print(
                    f"{workload['name']}: p50={latency['p50'] / 1e6:.3f} ms "
                    f"p95={latency['p95'] / 1e6:.3f} ms "
                    f"p99={latency['p99'] / 1e6:.3f} ms "
                    f"max={latency['max'] / 1e6:.3f} ms "
                    f"runs/s={summary['runs_per_second']:.2f} "
                    f"GiB/s={summary['payload_gib_per_second']:.4f}"
                )
            status = "pass"
        except BaseException as exc:
            writer.write("error", error=f"{type(exc).__name__}: {exc}")
            raise
        finally:
            reset_result = "not-opened"
            if board is not None:
                try:
                    board.full_reset()
                    reset_result = "pass"
                except BaseException as exc:
                    reset_result = f"fail: {type(exc).__name__}: {exc}"
                    cleanup_error = f"final full_reset failed: {type(exc).__name__}: {exc}"
                    status = "fail"
                try:
                    board.close()
                except BaseException as exc:
                    writer.write("close_error", error=f"{type(exc).__name__}: {exc}")
                    cleanup_error = cleanup_error or (
                        f"board close failed: {type(exc).__name__}: {exc}"
                    )
                    status = "fail"
            writer.write("run_end", status=status, final_full_reset=reset_result, summaries=summaries)

    if cleanup_error is not None:
        raise RuntimeError(cleanup_error)
    print(f"JSONL: {output_path.resolve()}")
    print(f"SHA-256: {sha256_file(output_path)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
