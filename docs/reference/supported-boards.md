# Supported Boards

The following boards are officially supported and maintained:

| Board | Memory | Python program target | DRAM command slot | Vivado | Project |
|---|---|---|---|---|---|
| AMD/Xilinx Alveo U200 | External DDR4 UDIMM or RDIMM | `DDR4Target` | 1.5 ns (666.67 MHz) | 2024.2 | [`hw/projects/U200`](../../hw/projects/U200) |
| AMD/Xilinx Alveo U50 | On-board HBM2 | `HBM2U50Target` | 1.67 ns (600 MHz) | 2024.2 | [`hw/projects/U50-HBM`](../../hw/projects/U50-HBM) |
| AMD/Xilinx Alveo U55C | On-board HBM2 | `HBM2U55Target` | 1.67 ns (600 MHz) | 2024.2 | [`hw/projects/U55-HBM`](../../hw/projects/U55-HBM) |

The DRAM command slot duration is what the software VM uses as
`dram_inst_latency`; see the [timing model](isa.md#timing-model).

C++ applications use `DRAMBender::DDR4` for U200 and `DRAMBender::HBM2` for
U50/U55C.

Prebuilt bitstreams for each board are provided through the `hw/prebuilt`
submodule; see [Obtain a bitstream](../how-to/obtain-a-bitstream.md).

## Board-specific features

- **U200** requires a supported DDR4 module, and its bitstream must match the
  installed DIMM organization and slot.
- **U55C** additionally exposes card power and thermal telemetry; see
  [Read power and temperature telemetry](../how-to/read-power-telemetry.md).
