#!/usr/bin/env python3
"""Manual host-side benchmark for the Python JIT template path."""

import argparse
import json
from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from draminspector.api.jit import (  # noqa: E402
    clear_template_caches,
    get_last_template_run_stats_dict,
    set_jit_cache_dir,
)
from tests.jit_benchmark.jit_benchmark_utils import (  # noqa: E402
    DEFAULT_NATIVE_EXE,
    benchmark_compiled_cold,
    benchmark_compiled_hot,
    benchmark_compiled_warm_disk,
    benchmark_interpreted,
    benchmark_native_cpp,
    get_workload_specs,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--workload",
        choices=["all", "tiny_scalar", "pattern", "rowhammer"],
        default="all",
    )
    parser.add_argument("--quick", action="store_true")
    parser.add_argument(
        "--cache-dir",
        type=Path,
        default=REPO_ROOT / "build" / "jit_benchmark" / "jit-cache",
    )
    parser.add_argument("--native-exe", type=Path, default=DEFAULT_NATIVE_EXE)
    parser.add_argument("--output-json", type=Path)
    parser.add_argument("--worker-warm-disk", action="store_true")
    parser.add_argument("--case-json")
    return parser.parse_args()


def run_worker(workload_name: str, cache_dir: Path, case_json: str) -> int:
    specs = get_workload_specs()
    spec = specs[workload_name]

    set_jit_cache_dir(cache_dir)
    clear_template_caches()
    program = spec.compiled_fn(**json.loads(case_json))
    stats = get_last_template_run_stats_dict() or {}
    stats["instruction_count"] = program.instruction_count
    print(json.dumps(stats, sort_keys=True))
    return 0


def print_mode(prefix: str, result: dict[str, float | int | str | bool]) -> None:
    instruction_count = int(result["instruction_count"])
    if "median_us" in result:
        print(
            f"  {prefix:<18s}"
            f" median={result['median_us']:9.2f} us"
            f" min={result['min_us']:9.2f} us"
            f" p95={result['p95_us']:9.2f} us"
            f" batch={result['batch_ms']:9.2f} ms"
            f" insts={instruction_count}"
        )
    else:
        print(
            f"  {prefix:<18s}"
            f" total={result['total_s'] * 1e3:9.2f} ms"
            f" trace={result['trace_s'] * 1e3:8.2f} ms"
            f" codegen={result['codegen_s'] * 1e3:8.2f} ms"
            f" compile={result['compile_s'] * 1e3:8.2f} ms"
            f" load={result['plugin_load_s'] * 1e3:8.2f} ms"
            f" inst={result['instantiate_s'] * 1e3:8.2f} ms"
            f" insts={instruction_count}"
        )


def main() -> int:
    args = parse_args()
    if args.worker_warm_disk:
        return run_worker(args.workload, args.cache_dir, args.case_json)

    specs = get_workload_specs()
    workload_names = (
        list(specs.keys())
        if args.workload == "all"
        else [args.workload]
    )

    if not args.native_exe.exists():
        raise FileNotFoundError(
            f"Native benchmark executable not found at {args.native_exe}. "
            "Build `draminspector_jit_native_benchmark` first."
        )

    all_results: dict[str, dict[str, dict[str, float | int | str | bool]]] = {}

    for workload_name in workload_names:
        spec = specs[workload_name]
        cases = spec.make_cases(args.quick)
        cache_dir = args.cache_dir / workload_name

        interpreted = benchmark_interpreted(spec, cases)
        cold = benchmark_compiled_cold(spec, cases[0], cache_dir)
        warm_disk = benchmark_compiled_warm_disk(
            Path(__file__),
            workload_name,
            cases[0],
            cache_dir,
        )
        hot = benchmark_compiled_hot(spec, cases)
        native = benchmark_native_cpp(args.native_exe, spec, cases)

        all_results[workload_name] = {
            "interpreted": interpreted,
            "compiled_cold": cold,
            "compiled_warm_disk": warm_disk,
            "compiled_hot": hot,
            "native_cpp": native,
        }

        print(f"\n{workload_name}")
        print_mode("interpreted", interpreted)
        print_mode("compiled cold", cold)
        print_mode("compiled warm", warm_disk)
        print_mode("compiled hot", hot)
        print_mode("native cpp", native)

    if args.output_json is not None:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(
            json.dumps(all_results, indent=2, sort_keys=True),
            encoding="utf-8",
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
