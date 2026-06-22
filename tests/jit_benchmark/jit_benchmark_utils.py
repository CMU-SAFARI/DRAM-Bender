from collections.abc import Callable
from dataclasses import dataclass
import json
import math
from pathlib import Path
import statistics
import subprocess
import sys
from typing import Any

from drambender.api.jit import (
    clear_lowering_stats,
    clear_template_caches,
    get_last_lowering_stats,
    get_last_template_run_stats_dict,
    set_jit_cache_dir,
)
from tests.jit_benchmark.workloads import (
    build_pattern_program_compiled,
    build_pattern_program_plain,
    build_rowhammer_program_compiled,
    build_rowhammer_program_plain,
    build_tiny_scalar_program_compiled,
    build_tiny_scalar_program_plain,
    pattern_cases,
    rowhammer_cases,
    tiny_scalar_cases,
)


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_NATIVE_EXE = REPO_ROOT / "build" / "dev-gcc12" / "drambender_jit_native_benchmark"


@dataclass(frozen=True)
class WorkloadSpec:
    name: str
    cpp_name: str
    plain_fn: Callable[..., Any]
    compiled_fn: Callable[..., Any]
    make_cases: Callable[[bool], list[dict[str, Any]]]


def get_workload_specs() -> dict[str, WorkloadSpec]:
    return {
        "tiny_scalar": WorkloadSpec(
            name="tiny_scalar",
            cpp_name="tiny_scalar",
            plain_fn=build_tiny_scalar_program_plain,
            compiled_fn=build_tiny_scalar_program_compiled,
            make_cases=lambda quick: tiny_scalar_cases(32 if quick else 256),
        ),
        "pattern": WorkloadSpec(
            name="pattern",
            cpp_name="pattern",
            plain_fn=build_pattern_program_plain,
            compiled_fn=build_pattern_program_compiled,
            make_cases=lambda quick: pattern_cases(16 if quick else 128, length=4),
        ),
        "rowhammer": WorkloadSpec(
            name="rowhammer",
            cpp_name="rowhammer",
            plain_fn=build_rowhammer_program_plain,
            compiled_fn=build_rowhammer_program_compiled,
            make_cases=lambda quick: rowhammer_cases(8 if quick else 64, hammer_count=1024 if quick else 250_000),
        ),
    }


def percentile(values_us: list[float], fraction: float) -> float:
    if not values_us:
        return 0.0
    if len(values_us) == 1:
        return values_us[0]

    ordered = sorted(values_us)
    index = (len(ordered) - 1) * fraction
    lower = math.floor(index)
    upper = math.ceil(index)
    if lower == upper:
        return ordered[lower]
    weight = index - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight


def summarize_times(times_s: list[float]) -> dict[str, float]:
    times_us = [value * 1e6 for value in times_s]
    return {
        "batch_ms": sum(times_s) * 1e3,
        "min_us": min(times_us),
        "median_us": statistics.median(times_us),
        "p95_us": percentile(times_us, 0.95),
    }


def benchmark_interpreted(spec: WorkloadSpec, cases: list[dict[str, Any]]) -> dict[str, Any]:
    clear_lowering_stats()

    times_s: list[float] = []
    lower_times_s: list[float] = []
    instruction_count = None

    import time

    for case in cases:
        start = time.perf_counter()
        program = spec.plain_fn(**case)
        times_s.append(time.perf_counter() - start)

        if instruction_count is None:
            instruction_count = program.instruction_count

        lowering_stats = get_last_lowering_stats()
        if lowering_stats is not None:
            lower_times_s.append(lowering_stats.lower_s)

    result = summarize_times(times_s)
    result["instruction_count"] = instruction_count
    if lower_times_s:
        result["lower_median_us"] = statistics.median([value * 1e6 for value in lower_times_s])
    return result


def benchmark_compiled_cold(spec: WorkloadSpec, first_case: dict[str, Any], cache_dir: Path) -> dict[str, Any]:
    set_jit_cache_dir(cache_dir)
    clear_template_caches(clear_disk=True)

    program = spec.compiled_fn(**first_case)
    stats = get_last_template_run_stats_dict() or {}
    stats["instruction_count"] = program.instruction_count
    return stats


def benchmark_compiled_hot(spec: WorkloadSpec, cases: list[dict[str, Any]]) -> dict[str, Any]:
    import time

    times_s: list[float] = []
    instantiate_times_s: list[float] = []
    instruction_count = None

    for case in cases:
        start = time.perf_counter()
        program = spec.compiled_fn(**case)
        times_s.append(time.perf_counter() - start)

        if instruction_count is None:
            instruction_count = program.instruction_count

        stats = get_last_template_run_stats_dict() or {}
        instantiate_times_s.append(stats.get("instantiate_s", 0.0))

    result = summarize_times(times_s)
    result["instruction_count"] = instruction_count
    result["instantiate_median_us"] = statistics.median(
        [value * 1e6 for value in instantiate_times_s]
    )
    return result


def benchmark_compiled_warm_disk(
    script_path: Path,
    workload_name: str,
    first_case: dict[str, Any],
    cache_dir: Path,
) -> dict[str, Any]:
    command = [
        sys.executable,
        str(script_path),
        "--worker-warm-disk",
        "--workload",
        workload_name,
        "--cache-dir",
        str(cache_dir),
        "--case-json",
        json.dumps(first_case),
    ]
    completed = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    return json.loads(completed.stdout)


def benchmark_native_cpp(
    native_exe: Path,
    spec: WorkloadSpec,
    cases: list[dict[str, Any]],
) -> dict[str, Any]:
    command = [
        str(native_exe),
        "--workload",
        spec.cpp_name,
        "--batch-size",
        str(len(cases)),
    ]

    if spec.name == "pattern":
        command.extend(["--pattern-length", str(len(cases[0]["pattern_words"]))])
    if spec.name == "rowhammer":
        command.extend(["--hammer-count", str(cases[0]["hammer_count"])])

    completed = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        cwd=REPO_ROOT,
    )
    return json.loads(completed.stdout)
