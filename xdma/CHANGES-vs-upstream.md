# Changes vs Upstream

This driver is a modified fork of the Xilinx XDMA driver from `dma_ip_drivers`.
This file lists the changes to the driver module sources.

DRAM Bender requires this fork.
The metadata-v1 readback path depends on the credit-based read path below.
The stock Xilinx driver does not contain that path.

## Baseline

- Upstream project: `https://github.com/Xilinx/dma_ip_drivers`
- Upstream path: `XDMA/linux-kernel`
- Upstream branch: `2020.2`

## New file

- `xdma/xdma_compat.h` — the kernel compatibility layer. It centralizes the API changes from Linux 5.0 through 6.4 and RHEL back-ported kernels.

## Changed module sources

| File | Change | Purpose |
| --- | --- | --- |
| `xdma/Makefile` | module rename | Build the module as `drambender_xdma`, not `xdma`. |
| `xdma/libxdma.c` | +965 / -37 | Add the credit-based AXI-ST C2H cyclic read path and a constant-time scatterlist lookup. |
| `xdma/libxdma.h` | +23 / -30 | Grow the cyclic ring from 256 to 8192 pages. Add the module parameters and the ring state. |
| `xdma/cdev_sgdma.c` | +110 / -23 | Route C2H reads through the cyclic path. Open each H2C and C2H endpoint for one process only. |
| `xdma/cdev_ctrl.c` | 1 line | Use the compat wrapper `xdma_vm_flags_set()` for Linux 6.3. |
| `xdma/xdma_cdev.c` | 1 line | Use the compat wrapper `xdma_class_create()` for Linux 6.4. |

## New module parameters

- `cyclic_rx_pages` — the cyclic ring size in pages. Default 8192.
- `cyclic_initial_credits` — the initial C2H credit window in pages. Default 512.
- `enable_st_c2h_credit` — required. Set this to 1 for metadata-v1 readback.

## User-visible behavior changes

- The kernel module is named `drambender_xdma`.
- A read of a C2H node returns a byte stream from a cyclic ring, not a fixed-size transfer.
- A second open of one H2C or C2H endpoint returns `-EBUSY`.

## Deployment tooling

The files below package and deploy the fork. They are DRAM Bender additions, not upstream module sources.

- `dkms.conf`, `install_dkms.sh`, `uninstall_dkms.sh`
- `modprobe.d/drambender-xdma.conf`
- `udev/70-drambender-xdma.rules`, `install_access.sh`, `uninstall_access.sh`
- `build_driver.sh`, `load_driver.sh`

## Preserved from upstream

- The upstream license files `COPYING` and `LICENSE`.
- The upstream `tools/` and `tests/` utilities.
- The externally visible interface: the PCI driver name `xdma`, the device class `xdma`, and the `/dev/xdma*` nodes.

> **Warning.** Do not load the stock Xilinx `xdma` driver together with `drambender_xdma`. Both drivers match the same PCI IDs, and the bind order is not deterministic.
