#!/usr/bin/env python3
"""Read HBM power and temperature from a U55C over the CMS (hardware test).

Opens an Alveo U55C by PCI BDF and samples ``read_power_telemetry()`` a few
times, reporting the HBM 1.2V rail power and the HBM stack temperatures. Power
telemetry is a U55C-only feature (the U50 design has no CMS monitoring), so this
test targets U55C.

This is a hardware-in-the-loop test: it requires a programmed U55C with the
CMS-enabled bitstream and access to the card's ``/dev/xdma*_user`` node.

Example:
    python power_telemetry_test.py --pci-bdf 0000:81:00.0 --samples 5
"""

from __future__ import annotations

import argparse
import re
import sys
import time

from drambender.api import HBM2U55C

PCI_BDF_RE = re.compile(
    r"^[0-9a-fA-F]{4}:[0-9a-fA-F]{2}:(?P<slot>[0-9a-fA-F]{2})\.[0-7]$"
)

# Plausibility bounds used only to catch an unconfigured CMS (all-zero reads) or
# obviously wrong register offsets. They are deliberately loose.
HBM_VOLTAGE_MIN_MV = 900
HBM_VOLTAGE_MAX_MV = 1500
HBM_TEMP_MAX_CELSIUS = 125


def parse_pci_bdf(text: str) -> str:
    match = PCI_BDF_RE.fullmatch(text)
    if match is None or int(match.group("slot"), 16) > 0x1F:
        raise argparse.ArgumentTypeError(
            "PCI BDF must use complete dddd:bb:ss.f form, for example 0000:81:00.0"
        )
    return text.lower()


def print_sample(index: int, telemetry) -> None:
    hbm = telemetry.hbm
    power = hbm.power_mw
    t0 = telemetry.hbm_temp0_celsius
    t1 = telemetry.hbm_temp1_celsius
    print(
        f"[{index}] HBM 1.2V: "
        f"V={hbm.voltage_mv.instant} mV, I={hbm.current_ma.instant} mA, "
        f"P(ins/max/avg)={power.instant}/{power.max}/{power.average} mW | "
        f"temp0={t0.instant} C, temp1={t1.instant} C"
    )


def check_sample(telemetry) -> None:
    v = telemetry.hbm.voltage_mv.instant
    if not (HBM_VOLTAGE_MIN_MV <= v <= HBM_VOLTAGE_MAX_MV):
        raise AssertionError(
            f"HBM 1.2V rail reads {v} mV, outside "
            f"[{HBM_VOLTAGE_MIN_MV}, {HBM_VOLTAGE_MAX_MV}] "
            "(CMS not ready, or wrong register offsets?)"
        )
    for name, temp in (("temp0", telemetry.hbm_temp0_celsius),
                       ("temp1", telemetry.hbm_temp1_celsius)):
        if not (0 < temp.instant <= HBM_TEMP_MAX_CELSIUS):
            raise AssertionError(
                f"HBM {name} reads {temp.instant} C, outside (0, {HBM_TEMP_MAX_CELSIUS}]"
            )


def main() -> int:
    parser = argparse.ArgumentParser(description="U55C HBM power/temperature telemetry test")
    parser.add_argument("--pci-bdf", type=parse_pci_bdf, required=True)
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument("--samples", type=int, default=5)
    parser.add_argument("--interval", type=float, default=0.5,
                        help="seconds between samples")
    args = parser.parse_args()

    try:
        with HBM2U55C(args.pci_bdf, args.xdma_channel) as board:
            if not board.power_telemetry_supported:
                raise AssertionError("board reports power telemetry unsupported")
            for i in range(args.samples):
                telemetry = board.read_power_telemetry()
                print_sample(i, telemetry)
                check_sample(telemetry)
                if i + 1 < args.samples:
                    time.sleep(args.interval)
    except Exception as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    print(f"PASS: read {args.samples} HBM power/temperature sample(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
