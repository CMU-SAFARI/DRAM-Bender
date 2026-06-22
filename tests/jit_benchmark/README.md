# JIT Benchmarks

This directory contains manual tools for measuring JIT template overhead and
native C++ baseline program construction.

The software-only benchmark scripts use generated programs and do not require a
board. Configure with `-DBUILD_TESTING=ON` and build
`drambender_jit_native_benchmark` before running `bench_jit_templates.py` or
`smoke_check.py`.

The `*_jit.py`, `*_bench.{py,cpp}`, and `run_benchmark.sh` rowhammer/read-write
programs are board-facing lab tools. They open XDMA devices, reset FPGA-side
state, and run DRAM programs on an attached board. Configure with
`-DDRAMBENDER_BUILD_BOARD_BENCHMARKS=ON` before building the C++ benchmark
targets.
