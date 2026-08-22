# Supported Boards

The following boards are officially supported and maintained:

| Board | Python board/config | Python program target | Memory | DRAM command slot | Vivado | Project |
|---|---|---|---|---|---|---|
| AMD/Xilinx Alveo U200 | `BoardType.U200`, `board_configs.U200` | `DDR4Target` | External DDR4 UDIMM or RDIMM | 1.5 ns (666.67 MHz) | 2024.2 | [`hw/projects/U200`](../../hw/projects/U200) |
| AMD/Xilinx Alveo U50 | `BoardType.U50`, `board_configs.U50` | `HBM2U50Target` | On-board HBM2 | 1.67 ns (600 MHz) | 2024.2 | [`hw/projects/U50-HBM`](../../hw/projects/U50-HBM) |
| AMD/Xilinx Alveo U55C | `BoardType.U55C`, `board_configs.U55C` | `HBM2U55Target` | On-board HBM2 | 1.67 ns (600 MHz) | 2024.2 | [`hw/projects/U55-HBM`](../../hw/projects/U55-HBM) |

The DRAM command slot duration is what the software VM uses as
`dram_inst_latency`; see the [timing model](isa.md#timing-model).

C++ applications use `BoardType::U200`, `BoardType::U50`, or
`BoardType::U55C` with `create_board()`. The corresponding concrete classes
are `DDR4`, `HBM2U50`, and `HBM2U55C`.

Prebuilt bitstreams for each board are provided through the `hw/prebuilt`
submodule; see [Obtain a bitstream](../how-to/obtain-a-bitstream.md).

## Board configuration

`BoardConfig` is the API's central description of the parameters fixed by a
board design and bitstream. The built-in configurations are
`board_configs.U200`, `board_configs.U50`, and `board_configs.U55C`. They
contain the board and memory type, instruction and readback capacities, DRAM
command timing, HBM topology, and optional feature support. Their definitions
live in
[`src/api/board/board_config.cpp`](../../src/api/board/board_config.cpp).

Targets expose their configuration as `target.board_config`, and an opened
board exposes the configuration it uses as `board.board_config`. In C++, use
`get_board_config(BoardType::U200)` or the equivalent board type, and
`board->board_config()` after opening the board.

These values are API assumptions, not values discovered from the programmed
FPGA image. Opening a board prints the selected configuration and a reminder
that the bitstream must match it. Check this output before running an
experiment. If a custom bitstream changes any of these parameters, update its
`BoardConfig` in the API and rebuild the software that will use it. Changes to
instruction encoding or command packing also require matching changes to the
program builder and ISA implementation.

## Board-specific features

- **U200** requires a supported DDR4 module, and its bitstream must match the
  installed DIMM organization and slot.
- **U55C** additionally exposes card power and thermal telemetry; see
  [Read power and temperature telemetry](../how-to/read-power-telemetry.md).
