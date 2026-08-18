# DRAM Bender Documentation

The documentation follows the [Diátaxis](https://diataxis.fr/) structure. Pick
the section that matches what you are trying to do:

| You want to... | Go to |
|---|---|
| Learn DRAM Bender by doing, starting from an empty host | [Tutorials](#tutorials) |
| Accomplish one specific task | [How-to guides](#how-to-guides) |
| Look up a fact about boards, the ISA, or the APIs | [Reference](#reference) |
| Understand how and why the system is designed this way | [Explanation](#explanation) |

## Tutorials

Step-by-step lessons. Follow them in order on a fresh setup.

- [Getting started](tutorials/getting-started.md) — install the driver and the
  Python API, program the FPGA, and run one DDR4 read/write test.
- [Writing DRAM Bender programs in Python](tutorials/writing-programs.md) —
  describe a memory target, build and inspect programs, execute them on
  hardware, and write a custom program with `ProgramBuilder`.

## How-to guides

Recipes for one task at a time. They assume a working setup.

- [Obtain a bitstream](how-to/obtain-a-bitstream.md)
- [Install the XDMA driver](how-to/install-the-xdma-driver.md)
- [Identify an FPGA endpoint](how-to/identify-an-endpoint.md)
- [Build an FPGA bitstream](how-to/build-a-bitstream.md)
- [Read power and temperature telemetry (U55C)](how-to/read-power-telemetry.md)
- [Use multiple boards and channels](how-to/use-multiple-boards.md)
- [Recover and troubleshoot](how-to/recover-and-troubleshoot.md)

## Reference

Facts, formats, and API surfaces.

- [Supported boards](reference/supported-boards.md)
- [ISA: instruction format and registers](reference/isa.md)
- [Python API](reference/python-api.md)
- [C++ API](reference/cpp-api.md)

## Explanation

Design discussion and background.

- [Hardware architecture](explanation/architecture.md) — the execution
  pipeline, the DDR4 and HBM2 adapters, and how to extend the ISA.
- [The readback protocol (metadata-v1)](explanation/readback-protocol.md)
- [Why the XDMA driver is a fork](explanation/xdma-fork.md)
