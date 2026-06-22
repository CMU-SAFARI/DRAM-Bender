"""Execution, VM-simulator, and DRAM-trace types."""

from dataclasses import dataclass
import math

from .._core import (
    BranchType,
    DRAMCommandEvent,
    DRAMCommandTrace,
    ExecutionResult,
    PCType,
)


@dataclass(frozen=True)
class TimingStat:
    """Min/max (in ns) and sample count for one DRAM timing parameter."""

    min_ns: float
    max_ns: float
    count: int


@dataclass(frozen=True)
class TimingSummary:
    """Observed tRCD / tRAS / tRP across a DRAM command trace.

    - ``tRCD`` — ACT → first RD/WR on the same bank, per row activation.
    - ``tRAS`` — ACT → PRE on the same bank.
    - ``tRP``  — PRE → ACT on the same bank.

    Each field is a :class:`TimingStat` with min/max/count.
    """

    tRCD: TimingStat
    tRAS: TimingStat
    tRP: TimingStat

    def __str__(self) -> str:
        lines = ["Timing summary (ns):"]
        for label, stat in (("tRCD", self.tRCD), ("tRAS", self.tRAS), ("tRP", self.tRP)):
            if stat.count == 0:
                lines.append(f"  {label:<4}  (no samples)")
            else:
                lines.append(
                    f"  {label:<4}  min={stat.min_ns:>7.1f}  "
                    f"max={stat.max_ns:>7.1f}  n={stat.count}"
                )
        return "\n".join(lines)


def _summarize_timings(self: DRAMCommandTrace) -> TimingSummary:
    """Compute min/max tRCD/tRAS/tRP observed in this trace.

    Groups commands by bank. ``tRCD`` is measured as ACT → first RD/WR
    following the activation (subsequent column accesses within the same
    row are tCCD, not tRCD, so they're excluded).
    """
    last_act: dict[int, float | None] = {}
    last_pre: dict[int, float | None] = {}
    rcd_recorded: dict[int, bool] = {}

    trcd_min = math.inf
    trcd_max = -math.inf
    trcd_n = 0
    tras_min = math.inf
    tras_max = -math.inf
    tras_n = 0
    trp_min = math.inf
    trp_max = -math.inf
    trp_n = 0

    for event in self.events:
        bank = event.bank
        if bank is None:
            continue
        cmd = event.command
        t = event.time_ns

        if cmd == "ACT":
            pre_t = last_pre.get(bank)
            if pre_t is not None:
                dt = t - pre_t
                trp_min = min(trp_min, dt)
                trp_max = max(trp_max, dt)
                trp_n += 1
            last_act[bank] = t
            rcd_recorded[bank] = False
        elif cmd == "PRE":
            act_t = last_act.get(bank)
            if act_t is not None:
                dt = t - act_t
                tras_min = min(tras_min, dt)
                tras_max = max(tras_max, dt)
                tras_n += 1
                last_act[bank] = None
            last_pre[bank] = t
        elif cmd in ("RD", "WR"):
            act_t = last_act.get(bank)
            if act_t is not None and not rcd_recorded.get(bank, False):
                dt = t - act_t
                trcd_min = min(trcd_min, dt)
                trcd_max = max(trcd_max, dt)
                trcd_n += 1
                rcd_recorded[bank] = True

    def _stat(n: int, mn: float, mx: float) -> TimingStat:
        if n == 0:
            return TimingStat(min_ns=0.0, max_ns=0.0, count=0)
        return TimingStat(min_ns=mn, max_ns=mx, count=n)

    return TimingSummary(
        tRCD=_stat(trcd_n, trcd_min, trcd_max),
        tRAS=_stat(tras_n, tras_min, tras_max),
        tRP=_stat(trp_n, trp_min, trp_max),
    )


# Attach to the nanobind-bound DRAMCommandTrace so callers can do:
#     trace = program.trace_dram_commands()
#     print(trace.summarize_timings())
DRAMCommandTrace.summarize_timings = _summarize_timings


__all__ = [
    "BranchType",
    "DRAMCommandEvent",
    "DRAMCommandTrace",
    "ExecutionResult",
    "PCType",
    "TimingStat",
    "TimingSummary",
]
