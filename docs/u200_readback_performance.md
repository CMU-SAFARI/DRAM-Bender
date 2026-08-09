# DRAM-Bender metadata-v1 readback: diagnosis, fixes, and U200 qualification

Date: 2026-08-09

## Executive summary

The new metadata-v1 readback protocol is not intrinsically slow. The original
new-repo performance regression came from two software implementation issues:

1. The XDMA cyclic receiver found the current DMA page by walking a linked
   scatterlist from its beginning on every read. Increasing the ring from 256
   to 8,192 pages turned this inherited linear lookup into a large,
   ring-position-dependent cost.
2. The API copied readback through several temporary vectors and a
   `std::deque<uint32_t>`, then removed every returned word individually.

Both issues are fixed. The driver retains the robust 8,192-page (32 MiB) ring,
but builds a 64 KiB flat SG-pointer index at ring setup. The API now keeps a
contiguous byte queue, performs bulk delivery, and lets large cyclic reads copy
directly into the protocol payload buffer.

On the same U200, kernel, DIMM, channel, CPU affinity, and byte-identical FPGA
programs, 512 KiB native-C++ latency improved from **926.1 us to 178.6 us p50**,
a **5.18x speedup**. The final result is **1.34x the legacy latency** and reaches
**2.690 GiB/s**, or 73.6% of legacy aggregate throughput. Release Python is
189.4 us p50, only 6.0% above final C++.

The approximately 45 us final C++ gap is receive-side overhead consistent with
metadata-v1's additional EOP-delimited metadata and payload operations. There
is no remaining ring-position sawtooth, fixed 100 ms delay, or Python
bottleneck. No FPGA-execution regression was observed in this U200 comparison.

## Scope and tested stacks

This comparison uses DRAM-Bender itself. It does not use or modify
`dram-inspector`.

### Legacy reference

- Repository/ref: DRAM-Bender `origin/master`
  `7e6fb6476e830fd974943137e27dc4f643b107c1`
- Driver: legacy XDMA 2017.1.47 with `enable_credit_mp=1`
- Driver source contains the same linear SG lookup, but its cyclic ring is only
  256 pages.
- Declared/programmed U200 raw-RBE file SHA-256:
  `da2b70e964fb67e928147b8c22cd2dbb38c4217b5bce7c45a01a4d47eaa234e4`

### Measured metadata-v1 stack

- Driver fix commit: `ca9792d` (`Make cyclic receive lookup constant time`)
- Host/API fix commit: `422acca` (`Reduce readback buffering copies`)
- Reproducible benchmark commit: `edea347`
- Loaded driver:
  - version: 2020.2.2
  - source version: `37AF925418A456732275CEA`
  - module SHA-256:
    `56babd869759035bd4fcf2efbdfad45a9eac2254c610439442e4d1973e6a9c19`
  - build ID: `a05ad5a24c60876ffcd8f1f918e1705d992fc059`
  - `cyclic_rx_pages=8192`
  - `cyclic_initial_credits=512`
  - `enable_st_c2h_credit=1`
- Declared/programmed U200 metadata-v1 file SHA-256:
  `9e41b59a84c395d51e245dd1849205d8fd6f9c14fff55486a3231518f4e4ecbf`

The bitstream files and programming logs establish the intended images, but
the running FPGA exposes no build-ID register with which the host can attest
the loaded image cryptographically.

Later deployment commits `f00e425` and `80500f6` give this driver a unique
module name and add DKMS/udev packaging; they do not change its DMA/readback
data path. The performance measurements therefore remain applicable to the
final packaged stack without another legacy-image reboot cycle.

### Common test environment

- Host: `safari-fpga28`
- OS/kernel: Ubuntu 20.04, Linux 5.4.0-216-generic
- FPGA: U200 at PCI BDF `0000:01:00.0`
- XDMA channel: 0 only; channel 1 was not used
- PCIe: Gen3 x8
- CPU affinity: CPUs 4 and 5 for every primary run
- Each workload: one preflight, five warmups, and 100 measured executions
- Timed region: immediately before `execute()` through return from
  `synchronize()`
- Pattern construction and verification are outside the timed region.
- Every measured payload is checked byte-for-byte and hashed.

The legacy C++ harness, final native-C++ harness, and final Python harness
generate the same finalized instruction bytes. All 79 program streams used by
the five workloads and their setup writes were compared byte-for-byte.

## Final performance comparison

### End-to-end p50 latency

| Payload | Legacy C++ | Final C++ | C++ / legacy | Release Python | Python / C++ |
|---|---:|---:|---:|---:|---:|
| Completion | 23.338 us | 22.556 us | 0.97x | 25.936 us | 1.15x |
| 64 B | 23.974 us | 23.081 us | 0.96x | 27.549 us | 1.19x |
| 8 KiB | 29.454 us | 30.183 us | 1.02x | 34.517 us | 1.14x |
| 64 KiB | 39.238 us | 46.382 us | 1.18x | 50.440 us | 1.09x |
| 512 KiB | 133.763 us | 178.637 us | 1.34x | 189.419 us | 1.06x |

Aggregate mean payload throughput for 512 KiB is 3.6575 GiB/s legacy,
2.6898 GiB/s final C++, and 2.5653 GiB/s Release Python.

At 512 KiB, phase medians are:

| Phase | Legacy C++ | Final C++ | Difference |
|---|---:|---:|---:|
| Execute | 24.724 us | 23.785 us | -0.939 us |
| Receive | 105.391 us | 150.561 us | +45.170 us |
| Synchronize | 3.736 us | 0.147 us | -3.589 us |
| End to end | 133.763 us | 178.637 us | +44.874 us |

Phase medians do not have to sum exactly to the end-to-end median because each
median can come from a different sample.

## Root cause 1: linear scatterlist lookup

The cyclic receive buffer contains ordinary DMA-mapped pages. Before the fix,
each read found page `rx_head` by starting at `sgt->sgl` and calling
`sg_next()` `rx_head` times. The work therefore grew linearly as the head moved
through the ring and reset only when the ring wrapped.

The old and new C++ implementations showed:

- Legacy 256-page ring: approximately flat receive latency.
- New 8,192-page ring: two measured ramps of +16.91 and +18.83 us per 512 KiB
  execution, with R-squared 0.910 and 0.991, followed by a sharp wrap reset.
- Captured sessions consumed roughly 151-152 ring pages per 512 KiB execution;
  the observed discontinuity is consistent with an 8,192-page wrap.

A controlled test changed only the ring to 256 pages. It reduced 512 KiB p50
from 926.1 us to 414.1 us and removed the trend. This proved that the lookup,
not Python or the FPGA program, was the dominant cause.

The permanent fix keeps 8,192 data pages but creates
`cyclic_sg_by_index[page]` once during setup. Lookup is now O(1). A 250-sample
hardware run crossed several full rings with a receive slope of effectively
zero and no wrap discontinuities.

### Why the data ring should still use scattered pages

A 32 MiB CPU-virtual buffer does not imply 32 MiB of physically contiguous DMA
memory. Requiring one physically contiguous 32 MiB allocation is fragile after
uptime and especially wasteful across several cards or channels. Six active
channels would require six such large contiguous allocations.

Linux and the XDMA descriptor engine already support DMA from independent
pages. The clean design is therefore:

- scattered physical pages for reliable allocation and DMA descriptors;
- a flat virtual pointer table for fast CPU indexing.

The pointer table costs about 64 KiB per active 8,192-page receive engine,
compared with the 32 MiB data ring. This provides flat-array lookup speed
without imposing a physically contiguous allocation requirement. `vmalloc()`
alone would not remove the need for DMA page addresses or descriptors; it only
makes the CPU virtual address range contiguous.

## Root cause 2: API copy and queue pipeline

The initial metadata-v1 host path performed the following work for each
payload:

1. Driver ring to an aligned XDMA staging buffer.
2. Staging buffer to `ByteStreamBuffer`.
3. `ByteStreamBuffer` to a packet payload vector.
4. Packet bytes to a newly allocated word vector.
5. Word vector to `std::deque<uint32_t>`.
6. One `front()` and `pop_front()` per returned word.

A 512 KiB result contains 131,072 words. An isolated benchmark measured about
131 us for deque fill and per-word removal, versus about 32 us for a flat
buffer path.

The fixed API stores queued readback as contiguous bytes with an unread offset,
appends packet bytes directly, and bulk-copies to the caller. Partial reads,
unread data spanning queued executions, timeout/reset behavior, and ordering
are preserved. On hardware, this change reduced 512 KiB p50 from 376.6 us to
205.8 us.

The final transport optimization preserves the existing read size and
poll/EAGAIN behavior. Large payload reads target the packet vector directly;
small logical reads such as 32-byte metadata still use the aligned staging
buffer, but only genuine surplus bytes are retained. This reduced 512 KiB p50
again to 178.6 us.

## Why the final result is still slightly slower than legacy

Legacy raw readback emits exactly sixteen 32 KiB payload TLAST packets plus one
32-byte terminator packet for this 512 KiB execution, requiring 17 successful
C2H reads.

Metadata-v1 deliberately emits metadata and payload as separate TLAST/EOP
packets. Two captured 512 KiB sessions contained respectively 17 metadata plus
17 payload EOP packets and 18 metadata plus 18 payload EOP packets. The payload
packets were split across 25 and 27 successful `read(2)` returns, producing 42
and 45 successful C2H reads in total. Compared with legacy, the extra 25-28
userspace operations need to cost only roughly 1.6-1.8 us each to account for
the final 45 us receive gap. That includes syscall/completion handling,
metadata parsing, thread handoff, and remaining small copies.

This accounting is consistent with the residual arising from the existing v1
protocol and driver fragmentation; it is not evidence of another ring-size
bug. Increasing the userspace receive quantum or changing RBE packet layout may
reduce it, but those are optional follow-ups rather than correctness fixes.
They should be evaluated as separate changes so v1 robustness is not traded
for a small benchmark gain.

## Correctness and interruption qualification

The final Release Python stack passed the standard seeded U200 qualification:

- 94 cases, zero transport or API failures;
- payloads from 64 B through 32,832 B;
- whole, boundary, randomized, and word-at-a-time receive partitions;
- separate and queued write/read programs;
- 0.15 s, 1 s, and 6 s gaps between read groups inside one FPGA program;
- 6 s of host-delayed consumption after readback starts;
- a default receive blocked correctly beyond the former 5 s limit;
- an explicit 250 ms timeout performed `full_reset()` and immediately reused
  the same board handle.

Host-separated retention sequences also worked:

1. execute write;
2. synchronize;
3. sleep in Python;
4. execute read;
5. receive and synchronize.

At 0, 0.15, and 1 s, the tested row had zero changed words. At 6 s with FPGA
auto-refresh off, 35 words differed. That is a DRAM retention observation, not
a transport failure: the exact byte count arrived, framing completed, and the
board remained usable.

The following additional hardware interruption checks were manually observed
to pass. Their logs were temporary and are not part of the persisted JSONL
artifact set listed below:

- Hardware SIGINT during a six-second program: `full_reset()` completed and
  raised `KeyboardInterrupt` in 0.808 s; immediate tagged reuse passed.
- Hardware SIGKILL: the next process opened the endpoint, completed
  `full_reset()` in 0.559 s, and passed an 8 KiB tagged canary without driver
  reload, FPGA reprogramming, or reboot.
- Twenty independent open/read/full-reset/close lifecycles passed with zero
  mismatches, reset failures, or new kernel messages.

CPU-side protocol tests cover randomized fragmentation, coalescing, malformed
metadata, partial queued reads, timeout/reset reuse, and a 512 KiB multi-packet
result. Debug, Release, ASan/UBSan, and TSan runs were also observed to pass;
their sanitizer logs are not included in the persisted benchmark artifacts.

## New-kernel and multicard status

The same O(1) driver and API were subsequently qualified on fpga99's Ubuntu
24.04 kernel `7.0.0-28-generic` with the dual-RDIMM metadata-v1 image: six U200
cards, both populated channels per card, and twelve concurrent BDF/channel
endpoints. Native C++ delivered 27.558 GiB/s across all twelve endpoints,
97.79% of the isolated sum; Release Python retained 97.72% of native. Across
the performance matrix, 202,000 timed 512-KiB transfers completed with zero
mismatched words and no ring-position sawtooth.

The final deployment uses the unique module name `drambender_xdma`, DKMS,
streaming credit mode, and persistent `root:drambender 0660` device nodes. A
host reboot auto-loaded that module and a post-boot 12 x 25 endpoint test
passed. Full provenance, fuzz, interruption, sibling-reset, retention, and
scaling results are in `docs/fpga99_dual_rdimm_qualification.md`.

## Reproduction artifacts

Primary JSONL artifacts are under `data/performance/u200-ab/`:

- Legacy C++:
  `legacy-main-cpp-cpu4-5-sha.jsonl`, SHA-256
  `448918d9fb3c1c6dd35de92b7600c814d677638b7ce4d9f85b59525e22d2a15c`
- Final C++:
  `new-cpp-final-exact-all-cpu4-5.jsonl`, SHA-256
  `4af793f027de51d5313b815035fc987bba29a257df697b02d3512d3351bdade5`
- Final Release Python:
  `new-python-release-final-exact-all-cpu4-5.jsonl`, SHA-256
  `0f152b3ffdc2171faf710af36e80704b830465cd73c51ebf287ba985a1f048e1`
- Standard final fuzz/retention run:
  `final-ddr4-fuzz-standard.jsonl`, SHA-256
  `c26a7b203bd30dcf671a7332e9cd476a442e1829c45a8fa70aebab9bc247bf00`

The benchmark sources are:

- `tests/board_tests/u200_readback_benchmark.cpp`
- `tests/board_tests/u200_readback_benchmark.py`

## Recommendation

Keep the current metadata-v1 RBE for this clean software cutover. The two
material software bottlenecks are fixed, the fixed 8,192-page ring is stable,
and correctness/recovery tests pass. Do not shrink the production ring merely
to hide the old lookup bug, and do not require a physically contiguous 32 MiB
allocation.

The U200 RDIMM correctness, interruption, dual-channel, reboot-deployment, and
multicard-scaling gates are now complete. Treat any further receive-quantum or
RBE packet-coalescing optimization as optional and measure it independently.
