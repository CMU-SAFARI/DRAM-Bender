# pyDRAMBender Monorepo

This repository uses pyDRAMBender as the main public software API and keeps the
DRAM-BenderV2 RTL and Vivado sources alongside it.

## Layout

- `include`: public C++ headers for the DRAMBender API.
- `src`: C++ implementation and Python binding sources.
- `python`: pure Python `drambender` package.
- `examples`: user-facing host programs that talk to a configured FPGA board.
- `tests`: board-facing validation scripts and manual JIT benchmark tools. Do
  not run `tests/board_tests` unless the host is connected to a configured FPGA
  board.
- `hw`: DRAM-Bender RTL, simulation sources, Vivado project skeletons, and
  Vivado/build helper scripts.
- `hw/prebuilt`: reserved for an optional prebuilt-bitstream submodule.
- `xdma`: imported XDMA driver source. It is not part of the default build.

## Software Build

For a C++ software-only build that avoids FPGA/device access, Python bindings,
and the XDMA driver:

```sh
bash build.sh --cxx-only release
```

To compile the board-facing example binaries, configure with
`-DDRAMBENDER_BUILD_EXAMPLES=ON`. Do not run those examples unless the host
is connected to a configured FPGA board.

Install the C++ library and CMake package metadata to a prefix:

```sh
cmake --install build --prefix /path/to/prefix
```

C++ consumers can then use:

```cmake
find_package(DRAMBender CONFIG REQUIRED)
target_link_libraries(my_target PRIVATE DRAMBender::DRAMBender)
```

For Python development on a fresh clone:

```sh
bash setup_venv.sh
```

The Python extension requires the development headers for the selected
interpreter. With the default `python3.12` on Ubuntu/Debian, install them with
`sudo apt install python3.12-dev`.

This creates `.venv`, installs requirements, and runs the editable install. For
iterative local C++ extension rebuilds after that setup step:

```sh
bash build.sh debug
```

`setup_venv.sh` is the environment/bootstrap script. `build.sh` is the local
build helper; by default it expects `.venv/bin/python`, while
`build.sh --cxx-only ...` does not use Python.

## Hardware Sources

The `hw` tree keeps source skeletons only. Generated Vivado output,
bitstreams, simulation products, and generated IP payloads are intentionally
excluded from the main repository.

Host examples, `tests/board_tests`, XDMA driver loading, and any command that
touches `/dev/xdma*` require an intentionally prepared FPGA host.
