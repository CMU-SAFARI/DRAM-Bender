# Hardware Architecture

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

## Frontend and execution pipeline

The frontend receives programs from XDMA, stores instructions, selects between
user programs and maintenance operations, and starts the in-order execution
pipeline. The pipeline fetches and decodes one 64-bit instruction stream and
produces either register/control operations or low-level DRAM operations.

The instruction encodings, registers, and timing model are listed in the
[ISA reference](../reference/isa.md).

The relevant RTL sources are:

- [`hw/rtl/verilog/frontend.v`](../../hw/rtl/verilog/frontend.v)
- [`hw/rtl/verilog/softmc_pipeline.v`](../../hw/rtl/verilog/softmc_pipeline.v)

## DDR4 and HBM2 adapters

The common pipeline emits target-independent DRAM operations. Board adapters
translate these operations to the interfaces exposed by the DDR4 or HBM2 PHY.
Target objects in the software provide the corresponding geometry, rank,
channel, pseudo-channel, and stack-selection rules.

## Readback

DRAM read results enter the readback engine, which frames data for the host.
The framing protocol has its own page:
[The readback protocol](readback-protocol.md).

## Extending the ISA

Adding an instruction normally requires coordinated changes in several layers:

1. Define the encoding in the RTL headers.
2. Decode and execute the instruction in the FPGA pipeline.
3. Add the C++ instruction encoder.
4. Expose it through `ProgramBuilder` and the Python bindings.
5. Model its behavior in the software VM.
6. Add formatting and software tests for its encoding and timing.

Keeping these layers together ensures that printed programs, dry runs, traces,
and hardware execution describe the same instruction stream.
