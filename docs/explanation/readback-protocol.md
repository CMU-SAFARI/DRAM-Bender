# The Readback Protocol

DRAM read results enter the readback engine, which batches data into framed
XDMA packets. For each batch, the engine emits a metadata packet that declares
the number of following data beats. A nonempty batch is followed by a data
packet, and a final marker indicates that no more batches belong to the
program. The host API uses these fields rather than depending on
operating-system read boundaries or an interval with no data.

This framing makes readback deterministic: the host always knows how much data
belongs to a program and when the program's readback is complete, even across
long idle intervals. It is also why the host driver matters — the readback
path depends on the credit-based read support in the
[forked XDMA driver](xdma-fork.md).

## Software and bitstream pairing

The readback metadata format is a protocol boundary between the bitstream and
the host software. Use the bitstream distributed for this software.

## Sources

The relevant RTL and encoding definitions are:

- [`hw/rtl/header_verilog/encoding.vh`](../../hw/rtl/header_verilog/encoding.vh)
- [`hw/rtl/header_verilog/parameters.vh`](../../hw/rtl/header_verilog/parameters.vh)
- [`hw/rtl/verilog/frontend.v`](../../hw/rtl/verilog/frontend.v)
- [`hw/rtl/verilog/softmc_pipeline.v`](../../hw/rtl/verilog/softmc_pipeline.v)
- [`hw/rtl/verilog/readback_engine.v`](../../hw/rtl/verilog/readback_engine.v)
- [`include/drambender/api/program/instruction.h`](../../include/drambender/api/program/instruction.h)
- [`python/drambender/api/program/`](../../python/drambender/api/program/)
