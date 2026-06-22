from ..api.program import ProgramBuilder
from ..api.program.instructions import *
from ._meta import program_template


@program_template
def read_row_range(bank: int, start_row: int, num_rows: int):
    """Sequentially read ``num_rows`` consecutive rows starting at ``start_row``.

    Rows read: ``start_row, start_row+1, ..., start_row+num_rows-1``.
    The hardware loop is do-while; pass ``num_rows >= 1``. Mirrors the C++
    ``read_row_range`` generator (converted from end_row to num_rows).

    Readback size per row = ``cachelines_per_row * words_per_cacheline * 4``
    bytes; total = that × ``num_rows``.
    """
    p = ProgramBuilder()
    p.alloc_reg("END_ROW")

    p.LI(bank, "BAR")
    p.LI(num_rows, "END_ROW")
    p.LI(start_row, "RAR")
    # END_ROW = start_row + num_rows (computed at FPGA runtime so both args
    # stay as patchable scalars).
    p.ADD("END_ROW", "RAR", "END_ROW")
    p.LI(p.meta.column_stride, "CASR")

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)

    p.LABEL("RD_ROW_BEGIN")
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(1)

    for _ in range(p.meta.cachelines_per_row):
        p.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)

    p.SLEEP(3)

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.ADDI("RAR", 1, "RAR")
    p.BL("RAR", "END_ROW", "RD_ROW_BEGIN")

    p.SLEEP(3)  # tRP cushion after the last iteration's closing PRE
    return p.conclude()
