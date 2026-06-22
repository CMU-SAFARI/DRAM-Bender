from collections.abc import Iterable

from ..api.program import ProgramBuilder
from ..api.program.instructions import ACT, NOP, PRE, WR
from ._helpers import _normalize_cacheline_ids, _normalize_pattern_words


def write_cachelines(
    *,
    bank: int,
    row: int,
    cacheline_ids: Iterable[int],
    pattern_words,
    cachelines_per_row: int,
    words_per_cacheline: int,
    column_stride: int,
):
    """Write selected cachelines while preserving full-row column cadence."""
    cachelines = _normalize_cacheline_ids(
        cacheline_ids,
        cachelines_per_row=cachelines_per_row,
    )
    pattern = _normalize_pattern_words(
        pattern_words,
        words_per_cacheline=words_per_cacheline,
    )

    p = ProgramBuilder()
    p.LI(int(bank), "BAR")
    p.LI(int(row), "RAR")
    p.LI(int(column_stride), "CASR")
    for index in range(int(words_per_cacheline)):
        p.LI(pattern[index], "PATTERN_REG")
        p.LDWD("PATTERN_REG", index)

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(2)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)

    selected = set(cachelines)
    for cacheline in range(int(cachelines_per_row)):
        if cacheline in selected:
            p.DRAM(WR("BAR", "CAR", icar=0), NOP(), NOP(), NOP())
            p.SLEEP(1)
        p.ADDI("CAR", int(column_stride), "CAR")

    p.SLEEP(8)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    return p.conclude()
