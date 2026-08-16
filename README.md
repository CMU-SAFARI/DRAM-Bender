# DRAM Bender

DRAM Bender is an FPGA-based infrastructure for experimental DRAM research. It
provides direct control over low-level DRAM commands and their timing while
retaining general-purpose registers, arithmetic instructions, branches, and
program-controlled data movement. Researchers can use these features to study
DRAM reliability, security, performance, and energy behavior.

DRAM Bender builds on [SoftMC](https://github.com/CMU-SAFARI/SoftMC). This
repository contains the Python and C++ APIs, the FPGA RTL, Vivado projects for
the maintained boards, the PCIe driver, and example programs. Both the Python
and C++ APIs are supported. This README uses Python for the program-writing
tutorial and provides C++ build and example references below.

## Cite DRAM Bender

Please cite the following paper if you use DRAM Bender:

Ataberk Olgun, Hasan Hassan, A. Giray Yağlıkçı, Yahya Can Tuğrul, Lois Orosa,
Haocong Luo, Minesh Patel, Oğuz Ergin, and Onur Mutlu, "DRAM Bender: An
Extensible and Versatile FPGA-Based Infrastructure to Easily Test
State-of-the-Art DRAM Chips," *IEEE Transactions on Computer-Aided Design of
Integrated Circuits and Systems*, vol. 42, no. 12, pp. 5098-5112, 2023.

- DOI: <https://doi.org/10.1109/TCAD.2023.3282172>
- Paper: <https://arxiv.org/abs/2211.05838>
- PDF: <https://arxiv.org/pdf/2211.05838.pdf>

```bibtex
@article{olgun2023drambender,
  author  = {Olgun, Ataberk and Hassan, Hasan and Yağlıkçı, A. Giray and
             Tuğrul, Yahya Can and Orosa, Lois and Luo, Haocong and
             Patel, Minesh and Ergin, Oğuz and Mutlu, Onur},
  title   = {{DRAM Bender: An Extensible and Versatile FPGA-Based
              Infrastructure to Easily Test State-of-the-Art DRAM Chips}},
  journal = {IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems},
  year    = {2023},
  volume  = {42},
  number  = {12},
  pages   = {5098--5112},
  doi     = {10.1109/TCAD.2023.3282172}
}
```

## Repository File Structure

```text
.
├── examples/                 # Python and C++ examples and the tutorial
├── hw/
│   ├── rtl/                  # Common DRAM Bender RTL
│   ├── projects/             # Board-specific Vivado projects
│   ├── scripts/              # FPGA programming and generation scripts
│   ├── sim/                  # RTL simulation sources
│   └── prebuilt/             # Released bitstreams and debug probe files
├── include/drambender/       # Public C++ headers
├── python/drambender/        # Python package
├── src/                      # C++ implementation and Python bindings
├── tests/                    # Software tests and hardware diagnostics
├── xdma/                     # DRAM Bender XDMA driver
├── build.sh                  # Local C++ and Python build helper
└── setup_venv.sh             # Python environment setup
```

## Getting Started

### Supported FPGA boards

The following boards are officially supported and maintained:

| Board | Memory | Python program target | Vivado | Project |
|---|---|---|---|---|
| AMD/Xilinx Alveo U200 | External DDR4 UDIMM or RDIMM | `DDR4Target` | 2020.2 | `hw/projects/U200` |
| AMD/Xilinx Alveo U50 | On-board HBM2 | `HBM2Target` | 2020.2 | `hw/projects/U50-HBM` |
| AMD/Xilinx Alveo U55C | On-board HBM2 | `HBM2Target` | 2024.2 | `hw/projects/U55-HBM` |

C++ applications use `DRAMBender::DDR4` for U200 and `DRAMBender::HBM2` for
U50/U55C.

### Hardware prerequisites

- A supported Alveo board installed in a suitable PCIe slot.
- A dedicated Linux host. The U200 also requires a supported DDR4 module.
- A JTAG connection and Vivado Hardware Manager or Vivado Lab for programming.
- A bitstream built for the selected board and memory configuration.
- A host restart when required to enumerate a newly programmed PCIe design.

### Software prerequisites

- Linux 5.4 through 7.0 and the matching kernel headers for the running kernel.
- `make` and a compiler compatible with the running kernel.
- CMake 3.16 or newer.
- `g++` 11 or newer with C++20 support.
- Python 3.10 or newer, `venv`, and the matching Python development headers.
- Git and standard PCI utilities such as `lspci`.

For example, install the common host build dependencies on Ubuntu with:

```bash
sudo apt install build-essential cmake git linux-headers-$(uname -r) pciutils
```

Install the `-dev` and `-venv` packages that match the Python interpreter you
intend to use. For Python 3.12 these packages are commonly named
`python3.12-dev` and `python3.12-venv`.

Pin the kernel and disable unattended kernel upgrades on an experiment host.
Treat a kernel change as a deliberate maintenance operation, then install its
matching headers and rebuild the driver.

### Obtain a bitstream

Prebuilt bitstreams will be distributed separately from the source tree:

- [Alveo U200 bitstreams](TODO-U200-BITSTREAM-URL)
- [Alveo U50 bitstreams](TODO-U50-BITSTREAM-URL)
- [Alveo U55C bitstreams](TODO-U55C-BITSTREAM-URL)

> **TODO before public release:** Replace the links above with the public
> release locations. Each release should list the supported memory
> configuration, Vivado version, and SHA-256 checksum for every `.bit` and
> `.ltx` file.

Place downloaded files under the matching directory in `hw/prebuilt/`. For a
U200 host with one JTAG target, the programming helper expects a bitstream and
an optional probes file with the same base name:

```bash
export VIVADO_EXEC=/path/to/vivado_or_vivado_lab
hw/scripts/program_fpga.sh XCU200 <bitstream-name-without-extension>
```

For U50/U55C or a multi-FPGA host, use Vivado Hardware Manager or a
board-specific Tcl script and select the exact JTAG target before programming.
Restart the host afterward if the programmed PCIe design is not re-enumerated
automatically.

### Install the XDMA driver

> **Note.** This repository ships a **modified fork** of the Xilinx XDMA driver
> (`dma_ip_drivers`, branch `2020.2`), not the stock driver. The kernel module
> is named `drambender_xdma`, and DRAM Bender readback depends on the fork's
> credit-based read path. See [xdma/CHANGES-vs-upstream.md](xdma/CHANGES-vs-upstream.md).
> Do not load the stock Xilinx `xdma` driver at the same time; both match the
> same PCI IDs and the bind order is not deterministic.

DRAM Bender uses a streaming XDMA interface for host-to-card programs and
card-to-host readback. Build it explicitly for the running kernel and load the
result directly from this checkout:

```bash
cd xdma
./build_driver.sh
sudo ./install_access.sh --user "$USER"
sudo ./load_driver.sh
cd ..
```

This procedure does not install an automatic rebuild or module-loading hook.
After restarting the same pinned kernel, run `sudo xdma/load_driver.sh` again.
If the kernel is intentionally changed, rebuild the module before loading it.

The access installer creates a `drambender` group and configures XDMA device
nodes as `root:drambender` with mode `0660`. Start a new login session after
the group membership is changed. Do not run DRAM Bender applications as root
to work around missing permissions.

Verify the module and device nodes:

```bash
modinfo xdma/xdma/drambender_xdma.ko
readlink -f /sys/bus/pci/drivers/xdma/module
ls -l /dev/xdma*
```

### Identify an FPGA endpoint

The Linux driver creates names such as:

```text
/dev/xdma0_h2c_0
/dev/xdma0_c2h_0
```

The fields have the following meanings:

| Field | Meaning |
|---|---|
| `xdma0` | Driver probe-order index |
| `h2c` or `c2h` | Host-to-card or card-to-host direction |
| final `_0` | XDMA channel on that PCI function |

These nodes remain the transport endpoints used by the API. Selecting by BDF
does not replace their direction or channel semantics. It provides a stable
way to find the correct pair without relying on the probe-order prefix.

The direction and channel names are meaningful, but the `xdmaN` number is not
a persistent physical-board identity. Probe order can change after a driver
reload, a host restart, or a hardware change. Applications therefore select an
endpoint using the complete PCI BDF and XDMA channel:

```text
0000:01:00.0, XDMA channel 0
```

List Xilinx PCI functions and inspect the XDMA sysfs paths:

```bash
lspci -D -d 10ee:
readlink -f /sys/class/xdma/xdma*_h2c_*
```

The canonical BDF has the form `dddd:bb:ss.f`. The API resolves the requested
BDF and channel to the current H2C/C2H device-node pair and verifies that both
directions belong to the same PCI function. Use a separate board handle for
each independent BDF/channel endpoint.

### Install the Python API

Clone the repository and create the development environment:

```bash
git clone https://github.com/CMU-SAFARI/DRAM-Bender.git
cd DRAM-Bender
PYTHON_BIN=python3.12 bash setup_venv.sh
source .venv/bin/activate
python -c 'import drambender; print(drambender.__file__)'
```

Set `PYTHON_BIN` to another Python 3.10 or newer interpreter if needed. Set
`CXX=/path/to/g++-11-or-newer` before running the setup script when the default
compiler is too old.

### Run a small DDR4 read/write test

[`examples/read_write.py`](examples/read_write.py) writes one U200 DDR4 row,
reads it back, and compares every returned word:

```bash
python examples/read_write.py \
    --pci-bdf 0000:01:00.0 \
    --xdma-channel 0 \
    --bank 0 \
    --row 0 \
    --pattern 0xDEADBEEF
```

A successful run prints:

```text
PASS: 2048 words matched (pattern=0xdeadbeef)
```

This is a quick endpoint and readback check, not an exhaustive memory test. It
overwrites the selected row. Replace the BDF, channel, bank, row, and pattern
arguments with values appropriate for your system. If the memory geometry
differs, edit the target constants near the top of the example before running
it.

The Python program-building interface is shared by DDR4 and HBM2. The same
`write_row` and `read_row` templates accept either `DDR4Target` or
`HBM2Target`. An HBM2 target carries channel, pseudo-channel, and stack
selections; set them to match the bitstream and experiment. Its raw readback
layout differs from DDR4.

> **TODO before public release:** Add a release-facing
> [U50/U55C HBM2 read/write example](TODO-HBM2-READ-WRITE-EXAMPLE-URL).

## Writing a DRAM Bender Program in Python

A DRAM Bender application has four parts:

1. Describe the memory target.
2. Build one or more programs.
3. Inspect their instruction and timing behavior.
4. Open an FPGA endpoint, execute the programs, and receive any readback.

### Describe the memory target

Use `DDR4Target` for U200 and `HBM2Target` for U50/U55C. Target objects carry
the geometry and address-selection information used by target-aware program
templates.

```python
from drambender.api import DDR4Target, HBM2Target

ddr4_target = DDR4Target(
    cachelines_per_row=128,
    column_stride=8,
    words_per_cacheline=16,
    rank=0,
)

hbm2_target = HBM2Target(
    channel=0,
    pseudo_channel=0,
    sid=0,
    columns_per_row=32,
    column_stride=1,
    words_per_cacheline=16,
)
```

`xdma_channel` selects a host DMA endpoint. The `channel`, `pseudo_channel`,
and `sid` fields in `HBM2Target` select locations within HBM2. They are
different concepts and should not be used interchangeably.

### Build target-aware programs

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

### Inspect and check a program without hardware

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

`summarize_timings()` reports observed tRCD, tRAS, and tRP minima and maxima.
It does not enforce the timing specification of the attached memory. Compare
the reported values with the module data sheet and the operating conditions of
the selected bitstream. Use it as a quick check for a trace addressing one
rank/channel target. The summary groups events by bank, so split interleaved
multi-rank or multi-channel traces before interpreting their timing values.

The VM models the DRAM Bender ISA, control flow, counters, and command timing.
It is not an RTL simulator, an electrical model, or a DRAM data simulator. RTL
simulation sources are under `hw/sim/`.

### Execute and receive readback

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

### Write a custom program

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
arithmetic, logic, scratchpad load/store, `SLEEP`, labels, and branches.

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

The complete tutorial in [`examples/tutorial.ipynb`](examples/tutorial.ipynb)
covers the register file, DRAM slot packing, `DRAMSEQ`, loops, JIT diagnostics,
row mappings, pattern mappings, HBM2 targets, and a complete RowHammer program.

## DRAM Bender Hardware Design and ISA

The main data path is:

```text
Python/C++ API
      |
   PCIe/XDMA
      |
Frontend and instruction memory
      |
Fetch -> Decode -> Execute
      |
DDR4 or HBM2 adapter
      |
     DRAM
      |
Readback engine -> PCIe/XDMA -> host
```

### Frontend and execution pipeline

The frontend receives programs from XDMA, stores instructions, selects between
user programs and maintenance operations, and starts the in-order execution
pipeline. The pipeline fetches and decodes one 64-bit instruction stream and
produces either register/control operations or low-level DRAM operations.

The software accepts programs containing at most 2,048 submitted instructions.
Long-running experiments normally use loops rather than unrolling every DRAM
command on the host.

### Registers and local state

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

### Instruction format

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

Four mini-operation slots make command placement explicit. The default Python
timing model uses a 1.5 ns DRAM slot and four slots per fabric cycle. Pass a
different timing configuration to the VM when inspecting an image with a
different clock. Most scalar instructions consume one fabric cycle, while a
branch resolves in six fabric cycles. Include these cycles when calculating
command spacing.

The programmer is responsible for meeting, measuring, or deliberately
violating the relevant DRAM timing constraints. The FPGA does not turn an
arbitrary program into a JEDEC-compliant command sequence.

### DDR4 and HBM2 adapters

The common pipeline emits target-independent DRAM operations. Board adapters
translate these operations to the interfaces exposed by the DDR4 or HBM2 PHY.
Target objects in the software provide the corresponding geometry, rank,
channel, pseudo-channel, and stack-selection rules.

### Readback engine

DRAM read results enter the readback engine, which batches data into framed
XDMA packets. For each batch, the engine emits a metadata packet that declares
the number of following data beats. A nonempty batch is followed by a data
packet, and a final marker indicates that no more batches belong to the
program. The host API uses these fields rather than depending on
operating-system read boundaries or an interval with no data.

The relevant RTL and encoding definitions are:

- [`hw/rtl/header_verilog/encoding.vh`](hw/rtl/header_verilog/encoding.vh)
- [`hw/rtl/header_verilog/parameters.vh`](hw/rtl/header_verilog/parameters.vh)
- [`hw/rtl/verilog/frontend.v`](hw/rtl/verilog/frontend.v)
- [`hw/rtl/verilog/softmc_pipeline.v`](hw/rtl/verilog/softmc_pipeline.v)
- [`hw/rtl/verilog/readback_engine.v`](hw/rtl/verilog/readback_engine.v)
- [`include/drambender/api/program/instruction.h`](include/drambender/api/program/instruction.h)
- [`python/drambender/api/program/`](python/drambender/api/program/)

### Extending the ISA

Adding an instruction normally requires coordinated changes in several layers:

1. Define the encoding in the RTL headers.
2. Decode and execute the instruction in the FPGA pipeline.
3. Add the C++ instruction encoder.
4. Expose it through `ProgramBuilder` and the Python bindings.
5. Model its behavior in the software VM.
6. Add formatting and software tests for its encoding and timing.

Keeping these layers together ensures that printed programs, dry runs, traces,
and hardware execution describe the same instruction stream.

## Multi-Board and Multi-Channel Systems

Each open board handle owns one `(PCI BDF, XDMA channel)` endpoint. A second
process cannot open the same endpoint while it is in use. Different channels
on the same FPGA and endpoints on different FPGAs may be used independently
when the bitstream provides separate controllers.

Do not persist `xdmaN` as a physical-card identifier. Record the complete PCI
BDF and channel with experiment results. If a card is moved to another slot,
discover its BDF again before running an experiment.

## C++ API

Build the C++ library without Python:

```bash
bash build.sh --cxx-only release
```

Install it to a prefix:

```bash
cmake --install build/cxx-release --prefix /path/to/prefix
```

CMake consumers can use the exported target:

```cmake
find_package(DRAMBender CONFIG REQUIRED)
target_link_libraries(my_experiment PRIVATE DRAMBender::DRAMBender)
```

When installing to a nonstandard prefix, add that prefix to
`CMAKE_PREFIX_PATH` while configuring the consuming project.

See [`examples/read_write.cpp`](examples/read_write.cpp) and
[`examples/single_sided_rowhammer.cpp`](examples/single_sided_rowhammer.cpp).

## Building FPGA Bitstreams

The maintained Vivado projects are under `hw/projects/`. Common RTL lives under
`hw/rtl/`, and board projects provide the memory controller, constraints, XDMA
configuration, and top-level adapter for each FPGA.

Before building a U200 image, select a memory-controller configuration and
constraints that exactly match the installed DIMM and slot. Use the Vivado
version listed in the supported-board table.

> **TODO before public release:** Add board-specific build instructions and
> document the exact source and tool version used for each released bitstream.

Software VM checks and RTL simulation serve different purposes. Use
`FinalProgram.dry_run()` and `trace_dram_commands()` to inspect program control
flow and command timing. Use the sources under `hw/sim/` and the board's Vivado
simulation environment to inspect RTL handshakes and PHY-facing behavior.

## Troubleshooting

### No `/dev/xdma*` nodes appear

- Confirm that the FPGA is programmed and visible in `lspci -D`.
- Confirm that `drambender_xdma` is loaded.
- Inspect the kernel log for probe or PCIe errors.
- Confirm that the bitstream exposes paired H2C and C2H streaming channels.

### Opening the endpoint reports `Device or resource busy`

Another process owns that BDF/channel endpoint. Close the existing board
handle or terminate the process cleanly. Use context managers in notebooks and
scripts so ownership is released promptly.

### The example receives the wrong amount of data

Check the selected target, rank/channel coordinates, program read count, and
buffer size. A U200 bitstream must also match the installed DIMM organization
and slot.

### Recovering after an interrupted application

Open the intended endpoint and call `full_reset()` before submitting another
program. This resets FPGA logic, cancels and drains old readback, and clears the
software queue.

### Device nodes are not accessible as a normal user

Verify membership in the `drambender` group and start a new login session after
running `xdma/install_access.sh`.

## Prior Work Using DRAM Bender

Sources for reproducing two studies that use DRAM Bender are available in
separate repositories:

- [U-TRR](https://github.com/CMU-SAFARI/U-TRR)
- [QUAC-TRNG](https://github.com/CMU-SAFARI/QUAC-TRNG)

## Contributing

Contributions that add experiments, improve the APIs, extend the ISA, or add a
new board adapter should include documentation and software tests. Hardware
changes should identify the target board, memory configuration, Vivado version,
and constraints used to generate the image.

Use the repository issue tracker for bug reports and feature requests.

## License

DRAM Bender is distributed under the terms in [`LICENSE`](LICENSE).

> **TODO before public release:** Restore the top-level license file and confirm
> the copyright statement for this release.
