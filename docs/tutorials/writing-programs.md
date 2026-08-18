# Writing DRAM Bender Programs in Python

A DRAM Bender application has four parts:

1. Describe the memory target.
2. Build one or more programs.
3. Inspect their instruction and timing behavior.
4. Open an FPGA endpoint, execute the programs, and receive any readback.

This tutorial walks through each part. It assumes a working installation; if
you do not have one, start with [Getting started](getting-started.md).

## Describe the memory target

Use `DDR4Target` for U200, `HBM2U50Target` for U50, and `HBM2U55Target` for
U55C. (`HBM2Target` is their abstract base; it cannot be instantiated
directly.) Target objects carry the geometry and address-selection
information used by target-aware program templates.

```python
from drambender.api import DDR4Target, HBM2U55Target

ddr4_target = DDR4Target(
    cachelines_per_row=128,
    column_stride=8,
    words_per_cacheline=16,
    rank=0,
)

hbm2_target = HBM2U55Target(
    channel=0,
    pseudo_channel=0,
    sid=0,
)
```

The HBM2 targets default to `columns_per_row=32`, `column_stride=1`, and
`words_per_cacheline=16`; override them only when the bitstream differs.

`xdma_channel` selects a host DMA endpoint. The `channel`, `pseudo_channel`,
and `sid` fields in `HBM2Target` select locations within HBM2. They are
different concepts and should not be used interchangeably.

## Build target-aware programs

The built-in programs are bound to a target once and then used with the same
Python calls for DDR4 or HBM2:

```python
import drambender

target = ddr4_target              # or hbm2_target
programs = drambender.builtin_programs.configure(target=target)

pattern = 0xDEADBEEF
pattern_words = (pattern,) * target.words_per_cacheline

write_program = programs.write_row(bank=0, row=42, pattern=pattern_words)
read_program = programs.read_row(bank=0, row=42)
```

Building a program does not open or access the FPGA. The result is a
`FinalProgram` that can be inspected, held, reused, and submitted later.
Available built-in templates include row read/write and single-sided and
double-sided RowHammer programs.

## Inspect and check a program without hardware

Print a program to see its decoded instruction stream:

```python
print(read_program)
print(f"instructions: {read_program.instruction_count}")
```

The software VM executes the control flow and reports instruction, branch,
register, timing, and DRAM-command information:

```python
result = read_program.dry_run(max_instructions=1_000_000)
print(result)
print(result.dram_cmd_counts)
```

Generate a timestamped DRAM-command trace and summarize three common timing
relationships:

```python
trace = read_program.trace_dram_commands()
if trace.truncated:
    raise RuntimeError("DRAM command trace was truncated")

print(trace)
print(trace.summarize_timings())
```

The VM's reported times use the DRAM command slot of the program's target:
1.5 ns (666.67 MHz) on U200 and 5/3 ns (600 MHz) on U50/U55C. Pass
`dram_inst_latency` to `dry_run()` and `trace_dram_commands()` only to
override that default; see the
[timing model](../reference/isa.md#timing-model).

`summarize_timings()` reports observed tRCD, tRAS, and tRP minima and maxima.
It does not enforce the timing specification of the attached memory. Compare
the reported values with the module data sheet and the operating conditions of
the selected bitstream. Use it as a quick check for a trace addressing one
rank/channel target. The summary groups events by bank, so split interleaved
multi-rank or multi-channel traces before interpreting their timing values.

The VM models the DRAM Bender ISA, control flow, counters, and command timing.
It is not an RTL simulator, an electrical model, or a DRAM data simulator. RTL
simulation sources are under [`hw/sim/`](../../hw/sim/).

## Execute and receive readback

The following block continues with the `ddr4_target` programs built above. It
uses a context manager so endpoint ownership is released promptly:

```python
import numpy as np
from drambender.api import HostInterface, open_board

readback = np.empty(
    ddr4_target.cachelines_per_row * ddr4_target.words_per_cacheline,
    dtype=np.uint32,
)

with open_board(
    ddr4_target,
    pci_bdf="0000:01:00.0",
    xdma_channel=0,
    host_interface=HostInterface.XDMA,
) as board:
    board.full_reset()
    board.execute([write_program, read_program])
    board.receive_into(readback, timeout=5.0)
    board.synchronize()

expected = np.full_like(readback, pattern)
np.testing.assert_array_equal(readback, expected)
```

`board.execute()` accepts one program or a list/tuple of programs. Readback is
delivered in program order. `receive_into()` writes into a preallocated,
writable, C-contiguous buffer whose size is a multiple of four bytes.

The default `timeout=None` waits without a deadline, including across long
retention intervals. A finite receive timeout is useful for bounded
applications. The API performs `full_reset()` before raising when
`receive_into()` times out, when it surfaces an asynchronous readback error, or
when Ctrl+C interrupts a receive or synchronization wait on the main Python
thread. Call `full_reset()` explicitly when abandoning in-flight work or when
opening a board after an uncleanly terminated process.

`reset_fpga()` resets the FPGA logic during a normally synchronized session.
`full_reset()` additionally cancels active readback, drains stale host data,
and clears queued software readback. Exiting the context manager releases the
endpoint but does not itself perform a full hardware reset.

## Write a custom program

`ProgramBuilder` is a Python DSL for DRAM Bender instructions. The example
below constructs a one-cacheline DDR4 read. It uses named registers, explicit
DRAM mini-operation placement, and fabric-cycle sleeps:

```python
from drambender.api import ProgramBuilder, program_template
from drambender.api.program.instructions import ACT, NOP, PRE, RD

target = ddr4_target

@program_template
def build_read_cacheline(bank: int, row: int, column: int):
    p = ProgramBuilder(target=target)

    p.LI(bank, "BAR")
    p.LI(row, "RAR")
    p.LI(column, "CAR")

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    p.DRAM(RD("BAR", "CAR"), NOP(), NOP(), NOP())
    p.SLEEP(4)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)

    return p.conclude()

program = build_read_cacheline(bank=0, row=42, column=0)
```

`DRAM(...)` always contains four explicit 16-bit DRAM mini-operations. Use
`NOP()` for an unused slot. `DRAMSEQ(...)` and `ALIGN()` provide a convenient
way to describe longer timed command sequences. Scalar instructions include
arithmetic, logic, scratchpad load/store, `SLEEP`, labels, and branches. The
complete instruction list is in the
[ISA reference](../reference/isa.md).

`conclude()` resolves labels and branches, appends program termination, and
inserts the read-count metadata consumed by the FPGA readback engine. Users do
not need to generate this bookkeeping manually.

The `@program_template` decorator traces a parameterized builder, compiles it
as a small C++ plugin, and caches the result. Later calls that vary only integer
scalar arguments reuse the loaded plugin. Non-integer arguments, such as a
tuple containing a write pattern, form part of the specialization and are
compiled into it. JIT diagnostics and cache controls are available from:

```python
from drambender.api.jit import (
    clear_template_caches,
    get_last_template_run_stats,
    set_jit_cache_dir,
)
```

Call `get_last_template_run_stats()` after instantiating a template to inspect
whether it compiled or reused a cached specialization. Use
`set_jit_cache_dir()` before the first template call to choose a cache
location, and `clear_template_caches(clear_disk=True)` when the compiled cache
must be discarded.

## Next steps

The complete tutorial in
[`examples/tutorial.ipynb`](../../examples/tutorial.ipynb) covers the register
file, DRAM slot packing, `DRAMSEQ`, loops, JIT diagnostics, row mappings,
pattern mappings, HBM2 targets, and a complete RowHammer program.
