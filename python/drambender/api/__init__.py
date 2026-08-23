"""DRAMBender API — the single canonical namespace for every user-visible name.

Submodules:

  - api.board      — Board classes, BoardType, HostInterface, open_board, ...
  - api.board_configs — Canonical U200, U50, and U55C BoardConfig objects.
  - api.execution  — VM / trace types: ExecutionResult, DRAMCommandTrace, ...
  - api.program    — ProgramBuilder, DDR4Target, HBM2Target, program_template;
                     DRAM command factories in `api.program.instructions`;
                     raw SMC factories in `api.program.raw_instructions`.

To receive readback data after `board.execute(...)`, allocate a numpy buffer
and call `board.receive_into(buf)` followed by `board.synchronize()` to wait
for readback completion and surface asynchronous receive errors. XOR against
the expected pattern with numpy — no wrapper helpers are shipped.

Every name in `__all__` below is re-exported here for convenience. The
canonical definitions live in the submodules above.
"""

from . import board_configs
from .board import (
    Board,
    BoardConfig,
    BoardType,
    DDR4,
    HBM2,
    HBM2U50,
    HBM2U55C,
    HBMTemperature,
    HostInterface,
    MemoryType,
    PowerTelemetry,
    RailTelemetry,
    SensorStat,
    get_board_config,
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
    DDR4Target,
    FinalProgram,
    HBM2Target,
    HBM2U50Target,
    HBM2U55CTarget,
    Program,
    ProgramBuilder,
    program_template,
)

__all__ = [
    "Board",
    "BoardConfig",
    "BoardType",
    "BranchType",
    "DDR4",
    "DDR4Target",
    "DRAMCommandEvent",
    "DRAMCommandTrace",
    "ExecutionResult",
    "FinalProgram",
    "HBM2",
    "HBM2Target",
    "HBM2U50",
    "HBM2U55C",
    "HBM2U50Target",
    "HBM2U55CTarget",
    "HBMTemperature",
    "HostInterface",
    "MemoryType",
    "PCType",
    "PowerTelemetry",
    "Program",
    "ProgramBuilder",
    "RailTelemetry",
    "SensorStat",
    "TimingStat",
    "TimingSummary",
    "board_configs",
    "get_board_config",
    "open_board",
    "program_template",
]
