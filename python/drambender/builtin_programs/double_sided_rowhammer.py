from ..api.program import HBM2Target, ProgramBuilder
from ..api.program.instructions import *
from ._meta import program_template


@program_template
def double_sided_rowhammer(
    target,
    bank: int,
    aggressor_row_1: int,
    aggressor_row_2: int,
    hammer_count: int,
):
    p = ProgramBuilder(target=target)
    p.alloc_reg("NUM_HMR")
    p.alloc_reg("HMR_COUNTER")

    p.LI(target.physical_bank(bank), "BAR")
    p.LI(aggressor_row_1, "RAR")
    p.LI(0, "HMR_COUNTER")
    p.LI(hammer_count, "NUM_HMR")

    if isinstance(target, HBM2Target):
        p.DRAM(SEL_CH(target), NOP(), NOP(), NOP())
        p.SLEEP(10)

    p.LABEL("HMR_BEGIN")
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(aggressor_row_1, "RAR")
    p.DRAM(NOP(), NOP(), NOP(), ACT("BAR", "RAR"))
    p.LI(aggressor_row_2, "RAR")
    p.SLEEP(5)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.ADDI("HMR_COUNTER", 1, "HMR_COUNTER")
    p.DRAM(NOP(), NOP(), NOP(), ACT("BAR", "RAR"))
    p.BL("HMR_COUNTER", "NUM_HMR", "HMR_BEGIN")
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)  # tRP cushion
    return p.conclude()
