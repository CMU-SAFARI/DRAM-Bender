# Changes in v2

This page lists what changed in the v2 overhaul relative to the previous
public DRAM Bender release (the pre-v2 `master` branch of
[CMU-SAFARI/DRAM-Bender](https://github.com/CMU-SAFARI/DRAM-Bender)). v2 is a
ground-up restructuring of the repository: the hardware projects were
modernized and pruned, the host software was rewritten as an installable C++
library with a first-class Python API, the XDMA driver became a clearly
identified fork, and the single long README was replaced by this documentation
tree.

## Supported boards

| | Before v2 | v2 |
|---|---|---|
| Supported boards | Bittware XUSP3S, XUPP3R, XUPVVH; Alveo U200, U50 | Alveo U200, U50, U55C |
| Vivado versions | 2018.2 / 2019.2 / 2020.2 (per board) | 2024.2 (all boards) |
| Prebuilt bitstreams | `.bit` files committed in `prebuilt/` | Separate submodule repository at `hw/prebuilt` |

- The Bittware XUSP3S, XUPP3R, and XUPVVH projects were removed. The
  maintained boards are the AMD/Xilinx Alveo U200 (external DDR4), U50
  (on-board HBM2), and U55C (on-board HBM2); see
  [supported boards](supported-boards.md).
- The Alveo U55C is a new board. The former single HBM2 target was split into
  distinct U50 and U55C variants with their own Vivado projects
  (`hw/projects/U50-HBM`, `hw/projects/U55-HBM`), board configurations, and
  program targets.
- All maintained Vivado projects were upgraded to Vivado 2024.2 and rebuilt
  around new top modules and constraints; generated IP output products, cached
  runs, and other Vivado clutter are no longer committed.
- Alveo U250 support is in progress. `hw/projects/U250` contains a Vivado
  project whose DRAM Bender sources are identical to the U200's, so on the
  software side the U250 is driven like a U200: the DDR4 program target and
  the U200 board configuration apply to it as-is. The project itself has not
  yet been brought to the U200 baseline (Vivado 2024.2 upgrade, 32K
  instruction memory, its own board configuration entry, and prebuilt
  bitstreams are pending).
- Program instruction capacities are now board-specific and documented: 32K
  instructions on U200 and U50, 128K on U55C (see the [ISA reference](isa.md)).
- The HBM2 images expose 16 channels per board. The U55C additionally exposes
  2 stack IDs (SIDs) and channel broadcast.
- Prebuilt bitstreams moved out of the main repository into the
  [`dram-bender-prebuilt-bitstreams`](https://github.com/CMU-SAFARI/dram-bender-prebuilt-bitstreams)
  submodule, mounted at `hw/prebuilt` with per-board directories `XCU200/`,
  `XCU50/`, and `XCU55/`.

## Repository layout

The old `projects/` + `sources/` + `prebuilt/` split became a conventional
monorepo:

| Before v2 | v2 |
|---|---|
| `projects/<BOARD>/` (with generated files) | `hw/projects/<BOARD>/` (sources only) |
| `sources/hdl/` | `hw/rtl/`, `hw/sim/` |
| `sources/scripts/`, `prebuilt/programFPGA.sh` | `hw/scripts/` (`generate.tcl`, `program_fpga.sh`) |
| `sources/api/` | `include/drambender/`, `src/`, `python/drambender/` |
| `sources/apps/` | `examples/` and `internal_tests/` |
| `sources/xdma_driver/` | `xdma/` |
| — | `docs/`, `CMakeLists.txt`, `pyproject.toml`, `build.sh`, `setup_venv.sh` |

Checked-in binaries (prebuilt app executables, driver build artifacts) and
stale submodule entries were removed. Project directories are now named after
the boards they target.

## Host software

The previous release shipped flat C++11 sources that every application
compiled directly via a hand-written Makefile, depended on Boost
(`boost::lockfree`), and included an experimental pybind11 binding
(`pySoftMC`). v2 replaces all of that:

- **C++ library.** The API is now a C++20 CMake library (`DRAMBender`,
  namespace `DRAMBender::`) with public headers under `include/drambender/`,
  an exported CMake package, and no Boost dependency. See the
  [C++ API reference](cpp-api.md).
- **Python package.** Python is now a first-class, supported API rather than
  an experiment: the `drambender` package (Python ≥ 3.10) is built with
  nanobind and scikit-build-core, installs with `pip install -e .`, and ships
  typed stubs. `setup_venv.sh` bootstraps a working environment in one step.
  See the [Python API reference](python-api.md).
- **Unified board API.** The `SoftMCPlatform` class was replaced by a single
  board abstraction (`IBoard` in C++, `open_board()` in Python) shared by DDR4
  and HBM2 boards. Board differences are captured by per-board memory targets
  (`DDR4Target`, `HBM2U50Target`, `HBM2U55CTarget`) instead of separate code
  paths, so the same program templates run on every board.
- **Board configuration registry.** Hardware constants (instruction capacity,
  DRAM command slot timing, channel/pseudo-channel/SID counts, capability
  flags) live in one C++ `BoardConfig` registry, exposed to Python as
  `board_configs.U200/U50/U55C`. Python no longer maintains a second set of
  hardware constants.
- **Program construction.** The raw `SMC_*` instruction encoders remain, and
  Python adds a `ProgramBuilder` with register allocation and named reserved
  registers, target-aware built-in programs (`read_row`, `write_row`,
  single/double-sided RowHammer), and a `@program_template` JIT that traces a
  Python template once and compiles it to a native plugin (requires g++ ≥ 11).
- **Software VM.** Programs can be dry-run and DRAM command traces (with
  cycle-accurate timing) extracted on the host without hardware, replacing the
  old Vivado-based debug flow as the first validation step.
- **New instructions.** The ISA gained `INFO` and `SLEEP`; the DRAM command
  slot timing model is documented per board. See the [ISA reference](isa.md).
- **smcLang removed.** The flex/yacc `smc_parser` and the `.smc` program file
  format were dropped in favor of the Python API.

## Readback protocol

The readback engine and host receive path were redesigned around framed
metadata (all boards use the same format):

- Each readback batch is preceded by a 32-byte metadata packet declaring its
  size, and a final marker signals program completion, so the host no longer
  infers completion from read sizes or idle intervals. Programs with long
  silent phases (for example retention experiments) now complete
  deterministically, with explicit timeouts.
- Readback buffering was reduced to fewer copies, and the U200 readback path
  has reproducible benchmarks under `internal_tests/`.
- The protocol is a compatibility boundary between the bitstream and the host
  software: v2 host software requires v2 bitstreams. See
  [the readback protocol](../explanation/readback-protocol.md).

## XDMA driver

The bundled Xilinx XDMA driver became an explicit, documented fork:

- The kernel module was renamed `drambender_xdma` so it cannot collide with
  the stock `xdma` module; device and sysfs names stay upstream-compatible.
- The fork rebases on upstream branch 2020.2 and adds a kernel compatibility
  layer (compile-tested from Linux 5.4 through current kernels).
- The C2H receive path is a credit-based cyclic byte stream (ring grown from
  256 to 8192 pages) matched to the new readback protocol, with constant-time
  scatterlist lookup.
- Endpoint ownership is enforced in the driver: a second open of an H2C/C2H
  endpoint returns `EBUSY`.
- New scripts separate concerns: `build_driver.sh` (compile only),
  `load_driver.sh` (load with required parameters, diagnose, roll back on
  failure), and `install_access.sh` (udev rules plus a dedicated `drambender`
  group, so tests no longer run as root).
- Every deviation from upstream is listed in `xdma/CHANGES-vs-upstream.md`;
  the rationale is in [why the driver is a fork](../explanation/xdma-fork.md).

## Endpoint selection and multi-board hosts

The old API hardcoded `/dev/xdma0_h2c_0` / `/dev/xdma0_c2h_0`. In v2,
applications select an endpoint by canonical PCI BDF (`dddd:bb:ss.f`) plus an
XDMA channel; the library resolves the device nodes through sysfs and verifies
both directions belong to the same PCI function. This makes multi-card hosts
and multi-channel U200 setups first-class; see
[identify an endpoint](../how-to/identify-an-endpoint.md) and
[use multiple boards](../how-to/use-multiple-boards.md).

## Reliability and recovery

- `full_reset()` recovers a board from interrupted readback, failed program
  uploads, and killed processes; the API performs it automatically on receive
  timeouts, asynchronous errors, and Ctrl+C, and the same handle stays usable
  afterwards.
- Resetting one XDMA channel is isolated from its sibling channel on the same
  card, and this isolation is tested in both directions.
- Readback timeouts are explicit API parameters instead of implicit waits.

## Telemetry

The U55C exposes power and thermal telemetry through the Alveo Card
Management Subsystem: five voltage rails and two HBM stack temperatures, each
with instant/max/average statistics, readable at any time without a running
program. The old API only exposed an HBM temperature read. See
[read power telemetry](../how-to/read-power-telemetry.md).

## Testing and qualification

The previous release had no software test suite. v2 adds `internal_tests/`, a
qualification suite with two layers:

- **Host tests** (no hardware, run via CTest): readback protocol framing and
  recovery, board configuration registry, VM timing, endpoint resolution, CMS
  telemetry decoding against a fake register map, driver deployment checks,
  and Python API/interruption tests.
- **Hardware qualification profiles** (explicitly named board runs):
  read/write integrity sweeps, full-reset recovery, HBM2 channel
  addressing/aliasing isolation, multi-card and multi-endpoint concurrency,
  interruption (SIGINT/SIGKILL) recovery, seeded readback/retention fuzzing,
  soak tests, and reproducible U200 readback benchmarks with recorded
  provenance.

## Examples and documentation

- `sources/apps/` was split: teaching material moved to `examples/` (a unified
  read/write example covering all three boards, RowHammer examples in Python
  and C++, and an 11-section tutorial notebook), while stress and
  qualification programs moved to `internal_tests/`. Prior-work reproduction
  apps (QUAC-TRNG, the TCAD case studies) were removed from this repository.
- The single 574-line README was replaced by a short entry-point README plus
  this [Diátaxis-structured documentation tree](../README.md) (tutorials,
  how-to guides, reference, explanation). The ISA and API references now live
  in the repository instead of external documents.
