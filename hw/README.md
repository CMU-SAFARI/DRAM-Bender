# DRAM-Bender Hardware

This directory contains the source-side hardware material imported from
DRAM-BenderV2.

## Layout

- `rtl/header_verilog` and `rtl/verilog`: DRAM-Bender RTL sources.
- `sim`: source testbenches for RTL simulation.
- `projects`: cleaned Vivado project skeletons for supported boards.
- `scripts`: Vivado helper scripts for bitstream generation and programming.
- `prebuilt`: reserved for an optional bitstream submodule.

The main repository intentionally excludes generated Vivado output, generated IP
products, caches, runs, simulation artifacts, and bitstreams. Prebuilt
bitstreams are expected to live in a separate repository mounted at
`hw/prebuilt`.

## Build Notes

The software API can be configured and built without Vivado, without prebuilt
bitstreams, and without building the XDMA driver. Hardware builds are a separate
Vivado workflow rooted in `hw/projects/<board>`.

Programming an FPGA or using generated bitstreams is a hardware bring-up action.
Keep it separate from routine software package builds and tests.
