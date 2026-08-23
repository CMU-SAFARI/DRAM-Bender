# Python API Reference

A compact map of the public Python surface. The
[program-writing tutorial](../tutorials/writing-programs.md) shows every item
below in running code, and
[`examples/tutorial.ipynb`](../../examples/tutorial.ipynb) covers the complete
feature set.

## Board configurations

The API provides one immutable `BoardConfig` for each maintained design:

| Object | Board type | Memory type |
|---|---|---|
| `drambender.api.board_configs.U200` | `BoardType.U200` | `MemoryType.DDR4` |
| `drambender.api.board_configs.U50` | `BoardType.U50` | `MemoryType.HBM2` |
| `drambender.api.board_configs.U55C` | `BoardType.U55C` | `MemoryType.HBM2` |

A configuration exposes `name`, `board_type`, `memory_type`,
`instruction_capacity`, `dram_command_slot_ns`,
`dram_slots_per_fabric_cycle`, `readback_buffer_capacity`,
`hbm_channel_count`, `hbm_pseudo_channel_count`, `hbm_sid_count`,
`broadcast_supported`, and `power_telemetry_supported`. Call `summary()` for a
formatted overview.

Targets expose the matching object as `target.board_config`. An opened board
exposes it as the read-only `board.board_config` property. The built-in values
describe what the API expects from the programmed bitstream; they are not
queried from the FPGA image.

## Memory targets

| Object | Board | Key fields |
|---|---|---|
| `drambender.api.DDR4Target` | U200 | `cachelines_per_row`, `column_stride`, `words_per_cacheline`, `rank` |
| `drambender.api.HBM2U50Target` | U50 | `channel`, `pseudo_channel`, `sid` (1 SID, no broadcast) |
| `drambender.api.HBM2U55CTarget` | U55C | `channel`, `pseudo_channel`, `sid` (2 SIDs, broadcast) |

`HBM2Target` is the abstract base of the two HBM2 targets (useful for
`isinstance` checks); it cannot be instantiated. The HBM2 targets default to
`columns_per_row=32`, `column_stride=1`, and `words_per_cacheline=16`.

The `channel`, `pseudo_channel`, and `sid` fields select locations within
HBM2. They are unrelated to `xdma_channel`, which selects a host DMA endpoint.

## Built-in programs

`drambender.builtin_programs.configure(target=...)` binds the built-in
templates to a target. Available templates include row read/write
(`read_row`, `write_row`) and single-sided and double-sided RowHammer
programs. Each template returns a `FinalProgram`.

## `FinalProgram`

Building a program does not open or access the FPGA. A `FinalProgram` can be
inspected, held, reused, and submitted later.

| Member | Purpose |
|---|---|
| `print(program)` | Decoded instruction stream |
| `instruction_count` | Number of encoded instructions |
| `default_dram_inst_latency` | Default DRAM command slot in ns; target-aware Python builders set it from `target.board_config`, while raw construction uses the U200 default |
| `dry_run(max_instructions=...)` | Software-VM execution report: instructions, branches, registers, timing, DRAM-command counts |
| `trace_dram_commands()` | Timestamped DRAM-command trace; `trace.truncated` flags an incomplete trace |
| `trace.summarize_timings()` | Observed tRCD, tRAS, and tRP minima and maxima (observational, not a specification check) |

## Board access

| Member | Purpose |
|---|---|
| `drambender.api.open_board(target_or_type, pci_bdf=..., xdma_channel=..., host_interface=HostInterface.XDMA)` | Open one `(PCI BDF, XDMA channel)` endpoint from a target, `BoardConfig`, or `BoardType.U200`, `BoardType.U50`, or `BoardType.U55C`; usable as a context manager |
| `board.board_config` | Read-only `BoardConfig` selected for this board |
| `board.execute(programs)` | Submit one program or a list/tuple; readback is delivered in program order |
| `board.receive_into(buffer, timeout=None)` | Fill a preallocated, writable, C-contiguous buffer whose size is a multiple of four bytes |
| `board.synchronize()` | Wait for outstanding work |
| `board.reset_fpga()` | Reset FPGA logic during a normally synchronized session |
| `board.full_reset()` | Additionally cancel active readback, drain stale host data, and clear queued software readback |

Exiting the context manager releases the endpoint but does not itself perform
a full hardware reset. The API performs `full_reset()` before raising when
`receive_into()` times out, when it surfaces an asynchronous readback error,
or when Ctrl+C interrupts a receive or synchronization wait on the main Python
thread.

Opening a board prints its configuration summary and states that the API
expects the programmed bitstream to match. This message reports the selected
API configuration; it is not bitstream auto-detection.

## Custom programs

`drambender.api.ProgramBuilder` is the instruction-level DSL:
`LI`/`MV`/arithmetic, `DRAM(...)` with four explicit mini-operation slots,
`DRAMSEQ(...)`, `ALIGN()`, `SLEEP`, labels, and branches. `conclude()`
resolves labels, appends termination, and inserts readback metadata. The
instruction list is in the [ISA reference](isa.md).

## JIT controls

`@program_template` compiles a traced builder as a cached C++ plugin.
Controls live in `drambender.api.jit`:

| Function | Purpose |
|---|---|
| `get_last_template_run_stats()` | Whether the last template call compiled or reused a cached specialization |
| `set_jit_cache_dir(path)` | Choose the cache location before the first template call |
| `clear_template_caches(clear_disk=True)` | Discard the compiled cache |

## Power telemetry (U55C)

`drambender.api.HBM2U55C` exposes `read_power_telemetry()`; `HBM2U50` reports
`power_telemetry_supported == False`. See
[Read power and temperature telemetry](../how-to/read-power-telemetry.md) for
the rail and sensor fields.
