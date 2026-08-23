#!/usr/bin/env python3
"""Run DRAM Bender's host and explicitly selected board qualification profiles."""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import time
from typing import Any, Sequence


REPO_ROOT = Path(__file__).resolve().parents[1]
BOARD_TESTS = REPO_ROOT / "internal_tests" / "board_tests"
DEFAULT_PYTHON = REPO_ROOT / ".venv" / "bin" / "python"
BOARD_BUILD_DIR = REPO_ROOT / "build" / "internal-board-tests"
BENCHMARK_SCHEMA = "drambender.u200-readback-benchmark"
TOPOLOGY_FORMAT = "drambender.internal-test-topology"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
BDF_RE = re.compile(
    r"^(?P<domain>[0-9a-fA-F]{4}):(?P<bus>[0-9a-fA-F]{2}):"
    r"(?P<slot>[0-9a-fA-F]{2})\.(?P<function>[0-7])$"
)

BOARD_PROFILES = (
    "u200-smoke",
    "u200-correctness",
    "u200-recovery",
    "u200-fuzz",
    "u200-soak",
    "hbm2-smoke",
    "multiboard-correctness",
    "multiboard-recovery",
    "u200-performance",
)


@dataclass(frozen=True)
class Case:
    name: str
    command: tuple[str, ...]
    gate: bool = False


@dataclass
class CaseResult:
    name: str
    status: str
    command: list[str]
    elapsed_seconds: float
    returncode: int | None


@dataclass(frozen=True)
class Topology:
    endpoints: tuple[tuple[str, int], ...]
    expected_board_count: int
    expected_endpoint_count: int


class Console:
    def __init__(self) -> None:
        self.color = sys.stdout.isatty() and "NO_COLOR" not in os.environ

    def paint(self, code: str, text: str) -> str:
        return f"\033[{code}m{text}\033[0m" if self.color else text

    def heading(self, title: str, detail: str | None = None) -> None:
        print()
        print(self.paint("1;36", f"DRAM Bender internal tests: {title}"))
        if detail:
            print(self.paint("2", detail))
        print(self.paint("2", "─" * 72))

    def start(self, index: int, total: int, case: Case) -> None:
        print()
        print(self.paint("1", f"[{index}/{total}] {case.name}"))
        print(self.paint("2", f"$ {shlex.join(case.command)}"), flush=True)

    def result(self, result: CaseResult) -> None:
        if result.status == "pass":
            label = self.paint("1;32", "PASS")
        elif result.status == "planned":
            label = self.paint("1;33", "PLAN")
        elif result.status == "interrupted":
            label = self.paint("1;33", "INTERRUPTED")
        else:
            label = self.paint("1;31", "FAIL")
        print(f"{label}  {result.name}  ({result.elapsed_seconds:.2f}s)", flush=True)

    def summary(self, results: Sequence[CaseResult], elapsed: float) -> None:
        counts = {
            status: sum(result.status == status for result in results)
            for status in ("pass", "fail", "interrupted", "planned")
        }
        print()
        print(self.paint("2", "─" * 72))
        print(self.paint("1", "Summary"))
        parts = [f"{len(results)} case(s)", f"{elapsed:.2f}s"]
        for status in ("pass", "fail", "interrupted", "planned"):
            if counts[status]:
                parts.append(f"{counts[status]} {status}")
        print("  " + " | ".join(parts))


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def normalize_bdf(value: str) -> str:
    match = BDF_RE.fullmatch(value)
    if not match:
        raise argparse.ArgumentTypeError("PCI BDF must use complete dddd:bb:ss.f form")
    slot = int(match.group("slot"), 16)
    if slot > 0x1F:
        raise argparse.ArgumentTypeError("PCI slot must be in the range 00..1f")
    return value.lower()


def parse_endpoint(value: str) -> tuple[str, int]:
    try:
        bdf_text, channel_text = value.rsplit("/", 1)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            "endpoint must use dddd:bb:ss.f/CHANNEL form"
        ) from exc
    bdf = normalize_bdf(bdf_text)
    try:
        channel = int(channel_text)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("endpoint channel must be 0 or 1") from exc
    if channel not in (0, 1):
        raise argparse.ArgumentTypeError("endpoint channel must be 0 or 1")
    return bdf, channel


def endpoint_text(endpoint: tuple[str, int]) -> str:
    return f"{endpoint[0]}/{endpoint[1]}"


def positive_count(value: Any, field: str) -> int:
    if type(value) is not int:
        raise ValueError(f"{field} must be a positive integer")
    if value < 1:
        raise ValueError(f"{field} must be a positive integer")
    return value


def topology_from_file(path: Path) -> Topology:
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read topology {path}: {exc}") from exc
    if not isinstance(document, dict):
        raise ValueError("topology must be a JSON object")
    allowed = {
        "format",
        "expected_board_count",
        "expected_endpoint_count",
        "endpoints",
    }
    unknown = sorted(set(document) - allowed)
    if unknown:
        raise ValueError("unknown topology field(s): " + ", ".join(unknown))
    if document.get("format") != TOPOLOGY_FORMAT:
        raise ValueError(f"topology format must be {TOPOLOGY_FORMAT!r}")
    expected_boards = positive_count(
        document.get("expected_board_count"), "expected_board_count"
    )
    expected_endpoints = positive_count(
        document.get("expected_endpoint_count"), "expected_endpoint_count"
    )
    entries = document.get("endpoints")
    if not isinstance(entries, list) or not entries:
        raise ValueError("topology endpoints must be a non-empty list")
    endpoints: list[tuple[str, int]] = []
    for index, entry in enumerate(entries):
        try:
            if not isinstance(entry, dict) or set(entry) != {
                "pci_bdf",
                "xdma_channel",
            }:
                raise ValueError(
                    "entry must contain only pci_bdf and xdma_channel"
                )
            if not isinstance(entry["pci_bdf"], str):
                raise ValueError("pci_bdf must be a string")
            if type(entry["xdma_channel"]) is not int:
                raise ValueError("xdma_channel must be an integer")
            endpoint = (
                normalize_bdf(entry["pci_bdf"]),
                entry["xdma_channel"],
            )
            if endpoint[1] not in (0, 1):
                raise ValueError("xdma_channel must be 0 or 1")
        except (KeyError, TypeError, ValueError, argparse.ArgumentTypeError) as exc:
            raise ValueError(f"invalid topology endpoint {index}: {exc}") from exc
        endpoints.append(endpoint)
    return validate_topology(endpoints, expected_boards, expected_endpoints)


def validate_topology(
    endpoints: Sequence[tuple[str, int]],
    expected_boards: int,
    expected_endpoints: int,
) -> Topology:
    if len(set(endpoints)) != len(endpoints):
        raise ValueError("each endpoint must be unique")
    if len(endpoints) > 255:
        raise ValueError("at most 255 endpoints are supported")
    actual_boards = len({endpoint[0] for endpoint in endpoints})
    if actual_boards != expected_boards:
        raise ValueError(
            f"topology declares {expected_boards} board(s), but contains {actual_boards}"
        )
    if len(endpoints) != expected_endpoints:
        raise ValueError(
            f"topology declares {expected_endpoints} endpoint(s), but contains "
            f"{len(endpoints)}"
        )
    return Topology(tuple(endpoints), expected_boards, expected_endpoints)


def collect_topology(args: argparse.Namespace) -> Topology:
    if args.topology:
        if args.endpoint:
            raise ValueError("use either --topology or repeated --endpoint, not both")
        if args.expected_board_count is not None or args.expected_endpoint_count is not None:
            raise ValueError(
                "expected counts belong in the topology file when --topology is used"
            )
        return topology_from_file(args.topology)
    if not args.endpoint:
        raise ValueError(
            "this profile requires --topology FILE or repeated --endpoint values"
        )
    if args.expected_board_count is None or args.expected_endpoint_count is None:
        raise ValueError(
            "repeated --endpoint values require --expected-board-count and "
            "--expected-endpoint-count"
        )
    return validate_topology(
        args.endpoint,
        args.expected_board_count,
        args.expected_endpoint_count,
    )


def ensure_complete_dual(endpoints: Sequence[tuple[str, int]]) -> None:
    channels: dict[str, set[int]] = {}
    for bdf, channel in endpoints:
        channels.setdefault(bdf, set()).add(channel)
    incomplete = sorted(bdf for bdf, values in channels.items() if values != {0, 1})
    if incomplete:
        raise ValueError(
            "profile requires channels 0 and 1 for every BDF; incomplete: "
            + ", ".join(incomplete)
        )


def python_case(name: str, python: Path, script: str, *arguments: str) -> Case:
    return Case(name, (str(python), str(BOARD_TESTS / script), *arguments))


def cpp_case(name: str, binary_dir: Path, binary: str, *arguments: str) -> Case:
    return Case(name, (str(binary_dir / binary), *arguments))


def includes_python(args: argparse.Namespace) -> bool:
    return (args.test_language or "both") in ("python", "both")


def includes_cpp(args: argparse.Namespace) -> bool:
    return (args.test_language or "both") in ("cpp", "both")


def endpoint_args(endpoints: Sequence[tuple[str, int]]) -> list[str]:
    result: list[str] = []
    for endpoint in endpoints:
        result.extend(("--endpoint", endpoint_text(endpoint)))
    return result


def bdf_args(endpoints: Sequence[tuple[str, int]]) -> list[str]:
    result: list[str] = []
    for bdf in dict.fromkeys(endpoint[0] for endpoint in endpoints):
        result.extend(("--bdf", bdf))
    return result


def host_cases(python: Path) -> list[Case]:
    build_dir = REPO_ROOT / "build" / "internal-tests"
    return [
        Case(
            "configure host-only test build",
            (
                "cmake",
                "-S",
                str(REPO_ROOT),
                "-B",
                str(build_dir),
                "-DBUILD_TESTING=ON",
                "-DCMAKE_BUILD_TYPE=Debug",
                f"-DPython_EXECUTABLE={python}",
                "-DDRAMBENDER_BUILD_PYTHON=ON",
                f"-DDRAMBENDER_PYTHON_PACKAGE_DIR={REPO_ROOT / 'python' / 'drambender'}",
                "-DDRAMBENDER_BUILD_BOARD_TESTS=OFF",
                "-DDRAMBENDER_BUILD_BOARD_BENCHMARKS=OFF",
            ),
            gate=True,
        ),
        Case(
            "build host-only tests",
            ("cmake", "--build", str(build_dir)),
            gate=True,
        ),
        Case(
            "run host-only tests",
            (
                "cmake",
                "-E",
                "chdir",
                str(build_dir),
                "ctest",
                "--output-on-failure",
                "-L",
                "host",
            ),
        ),
    ]


def board_build_targets(args: argparse.Namespace) -> list[str]:
    targets = {"drambender_core"}
    if includes_cpp(args):
        if args.profile in ("u200-smoke", "u200-correctness"):
            targets.add("drambender_rw_test")
        if args.profile in ("u200-smoke", "u200-recovery"):
            targets.add("drambender_full_reset_test")
        if args.profile == "hbm2-smoke":
            targets.add("drambender_hbm2_rw_test")
    if args.profile == "u200-performance" and (
        args.benchmark_language or "both"
    ) in ("cpp", "both"):
        targets.add("drambender_u200_readback_benchmark")
    return sorted(targets)


def board_build_cases(args: argparse.Namespace) -> list[Case]:
    return [
        Case(
            "configure dedicated Release board-qualification build",
            (
                "cmake",
                "-S",
                str(REPO_ROOT),
                "-B",
                str(BOARD_BUILD_DIR),
                "-DBUILD_TESTING=ON",
                "-DCMAKE_BUILD_TYPE=Release",
                f"-DPython_EXECUTABLE={args.python}",
                "-DDRAMBENDER_BUILD_PYTHON=ON",
                f"-DDRAMBENDER_PYTHON_PACKAGE_DIR={REPO_ROOT / 'python' / 'drambender'}",
                "-DDRAMBENDER_BUILD_BOARD_TESTS=ON",
                "-DDRAMBENDER_BUILD_BOARD_BENCHMARKS=ON",
            ),
            gate=True,
        ),
        Case(
            "build current Release qualification targets",
            (
                "cmake",
                "--build",
                str(BOARD_BUILD_DIR),
                "--config",
                "Release",
                "--target",
                *board_build_targets(args),
                "--parallel",
            ),
            gate=True,
        ),
    ]


def require_single_board(args: argparse.Namespace) -> tuple[str, int]:
    if args.pci_bdf is None:
        raise ValueError(f"{args.profile} requires --pci-bdf")
    return args.pci_bdf, args.xdma_channel


def validate_board_options(args: argparse.Namespace) -> None:
    multi = args.profile.startswith("multiboard-")
    if multi:
        if args.pci_bdf is not None or args.xdma_channel is not None or args.board is not None:
            raise ValueError(
                "multiboard profiles use --endpoint/--topology, not --pci-bdf, "
                "--xdma-channel, or --board"
            )
    else:
        if (
            args.endpoint
            or args.topology
            or args.expected_board_count is not None
            or args.expected_endpoint_count is not None
        ):
            raise ValueError(
                "single-board profiles do not accept multiboard topology selectors"
            )
        if args.pci_bdf is None:
            raise ValueError(f"{args.profile} requires --pci-bdf")
        if args.xdma_channel is None:
            args.xdma_channel = 0

    if args.profile == "hbm2-smoke":
        if args.board is None:
            raise ValueError("hbm2-smoke requires --board u50|u55c")
    elif args.board is not None:
        raise ValueError("--board is only valid with hbm2-smoke")

    functional_language_profiles = {
        "u200-smoke",
        "u200-correctness",
        "u200-recovery",
        "hbm2-smoke",
    }
    if args.profile not in functional_language_profiles and args.test_language is not None:
        raise ValueError("--test-language is not used by this profile")

    if args.profile == "u200-correctness":
        args.rw_rows = 65536 if args.rw_rows is None else args.rw_rows
        if not 1 <= args.rw_rows <= 65536:
            raise ValueError("--rw-rows must be in the range 1..65536")
    elif args.rw_rows is not None:
        raise ValueError("--rw-rows is only valid with u200-correctness")

    if args.profile == "multiboard-correctness":
        args.multi_iterations = 25 if args.multi_iterations is None else args.multi_iterations
        args.timeout_seconds = 120.0 if args.timeout_seconds is None else args.timeout_seconds
        if not 1 <= args.multi_iterations <= 0x1000000:
            raise ValueError("--multi-iterations must be in the range 1..16777216")
        if args.timeout_seconds <= 0:
            raise ValueError("--timeout-seconds must be positive")
    elif args.multi_iterations is not None or args.timeout_seconds is not None:
        raise ValueError(
            "--multi-iterations and --timeout-seconds are only valid with "
            "multiboard-correctness"
        )

    if args.profile in ("u200-fuzz", "u200-soak"):
        seed = 0x44524631 if args.fuzz_seed is None else int(args.fuzz_seed, 0)
        if not 0 <= seed <= 0xFFFFFFFFFFFFFFFF:
            raise ValueError("--fuzz-seed must fit in an unsigned 64-bit integer")
        args.fuzz_seed = f"0x{seed:x}"
    elif args.fuzz_seed is not None:
        raise ValueError("--fuzz-seed is only valid with u200-fuzz or u200-soak")

    performance_fields = (
        "benchmark_language",
        "stack_label",
        "driver_label",
        "bitstream_label",
        "bitstream_file",
        "warmups",
        "benchmark_iterations",
    )
    if args.profile == "u200-performance":
        args.benchmark_language = args.benchmark_language or "both"
        args.warmups = 5 if args.warmups is None else args.warmups
        args.benchmark_iterations = (
            100 if args.benchmark_iterations is None else args.benchmark_iterations
        )
        if args.warmups < 0:
            raise ValueError("--warmups cannot be negative")
        if args.benchmark_iterations < 1:
            raise ValueError("--benchmark-iterations must be positive")
    elif any(getattr(args, field) is not None for field in performance_fields):
        raise ValueError("benchmark provenance and controls are only valid with u200-performance")

    if args.require_complete_dual and not multi:
        raise ValueError("--require-complete-dual is only valid with multiboard profiles")


def board_cases(args: argparse.Namespace, artifact_dir: Path) -> list[Case]:
    python = args.python
    profile = args.profile

    if profile.startswith("multiboard-"):
        topology = collect_topology(args)
        endpoints = topology.endpoints
        if args.require_complete_dual or profile == "multiboard-recovery":
            ensure_complete_dual(endpoints)
        if profile == "multiboard-correctness":
            arguments = endpoint_args(endpoints) + [
                "--iterations",
                str(args.multi_iterations),
                "--timeout-seconds",
                str(args.timeout_seconds),
            ]
            if args.require_complete_dual:
                arguments.append("--require-complete-dual")
            return [
                python_case(
                    "concurrent endpoint read/write integrity",
                    python,
                    "multi_endpoint_test.py",
                    *arguments,
                )
            ]
        return [
            python_case(
                "SIGINT, SIGKILL, and fresh-process recovery",
                python,
                "multi_endpoint_interrupt_test.py",
                *endpoint_args(endpoints),
                "--output",
                str(artifact_dir / "multi-endpoint-interrupt.jsonl"),
            ),
            python_case(
                "sibling-channel full-reset isolation",
                python,
                "sibling_reset_isolation_test.py",
                *bdf_args(endpoints),
                "--output",
                str(artifact_dir / "sibling-reset-isolation.jsonl"),
            ),
        ]

    bdf, channel = require_single_board(args)
    board_args = ("--pci-bdf", bdf, "--xdma-channel", str(channel))
    if profile == "u200-smoke":
        cases = []
        if includes_cpp(args):
            cases.append(
                cpp_case(
                    "small DDR4 read/write integrity (C++)",
                    BOARD_BUILD_DIR,
                    "drambender_rw_test",
                    *board_args,
                    "--num-rows",
                    "8",
                )
            )
        if includes_python(args):
            cases.append(
                python_case(
                    "small DDR4 read/write integrity (Python)",
                    python,
                    "rw_test.py",
                    *board_args,
                    "--num-rows",
                    "8",
                )
            )
        if includes_cpp(args):
            cases.append(
                cpp_case(
                    "full-reset recovery smoke test (C++)",
                    BOARD_BUILD_DIR,
                    "drambender_full_reset_test",
                    *board_args,
                )
            )
        if includes_python(args):
            cases.append(
                python_case(
                    "full-reset recovery smoke test (Python)",
                    python,
                    "full_reset_test.py",
                    *board_args,
                )
            )
        return cases
    if profile == "u200-correctness":
        cases = []
        if includes_cpp(args):
            cases.append(
                cpp_case(
                    "DDR4 read/write integrity sweep (C++)",
                    BOARD_BUILD_DIR,
                    "drambender_rw_test",
                    *board_args,
                    "--num-rows",
                    str(args.rw_rows),
                )
            )
        if includes_python(args):
            cases.extend(
                (
                    python_case(
                        "DDR4 read/write integrity sweep (Python)",
                        python,
                        "rw_test.py",
                        *board_args,
                        "--num-rows",
                        str(args.rw_rows),
                    ),
                    python_case(
                        "VM-to-hardware timing report (Python, non-gating)",
                        python,
                        "vm_verify.py",
                        *board_args,
                    ),
                )
            )
        return cases
    if profile == "u200-recovery":
        cases = []
        if includes_cpp(args):
            cases.append(
                cpp_case(
                    "full-reset cancellation and clean reuse (C++)",
                    BOARD_BUILD_DIR,
                    "drambender_full_reset_test",
                    *board_args,
                )
            )
        if includes_python(args):
            cases.append(
                python_case(
                    "full-reset cancellation and clean reuse (Python)",
                    python,
                    "full_reset_test.py",
                    *board_args,
                )
            )
        cases.append(
            python_case(
                "SIGINT, SIGKILL, and fresh-process recovery",
                python,
                "multi_endpoint_interrupt_test.py",
                "--endpoint",
                f"{bdf}/{channel}",
                "--output",
                str(artifact_dir / "single-endpoint-interrupt.jsonl"),
            )
        )
        return cases
    if profile in ("u200-fuzz", "u200-soak"):
        fuzz_profile = "standard" if profile == "u200-fuzz" else "soak"
        return [
            python_case(
                f"seeded DDR4 readback {fuzz_profile}",
                python,
                "ddr4_readback_fuzz.py",
                *board_args,
                "--profile",
                fuzz_profile,
                "--seed",
                args.fuzz_seed,
                "--results",
                str(artifact_dir / f"ddr4-readback-{fuzz_profile}.jsonl"),
            )
        ]
    if profile == "hbm2-smoke":
        cases = []
        if includes_cpp(args):
            cases.append(
                cpp_case(
                    f"{args.board.upper()} HBM2 read/write integrity (C++)",
                    BOARD_BUILD_DIR,
                    "drambender_hbm2_rw_test",
                    *board_args,
                    "--board",
                    args.board,
                )
            )
        if includes_python(args):
            cases.append(
                python_case(
                    f"{args.board.upper()} HBM2 read/write integrity (Python)",
                    python,
                    "hbm2_rw_test.py",
                    *board_args,
                    "--board",
                    args.board,
                )
            )
        if args.board == "u55c":
            cases.append(
                python_case(
                    "U55C temperature and power telemetry",
                    python,
                    "power_telemetry_test.py",
                    *board_args,
                )
            )
        return cases
    if profile == "u200-performance":
        missing = [
            name
            for name in ("stack_label", "driver_label", "bitstream_label")
            if getattr(args, name) is None
        ]
        if missing:
            raise ValueError(
                "u200-performance requires "
                + ", ".join("--" + name.replace("_", "-") for name in missing)
            )
        common = [
            *board_args,
            "--stack-label",
            args.stack_label,
            "--driver-label",
            args.driver_label,
            "--bitstream-label",
            args.bitstream_label,
            "--warmups",
            str(args.warmups),
            "--iterations",
            str(args.benchmark_iterations),
        ]
        if args.bitstream_file:
            common.extend(("--bitstream-file", str(args.bitstream_file)))
        cases: list[Case] = []
        benchmark_language = args.benchmark_language or "both"
        if benchmark_language in ("python", "both"):
            cases.append(
                python_case(
                    "current Python API readback performance",
                    python,
                    "u200_readback_benchmark.py",
                    *common,
                    "--output",
                    str(artifact_dir / "current-python.jsonl"),
                )
            )
        if benchmark_language in ("cpp", "both"):
            cases.append(
                Case(
                    "current C++ API readback performance",
                    (
                        str(BOARD_BUILD_DIR / "drambender_u200_readback_benchmark"),
                        *common,
                        "--output",
                        str(artifact_dir / "current-cpp.jsonl"),
                        "--program-manifest",
                        str(artifact_dir / "current-cpp-programs.json"),
                    ),
                )
            )
        return cases
    raise ValueError(f"unsupported board profile: {profile}")


def run_cases(
    title: str,
    detail: str,
    cases: Sequence[Case],
    *,
    dry_run: bool,
    keep_going: bool,
) -> tuple[list[CaseResult], int]:
    console = Console()
    console.heading(title, detail)
    started = time.monotonic()
    command_environment = os.environ.copy()
    source_python = str(REPO_ROOT / "python")
    existing_pythonpath = command_environment.get("PYTHONPATH")
    command_environment["PYTHONPATH"] = (
        source_python + os.pathsep + existing_pythonpath
        if existing_pythonpath
        else source_python
    )
    results: list[CaseResult] = []
    exit_code = 0
    for index, case in enumerate(cases, start=1):
        console.start(index, len(cases), case)
        case_started = time.monotonic()
        if dry_run:
            result = CaseResult(case.name, "planned", list(case.command), 0.0, None)
        else:
            try:
                completed = subprocess.run(
                    case.command,
                    cwd=REPO_ROOT,
                    env=command_environment,
                    check=False,
                )
                status = "pass" if completed.returncode == 0 else "fail"
                result = CaseResult(
                    case.name,
                    status,
                    list(case.command),
                    time.monotonic() - case_started,
                    completed.returncode,
                )
            except OSError as exc:
                print(f"cannot start command: {exc}", file=sys.stderr)
                result = CaseResult(
                    case.name,
                    "fail",
                    list(case.command),
                    time.monotonic() - case_started,
                    127,
                )
            except KeyboardInterrupt:
                result = CaseResult(
                    case.name,
                    "interrupted",
                    list(case.command),
                    time.monotonic() - case_started,
                    130,
                )
        results.append(result)
        console.result(result)
        if result.status == "interrupted":
            exit_code = 130
            break
        if result.status == "fail":
            exit_code = result.returncode or 1
            if case.gate or not keep_going:
                break
    console.summary(results, time.monotonic() - started)
    return results, exit_code


def load_benchmark(path: Path) -> dict[str, Any]:
    try:
        records = [
            json.loads(line)
            for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read benchmark artifact {path}: {exc}") from exc
    if not records:
        raise ValueError(f"benchmark artifact is empty: {path}")
    if any(not isinstance(record, dict) for record in records):
        raise ValueError(f"benchmark artifact contains a non-object record: {path}")
    if any(record.get("schema") != BENCHMARK_SCHEMA for record in records):
        raise ValueError(f"benchmark artifact has an unexpected schema: {path}")
    run_ids = {record.get("run_id") for record in records}
    if len(run_ids) != 1 or None in run_ids:
        raise ValueError(f"benchmark artifact does not contain one consistent run_id: {path}")

    starts = [record for record in records if record.get("record_type") == "run_start"]
    ends = [record for record in records if record.get("record_type") == "run_end"]
    if (
        len(starts) != 1
        or len(ends) != 1
        or records[0] is not starts[0]
        or records[-1] is not ends[0]
        or ends[0].get("status") != "pass"
        or ends[0].get("final_full_reset") != "pass"
    ):
        raise ValueError(f"benchmark artifact must contain one passing run: {path}")
    allowed_record_types = {
        "run_start",
        "workload_start",
        "sample",
        "summary",
        "run_end",
    }
    if any(record.get("record_type") not in allowed_record_types for record in records):
        raise ValueError(f"benchmark artifact contains an invalid record type: {path}")

    provenance = starts[0].get("provenance")
    if not isinstance(provenance, dict):
        raise ValueError(f"benchmark artifact has invalid provenance: {path}")
    declared = provenance.get("workloads")
    if (
        not isinstance(declared, list)
        or not declared
        or not all(isinstance(name, str) and name for name in declared)
        or len(set(declared)) != len(declared)
    ):
        raise ValueError(f"benchmark artifact has an invalid workload declaration: {path}")
    iterations = provenance.get("iterations")
    warmups = provenance.get("warmups")
    if type(iterations) is not int or iterations < 1:
        raise ValueError(f"benchmark artifact has invalid measurement iterations: {path}")
    if type(warmups) is not int or warmups < 0:
        raise ValueError(f"benchmark artifact has invalid warm-up iterations: {path}")

    workload_starts = [
        record for record in records if record.get("record_type") == "workload_start"
    ]
    sample_records = [
        record for record in records if record.get("record_type") == "sample"
    ]
    summary_records = [
        record for record in records if record.get("record_type") == "summary"
    ]
    if len(workload_starts) != len(declared) or len(summary_records) != len(declared):
        raise ValueError(f"benchmark artifact has incomplete workload records: {path}")
    if {record.get("workload") for record in workload_starts} != set(declared) or {
        record.get("workload") for record in summary_records
    } != set(declared):
        raise ValueError(f"benchmark artifact workload records do not match its declaration: {path}")

    starts_by_name: dict[str, dict[str, Any]] = {}
    summaries: dict[str, dict[str, Any]] = {}
    for record in workload_starts:
        workload = record["workload"]
        if workload in starts_by_name:
            raise ValueError(f"duplicate workload_start for {workload}: {path}")
        validation = record.get("program_validation")
        if not isinstance(validation, dict):
            raise ValueError(f"invalid program validation for {workload}: {path}")
        instruction_hash = validation.get("instruction_sha256")
        workload_hash = record.get("workload_sha256")
        if not isinstance(instruction_hash, str) or not SHA256_RE.fullmatch(instruction_hash):
            raise ValueError(f"missing instruction hash for {workload}: {path}")
        if not isinstance(workload_hash, str) or not SHA256_RE.fullmatch(workload_hash):
            raise ValueError(f"missing semantic workload hash for {workload}: {path}")
        starts_by_name[workload] = record
    for record in summary_records:
        workload = record["workload"]
        if workload in summaries:
            raise ValueError(f"duplicate summary for {workload}: {path}")
        if record.get("payload_bytes") != starts_by_name[workload].get("payload_bytes"):
            raise ValueError(f"summary payload differs for {workload}: {path}")
        try:
            if record["latency_ns"]["p50"] <= 0 or record["runs_per_second"] <= 0:
                raise ValueError
        except (KeyError, TypeError, ValueError) as exc:
            raise ValueError(f"invalid performance summary for {workload}: {path}") from exc
        if record.get("samples") != iterations:
            raise ValueError(f"summary sample count differs for {workload}: {path}")
        summaries[workload] = record

    if any(record.get("workload") not in starts_by_name for record in sample_records):
        raise ValueError(f"benchmark artifact contains a sample for an unknown workload: {path}")
    for workload, workload_start in starts_by_name.items():
        workload_samples = [
            record for record in sample_records if record.get("workload") == workload
        ]
        phases = {
            phase: [record for record in workload_samples if record.get("phase") == phase]
            for phase in ("preflight", "warmup", "measurement")
        }
        if len(workload_samples) != 1 + warmups + iterations:
            raise ValueError(f"benchmark artifact has incomplete samples for {workload}: {path}")
        expected_indices = {
            "preflight": {0},
            "warmup": set(range(warmups)),
            "measurement": set(range(iterations)),
        }
        for phase, phase_records in phases.items():
            indices = [record.get("iteration") for record in phase_records]
            if (
                any(type(index) is not int for index in indices)
                or len(indices) != len(expected_indices[phase])
                or set(indices) != expected_indices[phase]
            ):
                raise ValueError(
                    f"benchmark artifact has invalid {phase} samples for {workload}: {path}"
                )
        payload_bytes = workload_start.get("payload_bytes")
        expected_hash = workload_start.get("expected_sha256")
        if type(payload_bytes) is not int or payload_bytes < 0:
            raise ValueError(f"invalid payload size for {workload}: {path}")
        if payload_bytes:
            if not isinstance(expected_hash, str) or not SHA256_RE.fullmatch(expected_hash):
                raise ValueError(f"missing expected payload hash for {workload}: {path}")
        elif expected_hash is not None:
            raise ValueError(f"zero-byte workload has an expected payload hash: {path}")
        for sample in workload_samples:
            sample_hash = sample.get("sha256")
            if (
                sample.get("payload_bytes") != payload_bytes
                or sample.get("mismatched_words") != 0
                or (payload_bytes and sample_hash != expected_hash)
                or (not payload_bytes and sample_hash is not None)
            ):
                raise ValueError(f"benchmark correctness sample failed for {workload}: {path}")
            try:
                if sample["elapsed_ns"] <= 0:
                    raise ValueError
                if any(sample[f"{phase}_ns"] < 0 for phase in ("execute", "receive", "synchronize")):
                    raise ValueError
            except (KeyError, TypeError, ValueError) as exc:
                raise ValueError(f"invalid timing sample for {workload}: {path}") from exc

    embedded_summaries = ends[0].get("summaries")
    if not isinstance(embedded_summaries, list) or {
        summary.get("workload")
        for summary in embedded_summaries
        if isinstance(summary, dict)
    } != set(declared) or len(embedded_summaries) != len(declared):
        raise ValueError(f"benchmark run_end has incomplete summaries: {path}")
    return {
        "path": str(path.resolve()),
        "summaries": summaries,
        "workloads": starts_by_name,
    }


def compare_benchmarks(
    baseline_path: Path, candidate_paths: Sequence[Path]
) -> dict[str, Any]:
    baseline = load_benchmark(baseline_path)
    candidates = [load_benchmark(path) for path in candidate_paths]
    baseline_workloads = set(baseline["summaries"])
    rows: list[dict[str, Any]] = []
    print("workload     candidate                  p50 ratio   throughput ratio")
    print("─" * 74)
    for candidate in candidates:
        if set(candidate["summaries"]) != baseline_workloads:
            raise ValueError(
                f"workload set differs between {baseline['path']} and {candidate['path']}"
            )
        for workload in sorted(baseline_workloads):
            base = baseline["summaries"][workload]
            current = candidate["summaries"][workload]
            if base.get("payload_bytes") != current.get("payload_bytes"):
                raise ValueError(f"payload differs for workload {workload}")
            base_hash = baseline["workloads"][workload]["workload_sha256"]
            current_hash = candidate["workloads"][workload]["workload_sha256"]
            if base_hash != current_hash:
                raise ValueError(f"semantic workload differs for {workload}")
            p50_ratio = current["latency_ns"]["p50"] / base["latency_ns"]["p50"]
            base_throughput = base["runs_per_second"]
            current_throughput = current["runs_per_second"]
            throughput_ratio = current_throughput / base_throughput
            row = {
                "workload": workload,
                "candidate": candidate["path"],
                "candidate_to_baseline_p50_ratio": p50_ratio,
                "candidate_to_baseline_throughput_ratio": throughput_ratio,
            }
            rows.append(row)
            print(
                f"{workload:<12} {Path(candidate['path']).name:<26} "
                f"{p50_ratio:>9.3f}x {throughput_ratio:>15.3f}x"
            )
    return {"baseline": baseline["path"], "comparisons": rows}


def add_result_options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--json-results", type=Path, help="write the runner summary as JSON")
    parser.add_argument(
        "--dry-run", action="store_true", help="print commands without executing them"
    )
    parser.add_argument(
        "--keep-going", action="store_true", help="continue after a failed case"
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    host = subparsers.add_parser(
        "host", help="configure, build, and run every host-only CTest"
    )
    add_result_options(host)
    host.add_argument("--python", type=Path, default=DEFAULT_PYTHON)

    board = subparsers.add_parser(
        "board",
        help="run an explicitly selected hardware profile",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    add_result_options(board)
    board.add_argument("--profile", required=True, choices=BOARD_PROFILES)
    board.add_argument("--python", type=Path, default=DEFAULT_PYTHON)
    board.add_argument(
        "--test-language",
        choices=("python", "cpp", "both"),
        help="exercise equivalent functional tests in Python, C++, or both; defaults to both",
    )
    board.add_argument("--pci-bdf", type=normalize_bdf)
    board.add_argument("--xdma-channel", type=int, choices=(0, 1))
    board.add_argument("--board", choices=("u50", "u55c"))
    board.add_argument(
        "--endpoint",
        action="append",
        type=parse_endpoint,
        help="multiboard endpoint dddd:bb:ss.f/CHANNEL; repeat per endpoint",
    )
    board.add_argument(
        "--topology",
        type=Path,
        help="deployment-owned JSON topology with expected counts",
    )
    board.add_argument("--expected-board-count", type=int)
    board.add_argument("--expected-endpoint-count", type=int)
    board.add_argument("--require-complete-dual", action="store_true")
    board.add_argument("--rw-rows", type=int)
    board.add_argument("--multi-iterations", type=int)
    board.add_argument("--timeout-seconds", type=float)
    board.add_argument("--fuzz-seed")
    board.add_argument(
        "--artifact-dir",
        type=Path,
        help="directory for board-test JSONL; defaults below the ignored build tree",
    )
    board.add_argument("--benchmark-language", choices=("python", "cpp", "both"))
    board.add_argument("--stack-label")
    board.add_argument("--driver-label")
    board.add_argument("--bitstream-label")
    board.add_argument("--bitstream-file", type=Path)
    board.add_argument("--warmups", type=int)
    board.add_argument("--benchmark-iterations", type=int)

    compare = subparsers.add_parser(
        "compare",
        help="compare current benchmark JSONL with a separately collected legacy baseline",
    )
    compare.add_argument("--baseline", required=True, type=Path)
    compare.add_argument("--candidate", required=True, action="append", type=Path)
    compare.add_argument("--json-results", type=Path)
    return parser


def resolve_path(path: Path, caller_cwd: Path) -> Path:
    expanded = path.expanduser()
    return expanded.resolve() if expanded.is_absolute() else (caller_cwd / expanded).resolve()


def resolve_cli_paths(args: argparse.Namespace, caller_cwd: Path) -> None:
    for name in ("python", "topology", "artifact_dir", "json_results", "bitstream_file"):
        value = getattr(args, name, None)
        if value is not None:
            setattr(args, name, resolve_path(value, caller_cwd))
    if args.command == "compare":
        args.baseline = resolve_path(args.baseline, caller_cwd)
        args.candidate = [resolve_path(path, caller_cwd) for path in args.candidate]


def command_output_paths(cases: Sequence[Case]) -> list[Path]:
    paths: list[Path] = []
    output_flags = {"--output", "--results", "--program-manifest"}
    for case in cases:
        for index, argument in enumerate(case.command[:-1]):
            if argument in output_flags:
                paths.append(Path(case.command[index + 1]).resolve())
    return paths


def refuse_output_collisions(
    outputs: Sequence[Path], inputs: Sequence[Path | None]
) -> None:
    output_set = set(outputs)
    if len(output_set) != len(outputs):
        raise ValueError("two result outputs resolve to the same path")
    input_set = {path for path in inputs if path is not None}
    collisions = sorted(output_set & input_set)
    if collisions:
        raise ValueError(f"result path collides with an input: {collisions[0]}")
    existing = sorted(path for path in output_set if path.exists())
    if existing:
        raise ValueError(f"refusing to overwrite existing result: {existing[0]}")


def write_results(path: Path, document: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with path.open("x", encoding="utf-8") as stream:
            stream.write(json.dumps(document, indent=2, sort_keys=True) + "\n")
    except FileExistsError as exc:
        raise ValueError(f"refusing to overwrite existing result: {path}") from exc
    print(f"Results: {path.resolve()}")


def main(argv: Sequence[str] | None = None) -> int:
    caller_cwd = Path.cwd()
    parser = build_parser()
    args = parser.parse_args(argv)
    resolve_cli_paths(args, caller_cwd)
    started_at = utc_now()

    if args.command == "compare":
        try:
            inputs = [args.baseline, *args.candidate]
            if len(set(inputs)) != len(inputs):
                raise ValueError("baseline and candidate paths must be distinct")
            if args.json_results:
                refuse_output_collisions([args.json_results], inputs)
            comparison = compare_benchmarks(args.baseline, args.candidate)
        except ValueError as exc:
            parser.error(str(exc))
        if args.json_results:
            try:
                write_results(
                    args.json_results,
                    {
                        "format": "drambender.internal-performance-comparison",
                        "started_at": started_at,
                        **comparison,
                    },
                )
            except ValueError as exc:
                parser.error(str(exc))
        return 0

    if args.command == "host":
        title = "host"
        detail = "No FPGA device is opened by this profile."
        cases = host_cases(args.python)
        artifact_dir = None
        if not args.dry_run and not args.python.is_file():
            parser.error(f"Python executable does not exist: {args.python}")
        if args.json_results:
            try:
                refuse_output_collisions([args.json_results], [args.python])
            except ValueError as exc:
                parser.error(str(exc))
    else:
        title = args.profile
        detail = "Board-facing profile: only the endpoints supplied on this command are used."
        artifact_dir = args.artifact_dir or (
            REPO_ROOT
            / "build"
            / "internal-test-results"
            / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        )
        try:
            validate_board_options(args)
            hardware_cases = board_cases(args, artifact_dir)
            cases = board_build_cases(args) + hardware_cases
            if not args.dry_run and not args.python.is_file():
                raise ValueError(f"Python executable does not exist: {args.python}")
            if not args.dry_run and args.json_results is None:
                args.json_results = artifact_dir / "run-summary.json"
            result_outputs = command_output_paths(hardware_cases)
            if args.json_results:
                result_outputs.append(args.json_results)
            refuse_output_collisions(
                result_outputs,
                [args.topology, args.bitstream_file, args.python],
            )
        except ValueError as exc:
            parser.error(str(exc))
        if not args.dry_run:
            artifact_dir.mkdir(parents=True, exist_ok=True)
        print(f"Artifacts: {artifact_dir.resolve()}")

    results, exit_code = run_cases(
        title,
        detail,
        cases,
        dry_run=args.dry_run,
        keep_going=args.keep_going,
    )
    if args.json_results:
        try:
            write_results(
                args.json_results,
                {
                    "format": "drambender.internal-test-run",
                    "profile": title,
                    "started_at": started_at,
                    "finished_at": utc_now(),
                    "repository": str(REPO_ROOT),
                    "artifact_directory": str(artifact_dir.resolve()) if artifact_dir else None,
                    "exit_code": exit_code,
                    "results": [asdict(result) for result in results],
                },
            )
        except ValueError as exc:
            print(f"failed to write runner summary: {exc}", file=sys.stderr)
            return exit_code or 2
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
