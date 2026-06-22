from ..api.program import ProgramBuilder
from ..api.program.instructions import ACT, NOP, PRE, RD
from ._helpers import _emit_short_tras_precharge


def multipulse_short_tras_read_row(
    *,
    bank: int,
    row: int,
    tRAS_cycles: int,
    pulses: int,
    cachelines_per_row: int,
    column_stride: int,
):
    """Run one or more short ACT/PRE pulses before the final full-row read."""
    if int(pulses) < 1:
        raise ValueError("pulses must be at least 1.")

    p = ProgramBuilder()
    p.LI(int(bank), "BAR")
    p.LI(int(row), "RAR")
    p.LI(int(column_stride), "CASR")

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    for _ in range(int(pulses)):
        p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
        _emit_short_tras_precharge(p, int(tRAS_cycles))
        p.SLEEP(3)

    p.LI(0, "CAR")
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    for _ in range(int(cachelines_per_row)):
        p.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)
    p.SLEEP(4)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    return p.conclude()
