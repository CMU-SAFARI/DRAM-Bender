from ..api.program import ProgramBuilder
from ..api.program.instructions import ACT, NOP, PRE, RD
from ._helpers import _emit_short_tras_precharge


def short_tras_read_row(
    *,
    bank: int,
    row: int,
    tRAS_cycles: int,
    cachelines_per_row: int,
    column_stride: int,
):
    """Issue one short ACT/PRE window, then read the full row."""
    p = ProgramBuilder()
    p.LI(int(bank), "BAR")
    p.LI(int(row), "RAR")
    p.LI(int(column_stride), "CASR")
    p.LI(0, "CAR")

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    _emit_short_tras_precharge(p, int(tRAS_cycles))

    p.SLEEP(3)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)

    for _ in range(int(cachelines_per_row)):
        p.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)

    p.SLEEP(4)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    return p.conclude()
