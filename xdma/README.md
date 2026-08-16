# XDMA Driver (Modified Fork)

This directory contains a **modified fork** of the Xilinx XDMA driver from
`dma_ip_drivers`, branch `2020.2`. This is not the stock Xilinx driver.

DRAM Bender requires this fork. The metadata-v1 readback path depends on a
credit-based read path that the stock driver does not contain. See
[CHANGES-vs-upstream.md](CHANGES-vs-upstream.md) for the full list of changes.

The kernel module is named `drambender_xdma`, not `xdma`.

> **Warning.** Do not load the stock Xilinx `xdma` driver together with
> `drambender_xdma`. Both drivers match the same PCI IDs, and the bind order is
> not deterministic.

The driver is not built during the default DRAM Bender software build. Build
and load it only on a Linux host that you prepare for FPGA hardware access.
Routine Python and C++ package builds do not build, install, or load this
driver.

## Supported Kernel Range

This fork is compile-tested on Linux `5.4` and `7.0` using a small
compatibility layer in `xdma/xdma_compat.h`; the same layer covers the
intervening kernel API changes.

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
modinfo -F name xdma/drambender_xdma.ko
modinfo -F vermagic xdma/drambender_xdma.ko
```

The kernel-module artifact is deliberately named `drambender_xdma.ko`.
Ubuntu also ships an unrelated in-tree module named `xdma`; the unique name
makes `modinfo`, DKMS state, module parameters, and `/sys/module` provenance
unambiguous. The externally visible FPGA interface stays unchanged:

- PCI driver: `/sys/bus/pci/drivers/xdma`
- device class: `/sys/class/xdma`
- device nodes: `/dev/xdma*`

## Loading

Loading is intentionally separate from building. After compiling, load the
module on a hardware host:

```sh
sudo ./load_driver.sh
```

If the module registers but no complete H2C/C2H pair appears, or any stream
node is unpaired, the loader reports likely bitstream/PCI-ID/udev causes and
attempts to remove the module it just loaded. It never removes a driver that
was already present when the script started.

`load_driver.sh` preserves DRAM-Bender's required streaming credit setting:

```sh
enable_st_c2h_credit=1
```

The script refuses to unload or replace any existing XDMA PCI driver. If you
need to replace the DRAM-Bender module, quiesce every process using every card
and unload it deliberately first:

```sh
sudo rmmod drambender_xdma
```

When migrating from the old artifact name, the one-time unload command is
`sudo rmmod xdma`. Check the owner first with
`readlink -f /sys/bus/pci/drivers/xdma/module`; the similarly named Ubuntu
module is unrelated and may coexist after this rename.

## DKMS

Install with DKMS so the module is rebuilt for future kernel updates:

```sh
sudo ./install_dkms.sh
```

Load the DKMS-installed module immediately when no XDMA PCI driver is already
registered (otherwise use the deliberate replacement procedure above):

```sh
sudo modprobe drambender_xdma
```

The PCI modalias also lets udev load it automatically after a reboot.

Install for a specific kernel:

```sh
sudo ./install_dkms.sh --kernel-release <kernel-release>
```

Installation is deliberately clean and non-replacing. If this exact DKMS
package or its `/usr/src` tree already exists, the installer exits before its
first write. To intentionally reinstall it, first run:

```sh
sudo ./uninstall_dkms.sh --remove-source
```

The installer never removes a module for this or any other kernel. Removing a
previously loaded driver remains a separate, explicit maintenance action.

Remove the DKMS package:

```sh
sudo ./uninstall_dkms.sh
```

Remove the DKMS package and its `/usr/src` source copy:

```sh
sudo ./uninstall_dkms.sh --remove-source
```

The DKMS install also installs
`/etc/modprobe.d/drambender-xdma.conf`, which enables the streaming C2H credit
mode required by metadata-v1 readback when udev auto-loads the module. Neither
the install nor uninstall script changes a currently loaded driver.

## Non-root device access

Install the checked-in udev rule and enroll each authorized login in the
dedicated `drambender` group:

```sh
sudo ./install_access.sh --user "$USER"
```

Repeat `--user <login>` for a multi-user test host. Start a new login session
afterward, then verify an endpoint:

```sh
id
stat -c '%A %U %G %n' /dev/xdma0_h2c_0 /dev/xdma0_c2h_0
```

Expected ownership is `root:drambender` with mode `0660`. The rule covers all
cards and all channels, including nodes created after driver reloads or host
reboots. Remove the rule with:

```sh
sudo ./uninstall_access.sh
```

The dedicated group is retained on uninstall so the script never silently
edits account memberships.

## Hardware Tests

The scripts under `tests/` and any command that touches `/dev/xdma*` require a
programmed FPGA and a host that is ready for hardware access. Do not run those
tests as part of normal software-only builds.

The original vendor license, release notes, tools, and test scripts are
preserved in this directory.
