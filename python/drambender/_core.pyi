from collections.abc import Sequence
import enum
from typing import overload

from . import instructions as instructions
from drambender.api.execution import TimingSummary


# Only XDMA is implemented today. QDMA and Ethernet are reserved for planned
# backends; open_board() raises for them.
class HostInterface(enum.Enum):
    XDMA = 0

    QDMA = 1

    Ethernet = 2

class BoardType(enum.Enum):
    U200 = 0

    U50 = 1

    U55C = 2

class MemoryType(enum.Enum):
    DDR4 = 0

    HBM2 = 1

class BoardConfig:
    @property
    def name(self) -> str: ...

    @property
    def board_type(self) -> BoardType: ...

    @property
    def memory_type(self) -> MemoryType: ...

    @property
    def instruction_capacity(self) -> int: ...

    @property
    def dram_command_slot_ns(self) -> float: ...

    @property
    def dram_slots_per_fabric_cycle(self) -> int: ...

    @property
    def readback_buffer_capacity(self) -> int: ...

    @property
    def hbm_channel_count(self) -> int: ...

    @property
    def hbm_pseudo_channel_count(self) -> int: ...

    @property
    def hbm_sid_count(self) -> int: ...

    @property
    def broadcast_supported(self) -> bool: ...

    @property
    def power_telemetry_supported(self) -> bool: ...

    def summary(self) -> str: ...

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

    @property
    def default_dram_inst_latency(self) -> float:
        """DRAM command slot duration (ns) of the target this program was built for."""
        ...

    @default_dram_inst_latency.setter
    def default_dram_inst_latency(self, latency_ns: float) -> None: ...

    def dry_run(self, max_instructions: int, dram_inst_latency: float | None = None, num_dram_insts_per_fabric_cycle: int = 4) -> ExecutionResult:
        """Execute in the software VM. dram_inst_latency=None uses the program's default."""
        ...

    def trace_dram_commands(self, max_instructions: int = 100000000, dram_inst_latency: float | None = None, num_dram_insts_per_fabric_cycle: int = 4) -> DRAMCommandTrace:
        """Trace DRAM commands. dram_inst_latency=None uses the program's default."""
        ...

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

    def receive_into(self, buffer: object, timeout: float | None = None) -> int:
        """Copy queued readback data into a writable C-contiguous buffer.

        The buffer size must be a multiple of four bytes. ``timeout`` is an
        optional number of seconds; ``None`` waits without a deadline, including
        across long retention intervals.
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

class SensorStat:
    """Instantaneous, maximum, and average value of one sensor."""
    instant: int
    max: int
    average: int

class RailTelemetry:
    """Voltage (mV), current (mA), and derived power (mW) for one rail."""
    voltage_mv: SensorStat
    current_ma: SensorStat

    @property
    def power_mw(self) -> SensorStat: ...

class PowerTelemetry:
    """Card power and thermal telemetry (U55C only)."""
    pex_12v: RailTelemetry
    pex_3v3: RailTelemetry
    vccint: RailTelemetry
    vccint_io: RailTelemetry
    hbm: RailTelemetry
    hbm_temp0_celsius: SensorStat
    hbm_temp1_celsius: SensorStat

    @property
    def total_input_power_mw(self) -> SensorStat: ...

class HBM2(Board):
    """Shared base for HBM2 boards. Construct HBM2U50 or HBM2U55C."""

    def read_temperature(self) -> HBMTemperature:
        """Read the current HBM stack temperatures in degrees Celsius."""
        ...

    def discard_readback_data(self, discard: bool) -> None:
        """Enable or disable discarding HBM readback data."""
        ...

    def set_broadcast_channels(self, channels: list[int]) -> None:
        """Configure the command broadcast channel mask (U55C only)."""
        ...

    def read_power_telemetry(self) -> PowerTelemetry:
        """Read card power and thermal telemetry from the CMS (U55C only)."""
        ...

    @property
    def num_sids(self) -> int: ...

    @property
    def broadcast_supported(self) -> bool: ...

    @property
    def power_supported(self) -> bool: ...

class HBM2U50(HBM2):
    """Alveo U50 HBM2 board."""

    def __init__(self, pci_bdf: str, xdma_channel: int = 0, host_interface: HostInterface = HostInterface.XDMA) -> None: ...

class HBM2U55C(HBM2):
    """Alveo U55C HBM2 board."""

    def __init__(self, pci_bdf: str, xdma_channel: int = 0, host_interface: HostInterface = HostInterface.XDMA) -> None: ...

def open_board(board_type: BoardType, pci_bdf: str, xdma_channel: int = 0, host_interface: HostInterface = HostInterface.XDMA) -> Board:
    """Open a DRAM Bender board.

    pci_bdf selects the FPGA PCI function, and xdma_channel selects an independent
    XDMA endpoint on that function.
    """
    ...

def get_board_config(board_type: BoardType) -> BoardConfig: ...

def lower(ops: list) -> FinalProgram: ...

class _ProgramPlugin:
    def instantiate(self, scalar_values: Sequence[int]) -> FinalProgram: ...

def load_program_plugin(plugin_path: str, scalar_names: Sequence[str], array_names: Sequence[str], array_lengths: Sequence[int]) -> _ProgramPlugin: ...
