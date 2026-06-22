from ..api.program import ProgramBuilder
from ..api.program.instructions import ACT, NOP, PRE, WR
from ._helpers import _normalize_pattern_words


def write_row_ordered(
    *,
    bank: int,
    row: int,
    pattern_words,
    cachelines_per_row: int,
    words_per_cacheline: int,
    column_stride: int,
    row_init_order: str = "forward",
):
    """Write a full row with explicit forward or reverse cacheline order."""
    order = str(row_init_order).strip().lower()
    if order not in {"forward", "reverse"}:
        raise ValueError("row_init_order must be 'forward' or 'reverse'.")
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
    p.SLEEP(2)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)

    if order == "forward":
        p.LI(0, "CAR")
        for _ in range(int(cachelines_per_row)):
            p.DRAM(WR("BAR", "CAR", icar=0), NOP(), NOP(), NOP())
            p.SLEEP(1)
            p.ADDI("CAR", int(column_stride), "CAR")
    else:
        p.LI((int(cachelines_per_row) - 1) * int(column_stride), "CAR")
        for _ in range(int(cachelines_per_row)):
            p.DRAM(WR("BAR", "CAR", icar=0), NOP(), NOP(), NOP())
            p.SLEEP(1)
            p.SUBI("CAR", int(column_stride), "CAR")

    p.SLEEP(8)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    return p.conclude()
