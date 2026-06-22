# Examples

These examples are host-side programs that talk to a programmed FPGA board.

Configure CMake with `-DDRAMINSPECTOR_BUILD_EXAMPLES=ON` to compile the C++
example binaries.

They require a compatible DRAM-Bender bitstream and a loaded XDMA driver. They
may reset FPGA-side state, access XDMA devices, execute DRAM programs, and read
data back from the board. Do not run them on a normal software-only development
machine.

Advanced JIT and timing benchmark scripts live under `tests/jit_benchmark`.
Board-facing validation scripts live under `tests/board_tests`.
