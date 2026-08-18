# Install the XDMA Driver

> **Note.** This repository ships a **modified fork** of the Xilinx XDMA driver
> (`dma_ip_drivers`, branch `2020.2`), not the stock driver. The kernel module
> is named `drambender_xdma`, and DRAM Bender readback depends on the fork's
> credit-based read path. See
> [xdma/CHANGES-vs-upstream.md](../../xdma/CHANGES-vs-upstream.md) and
> [Why the XDMA driver is a fork](../explanation/xdma-fork.md).
> Do not load the stock Xilinx `xdma` driver at the same time; both match the
> same PCI IDs and the bind order is not deterministic.

DRAM Bender uses a streaming XDMA interface for host-to-card programs and
card-to-host readback. Build it explicitly for the running kernel and load the
result directly from this checkout:

```bash
cd xdma
./build_driver.sh
sudo ./install_access.sh --user "$USER"
sudo ./load_driver.sh
cd ..
```

This procedure does not install an automatic rebuild or module-loading hook.
After restarting the same pinned kernel, run `sudo xdma/load_driver.sh` again.
If the kernel is intentionally changed, rebuild the module before loading it.

Pin the kernel and disable unattended kernel upgrades on an experiment host.
Treat a kernel change as a deliberate maintenance operation, then install its
matching headers and rebuild the driver.

## Device-node access

The access installer creates a `drambender` group and configures XDMA device
nodes as `root:drambender` with mode `0660`. Start a new login session after
the group membership is changed. Do not run DRAM Bender applications as root
to work around missing permissions.

## Verify the installation

Verify the module and device nodes:

```bash
modinfo xdma/xdma/drambender_xdma.ko
readlink -f /sys/bus/pci/drivers/xdma/module
ls -l /dev/xdma*
```

If no `/dev/xdma*` nodes appear, see
[Recover and troubleshoot](recover-and-troubleshoot.md).
