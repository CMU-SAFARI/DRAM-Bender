from ..api.program import HBM2Target, ProgramBuilder
from ..api.program.instructions import *
from ._meta import program_template


@program_template
def write_row(target, bank: int, row: int, pattern):
    p = ProgramBuilder(target=target)
    p.LI(target.physical_bank(bank), "BAR")
    p.LI(row, "RAR")
    p.LI(target.column_stride, "CASR")
    for index in range(target.words_per_cacheline):
        p.LI(pattern[index], "PATTERN_REG")
        p.LDWD("PATTERN_REG", index)

    if isinstance(target, HBM2Target):
        p.DRAM(SEL_CH(target), NOP(), NOP(), NOP())
        p.SLEEP(10)

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(2)

    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())

    p.SLEEP(2)
    for _ in range(target.columns_per_row):
        p.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)
    p.SLEEP(8)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)  # tRP cushion
    return p.conclude()
