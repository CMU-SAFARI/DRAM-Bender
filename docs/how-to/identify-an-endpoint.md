# Identify an FPGA Endpoint

The Linux driver creates names such as:

```text
/dev/xdma0_h2c_0
/dev/xdma0_c2h_0
```

The fields have the following meanings:

| Field | Meaning |
|---|---|
| `xdma0` | Driver probe-order index |
| `h2c` or `c2h` | Host-to-card or card-to-host direction |
| final `_0` | XDMA channel on that PCI function |

These nodes remain the transport endpoints used by the API. Selecting by BDF
does not replace their direction or channel semantics. It provides a stable
way to find the correct pair without relying on the probe-order prefix.

The direction and channel names are meaningful, but the `xdmaN` number is not
a persistent physical-board identity. Probe order can change after a driver
reload, a host restart, or a hardware change. Applications therefore select an
endpoint using the complete PCI BDF and XDMA channel:

```text
0000:01:00.0, XDMA channel 0
```

List Xilinx PCI functions and inspect the XDMA sysfs paths:

```bash
lspci -D -d 10ee:
readlink -f /sys/class/xdma/xdma*_h2c_*
```

The canonical BDF has the form `dddd:bb:ss.f`. The API resolves the requested
BDF and channel to the current H2C/C2H device-node pair and verifies that both
directions belong to the same PCI function. Use a separate board handle for
each independent BDF/channel endpoint.

For running several endpoints at once, see
[Use multiple boards and channels](use-multiple-boards.md).
