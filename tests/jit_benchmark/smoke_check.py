#!/usr/bin/env python3
"""Manual smoke checks for the host-side JIT benchmark/profile tools."""

import argparse
import os
from pathlib import Path
import subprocess
import sys


REPO_ROOT = Path(__file__).resolve().parents[2]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--build-dir",
        type=Path,
        default=REPO_ROOT / "build" / "jit-smoke",
    )
    parser.add_argument(
        "--python-executable",
        type=Path,
        default=Path(sys.executable),
    )
    return parser.parse_args()


def configure_if_needed(build_dir: Path, python_executable: Path) -> None:
    cache = build_dir / "CMakeCache.txt"
    if cache.exists():
        return

    subprocess.run(
        [
            "cmake",
            "-S",
            str(REPO_ROOT),
            "-B",
            str(build_dir),
            "-DCMAKE_BUILD_TYPE=Debug",
            f"-DCMAKE_C_COMPILER={os.environ.get('CC', 'gcc')}",
            f"-DCMAKE_CXX_COMPILER={os.environ.get('CXX', 'g++')}",
            f"-DPython_EXECUTABLE={python_executable}",
            "-DBUILD_TESTING=ON",
            "-DDRAMBENDER_BUILD_PYTHON=ON",
        ],
        check=True,
        cwd=REPO_ROOT,
    )


def main() -> int:
    args = parse_args()

    subprocess.run(
        [str(args.python_executable), "-m", "pip", "install", "-e", "."],
        check=True,
        cwd=REPO_ROOT,
    )

    configure_if_needed(args.build_dir, args.python_executable)
    subprocess.run(
        [
            "cmake",
            "--build",
            str(args.build_dir),
            "--target",
            "drambender_jit_native_benchmark",
            "drambender_core",
            "-j4",
        ],
        check=True,
        cwd=REPO_ROOT,
    )

    native_exe = args.build_dir / "drambender_jit_native_benchmark"
    subprocess.run(
        [
            str(args.python_executable),
            "tests/jit_benchmark/bench_jit_templates.py",
            "--quick",
            "--native-exe",
            str(native_exe),
        ],
        check=True,
        cwd=REPO_ROOT,
    )
    subprocess.run(
        [
            str(args.python_executable),
            "tests/jit_benchmark/profile_jit_templates.py",
            "--quick",
            "--workload",
            "rowhammer",
        ],
        check=True,
        cwd=REPO_ROOT,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
