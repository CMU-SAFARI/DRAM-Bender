# Why the XDMA Driver Is a Fork

This repository ships a **modified fork** of the Xilinx XDMA driver, not the
stock driver. The fork is based on
[`dma_ip_drivers`](https://github.com/Xilinx/dma_ip_drivers), path
`XDMA/linux-kernel`, branch `2020.2`. The kernel module is named
`drambender_xdma`.

## The rationale

DRAM Bender readback uses the [readback metadata protocol](readback-protocol.md):
the FPGA streams framed batches whose sizes the host does not know in advance,
across idle intervals that can be arbitrarily long (for example, retention
experiments). The stock XDMA driver models C2H reads as fixed-size transfers,
which does not fit this pattern. The fork adds a **credit-based AXI-ST C2H
cyclic read path**: a read of a C2H node returns a byte stream from a cyclic
ring, and the driver extends credits to the FPGA as the host consumes data.
The stock driver does not contain this path, so DRAM Bender requires the fork.

The fork also opens each H2C and C2H endpoint for one process only (a second
open returns `-EBUSY`), which is what gives a board handle exclusive ownership
of its endpoint.

## Scope of the changes

The changes to upstream module sources are deliberately small: six upstream
module files changed, plus one new file, `xdma_compat.h`, a kernel
compatibility layer. The complete list of changed files, new module
parameters, and user-visible behavior changes is in
[`xdma/CHANGES-vs-upstream.md`](../../xdma/CHANGES-vs-upstream.md).

The upstream license files (`xdma/COPYING`, `xdma/LICENSE`) and the Xilinx
copyright are preserved.

## Coexistence with the stock driver

> **Warning.** Do not load the stock Xilinx `xdma` driver together with
> `drambender_xdma`. Both drivers match the same PCI IDs, and the bind order
> is not deterministic.

The fork preserves the externally visible interface — the PCI driver name
`xdma`, the device class `xdma`, and the `/dev/xdma*` nodes — so tools that
expect the stock naming keep working, but this is also why the two modules
must not be loaded at the same time.

For build and installation steps, see
[Install the XDMA driver](../how-to/install-the-xdma-driver.md) and
[`xdma/README.md`](../../xdma/README.md).
