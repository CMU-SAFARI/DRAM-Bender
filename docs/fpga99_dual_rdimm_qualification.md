# FPGA99 dual-RDIMM U200 qualification for the clean metadata-v1 stack

Date: 2026-08-09

## Executive summary

The clean `new-repo` API, metadata-v1 readback protocol, and updated XDMA
driver passed functional, interruption, isolation, and performance
qualification on `safari-fpga99`: Ubuntu 24.04, Linux
`7.0.0-28-generic`, six U200 cards, two populated RDIMM channels per card, and
twelve independently addressed `(PCI BDF, XDMA channel)` endpoints.

All twelve DDR4 interfaces calibrated after programming and again after the
required host reboot. Sequential native-C++ smoke tests, a barrier-aligned
twelve-process isolation test, standard and soak fuzzing, long in-program and
host-side waits, endpoint ownership checks, SIGINT recovery, and SIGKILL
recovery all passed. The completed functional runs contain no data mismatch,
transport failure, reset failure, endpoint-cross-talk symptom, or new relevant
kernel message. After the performance phase, the exact driver was unloaded,
reloaded, and reprobed; all 24 stream nodes returned and the full functional
recovery gates passed again.

With each endpoint assigned both SMT threads of one distinct physical core,
native C++ delivered 27.558 GiB/s across all twelve endpoints, 97.79% of the
28.181 GiB/s isolated sum. Median endpoint p50 changed only from 212.240 us in
isolation to 212.469 us under full load. Release Python reached 26.929 GiB/s,
97.72% of native, with 220.370 us median p50. Across the complete performance
matrix, 202,000 timed transfers completed with zero mismatched words.

This establishes the requested new-kernel, multicard, dual-channel case as a
functional, performance, and clean-deployment release pass. The former
same-name module collision and temporary-ACL caveats are resolved: the final
driver is uniquely named `drambender_xdma`, installed and auto-rebuilt by DKMS,
and creates persistent `root:drambender` mode `0660` stream nodes through udev.
A host reboot auto-loaded the installed module with credit mode enabled,
preserved non-root access, and passed another all-twelve-endpoint test with zero
AER counters or kernel-log delta.

## Scope and intended operating model

This report covers DRAM-Bender's `new-repo` branch only. It does not use
`dram-inspector`, and it does not provide compatibility with the legacy raw
readback protocol. The operating model is:

1. select a board endpoint by complete PCI BDF plus XDMA channel;
2. allow only one DRAM-Bender owner of an endpoint at a time;
3. use metadata-v1 to determine packet sizes and the end of an execution,
   never a short read or a silence timeout;
4. permit arbitrarily long normal receives by default, with an explicit
   timeout only when requested by the caller; and
5. use `full_reset()` as the recovery boundary after interruption, timeout,
   malformed/incomplete readback, or a process killed before cleanup.

## Tested hardware and exact provenance

### Host and endpoints

- Host: `safari-fpga99.ee.ethz.ch`
- OS/kernel: Ubuntu 24.04.4, Linux `7.0.0-28-generic`
- FPGA cards: six Xilinx Alveo U200 devices, PCIe Gen3 x8
- Populated memory endpoints: both RDIMM channels on every card
- PCI BDFs: `0000:01:00.0`, `0000:21:00.0`, `0000:22:00.0`,
  `0000:41:00.0`, `0000:42:00.0`, and `0000:61:00.0`
- XDMA channels tested per BDF: 0 and 1, for twelve endpoints total

The driver exposed twelve H2C and twelve C2H stream nodes for channels 0 and
1. Linux's `xdmaN` numbering did not follow PCI order and must not be used as
card identity. The API resolved the requested BDF/channel through sysfs and
verified the character-device major/minor again after opening it.
The observed post-boot order was `xdma0` -> BDF 61, `xdma1` -> 41, `xdma2` ->
42, `xdma3` -> 21, `xdma4` -> 22, and `xdma5` -> 01; that order is descriptive,
not an interface contract.

### FPGA image

- Bitstream: `dual_rdimmx4_rdimmx4.bit`
- Bitstream SHA-256:
  `7eec7f06d72da42a41768fc22e3a4ad03a26688fc759427ba1005b3e75eb0865`
- Debug probes: `dual_rdimmx4_rdimmx4.ltx`
- LTX SHA-256:
  `fec5d01441a447fc2866623325e681e2ae9d4533c5d13854252373ac18885433`
- Programming tool: Vivado 2020.2

The six programmed JTAG serials were:

- `22100106100TA`
- `22100105Y03WA`
- `22100105Z008A`
- `21290605800HA`
- `22100105Z01GA`
- `221001061047A`

The image exposes two MIG debug cores with UUIDs
`88C96E55DF6F55F2B2DD820544662868` and
`B7CE0C0F516C50D2B0F7ECB7BF1E01D6`. After the host reboot, all twelve MIGs
reported terminal write/read sanity `PASS`, `CALIBRATION_FAIL=FALSE`, and DDR
calibration error code `000` (`CAL_PASS_TOTAL|12`).

The current image has no software-readable cryptographic build ID. The hashes,
explicit per-serial programming log, reboot, and post-boot MIG query establish
the intended image, but the running FPGA cannot independently attest the file
hash.

### Software and driver

- Performance measurements and validation checkout:
  `1cb6ec55dd559e5c736e9ba5f2640cad6b31592c`
- Safe interruption-harness commit:
  `3c857555aa84cf8226a02eaa994d2d6532b136ae`
- Post-reload sibling-isolation test checkout:
  `37a6c7a9bf2a12275addc011b04c5f3258ef04cf`
- Unique module identity and persistent-access commit:
  `f00e425a7e4b04873498d620d17dac68ce6fc82f`
- Final DKMS build fix and deployed repository state:
  `80500f6f9225d1e70279b29adef4cb3f9774ecfc`
- Standard/soak fuzz checkout: `40cdbec0c380acdfa3f6d6b00a9010034a113d15`
- Native benchmark executable SHA-256:
  `988dd5e6e4457b0df4b89b9ab92217bbdff3a6cdad0c7ab32bbefefcc0417bc7`
- Installed Python extension SHA-256:
  `927471f49e0a7af21670a93ccecc7a6ea6ea5d411880ef4f9216b9a118a4875d`
- Python: 3.12.3; native compiler: GCC 13.3.0, C++20
- Performance-phase out-of-tree XDMA driver version: 2020.2.2
- Performance-phase module file:
  `/home/safari/new-repo/build/xdma-stage-8455fb3-k7.0.0-28/xdma/xdma/xdma.ko`
- Performance-phase driver `srcversion`: `8E13BEADC02B4431ABA2736`
- Performance-phase driver module SHA-256:
  `ddbc905bcf06b95b2baea4c8c5402db7c040a8d9376ed9d31d1715e846552aa9`
- Performance-phase driver ELF build ID:
  `62a7d10c64b08280a44fd63640444f3e85c844d8`
- Final module name: `drambender_xdma`, version 2020.2.2
- DKMS package: `drambender-xdma/0.1.0`, status `installed`
- Installed module:
  `/lib/modules/7.0.0-28-generic/updates/dkms/drambender_xdma.ko.zst`
- Installed compressed-module SHA-256:
  `563ecb4f08efd0473b4b93425669db74287bd453ba8c4832915829449693d61a`
- Final loaded/installed `srcversion`: `8E13BEADC02B4431ABA2736`
- Driver vermagic: `7.0.0-28-generic SMP preempt mod_unload modversions`
- Cyclic C2H configuration: 8,192 pages (32 MiB), 512 initial credits,
  streaming C2H credit mode enabled, and 10 s per-driver H2C/C2H operation
  timeout

The 8,192-page ring retains scattered, DMA-mapped pages but uses the new flat
SG-pointer index, so current-page lookup is O(1) rather than a walk from the
start of the scatterlist.

Commits `f00e425` and `80500f6` change module identity, deployment scripts,
udev/modprobe configuration, test provenance lookup, and DKMS's top-level build
invocation; they do not change the XDMA cyclic/readback data path. The final
module has the same `srcversion` and runtime parameters as the measured module.
Accordingly, the performance results below measure the identical driver source
under its prior artifact name and do not need to be rerun merely for the clean
rename/packaging change. The renamed direct-build, DKMS-loaded, and post-reboot
installed paths were each functionally requalified.

## Functional qualification results

| Test | Coverage | Result |
|---|---|---:|
| Post-boot MIG check | 6 cards x 2 DDR4 interfaces | 12/12 pass |
| Sequential native-C++ smoke | completion, 64 B, and 8 KiB on all 12 endpoints; exact verification and final `full_reset()` | 12/12 pass, 0 mismatches |
| Concurrent isolation smoke | 12 spawned endpoint owners, 25 barrier-aligned write/read iterations each | 300/300 executions pass; 614,400 words verified |
| Concurrent isolation qualification | same 12 workers, 250 iterations each, endpoint-specific bank/row/pattern | 3,000/3,000 executions pass; 6,144,000 words verified |
| Standard seeded fuzz | 94 cases per endpoint | 1,128 cases, 0 failures, 0 mismatched words |
| Soak seeded fuzz | 546 cases per endpoint | 6,552 cases, 0 failures, 0 mismatched words |
| Endpoint ownership | same endpoint/direction reopened while held; sibling channel opened independently | 24/24 expected `EBUSY`; sibling opens pass |
| Real process interruption | SIGINT and SIGKILL sequence on every endpoint | 12/12 pass for both signals and recovery |
| Performance correctness | 40 result directories, 101 endpoint runs, 2,000 timed 512-KiB transfers per run | 202,000 transfers, 0 mismatched words |
| Driver reload/reprobe | unload and explicitly reload the exact candidate module | pass; all 24 stream nodes reprobed |
| Post-reload multicard smoke | 12 workers x 25 tagged write/read iterations | 300/300 pass; 614,400 words verified |
| Sibling reset isolation | on each card, reset one channel during the other's active six-second session, both directions | 12/12 pass; both active and resetting endpoints' canaries match |
| Post-reload self-attesting interruption rerun | SIGINT and SIGKILL on every endpoint | 12/12 pass, 0 failures |
| Direct renamed-module gate | `drambender_xdma` direct build, all 12 endpoints x 25 plus one SIGINT/SIGKILL case | 300/300 pass; signal/recovery pass |
| DKMS-installed module gate | load installed `.ko.zst`, verify source/config/nodes, all 12 endpoints x 25 | pass; 300/300 exact iterations |
| Host-reboot deployment gate | automatic module load, persistent group/mode, all 12 endpoints x 25 | pass; AER totals zero, dmesg smoke delta empty |

### Readback sizes, packetization, and API orderings

Each standard and soak fuzz worker exercised 34 payload sizes: 1, 2, 3, 4,
7, 8, 15, 16, 31, 32, 47, 48, 49, 63, 64, 65, 95, 96, 97, 127, 128, 129,
149, 150, 151, 255, 256, 257, 299, 300, 301, 511, 512, and 513 cachelines.
That spans 64 B through 32,832 B and deliberately crosses cacheline, row, and
multi-row boundaries. Patterns covered zero, ones, checkerboard, walking, and
endpoint-tagged data. Receive calls covered whole and fragmented buffers,
including randomized partitions and one-word-at-a-time delivery. Program/API
orderings covered separate execution, queued write/read execution, and
`synchronize()` before receive.

The standard profile also ran 50 independent short readback sessions per
endpoint; the soak profile ran 500, for 6,000 short sessions across the twelve
endpoints in the soak alone. Every returned byte count and value was checked.

### Long waits and retention-style workflows

The tests directly cover both required retention usage patterns:

- One FPGA program containing multiple read groups separated by 0.15 s, 1 s,
  and 6 s gaps; soak adds a 12 s gap. Metadata, not silence, terminated the
  readback session.
- Execute a write-only program, synchronize, sleep in Python, execute a
  separate read program, receive, and synchronize. Host delays were 0, 0.15,
  1, and 6 s; soak adds 12 s.
- Start readback, delay host consumption for 6 s, and then receive the queued
  data.
- Leave the normal receive unbounded beyond the former 5 s behavior.
- Request a deliberate 250 ms receive timeout, perform automatic
  `full_reset()`, and immediately reuse the same board handle.

All twelve endpoints completed these transport/framing checks. The tested
RDIMM rows also happened to show zero changed words at every host-retention
delay, but that is only a DRAM observation; transport success is established by
the exact expected byte count, valid session termination, and successful reuse.

### Interruption and stale-data recovery

For each endpoint, a child began a program with a six-second FPGA delay and
blocked in readback:

- With SIGINT, the Python interruption path invoked `full_reset()` and raised
  `KeyboardInterrupt`; the same board handle then wrote/read and verified an
  endpoint-tagged 8 KiB canary. Measured interruption/recovery times were about
  0.787-0.790 s.
- With SIGKILL, the killed process could not clean up. A fresh process opened
  the endpoint, called `full_reset()`, and verified a different tagged 8 KiB
  canary.

No driver reload, FPGA reprogramming, or host reboot was needed between the
kill and recovery. This validates the intentionally simple policy: graceful
interruptions reset automatically; after an ungraceful process death, the next
owner begins with `full_reset()`.

The authoritative post-reload rerun is self-attesting: it records the Python
extension hash, driver `srcversion`, and interruption-script SHA-256
`e15c0808bb844cf00bc6b0d037046ba4960d1b3c96bfb62f18c3e9f926ade726`.
It again passed SIGINT, same-handle reuse, SIGKILL, and fresh-process recovery
on all twelve endpoints.

### Driver reload and sibling-reset isolation

After performance, with every endpoint idle, the exact candidate module was
unloaded and reloaded by explicit file path. The loaded `srcversion` remained
`8E13BEADC02B4431ABA2736`; all six PCI functions reprobed with two H2C and two
C2H channels, giving 24 stream nodes. A 12-worker x 25-iteration tagged
write/read test then passed on the reloaded driver.

The final isolation gate checked the subtle same-card case in both directions.
For every U200, one channel began a six-second active FPGA session. About 100 ms
after it armed, its sibling called `full_reset()`, completed that reset in about
0.54 s, and verified a tagged canary. The active channel's payload completed
about 5.35-5.36 s after the sibling reset and also matched exactly. All twelve
`active ch0/reset ch1` and `active ch1/reset ch0` cases passed, including final
resets. This demonstrates that a channel-local recovery does not reset or
corrupt its sibling's active DRAM/readback session.

### Clean deployment and host-reboot validation

The final deployment removes ambiguity with Ubuntu's unrelated in-tree `xdma`
module while preserving the public PCI driver, sysfs class, and `/dev/xdma*`
interface:

- the kernel module is uniquely named `drambender_xdma`;
- DKMS 3.0.11 installed package `drambender-xdma/0.1.0` and the signed,
  compressed module under `/lib/modules/.../updates/dkms/`;
- `/etc/modprobe.d/drambender-xdma.conf` sets
  `enable_st_c2h_credit=1` for automatic loads; and
- `/etc/udev/rules.d/70-drambender-xdma.rules` assigns every XDMA stream node
  to `root:drambender` with mode `0660`; user `safari` is in that group.

The direct renamed module first passed a twelve-endpoint x 25 test and one
self-attesting SIGINT/SIGKILL recovery case. The installed DKMS module was then
loaded by name, reported the expected path, `srcversion`, credit setting, and 24
nodes, and passed the same twelve-endpoint x 25 test.

Finally, the host was rebooted. PCI modalias handling automatically loaded
`drambender_xdma`; the modprobe credit setting and all 24 udev ownership/mode
assignments persisted without manual ACLs. A non-root post-boot twelve-endpoint
x 25 test passed. Its privileged dmesg delta was empty, all final AER totals
were zero, and all endpoints were idle.

### Kernel and PCIe observations

No functional run produced a new relevant kernel message. The complete boot
log contains the expected out-of-tree/unsigned-module taint and the driver's
timeout configuration message; these are not runtime readback failures.

Immediately before the performance phase, every exported sysfs AER correctable,
nonfatal, and fatal counter was zero on all six cards. Five cards already had
sticky `UnsupReq`/`AdvNonFatalErr` status bits in `lspci -vv`; BDF
`0000:41:00.0` was clear. Those bits predated the measurements and their origin
was not established.

The authoritative before/after sysfs AER snapshots were byte-identical and all
counters remained zero. The privileged kernel-log delta contained no lines at
all during performance. After the explicit driver reload, the log contained
the expected remove/probe messages and unrelated firmware-notifier AppArmor
audit messages, but no XDMA/readback error. Final health again found all AER
counters zero, all 24 stream nodes idle, and no benchmark process. The Vivado
`hw_server` used for programming was stopped cleanly.

## Performance and scaling

Every measurement used the same 512-KiB workload: 8,192 reads over 64 complete
8-KiB rows, one correctness preflight, 20 untimed warmups, and 2,000 timed
iterations per endpoint. The timed region starts immediately before
`execute()` and ends when `synchronize()` returns; setup, validation, and final
reset are excluded. Native C++ is the primary measurement and Release Python is
the API-overhead cross-check.

For the deployment configuration, endpoint `i` was allowed logical CPUs
`{i,i+16}`: both SMT threads of one physical core, with a distinct physical
core per endpoint. This accommodates the API's caller and receiver threads.
The six XDMA IRQs were pinned away from worker cores and CPU governors were held
at `performance` during measurement.

| Configuration | Isolated sum | Concurrent sum | Efficiency | Median endpoint p50 |
|---|---:|---:|---:|---:|
| Native C++, SMT-pair CPUs, all 12 | 28.181 GiB/s | 27.558 GiB/s | 97.79% | 212.469 us |
| Python, SMT-pair CPUs, all 12 | n/a | 26.929 GiB/s | 97.72% of native | 220.370 us |
| Native C++, one logical CPU, all 12 control | 25.787 GiB/s | 24.167 GiB/s | 93.72% | 257.994 us |
| Python, one logical CPU, all 12 control | n/a | 22.617 GiB/s | 93.58% of native control | 270.487 us |

The native deployment median endpoint p50 was 212.240 us in the twelve
isolated runs and 212.469 us with all twelve endpoints active. Python retained
97.72% of native aggregate throughput and its p50 was only 3.72% higher. In
contrast, giving each endpoint its SMT pair rather than one logical CPU
improved native all-machine throughput by 14.03% and reduced median p50 by
17.65%. The one-CPU run is a scheduling-constrained control, not a
readback-engine or PCIe limit and not the recommended deployment.

The one-logical-CPU control also measured every sibling pair and six cards on
channel 0:

| Concurrent group | Isolated sum | Concurrent sum | Efficiency |
|---|---:|---:|---:|
| U200 `01:00.0`, channels 0+1 | 4.217 GiB/s | 4.122 GiB/s | 97.75% |
| U200 `21:00.0`, channels 0+1 | 4.316 GiB/s | 4.089 GiB/s | 94.75% |
| U200 `22:00.0`, channels 0+1 | 4.301 GiB/s | 4.134 GiB/s | 96.11% |
| U200 `41:00.0`, channels 0+1 | 4.332 GiB/s | 4.200 GiB/s | 96.94% |
| U200 `42:00.0`, channels 0+1 | 4.327 GiB/s | 4.157 GiB/s | 96.06% |
| U200 `61:00.0`, channels 0+1 | 4.293 GiB/s | 4.193 GiB/s | 97.68% |
| Six cards, channel 0 | 12.932 GiB/s | 12.473 GiB/s | 96.45% |

### Correctness, equivalence, and ring-position analysis

The validator accepted 40 result directories containing 101 endpoint runs and
202,000 timed transfers. Every process exited zero, every `run_end` and final
`full_reset()` passed, every expected payload digest matched, and the total
mismatched-word count was zero. For each endpoint, C++ and Python recorded an
identical workload descriptor: payload and geometry, static/dynamic instruction
counts, DRAM cycles, read/write counts, setup count, and expected digest.

The 512-KiB payload alone spans 128 4-KiB pages, while separate metadata EOPs
and packet-boundary fragmentation consume additional descriptors; exact ring
advance therefore varies with RBE packetization. The retained 64-phase median
diagnostic predicted at most 0.34% end-to-end latency change across isolated
runs, with five positive and seven negative slopes. Under native all-twelve
load its maximum prediction was 1.24%, with two positive and ten negative
slopes. This is an iteration-period diagnostic, not a claimed physical wrap
period. Maximum lag-64 autocorrelation was 0.104 isolated and 0.033 under full
load. Separately, every 2,000-call run necessarily crossed at least 31 complete
rings from payload descriptors alone, and none showed the prior repeated
rising ramp followed by a wrap reset. The mixed 64-phase slopes and absence of
a common lag-64 signature are further inconsistent with that old sawtooth.
Rare scheduler outliers exist, but native endpoint p99 remained below 258 us.

### Host restoration and health

After measurement, all 32 CPU governors were restored exactly to their
pre-test `powersave` state. All six XDMA IRQs were restored to configured
affinity `0-31` and effective CPUs 6 through 11. An independent restoration
validator reported zero governor, IRQ, idle-endpoint, or lingering-process
errors. AER counters were unchanged and the performance kernel-log delta was
empty.

One early same-card-pair artifact ending in `20260809T183942Z-62912` is invalid
and remains excluded: a shared FIFO launch gate allowed one worker to consume
both tokens and left its sibling blocked. The fixed runner uses one private
gate per worker; its gate smoke passed. The invalid directory is absent from
`perf-run-paths.txt`, `PERFORMANCE_SHA256SUMS`, and the final evidence manifest.

## Clean deployment and remaining protocol scope

### Deployment packaging: resolved

The former module-name collision and temporary-permission caveats are closed.
`modinfo drambender_xdma` resolves uniquely to the DKMS-installed DRAM-Bender
module; Ubuntu's unrelated module may keep its `xdma` name without ambiguity.
Automatic boot-time loading uses the required credit option, and udev gives all
current and future card/channel stream nodes persistent least-privilege group
access. The installer does not replace a live driver implicitly; deliberate
module replacement remains a maintenance-window operation after endpoints are
quiesced. That is an operational safety contract, not unfinished packaging.

### Metadata-v1 is deliberately minimal

One 32-byte metadata beat carries a 12-bit payload-beat count and one
end-of-session bit; the remaining bits must be zero. It has no magic/version
field, endpoint/session ID, sequence number, or payload checksum. Metadata and
payload are separate TLAST/EOP packets. Under the tested exclusive-owner and
`full_reset()` recovery model this is sufficient and robust, including long
silent programs, but it has two consequences:

- stale bytes after an ungraceful owner death cannot be identified from an ID;
  the next owner must call `full_reset()` before reuse; and
- the separate metadata/payload packets add receive-side operations and some
  throughput cost relative to the legacy raw RBE.

The qualification provides no reason to redesign the RBE for the clean
cutover. Protocol enrichment or packet coalescing should remain an optional,
separately measured follow-up rather than a release requirement.

### Endpoint and scope limits

- A single endpoint is intentionally single-owner; concurrency is across
  independent BDF/channel tuples.
- The current FPGA cannot expose the loaded image hash to software.
- This result qualifies the new-kernel U200/RDIMM multicard case. Old-kernel
  U200 and U50/U55 results belong in their respective reports and should not be
  inferred from this one.
- Legacy raw-RBE compatibility is intentionally absent.

## Evidence and integrity

Primary evidence is stored remotely under:

- `/home/safari/new-repo/data/qualification/fpga99-rdimm-20260809/`
- `/home/safari/new-repo/data/qualification/fpga99-rdimm-20260809/final-clean-deployment/`
- `/home/safari/new-repo/artifacts/fpga99/`
- `/home/safari/new-repo/artifacts/bitstreams/`

Key files and hashes:

| Evidence | SHA-256 |
|---|---|
| Post-boot twelve-MIG verification log | `813997dc45622509bc1334113173a69ba6c65244bcb6a4daa0a3c535ebe5df91` |
| Sequential-smoke result index | `1344853cf99086f2681c98a3f515f3a83fc33d9bdc3fa5de2646c8da3ece1314` |
| 12 x 25 concurrent log | `26fb74dad9b073c4bbbd3571476d8e4597df18e6c563a804dba5a1a143ad50be` |
| 12 x 250 concurrent log | `3257b08ca7eee05e1e14d9c7233db8b728787feb99ab5fb6bdf14f3ee48613d2` |
| Endpoint-ownership JSONL | `de9b1d8e00b0f0cc03a09fd2eb8f04c8994af21b101d59c6b64a7c32fbdf3c6d` |
| Authoritative post-reload SIGINT/SIGKILL JSONL | `7bdab8deaa0247bca0c7cba3855846a2de3cf62a27b8a5be6794ac3d09842ba8` |
| Sibling-reset isolation JSONL | `9f25843d7b250c3e61a0749840147f290c0db42414757f0508aaa96f3494db70` |
| Driver reload/reprobe record | `20b187605138c87aa056facf6a1af9c31affe4067016272a5ef5f04f28ca977d` |
| Post-reload 12 x 25 log | `d99dc63f542d5a03b711cad8af6acee0f5b0b045f3801bb50aa02e39017dd40e` |
| Performance summary | `4b537f27a64c6b8885aa1f5b9beda919fc2eb77ecf4c1aa352445c40593c2b26` |
| Machine-readable performance validation | `00ab99b3edcb3d34fac2c67d5066e7b59f9a0f136f203e8cde3e776575505a5b` |
| Machine-readable performance analysis | `b8e309ebdd926149a21a372f32b1960bf9300ddf071ad653e3b8de55775f51ea` |
| Performance manifest, 863 entries | `2a3429e129eaac5b7f0f9321ed994617fa9d97cdb41c38a79f3042cfa0a6a5de` |
| Host restoration validation | `edc71abbdc98a92a91ca61a20e3528c747cd234f81d0b8fb84b416594bf666fd` |
| Final post-reload health | `8325b33207e7fd054deb1165fb5983b310c0150a65217bb3b2e48db29ab64c03` |
| Vivado hardware-server cleanup | `48714ff0475d4fc1c22c5c69293fe31cb1a7e8fdb16308388657375aa70dbd7b` |
| Pre-performance AER counter snapshot | `83bf08d32a4a74007a7c4aa98a740ab364d54399d28cc51aac59cef7e04bb00a` |
| Full post-soak kernel log | `745e1d7ade2d2a88b658133057a623b1a77b3f2d9e89323ef39a3a55357357a0` |
| Filtered post-soak kernel log | `0a238245f1ffe54620ac346ae9db660a0a46671ac5fae22312a6ced2435f79c6` |
| Pre-deployment evidence manifest, 929 entries | `f053aa8bca0c1f0878da2040d873c2b4180cb74d33ead7ea68b6b22f59aec1de` |
| Installed DKMS `.ko.zst` | `563ecb4f08efd0473b4b93425669db74287bd453ba8c4832915829449693d61a` |
| Clean-deployment manifest, 61 entries | `816134400043152eb81de7be566ff34376f30b942f40489c8ab4f8616493ce8a` |
| Combined final evidence manifest, 993 entries | `09de56fc27a0930fb2d6c79dea65bfea4f463ad48f217f9b87bc95278f5600be` |

The programming `SHA256SUMS` manifest and both fuzz
`SHA256SUMS.final` manifests were rechecked with `sha256sum -c` and passed.
The fuzz manifests each cover 40 files and have these hashes:

- Standard:
  `41dcbf73ed0d0adede52caf0761accfeddab06cc358f7db11a8beee2e5e8903b`
- Soak:
  `f0edc103d385ddee9db335d99d4a3a1f460710746a14dd0ba5b702540e6bb810`

Every result directory in `perf-run-paths.txt` passed its own `SHA256SUMS`
verification. `PERFORMANCE_SHA256SUMS` covers the 40 accepted directories,
runners, analyzers, validation, and host-health captures; its 863 entries
verify successfully. The invalid partial gate run is absent.

The 61-entry `final-clean-deployment/DEPLOYMENT_SHA256SUMS` covers the unique
direct module, DKMS install and reload, persistent access, direct/DKMS/reboot
functional runs, reboot state, AER and dmesg evidence, and endpoint-idle check.
It verifies successfully.

`FINAL_EVIDENCE_SHA256SUMS_CLEAN_DEPLOYMENT` is the authoritative combined
qualification manifest. Its 993 absolute-path entries combine the earlier 929
bitstream, functional, fuzz, performance, recovery, and health artifacts with
all clean-deployment evidence. A fresh `sha256sum -c` verification of all 993
entries returned success. The older four-, 863-, and 929-entry manifests remain
useful phase snapshots but are superseded as the final integrity root.

## Release conclusion

**Functional verdict:** pass for six U200 cards and both RDIMM channels on the
new Ubuntu 24.04/kernel 7.0 host.

**Performance verdict:** pass. Native C++ sustains 27.558 GiB/s over all twelve
endpoints at 97.79% scaling efficiency, and Python retains 97.72% of native
throughput. All 202,000 measured transfers were correct, with no ring-position
sawtooth, AER increment, or performance-phase kernel message.

**FPGA99 stack and clean-deployment verdict:** release pass. The exact module
reload/reprobe and all recovery/isolation gates passed; the uniquely named DKMS
module auto-loaded after a host reboot with its required credit setting;
persistent least-privilege permissions worked; final AER totals are zero;
endpoints are idle; host settings are restored; the hardware server is stopped;
and the combined 993-entry evidence manifest verifies. No driver/API/RBE or
FPGA99 deployment action remains from this qualification.
