#!/usr/bin/env python3
"""Prove that full_reset() is isolated between sibling U200 XDMA channels.

For each PCI BDF, the test exercises both directions.  An active child starts
a program that delays data production, then writes and reads a tagged row.  A
second child owns the sibling channel and performs full_reset() plus a tagged
read/write canary while the active child is waiting for readback.  The parent
requires the reset interval to fall inside the active execution interval and
checks exact payload hashes from both children.
"""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import select
import signal
import socket
import subprocess
import sys
import time
from typing import Any

import numpy as np

import drambender
from drambender.api import DDR4Target, HostInterface, ProgramBuilder, open_board
from drambender.api.program.instructions import ACT, NOP, PRE, RD, WR


DEFAULT_BDFS = (
    "0000:01:00.0",
    "0000:21:00.0",
    "0000:22:00.0",
    "0000:41:00.0",
    "0000:42:00.0",
    "0000:61:00.0",
)
BDF_RE = re.compile(r"^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:([0-9a-fA-F]{2})\.[0-7]$")
CACHELINES_PER_ROW = 128
WORDS_PER_CACHELINE = 16
COLUMN_STRIDE = 8
ROW_WORDS = CACHELINES_PER_ROW * WORDS_PER_CACHELINE
FABRIC_CYCLE_NS = 6
DEFAULT_DELAY_CYCLES = 1_000_000_000  # Six seconds at the 6 ns fabric cycle.
DEFAULT_ARM_TIMEOUT_SECONDS = 8.0
DEFAULT_CASE_TIMEOUT_SECONDS = 20.0
DEFAULT_SETTLE_SECONDS = 0.100
TARGET = DDR4Target(
    cachelines_per_row=CACHELINES_PER_ROW,
    column_stride=COLUMN_STRIDE,
    words_per_cacheline=WORDS_PER_CACHELINE,
)


@dataclass(frozen=True)
class Case:
    case_id: str
    bdf: str
    active_channel: int
    reset_channel: int
    active_bank: int
    active_row: int
    active_tag: int
    active_sha256: str
    reset_bank: int
    reset_row: int
    reset_tag: int
    reset_sha256: str


def parse_bdf(text: str) -> str:
    match = BDF_RE.fullmatch(text)
    if match is None or int(match.group(1), 16) > 0x1F:
        raise argparse.ArgumentTypeError("PCI BDF must use complete dddd:bb:ss.f form")
    return text.lower()


def positive_float(text: str) -> float:
    try:
        value = float(text)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid positive duration: {text!r}") from exc
    if not np.isfinite(value) or value <= 0:
        raise argparse.ArgumentTypeError("duration must be finite and greater than zero")
    return value


def nonnegative_float(text: str) -> float:
    try:
        value = float(text)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid nonnegative duration: {text!r}") from exc
    if not np.isfinite(value) or value < 0:
        raise argparse.ArgumentTypeError("duration must be finite and nonnegative")
    return value


def positive_int(text: str) -> int:
    try:
        value = int(text, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid positive integer: {text!r}") from exc
    if value <= 0:
        raise argparse.ArgumentTypeError("value must be greater than zero")
    return value


def payload_tag(case_id: str, role: str) -> int:
    digest = hashlib.sha256(f"{case_id}:{role}".encode()).digest()
    return int.from_bytes(digest[:4], "little") or 0x9E3779B9


def lane_words(tag: int) -> np.ndarray:
    value = tag & 0xFFFFFFFF
    words = []
    for lane in range(WORDS_PER_CACHELINE):
        value ^= (value << 13) & 0xFFFFFFFF
        value ^= value >> 17
        value ^= (value << 5) & 0xFFFFFFFF
        words.append((value ^ (lane * 0x45D9F3B)) & 0xFFFFFFFF)
    return np.asarray(words, dtype="<u4")


def expected_payload(tag: int) -> np.ndarray:
    return np.tile(lane_words(tag), CACHELINES_PER_ROW)


def payload_sha256(tag: int) -> str:
    return hashlib.sha256(expected_payload(tag).tobytes()).hexdigest()


def make_cases(bdfs: list[str], directions: tuple[int, ...]) -> list[Case]:
    cases = []
    for bdf_index, bdf in enumerate(bdfs):
        for active_channel in directions:
            reset_channel = 1 - active_channel
            case_id = f"{bdf}-active{active_channel}-reset{reset_channel}"
            active_tag = payload_tag(case_id, "active")
            reset_tag = payload_tag(case_id, "reset-canary")
            cases.append(
                Case(
                    case_id=case_id,
                    bdf=bdf,
                    active_channel=active_channel,
                    reset_channel=reset_channel,
                    active_bank=(2 * bdf_index + active_channel) % 16,
                    active_row=1024 + 8 * bdf_index + active_channel,
                    active_tag=active_tag,
                    active_sha256=payload_sha256(active_tag),
                    reset_bank=(2 * bdf_index + reset_channel + 8) % 16,
                    reset_row=2048 + 8 * bdf_index + reset_channel,
                    reset_tag=reset_tag,
                    reset_sha256=payload_sha256(reset_tag),
                )
            )
    return cases


def stage_pattern(program: ProgramBuilder, words: np.ndarray) -> None:
    for lane, word in enumerate(words):
        program.LI(int(word), "PATTERN_REG")
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


def append_write_read(program: ProgramBuilder, bank: int, row: int, tag: int) -> None:
    stage_pattern(program, lane_words(tag))
    begin_row(program, bank, row)
    for _ in range(CACHELINES_PER_ROW):
        program.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=True)

    begin_row(program, bank, row)
    for _ in range(CACHELINES_PER_ROW):
        program.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        program.SLEEP(1)
    end_row(program, write=False)


def build_write_read(bank: int, row: int, tag: int):
    program = ProgramBuilder(target=TARGET)
    append_write_read(program, bank, row, tag)
    return program.conclude()


def build_delayed_write_read(bank: int, row: int, tag: int, delay_cycles: int):
    program = ProgramBuilder(target=TARGET)
    # No DRAM access or data production precedes this delay.  Writing after
    # the delay keeps the isolation verdict independent of DRAM retention.
    program.SLEEP(delay_cycles)
    append_write_read(program, bank, row, tag)
    return program.conclude()


def validate_program(program: Any, delay_cycles: int = 0) -> dict[str, int]:
    result = program.dry_run(100_000)
    trace = program.trace_dram_commands(100_000)
    reads = int(result.dram_cmd_counts["RD"])
    writes = int(result.dram_cmd_counts["WR"])
    if reads != CACHELINES_PER_ROW or writes != CACHELINES_PER_ROW:
        raise AssertionError(
            f"expected {CACHELINES_PER_ROW} RD/WR commands, got RD={reads} WR={writes}"
        )
    if int(result.total_cycles) < delay_cycles:
        raise AssertionError(
            f"program ran for {result.total_cycles} cycles, below delay {delay_cycles}"
        )
    first_dram_ns = int(trace.events[0].time_ns) if trace.events else -1
    if delay_cycles and first_dram_ns < delay_cycles * FABRIC_CYCLE_NS:
        raise AssertionError(
            "the first DRAM command occurs before the requested leading delay: "
            f"first_dram_ns={first_dram_ns}, delay_ns={delay_cycles * FABRIC_CYCLE_NS}"
        )
    return {
        "instructions_executed": int(result.instructions_executed),
        "total_cycles": int(result.total_cycles),
        "reads": reads,
        "writes": writes,
        "first_dram_ns": first_dram_ns,
    }


def verify_payload(observed: np.ndarray, tag: int, label: str) -> str:
    expected = expected_payload(tag)
    mismatch = np.flatnonzero(observed != expected)
    if mismatch.size:
        first = int(mismatch[0])
        raise RuntimeError(
            f"{label}: {mismatch.size}/{ROW_WORDS} words mismatched; word {first}: "
            f"expected=0x{int(expected[first]):08x} observed=0x{int(observed[first]):08x}"
        )
    return hashlib.sha256(observed.astype("<u4", copy=False).tobytes()).hexdigest()


def emit(record: dict[str, Any]) -> None:
    print(json.dumps(record, sort_keys=True), flush=True)


def best_effort_reset(board: Any) -> str:
    if board is None:
        return "not-open"
    try:
        board.full_reset()
        return "pass"
    except BaseException as exc:
        return f"fail: {type(exc).__name__}: {exc}"


def active_child(case: Case, delay_cycles: int, receive_timeout: float) -> int:
    board = None
    reset_complete = False
    try:
        board = open_board(
            TARGET,
            pci_bdf=case.bdf,
            xdma_channel=case.active_channel,
            host_interface=HostInterface.XDMA,
        )
        board.full_reset()
        program = build_delayed_write_read(
            case.active_bank, case.active_row, case.active_tag, delay_cycles
        )
        observed = np.empty(ROW_WORDS, dtype=np.uint32)
        execute_started_ns = time.monotonic_ns()
        board.execute(program)
        execute_sent_ns = time.monotonic_ns()
        emit(
            {
                "event": "armed",
                "role": "active",
                "case_id": case.case_id,
                "execute_started_monotonic_ns": execute_started_ns,
                "execute_sent_monotonic_ns": execute_sent_ns,
            }
        )
        received_bytes = board.receive_into(observed, timeout=receive_timeout)
        board.synchronize()
        payload_complete_ns = time.monotonic_ns()
        digest = verify_payload(observed, case.active_tag, "active payload")
        if digest != case.active_sha256:
            raise RuntimeError(
                f"active payload hash mismatch: expected {case.active_sha256}, got {digest}"
            )
        board.full_reset()
        reset_complete = True
        emit(
            {
                "event": "pass",
                "role": "active",
                "case_id": case.case_id,
                "payload_sha256": digest,
                "received_bytes": int(received_bytes),
                "payload_complete_monotonic_ns": payload_complete_ns,
                "final_full_reset": "pass",
            }
        )
        return 0
    except BaseException as exc:
        cleanup = "already-complete" if reset_complete else best_effort_reset(board)
        emit(
            {
                "event": "fail",
                "role": "active",
                "case_id": case.case_id,
                "error": f"{type(exc).__name__}: {exc}",
                "cleanup_full_reset": cleanup,
            }
        )
        return 130 if isinstance(exc, KeyboardInterrupt) else 2
    finally:
        if board is not None:
            try:
                board.close()
            except BaseException:
                pass


def read_child_command(timeout: float) -> str:
    ready, _, _ = select.select([sys.stdin], [], [], timeout)
    if not ready:
        raise TimeoutError(f"no parent command within {timeout:.3f}s")
    command = sys.stdin.readline().strip()
    if command not in ("reset", "abort"):
        raise RuntimeError(f"invalid or missing parent command: {command!r}")
    return command


def resetter_child(case: Case, command_timeout: float) -> int:
    board = None
    test_reset_complete = False
    try:
        board = open_board(
            TARGET,
            pci_bdf=case.bdf,
            xdma_channel=case.reset_channel,
            host_interface=HostInterface.XDMA,
        )
        board.full_reset()
        emit(
            {
                "event": "ready",
                "role": "resetter",
                "case_id": case.case_id,
                "ready_monotonic_ns": time.monotonic_ns(),
            }
        )
        command = read_child_command(command_timeout)
        if command == "abort":
            board.full_reset()
            test_reset_complete = True
            emit({"event": "aborted", "role": "resetter", "case_id": case.case_id})
            return 130

        reset_started_ns = time.monotonic_ns()
        board.full_reset()
        reset_completed_ns = time.monotonic_ns()
        test_reset_complete = True

        observed = np.empty(ROW_WORDS, dtype=np.uint32)
        board.execute(build_write_read(case.reset_bank, case.reset_row, case.reset_tag))
        received_bytes = board.receive_into(observed, timeout=command_timeout)
        board.synchronize()
        digest = verify_payload(observed, case.reset_tag, "resetter canary")
        if digest != case.reset_sha256:
            raise RuntimeError(
                f"resetter canary hash mismatch: expected {case.reset_sha256}, got {digest}"
            )
        emit(
            {
                "event": "pass",
                "role": "resetter",
                "case_id": case.case_id,
                "reset_started_monotonic_ns": reset_started_ns,
                "reset_completed_monotonic_ns": reset_completed_ns,
                "reset_elapsed_seconds": (reset_completed_ns - reset_started_ns) / 1e9,
                "canary_sha256": digest,
                "received_bytes": int(received_bytes),
            }
        )
        return 0
    except BaseException as exc:
        cleanup = "already-complete" if test_reset_complete else best_effort_reset(board)
        emit(
            {
                "event": "fail",
                "role": "resetter",
                "case_id": case.case_id,
                "error": f"{type(exc).__name__}: {exc}",
                "cleanup_full_reset": cleanup,
            }
        )
        return 130 if isinstance(exc, KeyboardInterrupt) else 2
    finally:
        if board is not None:
            try:
                board.close()
            except BaseException:
                pass


def start_child(
    role: str,
    case: Case,
    delay_cycles: int,
    timeout: float,
) -> subprocess.Popen[str]:
    command = [
        sys.executable,
        str(Path(__file__).resolve()),
        "--child-role",
        role,
        "--child-case-json",
        json.dumps(asdict(case), sort_keys=True),
        "--delay-cycles",
        str(delay_cycles),
        "--case-timeout-seconds",
        str(timeout),
    ]
    return subprocess.Popen(
        command,
        stdin=subprocess.PIPE if role == "resetter" else subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )


def wait_for_event(
    process: subprocess.Popen[str], expected_event: str, timeout: float
) -> dict[str, Any]:
    assert process.stdout is not None
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        remaining = max(0.0, deadline - time.monotonic())
        readable, _, _ = select.select([process.stdout], [], [], min(0.1, remaining))
        if readable:
            line = process.stdout.readline()
            if not line:
                break
            try:
                record = json.loads(line)
            except json.JSONDecodeError as exc:
                raise RuntimeError(f"child emitted invalid JSON: {line.rstrip()!r}") from exc
            if record.get("event") == "fail":
                raise RuntimeError(f"child reported failure: {json.dumps(record, sort_keys=True)}")
            if record.get("event") == expected_event:
                return record
            raise RuntimeError(
                f"expected child event {expected_event!r}, got {record.get('event')!r}"
            )
        if process.poll() is not None:
            break
    return_code = process.poll()
    stderr = "<child still running>"
    if return_code is not None and process.stderr is not None:
        stderr = process.stderr.read()
    raise RuntimeError(
        f"child did not emit {expected_event!r} within {timeout:.3f}s; "
        f"rc={return_code} stderr={stderr}"
    )


def send_command(process: subprocess.Popen[str], command: str) -> None:
    if process.stdin is None:
        raise RuntimeError("child command pipe is unavailable")
    try:
        process.stdin.write(command + "\n")
        process.stdin.flush()
        process.stdin.close()
    except BrokenPipeError as exc:
        raise RuntimeError("child command pipe closed early") from exc
    finally:
        process.stdin = None


def finish_child(
    process: subprocess.Popen[str], timeout: float
) -> tuple[int, list[dict[str, Any]], str]:
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        # Leave the process alive for cleanup_children(), which first requests
        # SIGINT/abort so the child can full-reset its endpoint before a forced
        # kill becomes necessary.
        raise RuntimeError(
            f"child timed out after {timeout:.3f}s; "
            f"partial_stdout={exc.output!r} partial_stderr={exc.stderr!r}"
        ) from exc
    records = []
    for line in stdout.splitlines():
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"child emitted invalid JSON: {line!r}") from exc
    return process.returncode, records, stderr


def child_pass_record(records: list[dict[str, Any]], role: str) -> dict[str, Any]:
    matches = [record for record in records if record.get("event") == "pass"]
    if len(matches) != 1:
        raise RuntimeError(
            f"{role} child emitted {len(matches)} pass records: "
            f"{json.dumps(records, sort_keys=True)}"
        )
    return matches[0]


def cleanup_children(
    children: list[tuple[str, subprocess.Popen[str] | None]], timeout: float = 3.0
) -> list[str]:
    """Request recoverable shutdown, then kill and reap any stuck children."""
    errors = []
    for role, process in children:
        if process is None or process.poll() is not None:
            continue
        try:
            if role == "resetter" and process.stdin is not None:
                send_command(process, "abort")
            else:
                process.send_signal(signal.SIGINT)
        except BaseException as exc:
            errors.append(f"{role} graceful-stop failed: {type(exc).__name__}: {exc}")

    deadline = time.monotonic() + timeout
    for role, process in children:
        if process is None or process.poll() is not None:
            continue
        try:
            process.wait(timeout=max(0.0, deadline - time.monotonic()))
        except subprocess.TimeoutExpired:
            try:
                process.kill()
                process.wait(timeout=2.0)
            except BaseException as exc:
                errors.append(f"{role} forced-stop failed: {type(exc).__name__}: {exc}")
    return errors


def validate_overlap(
    armed: dict[str, Any], resetter: dict[str, Any], active: dict[str, Any]
) -> dict[str, float]:
    armed_ns = int(armed["execute_sent_monotonic_ns"])
    reset_started_ns = int(resetter["reset_started_monotonic_ns"])
    reset_completed_ns = int(resetter["reset_completed_monotonic_ns"])
    payload_complete_ns = int(active["payload_complete_monotonic_ns"])
    if not (armed_ns <= reset_started_ns < reset_completed_ns <= payload_complete_ns):
        raise RuntimeError(
            "sibling reset was not wholly contained in the active readback session: "
            f"armed={armed_ns}, reset=[{reset_started_ns}, {reset_completed_ns}], "
            f"payload_complete={payload_complete_ns}"
        )
    return {
        "reset_started_after_arm_seconds": (reset_started_ns - armed_ns) / 1e9,
        "reset_elapsed_seconds": (reset_completed_ns - reset_started_ns) / 1e9,
        "payload_completed_after_reset_seconds":
            (payload_complete_ns - reset_completed_ns) / 1e9,
    }


def run_case(
    case: Case,
    delay_cycles: int,
    arm_timeout: float,
    case_timeout: float,
    settle_seconds: float,
) -> dict[str, Any]:
    started = time.monotonic()
    record: dict[str, Any] = {"type": "case", **asdict(case), "status": "running"}
    resetter: subprocess.Popen[str] | None = None
    active: subprocess.Popen[str] | None = None
    try:
        resetter = start_child("resetter", case, delay_cycles, case_timeout)
        ready = wait_for_event(resetter, "ready", arm_timeout)
        active = start_child("active", case, delay_cycles, case_timeout)
        armed = wait_for_event(active, "armed", arm_timeout)
        time.sleep(settle_seconds)
        send_command(resetter, "reset")

        reset_rc, reset_records, reset_stderr = finish_child(resetter, case_timeout)
        if reset_rc != 0:
            raise RuntimeError(
                f"resetter child exited {reset_rc}; records={reset_records} "
                f"stderr={reset_stderr!r}"
            )
        reset_pass = child_pass_record(reset_records, "resetter")

        active_rc, active_records, active_stderr = finish_child(active, case_timeout)
        if active_rc != 0:
            raise RuntimeError(
                f"active child exited {active_rc}; records={active_records} "
                f"stderr={active_stderr!r}"
            )
        active_pass = child_pass_record(active_records, "active")

        if reset_pass.get("canary_sha256") != case.reset_sha256:
            raise RuntimeError("resetter child returned the wrong canary hash")
        if active_pass.get("payload_sha256") != case.active_sha256:
            raise RuntimeError("active child returned the wrong payload hash")
        overlap = validate_overlap(armed, reset_pass, active_pass)
        record.update(
            status="pass",
            resetter_ready=ready,
            active_armed=armed,
            resetter_result=reset_pass,
            active_result=active_pass,
            overlap=overlap,
        )
    except KeyboardInterrupt:
        cleanup_children([("resetter", resetter), ("active", active)])
        raise
    except BaseException as exc:
        record.update(status="fail", error=f"{type(exc).__name__}: {exc}")
        cleanup_errors = cleanup_children([("resetter", resetter), ("active", active)])
        if cleanup_errors:
            record["cleanup_errors"] = cleanup_errors
    record["elapsed_seconds"] = time.monotonic() - started
    return record


def command_output(args: list[str]) -> str:
    try:
        return subprocess.check_output(
            args,
            cwd=Path(__file__).resolve().parents[2],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def optional_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except OSError as exc:
        return f"unavailable: {type(exc).__name__}: {exc}"


def provenance(cases: list[Case], delay_cycles: int) -> dict[str, Any]:
    script_path = Path(__file__).resolve()
    extension_path = Path(drambender._core.__file__).resolve()
    return {
        "type": "environment",
        "schema": "drambender-sibling-reset-isolation-v1",
        "started_utc": datetime.now(timezone.utc).isoformat(),
        "hostname": socket.gethostname(),
        "kernel": os.uname().release,
        "python": sys.version,
        "argv": sys.argv,
        "git_head": command_output(["git", "rev-parse", "HEAD"]),
        "git_status": command_output(["git", "status", "--short"]).splitlines(),
        "script": str(script_path),
        "script_sha256": hashlib.sha256(script_path.read_bytes()).hexdigest(),
        "extension": str(extension_path),
        "extension_sha256": hashlib.sha256(extension_path.read_bytes()).hexdigest(),
        "driver_srcversion": optional_text(
            Path("/sys/module/drambender_xdma/srcversion")
        ),
        "delay_cycles": delay_cycles,
        "delay_seconds_at_6ns": delay_cycles * FABRIC_CYCLE_NS / 1e9,
        "target": {
            "cachelines_per_row": CACHELINES_PER_ROW,
            "words_per_cacheline": WORDS_PER_CACHELINE,
            "column_stride": COLUMN_STRIDE,
        },
        "cases": [asdict(case) for case in cases],
    }


def run_parent(
    cases: list[Case],
    output: Path,
    delay_cycles: int,
    arm_timeout: float,
    case_timeout: float,
    settle_seconds: float,
) -> int:
    failures = 0
    with output.open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(provenance(cases, delay_cycles), sort_keys=True) + "\n")
        stream.flush()
        for case in cases:
            record = run_case(
                case, delay_cycles, arm_timeout, case_timeout, settle_seconds
            )
            if record["status"] != "pass":
                failures += 1
            stream.write(json.dumps(record, sort_keys=True) + "\n")
            stream.flush()
            print(
                f"{record['status'].upper()} {case.bdf}: active ch{case.active_channel}, "
                f"full_reset ch{case.reset_channel} ({record['elapsed_seconds']:.3f}s)",
                flush=True,
            )
        summary = {
            "type": "summary",
            "cases": len(cases),
            "failures": failures,
            "status": "pass" if failures == 0 else "fail",
        }
        stream.write(json.dumps(summary, sort_keys=True) + "\n")
        stream.flush()
    return 0 if failures == 0 else 1


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--bdf",
        action="append",
        type=parse_bdf,
        help="U200 PCI BDF; repeat for multiple cards (default: all six FPGA99 BDFs).",
    )
    parser.add_argument(
        "--direction",
        choices=("both", "0", "1"),
        default="both",
        help="Active channel direction; the other channel is reset (default: both).",
    )
    parser.add_argument("--delay-cycles", type=positive_int, default=DEFAULT_DELAY_CYCLES)
    parser.add_argument(
        "--arm-timeout-seconds",
        type=positive_float,
        default=DEFAULT_ARM_TIMEOUT_SECONDS,
    )
    parser.add_argument(
        "--case-timeout-seconds",
        type=positive_float,
        default=DEFAULT_CASE_TIMEOUT_SECONDS,
    )
    parser.add_argument(
        "--settle-seconds",
        type=nonnegative_float,
        default=DEFAULT_SETTLE_SECONDS,
    )
    parser.add_argument("--output", type=Path)
    parser.add_argument("--dry-run-only", action="store_true")
    parser.add_argument("--child-role", choices=("active", "resetter"), help=argparse.SUPPRESS)
    parser.add_argument("--child-case-json", help=argparse.SUPPRESS)
    args = parser.parse_args(argv)
    bdfs = args.bdf or list(DEFAULT_BDFS)
    if len(set(bdfs)) != len(bdfs):
        parser.error("BDFs must be unique")
    args.bdf = bdfs
    if args.child_role and not args.child_case_json:
        parser.error("--child-role requires --child-case-json")
    delay_seconds = args.delay_cycles * FABRIC_CYCLE_NS / 1e9
    if args.case_timeout_seconds <= delay_seconds:
        parser.error(
            "--case-timeout-seconds must exceed the programmed delay "
            f"({delay_seconds:.6f}s)"
        )
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.child_role:
        case = Case(**json.loads(args.child_case_json))
        if args.child_role == "active":
            return active_child(case, args.delay_cycles, args.case_timeout_seconds)
        return resetter_child(case, args.case_timeout_seconds)

    directions = (0, 1) if args.direction == "both" else (int(args.direction),)
    cases = make_cases(args.bdf, directions)
    active_validation = validate_program(
        build_delayed_write_read(
            cases[0].active_bank,
            cases[0].active_row,
            cases[0].active_tag,
            args.delay_cycles,
        ),
        args.delay_cycles,
    )
    canary_validation = validate_program(
        build_write_read(cases[0].reset_bank, cases[0].reset_row, cases[0].reset_tag)
    )
    if args.dry_run_only:
        print(
            json.dumps(
                {
                    "status": "pass",
                    "cases": len(cases),
                    "active_program": active_validation,
                    "resetter_canary": canary_validation,
                },
                sort_keys=True,
            )
        )
        return 0

    output = args.output or Path(
        f"sibling-reset-isolation-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.jsonl"
    )
    return run_parent(
        cases,
        output,
        args.delay_cycles,
        args.arm_timeout_seconds,
        args.case_timeout_seconds,
        args.settle_seconds,
    )


if __name__ == "__main__":
    raise SystemExit(main())
