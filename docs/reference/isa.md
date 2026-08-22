# ISA Reference: Instruction Format and Registers

This page lists the facts of the DRAM Bender instruction set. For how the
pipeline executes these instructions, see
[Hardware architecture](../explanation/architecture.md).

## Program size limit

The maximum number of submitted instructions per program depends on the board:

| Board | Instruction capacity |
|---|---|
| Alveo U200 | 32,768 (32 K) |
| Alveo U50 | 2,048 (2 K) |
| Alveo U55C | 131,072 (128 K) |

These limits come from the built-in `BoardConfig` records listed under
[Supported boards](supported-boards.md#board-configuration).

Long-running experiments normally use loops rather than unrolling every DRAM
command on the host.

## Registers and local state

DRAM Bender exposes 16 32-bit registers. Seven have conventional names used by
the Python builder:

| Register | Purpose |
|---|---|
| `CASR` | Column-address stride |
| `BASR` | Bank-address stride |
| `RASR` | Row-address stride |
| `CAR` | Current column address |
| `BAR` | Current bank address |
| `RAR` | Current row address |
| `PATTERN_REG` | Source for the wide write-data register |

Registers 7 through 15 are available to user programs. `ProgramBuilder`
allocates them by name. The core also contains scratchpad storage and a wide
write-data register populated with `LDWD` instructions.

## Instruction format

Every instruction word is 64 bits. The most significant encoding bits select
one of two forms:

1. One scalar or control instruction.
2. Four packed 16-bit DRAM mini-operations.

Scalar and control instructions include:

- `LI`, `MV`, `ADD`, `ADDI`, `SUB`, and `SUBI`;
- `AND`, `OR`, `XOR`, and `SRC` (a one-bit circular right shift);
- scratchpad `LD` and `ST`;
- `LDWD` and performance-counter reads;
- `SLEEP`, self-refresh entry/exit, conditional branches, and jumps.

The user-facing DRAM mini-operations include:

- `PRE`, `ACT`, `RD`, `WR`, `REF`, and `NOP`;
- HBM channel and pseudo-channel selection;
- address auto-increment flags;
- rank selection and auto-precharge.

## Timing model

Four mini-operation slots make command placement explicit. The duration of one
DRAM command slot depends on the board design:

| Board | DRAM command clock | Slot duration |
|---|---|---|
| Alveo U200 | 666.67 MHz | 1.5 ns |
| Alveo U50 | 600 MHz | 1.67 ns (5/3 ns) |
| Alveo U55C | 600 MHz | 1.67 ns (5/3 ns) |

The software VM uses `FinalProgram.default_dram_inst_latency` when no slot
duration is supplied explicitly. Target-aware Python builders initialize that
property from the selected target's `BoardConfig`. Independently, the VM
defaults to four mini-operation slots per fabric cycle, matching every
maintained board configuration. Pass
`dram_inst_latency` or `num_dram_insts_per_fabric_cycle` explicitly to
`dry_run()` or `trace_dram_commands()` when modeling a bitstream with different
timing or packing:

```python
result = program.dry_run(max_instructions=1_000_000, dram_inst_latency=1.25)
trace = program.trace_dram_commands(
    dram_inst_latency=1.25,
    num_dram_insts_per_fabric_cycle=4,
)
```

Most scalar instructions consume one fabric cycle, while a branch resolves in
six fabric cycles. Include these cycles when calculating command spacing.

The programmer is responsible for meeting, measuring, or deliberately
violating the relevant DRAM timing constraints. The FPGA does not turn an
arbitrary program into a JEDEC-compliant command sequence.

## Encoding definitions

The authoritative encoding definitions are:

- [`hw/rtl/header_verilog/encoding.vh`](../../hw/rtl/header_verilog/encoding.vh)
- [`hw/rtl/header_verilog/parameters.vh`](../../hw/rtl/header_verilog/parameters.vh)
- [`include/drambender/api/program/instruction.h`](../../include/drambender/api/program/instruction.h)
- [`python/drambender/api/program/`](../../python/drambender/api/program/)
