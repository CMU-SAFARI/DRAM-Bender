# FPGA77 U55C metadata-v1 qualification

Date: 2026-08-09 (Europe/Zurich)

## Scope and result

The clean `new-repo` API/driver at commit
`1cb6ec55dd559e5c736e9ba5f2640cad6b31592c` passed the U55C qualification on
`safari-fpga77` for PCI function `0000:01:00.0`, XDMA stream channel 0, and HBM
channel 0. No broadcast operation or other HBM channel was used. Both
pseudo-channels and both SIDs were exercised.

The card was left quiescent after a successful `full_reset()`, with no open XDMA
file descriptors. After qualification, the same driver source was installed in
its final clean deployment form as `drambender_xdma`; that module remains
loaded.

## Host and software provenance

- Host: Ubuntu 20.04.6 LTS, kernel `5.4.0-216-generic`.
- Qualification-phase isolated checkout: `/home/safari/new-repo-v1` (detached
  at the exact target commit for testing, then advanced to `80500f6` for final
  deployment; the pre-existing repositories were not modified).
- Commit tree: `d6cec9a3805d0125d24e44b85fc94f19e61d2389`.
- Transfer bundle SHA-256:
  `05603598a7e5ad7a1da43797b3973a92ef12a65b299bee93f9c2a8dd4dc0ffd9`.
- Driver SHA-256:
  `05f2ec4bd556365e937258515ed82e6dc0b8cc3489099235b5f83a480fa6cfdb`.
- Loaded/expected driver `srcversion`: `37AF925418A456732275CEA`.
- Driver parameters: streaming C2H credits enabled, 8,192 cyclic RX pages, 512
  initial credits, 10-second H2C/C2H transport timeouts.
- C++ HBM test SHA-256:
  `264ac2a3cbfed67b123e4ca55d756de582891e2f8a3b72fa756abc1ca71d1874`.
- Python extension SHA-256:
  `4f0ce40288b7634092e34b940d2a3d5711e57236d66b7d0f817234ccd3d815cc`.
- Qualification harness SHA-256:
  `1ccbb7e5cda5e8aab98c50523bab926e1dcd05e3cdf8099a0f9753ce9069d3c9`.

The final deployment-only update is commit
`80500f6f9225d1e70279b29adef4cb3f9774ecfc`. On this Ubuntu 20.04 host it was
installed and built by DKMS 2.8 against the running kernel as:

- module name: `drambender_xdma`
- installed path:
  `/lib/modules/5.4.0-216-generic/updates/dkms/drambender_xdma.ko`
- installed module SHA-256:
  `f404fce915e33d37fb8746c40b9eddcd1bc5f27f4ca77dbb67ce7d1583faf702`
- loaded/installed `srcversion`: `37AF925418A456732275CEA`
- device ownership: `root:drambender`, mode `0660`

The unchanged `srcversion` ties the final named module to the driver code used
for qualification; the additional commits change deployment identity,
provenance paths, and permissions rather than the DMA/readback implementation.

For the main qualification, the driver was built against the running kernel
and loaded by absolute path. The later final-deployment gate replaced it with
the identically sourced DKMS module loaded by its unique module name.

## Programmed image and RBE compatibility

The system journal records `XCU55_latest_600MHz_sid` as the last successful U55
programming operation (2026-06-17 23:32). The surviving exact artifacts are:

- bitstream SHA-256:
  `242dc81bb8a6bec2c94b62290a170928d13095e97e9a1b7529bcc19c27c63035`
- LTX SHA-256:
  `3a7d3e3e69425ed30e9625e44ab63e8d2d5c23d69294a82579c560d6706564fe`
- embedded bitstream identity: `softmc_top`, Vivado 2024.2,
  `xcu55c-fsvh2892-2L-e`, built 2026-05-17 18:58:42.

The generated-image source checkout is commit
`75b622a37cce8f83c0ed7926f89744fcf7ee80c1` on `vivado-upgrade`. Its imported
RBE SHA-256 is
`589d9ed1fdf286b5e59e2ba1a526b0ae814affc5e19a1d63fda49593b5ab6365`.
Compared while ignoring whitespace with the target API's RBE, the functional
differences are only the signal rename `hbm_garbage_reads` to
`hbm_discard_readback_data` and a later HBM preprocessor guard. The synthesized
HBM behavior and control bit are unchanged. In particular, the image emits the
same metadata-v1 format with zero reserved bits; it does not emit a rolling
packet counter.

Read-only JTAG inventory before and after testing found `xcu280_u55c_0`, IDCODE
`14B7D093`, cable serial `XFL104D0EZU2A`, all three SLRs in DONE/EOS state, and
no CRC, ID, security, watchdog, or fallback error. The image does not embed a
cryptographic hash in `USR_ACCESS`, so JTAG alone cannot prove the file hash;
the journal, surviving artifact, generated-source inventory, and successful
protocol tests together provide the provenance chain.

The LTX does not expose every DFI initialization bit. HBM channel-0 calibration
was therefore validated functionally: exact writes and reads passed on both
pseudo-channels, both SIDs, and extreme bank/row addresses. No claim is made for
HBM channels 1 through 15 in this run.

## Tests completed

- Offline C++ protocol/build tests: 5/5 passed.
- Static HBM trace: correct `SEL_CH`, pseudo-channel, SID-to-BAR mapping, 32 WR,
  32 RD, and column sequence at bank/row extremes.
- C++ hardware matrix: all four `(pseudo-channel, SID)` combinations passed at
  bank 0/15 and row 0/16383; each returned and verified 2,048 bytes.
- Python boundary matrix: the same four combinations passed.
- Counter-free check: two different data-bearing sessions on one handle passed
  without an intervening reset.
- Variable-size fuzz/soak: 94/94 cases, 1,400,768 total readback bytes, zero
  mismatches. Read counts covered 1, 2, 3, 31, 32, 33, 63, 64, 65, 127, 149,
  150, 151, 255, 257, 511, and deterministic random values. Caller receive
  partitions deliberately crossed packet boundaries.
- Long FPGA gap: a single readback session containing a six-second FPGA sleep
  completed in 6.667 seconds and verified both pre-gap and post-gap data.
- Host retention: write-only session, 6.0-second host sleep with auto-refresh,
  then a separate read-only session passed (6.002 seconds measured).
- Explicit receive timeout: a 100 ms API timeout triggered automatic
  `full_reset()`; same-handle tagged reuse passed immediately afterward
  (0.766 seconds including recovery).
- Discard mode: 151 reads were discarded, the session terminated normally,
  discard was disabled, and tagged same-handle reuse passed.
- SIGINT: an armed child blocked in a six-second readback was interrupted;
  automatic reset and same-handle reuse passed (1.533 seconds).
- SIGKILL: an armed process was killed; a fresh process opened the endpoint,
  performed `full_reset()`, and passed a tagged read/write canary without a
  driver reload or FPGA reprogramming.
- Endpoint ownership: a duplicate open was rejected with `EBUSY`; close/reopen
  and final reset passed.
- Final deployment gate: the old `xdma` module was removed explicitly, the
  DKMS-installed `drambender_xdma` was loaded with plain `modprobe`, streaming
  C2H credit mode remained enabled, the H2C/C2H pair reappeared as
  `root:drambender 0660`, and a non-root 2,048-byte HBM write/read canary passed.

HBM temperature was intentionally not tested because the known v1 temperature
helper remains outside this qualification. Broadcast was intentionally not
tested.

## Post-test health

- All sysfs correctable, nonfatal, and fatal AER counters are zero.
- PCIe AER status did not change. Pre-existing sticky `DevSta` `CorrErr` and
  `UnsupReq` summary bits were identical before and after; detailed `UESta` and
  `CESta` remained clear.
- The test-window kernel journal contains only the expected driver remove/load
  and probe messages. It contains no new XDMA timeout, stuck-ring, short
  transfer, AER, or recovery error.
- No test process, JTAG server, or XDMA file descriptor remains open.
- The post-deployment canary left all AER totals at zero and added no filtered
  kernel BUG, warning, DMA/XDMA failure, or AER-error line.

## Artifacts

All raw results and provenance are under:

`/home/safari/new-repo-v1/data/qualification/fpga77-u55c-20260809`

The SHA-256 of that directory's `SHA256SUMS` manifest is:

`acbb87dd3d4e924e4517870f71dcfd7133da452a579d3319b6522c4ae3065a43`

Final deployment evidence is in the `final-clean-deployment/` subdirectory.
Its 26-file `DEPLOYMENT_SHA256SUMS` verifies successfully and has SHA-256:

`307a35a3e3fa6ef3ae04c9e9c989d2c980a6c6337e2fbaadf1577e1db9c27f3c`
