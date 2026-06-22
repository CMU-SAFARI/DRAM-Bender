# API Improvements Over Original DRAM-Bender

pyDRAMBender keeps the low-level DRAM-Bender execution model, but wraps it in a
cleaner C++ and Python API that is easier to use from scripts, notebooks, and
external CMake projects.

## Readback Lifecycle

- `execute()` starts a bounded readback session for each program.
- `receive()` / `receive_into()` copy requested readback bytes into user-owned
  buffers.
- `synchronize()` gives users an explicit completion boundary: it waits for the
  active readback session to finish and rethrows asynchronous receive errors.
- Queued readback is preserved until the user receives it or explicitly calls
  `full_reset()`.

The original DRAM-Bender API relied mostly on blocking `receiveData()` calls as
the synchronization point. That works when the caller knows the exact readback
size, but it gives less structure for no-read programs, partial reads, and
receive-side failures.

## Safer Reset And Recovery

- `reset_fpga()` remains the normal low-level FPGA reset control packet for an
  idle or healthy board.
- `full_reset()` is the recovery boundary: it cancels active readback, resets
  FPGA logic, drains stale XDMA card-to-host data, and clears queued software
  readback.
- XDMA receive cancellation wakes a blocked card-to-host read without closing
  device file descriptors from another thread.
- XDMA drain is bounded, so recovery cannot spin forever if hardware continues
  producing readback.

## Cleaner Host/Board Separation

- Board logic owns program execution, readback queuing, synchronization, and
  recovery policy.
- Host interfaces own transport details such as XDMA file descriptors,
  cancellation, send, receive, and stale-data drain.
- This separation keeps the public API stable while allowing XDMA-specific
  robustness work to stay inside the backend.

## Python-Friendly API

- Python users can execute `FinalProgram` objects directly and receive into
  NumPy arrays or other writable C-contiguous buffers.
- Asynchronous receive errors are surfaced through ordinary Python exceptions
  when calling `receive_into()` or `synchronize()`.
- The supported public generator path is `drambender.builtin_programs` and
  `ProgramBuilder`; legacy C++ program-generator comparison code is not part of
  the public package.

## C++ Library Packaging

- The C++ API installs public headers, the library target, and CMake package
  metadata.
- External consumers can use `find_package(DRAMBender CONFIG REQUIRED)` and
  link `DRAMBender::DRAMBender`.
