# Supported Boards

The following boards are officially supported and maintained:

| Board | Memory | Python program target | Vivado | Project |
|---|---|---|---|---|
| AMD/Xilinx Alveo U200 | External DDR4 UDIMM or RDIMM | `DDR4Target` | 2024.2 | [`hw/projects/U200`](../../hw/projects/U200) |
| AMD/Xilinx Alveo U50 | On-board HBM2 | `HBM2Target` | 2024.2 | [`hw/projects/U50-HBM`](../../hw/projects/U50-HBM) |
| AMD/Xilinx Alveo U55C | On-board HBM2 | `HBM2Target` | 2024.2 | [`hw/projects/U55-HBM`](../../hw/projects/U55-HBM) |

C++ applications use `DRAMBender::DDR4` for U200 and `DRAMBender::HBM2` for
U50/U55C.

Prebuilt bitstreams for each board are provided through the `hw/prebuilt`
submodule; see [Obtain a bitstream](../how-to/obtain-a-bitstream.md).

## Board-specific features

- **U200** requires a supported DDR4 module, and its bitstream must match the
  installed DIMM organization and slot.
- **U55C** additionally exposes card power and thermal telemetry; see
  [Read power and temperature telemetry](../how-to/read-power-telemetry.md).
