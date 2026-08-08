from collections.abc import Sequence
import enum
from typing import overload

from . import instructions as instructions
from drambender.api.execution import TimingSummary


class HostInterface(enum.Enum):
    XDMA = 0

    QDMA = 1

    Ethernet = 2

class BoardType(enum.Enum):
    DDR4 = 0

    HBM2 = 1

class PCType(enum.Enum):
    WRITE = 0

    READ = 1

    PRE = 2

    ACT = 3

    SEL_CH = 4

    REF = 5

    CYC = 6

class BranchType(enum.Enum):
    BEQ = 0

    BL = 1

    JUMP = 2

class HBMTemperature:
    """Temperatures reported by an HBM2 board, in degrees Celsius."""

    @property
    def stack0_celsius(self) -> int: ...

    @stack0_celsius.setter
    def stack0_celsius(self, arg: int, /) -> None: ...

    @property
    def stack1_celsius(self) -> int: ...

    @stack1_celsius.setter
    def stack1_celsius(self, arg: int, /) -> None: ...

class Program:
    def __init__(self) -> None: ...

    def add_mininst(self, arg0: int, arg1: int, /) -> Program: ...

    def add_DRAM_wait(self, arg: int, /) -> Program: ...

    @overload
    def add_inst(self, arg: int, /) -> Program: ...

    @overload
    def add_inst(self, arg0: int, arg1: int, arg2: int, arg3: int, /) -> Program: ...

    def add_label(self, arg: str, /) -> Program: ...

    def add_branch(self, arg0: BranchType, arg1: int, arg2: int, arg3: str, /) -> Program: ...

    def add_below(self, arg: Program, /) -> Program: ...

    def flush(self) -> Program: ...

    def conclude(self) -> FinalProgram: ...

    def __str__(self) -> str: ...

    def __repr__(self) -> str: ...

class FinalProgram:
    def __init__(self, arg: Sequence[int], /) -> None: ...

    def instructions(self) -> list[int]: ...

    @property
    def instruction_count(self) -> int: ...

    def __len__(self) -> int: ...

    def size(self) -> int: ...

    def dry_run(self, max_instructions: int, dram_inst_latency: float = 1.5, num_dram_insts_per_fabric_cycle: int = 4) -> ExecutionResult: ...

    def trace_dram_commands(self, max_instructions: int = 100000000, dram_inst_latency: float = 1.5, num_dram_insts_per_fabric_cycle: int = 4) -> DRAMCommandTrace: ...

    def __str__(self) -> str: ...

    def __repr__(self) -> str: ...

class DRAMCommandEvent:
    @property
    def command(self) -> str: ...

    @property
    def pc(self) -> int: ...

    @property
    def slot(self) -> int: ...

    @property
    def time_ns(self) -> float: ...

    @property
    def delta_ns(self) -> float: ...

    @property
    def bank(self) -> object: ...

    @property
    def row(self) -> object: ...

    @property
    def column(self) -> object: ...

    @property
    def rank(self) -> object: ...

    @property
    def channel(self) -> object: ...

    @property
    def pseudo_channel(self) -> object: ...

    @property
    def auto_precharge(self) -> bool: ...

    @property
    def precharge_all(self) -> bool: ...

    def __repr__(self) -> str: ...

class DRAMCommandTrace:
    @property
    def events(self) -> list[DRAMCommandEvent]: ...

    @property
    def truncated(self) -> bool: ...

    @property
    def instructions_executed(self) -> int: ...

    @property
    def total_cycles(self) -> int: ...

    @property
    def total_ns(self) -> float: ...

    def __len__(self) -> int: ...

    def __str__(self) -> str: ...

    def __repr__(self) -> str: ...

    # Monkey-patched onto DRAMCommandTrace at module-import time by
    # drambender.api.execution. Declared here so Pylance sees it.
    def summarize_timings(self) -> "TimingSummary": ...

class ExecutionResult:
    @property
    def total_cycles(self) -> int: ...

    @property
    def total_ns(self) -> float: ...

    @property
    def registers(self) -> list[int]: ...

    @property
    def dram_cmd_counts(self) -> dict: ...

    @property
    def instructions_executed(self) -> int: ...

    @property
    def branches_taken(self) -> int: ...

    def __str__(self) -> str: ...

    def __repr__(self) -> str: ...

class Board:
    """Open FPGA board handle.

    Use it to execute programs, receive readback data, reset the board, and
    release the host connection when finished.
    """

    def execute(self, arg: object, /) -> None:
        """Send one program, or a list/tuple of programs, to the board.

        If the program returns data, call receive_into() for the bytes you
        expect and synchronize() as a barrier.
        """
        ...

    def synchronize(self) -> None:
        """Wait for active readback to finish and surface async receive errors.

        This does not consume, discard, or drain queued readback data.
        """
        ...

    def receive_into(self, arg: object, /) -> int:
        """Copy queued readback data into a writable C-contiguous buffer.

        The buffer size must be a multiple of four bytes. This blocks until the
        buffer is full or the receive session fails.
        """
        ...

    def set_aref(self, arg: bool, /) -> None:
        """Enable or disable FPGA-managed DRAM auto-refresh."""
        ...

    def reset_fpga(self) -> None:
        """Send the FPGA reset control packet.

        Use full_reset() when recovering from stale data, a stuck readback, or
        a failed receive session.
        """
        ...

    def full_reset(self) -> None:
        """Cancel active readback, reset FPGA logic, drain stale host readback,
        and clear queued software readback.
        """
        ...

    def close(self) -> None:
        """Release the host connection."""
        ...

    @property
    def is_closed(self) -> bool:
        """True after the host connection has been released."""
        ...

    def __enter__(self) -> Board: ...

    def __exit__(self, *args) -> bool: ...

class DDR4(Board):
    """DDR4-backed DRAM Bender board."""

    def __init__(self, pci_bdf: str, xdma_channel: int = 0, host_interface: HostInterface = HostInterface.XDMA) -> None: ...

class HBM2(Board):
    """HBM2-backed DRAM Bender board."""

    def __init__(self, pci_bdf: str, xdma_channel: int = 0, host_interface: HostInterface = HostInterface.XDMA) -> None: ...

    def read_temperature(self) -> HBMTemperature:
        """Read the current HBM stack temperatures in degrees Celsius."""
        ...

    def discard_readback_data(self, discard: bool) -> None:
        """Enable or disable discarding HBM readback data."""
        ...

    def set_broadcast_channels(self, channels: list[int]) -> None:
        """Configure the optional HBM command broadcast channel mask."""
        ...

def open_board(board_type: BoardType, pci_bdf: str, xdma_channel: int = 0, host_interface: HostInterface = HostInterface.XDMA) -> Board:
    """Open a DRAM Bender board.

    pci_bdf selects the FPGA PCI function, and xdma_channel selects an independent
    XDMA endpoint on that function.
    """
    ...

def lower(ops: list) -> FinalProgram: ...

class _ProgramPlugin:
    def instantiate(self, scalar_values: Sequence[int]) -> FinalProgram: ...

def load_program_plugin(plugin_path: str, scalar_names: Sequence[str], array_names: Sequence[str], array_lengths: Sequence[int]) -> _ProgramPlugin: ...
