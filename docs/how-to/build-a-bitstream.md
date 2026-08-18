# Build an FPGA Bitstream

Most users do not need to build a bitstream:
[prebuilt bitstreams](obtain-a-bitstream.md) are released for every supported
board. Build one yourself when you change the RTL or need a memory
configuration that is not covered by a released image.

The maintained Vivado projects are under [`hw/projects/`](../../hw/projects/).
Common RTL lives under [`hw/rtl/`](../../hw/rtl/), and board projects provide
the memory controller, constraints, XDMA configuration, and top-level adapter
for each FPGA.

Each board directory keeps only the source-like files needed to reconstruct
the project: the top-level `.xpr`, board constraints, `verilog/project.vh`,
and PHY patch scripts where the board needs them. Generated IP output, run
directories, caches, and logs are intentionally excluded from the repository;
Vivado regenerates them on the first build.

## Use the exact Vivado version

Use the Vivado version listed for the board; project and IP state does not
migrate cleanly across versions:

| Board | Project | Vivado |
|---|---|---|
| Alveo U200 | `hw/projects/U200` | 2024.2 |
| Alveo U50 | `hw/projects/U50-HBM` | 2024.2 |
| Alveo U55C | `hw/projects/U55-HBM` | 2024.2 |

The test status of every released bitstream is documented in the
[bitstreams repository](https://github.com/CMU-SAFARI/dram-bender-bitstreams);
the memory configuration is encoded in each bitstream's file name.

## Build with the Vivado GUI

1. Open the board's `.xpr` in the matching Vivado version.
2. Let Vivado generate the IP output products on first open.
3. **U200 only:** apply the DRAM Bender PHY patches to the generated DDR4 IP
   sources by running `./apply_patches.sh` from `hw/projects/U200` after IP
   generation. The script requires `dos2unix` and `patch`.
4. Launch synthesis, implementation, and bitstream generation.

## Build in batch mode

From a board project directory, the legacy batch flow generates the bitstream
without the GUI:

```bash
cd hw/projects/U200
vivado -mode batch -source ../../scripts/generate.tcl -tclargs <number_of_threads>
```

## Board-specific notes

- **U200 (DDR4).** Before building, select a memory-controller configuration
  and constraints that exactly match the installed DIMM and slot. The project
  includes `custom_parts_ddr4_2016_4_and_above.csv` for parts that are not in
  the stock Vivado memory-part catalog.
- **U50 / U55C (HBM2).** The HBM2 stacks are on the package, so there is no
  DIMM matching step. Select the channel configuration in the project to match
  the intended experiment setup.

## Validate before hardware runs

Software VM checks and RTL simulation serve different purposes. Use
`FinalProgram.dry_run()` and `trace_dram_commands()` to inspect program control
flow and command timing (see
[Writing DRAM Bender programs](../tutorials/writing-programs.md)). Use the
sources under [`hw/sim/`](../../hw/sim/) and the board's Vivado simulation
environment to inspect RTL handshakes and PHY-facing behavior.
