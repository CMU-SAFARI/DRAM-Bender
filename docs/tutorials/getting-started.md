# Getting Started

This tutorial takes you from an empty Linux host to one passing DRAM Bender
test: writing a DDR4 row on an Alveo U200 and reading it back. The flow is the
same for the HBM2 boards (U50 and U55C); board differences are noted where they
matter. See [Supported boards](../reference/supported-boards.md) for the full
board list.

## Hardware prerequisites

- A supported Alveo board installed in a suitable PCIe slot.
- A dedicated Linux host. The U200 also requires a supported DDR4 module.
- A JTAG connection and Vivado Hardware Manager or Vivado Lab for programming.
- A bitstream built for the selected board and memory configuration.
- A host restart when required to enumerate a newly programmed PCIe design.

## Software prerequisites

- Linux 5.4 through 7.0 and the matching kernel headers for the running kernel.
- `make` and a compiler compatible with the running kernel.
- CMake 3.16 or newer.
- `g++` 11 or newer with C++20 support.
- Python 3.10 or newer, `venv`, and the matching Python development headers.
- Git and standard PCI utilities such as `lspci`.

For example, install the common host build dependencies on Ubuntu with:

```bash
sudo apt install build-essential cmake git linux-headers-$(uname -r) pciutils
```

Install the `-dev` and `-venv` packages that match the Python interpreter you
intend to use. For Python 3.12 these packages are commonly named
`python3.12-dev` and `python3.12-venv`.

Pin the kernel and disable unattended kernel upgrades on an experiment host.
Treat a kernel change as a deliberate maintenance operation, then install its
matching headers and rebuild the driver.

## Step 1: Obtain a bitstream and program the FPGA

Clone the repository and fetch the prebuilt bitstreams, which live in a
separate repository included as the `hw/prebuilt` submodule:

```bash
git clone https://github.com/CMU-SAFARI/DRAM-Bender.git
cd DRAM-Bender
git submodule update --init hw/prebuilt
```

For a U200 host with one JTAG target, the programming helper expects a
bitstream and an optional probes file with the same base name:

```bash
export VIVADO_EXEC=/path/to/vivado_or_vivado_lab
hw/scripts/program_fpga.sh XCU200 <bitstream-name-without-extension>
```

Restart the host afterward if the programmed PCIe design is not re-enumerated
automatically.

For U50/U55C, a multi-FPGA host, or details on the bitstream repository
layout, see [Obtain a bitstream](../how-to/obtain-a-bitstream.md).

## Step 2: Install the XDMA driver

> **Note.** This repository ships a **modified fork** of the Xilinx XDMA
> driver, not the stock driver. The kernel module is named `drambender_xdma`.
> Do not load the stock Xilinx `xdma` driver at the same time. See
> [Why the XDMA driver is a fork](../explanation/xdma-fork.md).

Build the driver for the running kernel, set up device-node access, and load
the module:

```bash
cd xdma
./build_driver.sh
sudo ./install_access.sh --user "$USER"
sudo ./load_driver.sh
cd ..
```

The access installer creates a `drambender` group and configures XDMA device
nodes as `root:drambender` with mode `0660`. Start a new login session after
the group membership is changed. Do not run DRAM Bender applications as root
to work around missing permissions.

Verify the module and device nodes:

```bash
ls -l /dev/xdma*
```

This procedure does not install an automatic rebuild or module-loading hook.
After a restart, run `sudo xdma/load_driver.sh` again. For the full procedure,
verification steps, and kernel-change handling, see
[Install the XDMA driver](../how-to/install-the-xdma-driver.md).

## Step 3: Identify the FPGA endpoint

Applications select an endpoint using the complete PCI BDF and XDMA channel,
for example `0000:01:00.0`, channel 0. List the Xilinx PCI functions on the
host:

```bash
lspci -D -d 10ee:
```

Note the BDF of your board; the test in Step 5 takes it as an argument. The
`xdmaN` prefix in `/dev/xdma*` names is probe order, not a stable board
identity — see
[Identify an FPGA endpoint](../how-to/identify-an-endpoint.md) for why and for
the full discovery procedure.

## Step 4: Install the Python API

Create the development environment from the repository checkout:

```bash
PYTHON_BIN=python3.12 bash setup_venv.sh
source .venv/bin/activate
python -c 'import drambender; print(drambender.__file__)'
```

Set `PYTHON_BIN` to another Python 3.10 or newer interpreter if needed. Set
`CXX=/path/to/g++-11-or-newer` before running the setup script when the
default compiler is too old.

## Step 5: Run a small DDR4 read/write test

[`examples/read_write.py`](../../examples/read_write.py) writes one U200 DDR4
row, reads it back, and compares every returned word:

```bash
python examples/read_write.py \
    --pci-bdf 0000:01:00.0 \
    --xdma-channel 0 \
    --bank 0 \
    --row 0 \
    --pattern 0xDEADBEEF
```

A successful run ends with:

```text
PASS: 2048 words matched (pattern=0xdeadbeef)
```

Before the result, `open_board()` prints the selected board configuration,
including the instruction capacity, command timing, readback capacity, and
board-specific features. It also states that the API expects the programmed
bitstream to match. This output describes the API configuration rather than
probing the FPGA image, so confirm it against the bitstream you programmed.

This is a quick endpoint and readback check, not an exhaustive memory test. It
overwrites the selected row. Replace the BDF, channel, bank, row, and pattern
arguments with values appropriate for your system. If the memory geometry
differs, edit the target constants near the top of the example before running
it.

The Python program-building interface is shared by DDR4 and HBM2. The same
`write_row` and `read_row` templates accept either a `DDR4Target` or an HBM2
target (`HBM2U50Target`, `HBM2U55Target`). An HBM2 target carries channel,
pseudo-channel, and stack (SID) selections; set them to match the bitstream
and experiment. Its raw readback layout differs from DDR4.

For U50/U55C, run the HBM2 counterpart
[`examples/read_write_hbm2.py`](../../examples/read_write_hbm2.py):

```bash
python examples/read_write_hbm2.py \
    --pci-bdf 0000:01:00.0 \
    --board u55c \
    --channel 0 \
    --pseudo-channel 0 \
    --sid 0 \
    --pattern 0xDEADBEEF
```

It writes and reads one row at the selected HBM2 location. Each 64-byte
column readback carries both pseudo-channels, so the example verifies the
32-byte half belonging to the selected pseudo-channel.

## Next steps

- [Writing DRAM Bender programs in Python](writing-programs.md) — build,
  inspect, and execute your own programs.
- [`examples/tutorial.ipynb`](../../examples/tutorial.ipynb) — a complete
  notebook tutorial, up to a full RowHammer program.
- [Recover and troubleshoot](../how-to/recover-and-troubleshoot.md) — if any
  step above did not behave as described.
