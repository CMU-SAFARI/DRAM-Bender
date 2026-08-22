# C++ API Reference

C++ applications open maintained designs with `BoardType::U200`,
`BoardType::U50`, or `BoardType::U55C`. The corresponding concrete board
classes are `DRAMBender::DDR4`, `DRAMBender::HBM2U50`, and
`DRAMBender::HBM2U55C`. The public headers are under
[`include/drambender/`](../../include/drambender/).

## Board configuration

`BoardConfig` centralizes the API assumptions for each board and bitstream.
Resolve the built-in record with `get_board_config()`, or inspect the same
record through an opened board:

```cpp
const auto& expected =
    DRAMBender::get_board_config(DRAMBender::BoardType::U200);
const auto summary = expected.summary();

auto board = DRAMBender::create_board(
    DRAMBender::BoardType::U200, "0000:01:00.0");
const DRAMBender::BoardConfig& active = board->board_config();
```

The fields cover board and memory identity, instruction and readback
capacities, DRAM command timing, HBM topology, and optional features. Opening
a board prints this configuration and reminds the user that the programmed
bitstream must match it. The values are not read from the FPGA image. Update
the API configuration when using a custom bitstream with different parameters.

## Build the library

Build the C++ library without Python:

```bash
bash build.sh --cxx-only release
```

Install it to a prefix:

```bash
cmake --install build/cxx-release --prefix /path/to/prefix
```

## Consume from CMake

CMake consumers can use the exported target:

```cmake
find_package(DRAMBender CONFIG REQUIRED)
target_link_libraries(my_experiment PRIVATE DRAMBender::DRAMBender)
```

When installing to a nonstandard prefix, add that prefix to
`CMAKE_PREFIX_PATH` while configuring the consuming project.

## Examples

See [`examples/read_write.cpp`](../../examples/read_write.cpp) and
[`examples/single_sided_rowhammer.cpp`](../../examples/single_sided_rowhammer.cpp).
