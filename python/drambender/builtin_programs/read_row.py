from ..api.program import ProgramBuilder
from ..api.program.instructions import *
from ._meta import program_template


@program_template
def read_row(bank: int, row: int):
    p = ProgramBuilder()
    p.LI(bank, "BAR")
    p.LI(row, "RAR")
    p.LI(p.meta.column_stride, "CASR")

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(2)

    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())

    p.SLEEP(2)
    for _ in range(p.meta.cachelines_per_row):
        p.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)
    p.SLEEP(4)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    return p.conclude()
