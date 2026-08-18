# Read Power and Temperature Telemetry (U55C)

The Alveo U55C design exposes card power and thermal telemetry through the Card
Management Subsystem (CMS). `HBM2U55C` reads it with `read_power_telemetry()`.
This is a U55C-only feature; `HBM2U50` reports `power_supported == False` and
raises if you call it.

Telemetry is read over the card's `/dev/xdma*_user` node, which is separate from
the program/readback path. It does not require a running program.

```python
from drambender.api import HBM2U55C

with HBM2U55C("0000:81:00.0") as board:
    t = board.read_power_telemetry()

    # HBM 1.2V rail: each field is instant / max / average.
    hbm_power = t.hbm.power_mw            # milliwatts (a property, no parentheses)
    print("HBM power (mW):", hbm_power.instant, hbm_power.max, hbm_power.average)
    print("HBM voltage (mV):", t.hbm.voltage_mv.instant)
    print("HBM current (mA):", t.hbm.current_ma.instant)
    print("HBM temps (C):", t.hbm_temp0_celsius.instant, t.hbm_temp1_celsius.instant)

    # Full per-rail telemetry is available: pex_12v, pex_3v3, vccint, vccint_io, hbm.
    print("Total card input power (mW):", t.total_input_power_mw.instant)
```

Every rail exposes `voltage_mv`, `current_ma`, and derived `power_mw`, each a
`SensorStat` with `instant`, `max`, and `average` fields. `power_mw` is
`voltage_mv * current_ma / 1000`; its `max` field is the product of the maxima
(an upper envelope, not a simultaneous sample). `total_input_power_mw` is the
sum of the two PCIe input rails (12V + 3.3V).

A hardware smoke test is in
[`tests/board_tests/power_telemetry_test.py`](../../tests/board_tests/power_telemetry_test.py):

```bash
python tests/board_tests/power_telemetry_test.py --pci-bdf 0000:81:00.0 --samples 5
```
