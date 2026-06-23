# JIT Benchmarks

This directory contains manual tools for measuring JIT template overhead and
native C++ baseline program construction.

The software-only benchmark scripts use generated programs and do not require a
board. Configure with `-DBUILD_TESTING=ON` and build
`drambender_jit_native_benchmark` before running `bench_jit_templates.py` or
`smoke_check.py`.

The Python `@program_template` JIT needs G++ 11 or newer with C++20 `<span>`
support. Set `DRAMBENDER_JIT_CXX=/path/to/g++` to choose a compiler explicitly;
otherwise `CXX` and common `g++` executables on `PATH` are tried.

The `*_jit.py`, `*_bench.{py,cpp}`, and `run_benchmark.sh` rowhammer/read-write
programs are board-facing lab tools. They open XDMA devices, reset FPGA-side
state, and run DRAM programs on an attached board. Configure with
`-DDRAMBENDER_BUILD_BOARD_BENCHMARKS=ON` before building the C++ benchmark
targets.
