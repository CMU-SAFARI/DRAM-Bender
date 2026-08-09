#!/usr/bin/env python3
"""Exercise SIGINT and SIGKILL recovery on explicit DDR4 endpoints.

The parent never opens a Board.  For each requested BDF/channel tuple it first
interrupts a child blocked in readback from a six-second FPGA program and
requires automatic full-reset plus same-handle reuse.  It then kills an armed
child with SIGKILL and requires a fresh process to full-reset and verify a
tagged row without reloading the driver or reprogramming the FPGA.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import select
import signal
import subprocess
import sys
import time
from typing import Any

import numpy as np

import drambender
from drambender.api import DDR4Target, HostInterface, ProgramBuilder, open_board
from drambender.api.program.instructions import ACT, NOP, PRE, RD, WR


ENDPOINTS = (
    "0000:01:00.0/0", "0000:01:00.0/1",
    "0000:21:00.0/0", "0000:21:00.0/1",
    "0000:22:00.0/0", "0000:22:00.0/1",
    "0000:41:00.0/0", "0000:41:00.0/1",
    "0000:42:00.0/0", "0000:42:00.0/1",
    "0000:61:00.0/0", "0000:61:00.0/1",
)
BDF_RE = re.compile(r"^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}\.[0-7]$")
CACHELINES_PER_ROW = 128
WORDS_PER_CACHELINE = 16
COLUMN_STRIDE = 8
ROW_WORDS = CACHELINES_PER_ROW * WORDS_PER_CACHELINE
DELAY_CYCLES = 1_000_000_000  # Six seconds at the 6 ns fabric cycle.
TARGET = DDR4Target(
    cachelines_per_row=CACHELINES_PER_ROW,
    column_stride=COLUMN_STRIDE,
    words_per_cacheline=WORDS_PER_CACHELINE,
)


def parse_endpoint(text: str) -> tuple[str, int]:
    try:
        bdf, channel_text = text.rsplit("/", 1)
        channel = int(channel_text)
    except (ValueError, TypeError) as exc:
        raise argparse.ArgumentTypeError("endpoint must use dddd:bb:ss.f/0|1") from exc
    if BDF_RE.fullmatch(bdf) is None or channel not in (0, 1):
        raise argparse.ArgumentTypeError("endpoint must use dddd:bb:ss.f/0|1")
    return bdf.lower(), channel


def stage_pattern(program: ProgramBuilder, pattern: int) -> None:
    for lane in range(WORDS_PER_CACHELINE):
        value = (pattern ^ (lane * 0x45D9F3B)) & 0xFFFFFFFF
        program.LI(value, "PATTERN_REG")
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


def build_write(bank: int, row: int, pattern: int):
    program = ProgramBuilder(target=TARGET)
    stage_pattern(program, pattern)
    begin_row(program, bank, row)
    for _ in range(CACHELINES_PER_ROW):
        program.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=True)
    return program.conclude()


def build_read(bank: int, row: int):
    program = ProgramBuilder(target=TARGET)
    begin_row(program, bank, row)
    for _ in range(CACHELINES_PER_ROW):
        program.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=False)
    return program.conclude()


def build_delayed_write_read(bank: int, row: int, pattern: int):
    program = ProgramBuilder(target=TARGET)
    stage_pattern(program, pattern)
    begin_row(program, bank, row)
    for _ in range(CACHELINES_PER_ROW):
        program.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=True)
    program.SLEEP(DELAY_CYCLES)
    begin_row(program, bank, row)
    for _ in range(CACHELINES_PER_ROW):
        program.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=False)
    return program.conclude()


def expected_words(pattern: int) -> np.ndarray:
    lanes = np.asarray(
        [(pattern ^ (lane * 0x45D9F3B)) & 0xFFFFFFFF for lane in range(WORDS_PER_CACHELINE)],
        dtype=np.uint32,
    )
    return np.tile(lanes, CACHELINES_PER_ROW)


def verify_canary(board: Any, bank: int, row: int, pattern: int) -> str:
    observed = np.empty(ROW_WORDS, dtype=np.uint32)
    board.execute([build_write(bank, row, pattern), build_read(bank, row)])
    board.receive_into(observed)
    board.synchronize()
    expected = expected_words(pattern)
    if not np.array_equal(observed, expected):
        mismatches = np.flatnonzero(observed != expected)
        first = int(mismatches[0])
        raise RuntimeError(
            f"{mismatches.size} canary mismatches; first word {first}: "
            f"expected=0x{int(expected[first]):08x} observed=0x{int(observed[first]):08x}"
        )
    return hashlib.sha256(observed.tobytes()).hexdigest()


def child_main(mode: str, bdf: str, channel: int, endpoint_index: int) -> int:
    bank = endpoint_index % 16
    row = 512 + endpoint_index
    delayed_pattern = (0xA1000000 | endpoint_index) & 0xFFFFFFFF
    canary_pattern = (0xC3000000 | (endpoint_index << 8) | channel) & 0xFFFFFFFF
    board = open_board(
        TARGET,
        pci_bdf=bdf,
        xdma_channel=channel,
        host_interface=HostInterface.XDMA,
    )
    try:
        board.full_reset()
        if mode in ("sigint", "sigkill"):
            observed = np.empty(ROW_WORDS, dtype=np.uint32)
            board.execute(build_delayed_write_read(bank, row, delayed_pattern))
            print(json.dumps({"event": "armed", "mode": mode, "bdf": bdf, "channel": channel}), flush=True)
            started = time.monotonic()
            try:
                board.receive_into(observed)
                board.synchronize()
            except KeyboardInterrupt:
                if mode != "sigint":
                    raise
                interrupt_seconds = time.monotonic() - started
                digest = verify_canary(board, bank, row + 64, canary_pattern)
                board.full_reset()
                print(json.dumps({"event": "pass", "mode": mode,
                                  "interrupt_seconds": interrupt_seconds,
                                  "canary_sha256": digest}), flush=True)
                return 0
            raise RuntimeError(f"{mode} child completed delayed program before interruption")
        if mode == "recover":
            digest = verify_canary(board, bank, row + 128, canary_pattern ^ 0x01010101)
            board.full_reset()
            print(json.dumps({"event": "pass", "mode": mode,
                              "canary_sha256": digest}), flush=True)
            return 0
        raise ValueError(f"unknown child mode {mode}")
    finally:
        board.close()


def wait_for_armed(process: subprocess.Popen[str], timeout: float) -> dict[str, Any]:
    assert process.stdout is not None
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        remaining = max(0.0, deadline - time.monotonic())
        ready, _, _ = select.select([process.stdout], [], [], min(0.1, remaining))
        if ready:
            line = process.stdout.readline()
            if not line:
                break
            record = json.loads(line)
            if record.get("event") == "armed":
                return record
        if process.poll() is not None:
            break
    return_code = process.poll()
    stderr = "<child still running>"
    if return_code is not None and process.stderr is not None:
        stderr = process.stderr.read()
    raise RuntimeError(
        f"child did not arm within {timeout}s; rc={return_code} stderr={stderr}"
    )


def start_child(mode: str, endpoint: tuple[str, int], index: int) -> subprocess.Popen[str]:
    bdf, channel = endpoint
    return subprocess.Popen(
        [sys.executable, str(Path(__file__).resolve()), "--child-mode", mode,
         "--child-bdf", bdf, "--child-channel", str(channel),
         "--child-index", str(index)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def finish_child(process: subprocess.Popen[str], timeout: float) -> tuple[int, str, str]:
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        process.kill()
        stdout, stderr = process.communicate()
        raise RuntimeError(f"child timed out; stdout={stdout} stderr={stderr}")
    return process.returncode, stdout, stderr


def cleanup_children(
    children: tuple[tuple[str, subprocess.Popen[str] | None], ...],
    timeout: float = 2.0,
) -> list[str]:
    """Kill and reap active children without masking the caller's exception."""
    errors: list[str] = []
    for label, child in children:
        if child is None:
            continue
        try:
            if child.poll() is None:
                child.kill()
            child.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            errors.append(
                f"{label} child pid={child.pid} did not exit within {timeout:.1f}s"
            )
        except Exception as exc:
            errors.append(f"{label} child cleanup failed: {type(exc).__name__}: {exc}")
    return errors


def run_parent(endpoints: list[tuple[str, int]], output: Path) -> int:
    failures = 0
    with output.open("x", encoding="utf-8") as stream:
        script_path = Path(__file__).resolve()
        core_path = Path(drambender._core.__file__).resolve()
        stream.write(json.dumps({
            "type": "environment",
            "endpoints": endpoints,
            "python": sys.version,
            "kernel": os.uname().release,
            "script": str(script_path),
            "script_sha256": hashlib.sha256(script_path.read_bytes()).hexdigest(),
            "extension": str(core_path),
            "extension_sha256": hashlib.sha256(core_path.read_bytes()).hexdigest(),
            "driver_srcversion": Path(
                "/sys/module/drambender_xdma/srcversion"
            ).read_text().strip(),
        }, sort_keys=True) + "\n")
        for index, endpoint in enumerate(endpoints):
            bdf, channel = endpoint
            case_started = time.monotonic()
            record: dict[str, Any] = {"bdf": bdf, "channel": channel}
            sigint_child: subprocess.Popen[str] | None = None
            kill_child: subprocess.Popen[str] | None = None
            try:
                sigint_child = start_child("sigint", endpoint, index)
                wait_for_armed(sigint_child, 5.0)
                time.sleep(0.25)
                os.kill(sigint_child.pid, signal.SIGINT)
                rc, stdout, stderr = finish_child(sigint_child, 10.0)
                if rc != 0 or '"event": "pass"' not in stdout:
                    raise RuntimeError(f"SIGINT child failed: rc={rc} stdout={stdout} stderr={stderr}")
                record["sigint"] = "pass"
                record["sigint_output"] = [json.loads(line) for line in stdout.splitlines() if line]

                kill_child = start_child("sigkill", endpoint, index)
                wait_for_armed(kill_child, 5.0)
                time.sleep(0.25)
                os.kill(kill_child.pid, signal.SIGKILL)
                rc, stdout, stderr = finish_child(kill_child, 3.0)
                if rc != -signal.SIGKILL:
                    raise RuntimeError(f"SIGKILL child exit={rc}: stdout={stdout} stderr={stderr}")
                recovery = subprocess.run(
                    [sys.executable, str(Path(__file__).resolve()), "--child-mode", "recover",
                     "--child-bdf", bdf, "--child-channel", str(channel),
                     "--child-index", str(index)],
                    text=True, capture_output=True, timeout=10.0, check=False,
                )
                if recovery.returncode != 0 or '"event": "pass"' not in recovery.stdout:
                    raise RuntimeError(
                        f"fresh recovery failed: rc={recovery.returncode} "
                        f"stdout={recovery.stdout} stderr={recovery.stderr}"
                    )
                record["sigkill"] = "pass"
                record["recovery_output"] = [json.loads(line) for line in recovery.stdout.splitlines() if line]
                record["status"] = "pass"
            except KeyboardInterrupt:
                cleanup_errors = cleanup_children((
                    ("SIGINT", sigint_child),
                    ("SIGKILL", kill_child),
                ))
                for error in cleanup_errors:
                    print(f"warning: {error}", file=sys.stderr, flush=True)
                raise
            except Exception as exc:
                failures += 1
                record["status"] = "fail"
                record["error"] = f"{type(exc).__name__}: {exc}"
                cleanup_errors = cleanup_children((
                    ("SIGINT", sigint_child),
                    ("SIGKILL", kill_child),
                ))
                if cleanup_errors:
                    record["cleanup_errors"] = cleanup_errors
            record["elapsed_seconds"] = time.monotonic() - case_started
            stream.write(json.dumps(record, sort_keys=True) + "\n")
            stream.flush()
            print(f"{record['status'].upper()} {bdf}/ch{channel} "
                  f"({record['elapsed_seconds']:.3f}s)", flush=True)
        summary = {"type": "summary", "cases": len(endpoints), "failures": failures}
        stream.write(json.dumps(summary, sort_keys=True) + "\n")
    return 0 if failures == 0 else 1


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--endpoint", action="append", type=parse_endpoint)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--dry-run-only", action="store_true")
    parser.add_argument("--child-mode", choices=("sigint", "sigkill", "recover"))
    parser.add_argument("--child-bdf")
    parser.add_argument("--child-channel", type=int)
    parser.add_argument("--child-index", type=int)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.child_mode:
        if args.child_bdf is None or args.child_channel not in (0, 1) or args.child_index is None:
            raise SystemExit("child mode requires BDF, channel, and index")
        return child_main(args.child_mode, args.child_bdf, args.child_channel, args.child_index)
    endpoints = args.endpoint or [parse_endpoint(text) for text in ENDPOINTS]
    if len(set(endpoints)) != len(endpoints):
        raise SystemExit("endpoints must be unique")
    for index in range(len(endpoints)):
        for program in (
            build_write(index % 16, 512 + index, 0xC3000000 | index),
            build_read(index % 16, 512 + index),
            build_delayed_write_read(index % 16, 512 + index, 0xA1000000 | index),
        ):
            program.dry_run(100_000)
    if args.dry_run_only:
        print(f"Validated interrupt programs for {len(endpoints)} endpoint(s).")
        return 0
    output = args.output or Path(f"multi-endpoint-interrupt-{int(time.time())}.jsonl")
    return run_parent(endpoints, output)


if __name__ == "__main__":
    raise SystemExit(main())
