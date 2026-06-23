from ..api.program import ProgramBuilder, program_template
from ..api.program.instructions import *


@program_template
def double_sided_rowhammer(
    bank: int,
    aggressor_row_1: int,
    aggressor_row_2: int,
    hammer_count: int,
):
    p = ProgramBuilder()
    p.alloc_reg("NUM_HMR")
    p.alloc_reg("HMR_COUNTER")

    p.LI(bank, "BAR")
    p.LI(aggressor_row_1, "RAR")
    p.LI(0, "HMR_COUNTER")
    p.LI(hammer_count, "NUM_HMR")

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
