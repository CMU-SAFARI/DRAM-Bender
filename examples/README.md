# DRAM Bender Examples

DRAM Bender supports both Python and C++ APIs. The examples in this directory
show complete programs that can be adapted for an experiment. Set up the host,
program a supported FPGA, install the driver, and activate the Python
environment before running them. See the
[getting-started tutorial](../docs/tutorials/getting-started.md) for those
steps.

All board-facing examples overwrite the selected DRAM locations.

## Read and write one row

[`read_write.py`](read_write.py) uses one Python program-building and execution
workflow for all maintained boards. The `--board` argument selects external
DDR4 on U200 or HBM2 on U50/U55C.

U200:

```bash
python examples/read_write.py \
    --board u200 \
    --pci-bdf 0000:01:00.0 \
    --xdma-channel 0 \
    --bank 0 --row 0 --pattern 0xDEADBEEF
```

U50:

```bash
python examples/read_write.py \
    --board u50 \
    --pci-bdf 0000:01:00.0 \
    --xdma-channel 0 \
    --channel 0 --pseudo-channel 0 --sid 0 \
    --bank 0 --row 0 --pattern 0xDEADBEEF
```

U55C:

```bash
python examples/read_write.py \
    --board u55c \
    --pci-bdf 0000:01:00.0 \
    --xdma-channel 0 \
    --channel 0 --pseudo-channel 0 --sid 0 \
    --bank 0 --row 0 --pattern 0xDEADBEEF
```

The calls to `write_row`, `read_row`, `open_board`, `execute`, `receive_into`,
and `synchronize` are common to all three boards. Target construction carries
the board-specific memory geometry. HBM2 readback also needs one normalization
step because each returned 64-byte block contains both pseudo-channels.

[`read_write.cpp`](read_write.cpp) is the corresponding compact C++ example
for U200. It constructs the DRAM Bender instructions directly and demonstrates
the C++ board and readback interfaces.

## Single-sided RowHammer

[`single_sided_rowhammer.py`](single_sided_rowhammer.py) and
[`single_sided_rowhammer.cpp`](single_sided_rowhammer.cpp) demonstrate the same
U200 characterization experiment through the Python and C++ APIs. They write
victim and aggressor rows, repeatedly activate the aggressor, read the victim,
and report observed bit flips.

Use locations, mappings, patterns, timings, and hammer counts suitable for the
installed DIMM and programmed bitstream.

## Python tutorial

[`tutorial.ipynb`](tutorial.ipynb) introduces memory targets, built-in
programs, instruction tracing, timing checks, hardware execution, custom
programs, and JIT templates. Hardware execution is opt-in, so the
program-building and debugging sections can be used without opening an FPGA.

Start it from the repository environment with:

```bash
jupyter lab examples/tutorial.ipynb
```

## Build the C++ examples

Configure and build the optional example targets:

```bash
cmake -S . -B build/examples \
    -DDRAMBENDER_BUILD_PYTHON=OFF \
    -DDRAMBENDER_BUILD_EXAMPLES=ON
cmake --build build/examples
```

The resulting executables are `drambender_example_read_write` and
`drambender_example_single_sided_rowhammer` in `build/examples/`.

For example:

```bash
build/examples/drambender_example_read_write \
    --pci-bdf 0000:01:00.0 \
    --xdma-channel 0 \
    --bank 0 --row 0 --pattern 0xDEADBEEF
```
