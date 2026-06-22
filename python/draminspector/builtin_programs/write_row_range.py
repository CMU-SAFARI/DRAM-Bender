from ..api.program import ProgramBuilder
from ..api.program.instructions import *
from ._meta import program_template


@program_template
def write_row_range(bank: int, start_row: int, num_rows: int, pattern):
    """Write ``pattern`` (a length-``words_per_cacheline`` tuple) to every
    cacheline of ``num_rows`` consecutive rows starting at ``start_row``.

    Rows written: ``start_row, start_row+1, ..., start_row+num_rows-1``.
    The hardware loop is do-while; pass ``num_rows >= 1``. Mirrors the C++
    ``init_row_range`` generator (converted from end_row to num_rows).

    ``pattern`` is baked into the JIT specialization at trace time — varying
    it across calls triggers a recompile. For a single pattern broadcast to
    many rows, this is perfect: one compile, patches ``start_row`` and
    ``num_rows`` per call.
    """
    p = ProgramBuilder()
    p.alloc_reg("END_ROW")

    p.LI(bank, "BAR")
    p.LI(num_rows, "END_ROW")
    p.LI(start_row, "RAR")
    # END_ROW = start_row + num_rows (computed at FPGA runtime).
    p.ADD("END_ROW", "RAR", "END_ROW")
    p.LI(p.meta.column_stride, "CASR")

    # Broadcast the scalar pattern word into every lane of PATTERN_REG.
    for index in range(p.meta.words_per_cacheline):
        p.LI(pattern[index], "PATTERN_REG")
        p.LDWD("PATTERN_REG", index)

    # CAR is initialized once outside the loop and keeps incrementing
    # across rows — the DRAM masks column addresses to the row width, so
    # the upper bits are harmless. Matches the C++ init_row_range behavior.
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(2)

    p.LABEL("WR_ROW_BEGIN")
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)

    for _ in range(p.meta.cachelines_per_row):
        p.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)

    p.SLEEP(4)

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(1)
    p.ADDI("RAR", 1, "RAR")
    p.BL("RAR", "END_ROW", "WR_ROW_BEGIN")

    p.SLEEP(3)  # tRP cushion after the last iteration's closing PRE
    return p.conclude()
