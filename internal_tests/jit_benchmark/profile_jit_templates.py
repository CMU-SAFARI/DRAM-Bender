#!/usr/bin/env python3
"""Profile interpreted and compiled JIT template orchestration with cProfile."""

import argparse
import cProfile
import io
from pathlib import Path
import pstats
import sys

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from drambender.api.jit import (  # noqa: E402
    clear_template_caches,
    get_last_template_run_stats_dict,
    set_jit_cache_dir,
)
from internal_tests.jit_benchmark.jit_benchmark_utils import get_workload_specs  # noqa: E402


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--workload",
        choices=["tiny_scalar", "pattern", "rowhammer"],
        default="rowhammer",
    )
    parser.add_argument(
        "--mode",
        choices=["all", "interpreted", "compiled-cold", "compiled-hot"],
        default="all",
    )
    parser.add_argument("--quick", action="store_true")
    parser.add_argument(
        "--cache-dir",
        type=Path,
        default=REPO_ROOT / "build" / "jit_benchmark" / "jit-cache",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=REPO_ROOT / "build" / "jit_benchmark" / "profiles",
    )
    return parser.parse_args()


def profile_mode(
    mode: str,
    plain_fn,
    compiled_fn,
    cases: list[dict],
    cache_dir: Path,
    output_dir: Path,
) -> None:
    profiler = cProfile.Profile()

    if mode == "interpreted":
        clear_template_caches()

        def run() -> None:
            for case in cases:
                plain_fn(**case)

    elif mode == "compiled-cold":
        clear_template_caches(clear_disk=True)

        def run() -> None:
            compiled_fn(**cases[0])

    elif mode == "compiled-hot":
        clear_template_caches(clear_disk=True)
        compiled_fn(**cases[0])

        def run() -> None:
            for case in cases:
                compiled_fn(**case)

    else:
        raise ValueError(f"Unsupported mode {mode!r}.")

    profiler.enable()
    run()
    profiler.disable()

    output_dir.mkdir(parents=True, exist_ok=True)
    base = output_dir / f"{args.workload}_{mode}"
    profiler.dump_stats(str(base.with_suffix(".prof")))

    summary = io.StringIO()
    stats = pstats.Stats(profiler, stream=summary).sort_stats("cumtime")
    stats.print_stats(25)

    last_template_stats = get_last_template_run_stats_dict()
    text = [summary.getvalue()]
    if last_template_stats is not None:
        text.append("last_template_stats:\n")
        for key, value in sorted(last_template_stats.items()):
            text.append(f"  {key}: {value}\n")

    base.with_suffix(".txt").write_text("".join(text), encoding="utf-8")
    print(f"{mode:<14s} -> {base.with_suffix('.prof')} and {base.with_suffix('.txt')}")


if __name__ == "__main__":
    args = parse_args()

    specs = get_workload_specs()
    spec = specs[args.workload]
    cases = spec.make_cases(args.quick)
    set_jit_cache_dir(args.cache_dir / args.workload)

    modes = (
        ["interpreted", "compiled-cold", "compiled-hot"]
        if args.mode == "all"
        else [args.mode]
    )
    for mode in modes:
        profile_mode(
            mode,
            spec.plain_fn,
            spec.compiled_fn,
            cases,
            args.cache_dir / args.workload,
            args.output_dir,
        )
