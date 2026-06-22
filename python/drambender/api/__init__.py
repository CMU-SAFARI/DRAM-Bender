"""DRAMBender API — the single canonical namespace for every user-visible name.

Submodules:

  - api.board      — Board classes, BoardType, HostInterface, open_board, ...
  - api.execution  — VM / trace types: ExecutionResult, DRAMCommandTrace, ...
  - api.program    — ProgramBuilder, program_template; DRAM command factories
                     in `api.program.instructions`; raw SMC factories in
                     `api.program.raw_instructions`.

To receive readback data after `board.execute(...)`, allocate a numpy buffer
and call `board.receive_into(buf)` followed by `board.synchronize()` to wait
for readback completion and surface asynchronous receive errors. XOR against
the expected pattern with numpy — no wrapper helpers are shipped.

Every name in `__all__` below is re-exported here for convenience. The
canonical definitions live in the submodules above.
"""

from .board import (
    Board,
    BoardType,
    DDR4,
    HBM2,
    HBMTemperature,
    HostInterface,
    open_board,
)
from .execution import (
    BranchType,
    DRAMCommandEvent,
    DRAMCommandTrace,
    ExecutionResult,
    PCType,
    TimingStat,
    TimingSummary,
)
from .program import (
    FinalProgram,
    Program,
    ProgramBuilder,
    program_template,
)

__all__ = [
    "Board",
    "BoardType",
    "BranchType",
    "DDR4",
    "DRAMCommandEvent",
    "DRAMCommandTrace",
    "ExecutionResult",
    "FinalProgram",
    "HBM2",
    "HBMTemperature",
    "HostInterface",
    "PCType",
    "Program",
    "ProgramBuilder",
    "TimingStat",
    "TimingSummary",
    "open_board",
    "program_template",
]
