# Obtain a Bitstream

Prebuilt bitstreams live in a separate repository,
[CMU-SAFARI/dram-bender-bitstreams](https://github.com/CMU-SAFARI/dram-bender-bitstreams),
included here as the `hw/prebuilt` submodule. Fetch them with:

```bash
git submodule update --init hw/prebuilt
```

The submodule provides one directory per supported board:

- `hw/prebuilt/XCU200/` — Alveo U200 (DDR4)
- `hw/prebuilt/XCU50/` — Alveo U50 (HBM2)
- `hw/prebuilt/XCU55/` — Alveo U55C (HBM2)

See the bitstreams repository for the supported memory configuration, the
Vivado version, and the checksum of each `.bit` and `.ltx` file.

To build a bitstream yourself instead, see
[Build an FPGA bitstream](build-a-bitstream.md).

## Program a single-target host

For a host with one JTAG target, the programming helper expects a bitstream
and an optional probes file with the same base name:

```bash
export VIVADO_EXEC=/path/to/vivado_or_vivado_lab
hw/scripts/program_fpga.sh XCU200 <bitstream-name-without-extension>
```

## Program a multi-FPGA host or an HBM2 board

For U50/U55C or a multi-FPGA host, use Vivado Hardware Manager or a
board-specific Tcl script and select the exact JTAG target before programming.

## After programming

Restart the host if the programmed PCIe design is not re-enumerated
automatically. Confirm that the board is visible before using it:

```bash
lspci -D -d 10ee:
```
