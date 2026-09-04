# DRAM Bender

DRAM Bender is an FPGA-based infrastructure for experimental DRAM research. It
provides direct control over low-level DRAM commands and their timing while
retaining general-purpose registers, arithmetic instructions, branches, and
program-controlled data movement. Researchers can use these features to study
DRAM reliability, security, performance, and energy behavior.

DRAM Bender builds on [SoftMC](https://github.com/CMU-SAFARI/SoftMC). This
repository contains the Python and C++ APIs, the FPGA RTL, Vivado projects for
the maintained boards, the PCIe driver, and example programs.

## What's New in v2

Version 2 is a ground-up overhaul of the previous public release. Board
support now focuses on the Alveo U200, U50, and the newly added U55C, with all
Vivado projects upgraded to 2024.2 and prebuilt bitstreams moved to a
submodule. The host software was
rewritten as an installable C++20 library with a first-class, pip-installable
Python API that adds a program builder, target-aware built-in programs, a
tracing JIT for program templates, and a software VM for validating programs
without hardware. Boards are now selected by PCI BDF instead of a fixed device
path, DDR4 and HBM2 share one unified API driven by a central board
configuration registry, and readback uses a framed metadata protocol that
makes completion deterministic. The bundled XDMA driver became a clearly
identified fork (`drambender_xdma`) with a credit-based cyclic receive path
and exclusive endpoint ownership, the U55C gained power and thermal telemetry,
and the repository gained a qualification test suite and this
Diátaxis-structured documentation. The full list is in
[docs/reference/changes-in-v2.md](docs/reference/changes-in-v2.md).

## Cite DRAM Bender

Please cite the following paper if you use DRAM Bender:

Ataberk Olgun, Hasan Hassan, A. Giray Yağlıkçı, Yahya Can Tuğrul, Lois Orosa,
Haocong Luo, Minesh Patel, Oğuz Ergin, and Onur Mutlu, "DRAM Bender: An
Extensible and Versatile FPGA-Based Infrastructure to Easily Test
State-of-the-Art DRAM Chips," *IEEE Transactions on Computer-Aided Design of
Integrated Circuits and Systems*, vol. 42, no. 12, pp. 5098-5112, 2023.

- DOI: <https://doi.org/10.1109/TCAD.2023.3282172>
- Paper: <https://arxiv.org/abs/2211.05838>
- PDF: <https://arxiv.org/pdf/2211.05838.pdf>

```bibtex
@article{olgun2023drambender,
  author  = {Olgun, Ataberk and Hassan, Hasan and Yağlıkçı, A. Giray and
             Tuğrul, Yahya Can and Orosa, Lois and Luo, Haocong and
             Patel, Minesh and Ergin, Oğuz and Mutlu, Onur},
  title   = {{DRAM Bender: An Extensible and Versatile FPGA-Based
              Infrastructure to Easily Test State-of-the-Art DRAM Chips}},
  journal = {IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems},
  year    = {2023},
  volume  = {42},
  number  = {12},
  pages   = {5098--5112},
  doi     = {10.1109/TCAD.2023.3282172}
}
```

## Supported FPGA Boards

DRAM Bender officially supports the AMD/Xilinx Alveo **U200** (external DDR4),
**U50** (on-board HBM2), and **U55C** (on-board HBM2). Board details, program
targets, API board configurations, and Vivado versions are listed in
[docs/reference/supported-boards.md](docs/reference/supported-boards.md).

## Quick Start

On a prepared Linux host with a supported board (see the
[prerequisites](docs/tutorials/getting-started.md#hardware-prerequisites)):

```bash
git clone https://github.com/CMU-SAFARI/DRAM-Bender.git
cd DRAM-Bender
git submodule update --init hw/prebuilt

# Program the FPGA over JTAG (single-target U200 host shown).
export VIVADO_EXEC=/path/to/vivado_or_vivado_lab
hw/scripts/program_fpga.sh XCU200 <bitstream-name-without-extension>

# Build and load the DRAM Bender XDMA driver (a modified Xilinx fork).
cd xdma && ./build_driver.sh && sudo ./install_access.sh --user "$USER" \
    && sudo ./load_driver.sh && cd ..

# Install the Python API and run one DDR4 read/write test.
PYTHON_BIN=python3.12 bash setup_venv.sh
source .venv/bin/activate
python examples/read_write.py --board u200 --pci-bdf 0000:01:00.0 --xdma-channel 0 \
    --bank 0 --row 0 --pattern 0xDEADBEEF
```

Each step, with verification and board variations, is explained in the
[getting-started tutorial](docs/tutorials/getting-started.md).

## Documentation

The documentation under [`docs/`](docs/README.md) follows the
[Diátaxis](https://diataxis.fr/) structure:

| You want to... | Go to |
|---|---|
| Learn by doing: install everything, run a first test, write programs | [Tutorials](docs/README.md#tutorials) |
| Do one task: obtain or build a bitstream, install the driver, find an endpoint, read telemetry, recover | [How-to guides](docs/README.md#how-to-guides) |
| Look up boards, the ISA, or the Python/C++ APIs | [Reference](docs/README.md#reference) |
| Understand the pipeline, the readback protocol, or the driver fork | [Explanation](docs/README.md#explanation) |

## Repository File Structure

```text
.
├── docs/                     # Documentation (tutorials, how-to, reference, explanation)
├── examples/                 # Python and C++ examples and the tutorial
├── hw/
│   ├── rtl/                  # Common DRAM Bender RTL
│   ├── projects/             # Board-specific Vivado projects
│   ├── scripts/              # FPGA programming and generation scripts
│   ├── sim/                  # RTL simulation sources
│   └── prebuilt/             # Released bitstreams (git submodule)
├── include/drambender/       # Public C++ headers
├── python/drambender/        # Python package
├── src/                      # C++ implementation and Python bindings
├── internal_tests/           # Internal software and hardware qualification
├── xdma/                     # DRAM Bender XDMA driver
├── build.sh                  # Local C++ and Python build helper
└── setup_venv.sh             # Python environment setup
```

## Known Issues

- The readback metadata protocol is a boundary between the bitstream and the
  host software. Use the bitstream distributed for this software. See
  [the readback protocol](docs/explanation/readback-protocol.md).
- The XDMA driver is a modified fork and must not be loaded together with the
  stock Xilinx `xdma` module. There is no automatic rebuild hook: rebuild and
  reload the driver after any kernel change. See
  [why the driver is a fork](docs/explanation/xdma-fork.md).
- A U200 bitstream must exactly match the installed DIMM organization and
  slot; a mismatched image fails in non-obvious ways (for example, wrong
  readback sizes).
- The API in this repository differs in places from the API described in the
  DRAM Bender publication.

## Contributing

Contributions that add experiments, improve the APIs, extend the ISA, or add a
new board adapter should include documentation and software tests. Hardware
changes should identify the target board, memory configuration, Vivado version,
and constraints used to generate the image.

Use the repository issue tracker for bug reports and feature requests.

## Contacts

Those who discover or resolve issues, or adapt DRAM Bender to additional FPGA
boards, are encouraged to reach out to:

- Ataberk Olgun (ataberk.olgun [at] safari [dot] ethz [dot] ch)
- Haocong Luo (haocong.luo [at] safari [dot] ethz [dot] ch)

## License

DRAM Bender is distributed under the terms in [`LICENSE`](LICENSE).
