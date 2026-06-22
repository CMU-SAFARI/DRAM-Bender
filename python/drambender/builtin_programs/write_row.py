from ..api.program import ProgramBuilder
from ..api.program.instructions import *
from ._meta import program_template


@program_template
def write_row(bank: int, row: int, pattern):
    p = ProgramBuilder()
    p.LI(bank, "BAR")
    p.LI(row, "RAR")
    p.LI(p.meta.column_stride, "CASR")
    for index in range(p.meta.words_per_cacheline):
        p.LI(pattern[index], "PATTERN_REG")
        p.LDWD("PATTERN_REG", index)

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(2)

    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())

    p.SLEEP(2)
    for _ in range(p.meta.cachelines_per_row):
        p.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)
    p.SLEEP(8)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)  # tRP cushion
    return p.conclude()
