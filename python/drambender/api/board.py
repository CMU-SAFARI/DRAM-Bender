"""Hardware interface: boards, their configurations, and the open factory."""

from .._core import (
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
    open_board as _native_open_board,
)
from .program.targets import DDR4Target, HBM2Target


def _resolve_board_type(
    target_or_type: BoardType | BoardConfig | DDR4Target | HBM2Target,
) -> BoardType:
    if isinstance(target_or_type, BoardType):
        return target_or_type
    if isinstance(target_or_type, BoardConfig):
        return target_or_type.board_type
    if isinstance(target_or_type, DDR4Target):
        return target_or_type.board_config.board_type
    if isinstance(target_or_type, HBM2Target):
        return target_or_type.board_config.board_type
    raise TypeError(
        "open_board expects a DDR4Target, HBM2U50Target, HBM2U55Target, "
        "BoardConfig, or BoardType."
    )


def open_board(
    target_or_type: BoardType | BoardConfig | DDR4Target | HBM2Target,
    pci_bdf: str,
    xdma_channel: int = 0,
    host_interface: HostInterface = HostInterface.XDMA,
) -> Board:
    """Open an endpoint by complete PCI BDF and XDMA channel."""
    return _native_open_board(
        _resolve_board_type(target_or_type),
        pci_bdf,
        xdma_channel,
        host_interface,
    )

__all__ = [
    "Board",
    "BoardConfig",
    "BoardType",
    "DDR4",
    "HBM2",
    "HBM2U50",
    "HBM2U55C",
    "HBMTemperature",
    "HostInterface",
    "MemoryType",
    "PowerTelemetry",
    "RailTelemetry",
    "SensorStat",
    "get_board_config",
    "open_board",
]
