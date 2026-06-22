# XDMA Driver Source

This directory contains the Xilinx XDMA driver source imported from
DRAM-BenderV2 `sources/xdma_driver`.

The driver is not built as part of the default pyDRAMBender software build. It
should be built and loaded only on Linux hosts that are intentionally being
prepared for FPGA hardware access.

Routine Python/C++ package builds should not build, install, or load this
driver.

## Supported Kernel Range

This fork is maintained for Linux `5.4` through `6.17` using a small
compatibility layer in `xdma/xdma_compat.h`.

The compatibility layer centralizes kernel API differences such as:

- `class_create()` before and after Linux `6.4`
- `get_user_pages_fast()` flags
- `access_ok()`
- selected RHEL/backport-aware compatibility macros already present in the
  imported V2 driver

## Prerequisites

- Matching kernel headers/build tree for each target kernel:
  `/lib/modules/<kernel-release>/build`
- `make` and a compiler compatible with the target kernel
- Optional: `dkms` for automatic rebuilds after kernel upgrades

## Compile-Only Build

Build for the running kernel without loading the module:

```sh
./build_driver.sh
```

Build for another installed kernel:

```sh
./build_driver.sh --kernel-release <kernel-release>
```

Build against an explicit kernel build tree:

```sh
./build_driver.sh --kernel-release <kernel-release> --kernel-dir /path/to/kernel/build
```

Clean build products:

```sh
./build_driver.sh --clean
```

After a successful build, verify the module target:

```sh
modinfo -F vermagic xdma/xdma.ko
```

## Loading

Loading is intentionally separate from building. After compiling, load the
module on a hardware host:

```sh
sudo ./load_driver.sh
```

`load_driver.sh` preserves DRAM-Bender's required streaming credit setting:

```sh
enable_st_c2h_credit=1
```

The script refuses to unload an existing `xdma` module automatically. If you
need to replace a loaded module, unload it deliberately first:

```sh
sudo rmmod xdma
```

## DKMS

Install with DKMS so the module is rebuilt for future kernel updates:

```sh
sudo ./install_dkms.sh
```

Install for a specific kernel:

```sh
sudo ./install_dkms.sh --kernel-release <kernel-release>
```

Remove the DKMS package:

```sh
sudo ./uninstall_dkms.sh
```

Remove the DKMS package and its `/usr/src` source copy:

```sh
sudo ./uninstall_dkms.sh --remove-source
```

## Hardware Tests

The scripts under `tests/` and any command that touches `/dev/xdma*` require a
programmed FPGA and a host that is ready for hardware access. Do not run those
tests as part of normal software-only builds.

The original vendor license, release notes, tools, and test scripts are
preserved in this directory.
