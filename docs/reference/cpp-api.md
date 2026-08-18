# C++ API Reference

C++ applications use `DRAMBender::DDR4` for U200 and `DRAMBender::HBM2` for
U50/U55C. The public headers are under
[`include/drambender/`](../../include/drambender/).

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
