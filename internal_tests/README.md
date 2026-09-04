# DRAM Bender Internal Tests

This directory contains the qualification suite used to develop and release
DRAM Bender. It is separate from `examples/`: internal tests assert API,
driver, protocol, recovery, and hardware behavior, while examples teach the
public API without deployment-specific test machinery.

Board tests are never registered with CTest and are never selected
implicitly. A board-facing run must name a profile and supply every PCI
endpoint it may open.

## Entry point

`run_tests.py` is the common entry point. It prints each command, streams its
output, reports elapsed time and status, stops after the first failure by
default, and returns a nonzero status if a case fails. `--keep-going` runs the
remaining cases. `--dry-run` prints the plan without executing it.

```bash
python internal_tests/run_tests.py host
python internal_tests/run_tests.py board --profile u200-smoke \
  --pci-bdf dddd:bb:ss.f --xdma-channel 0
```

Use `--json-results PATH` to choose the runner summary path. Every non-dry
board run writes a summary, defaulting below `build/internal-test-results/`.
Profiles with detailed recovery, fuzz, or performance records write JSONL in
the same artifact directory. Existing result files are never overwritten.

## Host-only tests

The `host` profile configures `build/internal-tests` with `BUILD_TESTING=ON`,
builds it, and runs every CTest labeled `host`:

```bash
python internal_tests/run_tests.py host
```

Run `bash setup_venv.sh` first. The preset deliberately enables
`BUILD_TESTING`, enables the Python bindings, and leaves board test and board
benchmark targets disabled. The extension is built directly into the editable
source package, so the Python API tests exercise that exact target rather than
an older installed copy. No FPGA device is opened.

The host suite covers:

| Test | Coverage |
| --- | --- |
| `program_metadata_test.cpp` | Final-program read count, target metadata, and instruction-RAM limits |
| `board_config_test.cpp` | Built-in board configuration values, validation, target selection, and capability reporting |
| `vm_timing_test.cpp` | VM instruction timing and DRAM-command trace timestamps |
| `readback_protocol_test.cpp` | Framing, fragmented reads, completion, malformed metadata, timeout, interruption, automatic `full_reset()`, and reuse of the same handle |
| `xdma_device_resolver_test.cpp` | Complete PCI BDF validation and deterministic XDMA endpoint resolution |
| `cms_telemetry_test.cpp` | U55C CMS parsing and telemetry capability behavior without hardware |
| `driver_deployment_test.sh` | Explicit driver build/load boundary, fixed streaming credit, access rules, paired-device discovery, and failed-load rollback |
| `python_interrupt_test.py` | Python signal interruption at the native binding boundary |
| `target_api_test.py` | Python target API, board configs, built-in programs, JIT lowering, and VM defaults |
| `multi_endpoint_interrupt_harness_test.py` | Offline process cleanup and result handling for interrupt recovery |
| `sibling_reset_isolation_harness_test.py` | Offline orchestration, overlap validation, hashes, and recoverable child cleanup |

Individual groups can be selected with CTest labels, for example:

```bash
cmake -E chdir build/internal-tests ctest --output-on-failure -L readback
cmake -E chdir build/internal-tests ctest --output-on-failure -L recovery
cmake -E chdir build/internal-tests ctest --output-on-failure -L python
```

The driver deployment test performs static and mocked shell checks only. It
does not build, load, or install a kernel module and does not use `sudo`. DKMS
is not required. The supported workflow is an explicit `build_driver.sh`,
`load_driver.sh`, and optional access-rule installation.

## Board profiles

Board tests require the intended bitstream, the matching API configuration,
the explicitly built and loaded `drambender_xdma` driver, permissions for the
selected device nodes, and exclusive use of the listed endpoints.

| Profile | What it runs |
| --- | --- |
| `u200-smoke` | Small C++ and Python DDR4 read/write checks followed by basic `full_reset()` recovery in both APIs |
| `u200-correctness` | Matching C++ and Python DDR4 row sweeps plus a non-gating Python VM-to-hardware timing report |
| `u200-recovery` | C++ and Python active/stale-read cancellation and same-handle reuse, plus Python-orchestrated SIGINT, SIGKILL, and fresh-process recovery |
| `u200-fuzz` | Seeded standard readback fuzzing over sizes, receive partitions, patterns, program shapes, timeouts, FPGA sleeps, and host retention waits |
| `u200-soak` | Longer seeded fuzz and retention run with the same assertions |
| `hbm2-smoke` | Matching C++ and Python HBM2 read/write checks for U50 or U55C, a Python channel-isolation sweep, plus U55C telemetry |
| `multiboard-correctness` | Barrier-aligned concurrent read/write integrity on every supplied endpoint |
| `multiboard-recovery` | Interrupt recovery on every endpoint and `full_reset()` isolation in both channel directions on every supplied board |
| `u200-performance` | Matching current C++ and Python readback workloads with correctness checks and full provenance |

Examples:

```bash
python internal_tests/run_tests.py board --profile u200-fuzz \
  --pci-bdf dddd:bb:ss.f --xdma-channel 0

python internal_tests/run_tests.py board --profile hbm2-smoke --board u55c \
  --pci-bdf dddd:bb:ss.f --xdma-channel 0
```

`rowhammer_test.{cpp,py}` remains a characterization-oriented board tool. A
bit flip is an experimental observation, not a transport-correctness failure,
so it is not part of the automated pass/fail profiles.

### Multiboard topology

Supply multiboard endpoints with repeated arguments or a JSON topology file:

```bash
python internal_tests/run_tests.py board \
  --profile multiboard-correctness \
  --endpoint dddd:bb:ss.f/0 \
  --endpoint dddd:bb:ss.f/1 \
  --expected-board-count 1 \
  --expected-endpoint-count 2 \
  --require-complete-dual
```

```json
{
  "format": "drambender.internal-test-topology",
  "expected_board_count": 1,
  "expected_endpoint_count": 2,
  "endpoints": [
    {"pci_bdf": "dddd:bb:ss.f", "xdma_channel": 0},
    {"pci_bdf": "dddd:bb:ss.f", "xdma_channel": 1}
  ]
}
```

The maintained six-board qualification uses both RDIMM channels on every
U200, so its deployment-owned topology declares six boards and twelve
endpoints. The repository does not store its hostname or BDF allocation. Use
`--profile multiboard-recovery` only with complete channel pairs; the runner
validates that requirement before starting a process.

## Reset, interruption, and retention behavior

Board tests establish a clean readback boundary with `full_reset()` before or
after cases where stale data or an active receiver is possible. Recovery is
considered complete only after a verified write/read succeeds. The recovery
profiles specifically cover Ctrl+C/SIGINT, forced child termination, fresh
process recovery, and reuse of an existing board handle.

The fuzz suite separates transport correctness from DRAM retention results.
Receiving the exact framed payload is mandatory. Bit differences observed
after an intentional refresh-off delay are recorded as retention observations
and do not by themselves fail the transport test.

If the top-level runner is interrupted, it stops and returns 130. The active
test owns device cleanup because it has the board handle and enough context to
perform the correct `full_reset()`. If a process was killed before cleanup,
run the recovery profile before continuing with other work.

## C++ board binaries

Board-facing C++ tests and benchmarks are build targets, not CTests. This
prevents an ordinary `ctest` invocation from touching hardware.

Before every board profile, the runner configures
`build/internal-board-tests` as a dedicated Release build and builds the
current Python extension plus the C++ targets required by that profile. A
failed configure or build is a hard gate, even with `--keep-going`, so a stale
binary is never used for qualification.

```bash
cmake -S . -B build/internal-board-tests \
  -DBUILD_TESTING=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DDRAMBENDER_BUILD_PYTHON=ON \
  -DDRAMBENDER_PYTHON_PACKAGE_DIR="$PWD/python/drambender" \
  -DDRAMBENDER_BUILD_BOARD_TESTS=ON \
  -DDRAMBENDER_BUILD_BOARD_BENCHMARKS=ON
cmake --build build/internal-board-tests
```

Functional profiles run matching Python and C++ tests by default where both
exist. Use `--test-language python` or `--test-language cpp` for a deliberate
single-language diagnostic run. Process interruption, multiboard
orchestration, fuzzing, and telemetry remain Python tools. The C++ HBM2 test
selects U50 or U55C with the same `--board` argument as the Python test.

The performance profile runs both `u200_readback_benchmark.py` and the matching
`drambender_u200_readback_benchmark` binary by default. Select one explicitly
with `--benchmark-language python` or `--benchmark-language cpp`.

## Performance comparison with legacy DRAM Bender

Performance is the last qualification step. Run correctness, recovery,
fuzzing, and the required target matrix first. The current Python and C++
benchmarks construct the same deterministic programs, verify every payload
outside the timed region, and record workload hashes and host, driver, and
bitstream provenance.

Legacy DRAM Bender remains a separate checkout and runtime environment. There
is no compatibility layer and the runner does not switch drivers, branches,
or bitstreams. Collect its matching JSONL baseline once in that environment,
preserve it across any required reboot, then compare it without reopening a
board:

```bash
python internal_tests/run_tests.py compare \
  --baseline legacy.jsonl \
  --candidate build/internal-test-results/RUN/current-cpp.jsonl \
  --candidate build/internal-test-results/RUN/current-python.jsonl
```

The comparator accepts only the current benchmark schema and complete,
passing runs. It requires identical workload sets, payload sizes, and semantic
workload hashes. Raw instruction hashes must be present for provenance but do
not need to match across stacks because transport framing may change encoded
instructions without changing the measured workload. The report shows
candidate-to-legacy median-latency and throughput ratios without imposing a
noise-sensitive pass threshold.

An existing legacy measurement does not need to be rerun when its raw samples,
program dump or source, and provenance are sufficient to materialize this
schema offline. Preserve that normalized file as the baseline. The comparator
itself intentionally contains no parser for an older artifact format.
