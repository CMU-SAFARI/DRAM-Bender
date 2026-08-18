# ISA Reference: Instruction Format and Registers

This page lists the facts of the DRAM Bender instruction set. For how the
pipeline executes these instructions, see
[Hardware architecture](../explanation/architecture.md).

## Program size limit

The maximum number of submitted instructions per program depends on the board:

| Board | Instruction capacity |
|---|---|
| Alveo U200 | 32,768 (32 K) |
| Alveo U50 | 32,768 (32 K) |
| Alveo U55C | 131,072 (128 K) |

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

The software VM uses the slot duration of the target the program was built
for (stored on the program as `FinalProgram.default_dram_inst_latency`) and
four slots per fabric cycle. Pass `dram_inst_latency` explicitly to
`dry_run()` or `trace_dram_commands()` only when inspecting an image with a
different clock:

```python
result = program.dry_run(max_instructions=1_000_000, dram_inst_latency=1.25)
trace = program.trace_dram_commands(dram_inst_latency=1.25)
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
