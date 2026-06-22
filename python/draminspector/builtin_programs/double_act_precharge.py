from ..api.program import ProgramBuilder
from ..api.program.instructions import ACT, NOP, PRE
from ._helpers import _require_nonnegative_timing


def double_act_precharge(
    bank: int,
    src_row: int,
    dst_row: int,
    t1: int,
    t2: int,
    t3: int,
):
    """Build a RowClone-style ACT(src)/PRE/ACT(dst)/PRE primitive."""
    _require_nonnegative_timing("t1", t1)
    _require_nonnegative_timing("t2", t2)
    _require_nonnegative_timing("t3", t3)

    p = ProgramBuilder()
    p.alloc_reg("RAR_2")

    p.LI(int(bank), "BAR")
    p.LI(int(src_row), "RAR")
    p.LI(int(dst_row), "RAR_2")

    total = 4 + int(t1) + int(t2) + int(t3)
    num_cmd = ((total + 3) // 4) * 4
    slots = [NOP()] * num_cmd
    slots[0] = ACT("BAR", "RAR")
    slots[int(t1) + 1] = PRE("BAR")
    slots[2 + int(t1) + int(t2)] = ACT("BAR", "RAR_2")
    slots[3 + int(t1) + int(t2) + int(t3)] = PRE("BAR")

    for i in range(0, num_cmd, 4):
        p.DRAM(slots[i], slots[i + 1], slots[i + 2], slots[i + 3])

    p.SLEEP(3)
    return p.conclude()
