"""Hardware interface: Board classes, board-type enums, and factory."""

from .._core import (
    Board,
    BoardType,
    DDR4,
    HBM2,
    HBMTemperature,
    HostInterface,
    open_board as _native_open_board,
)
from .program.targets import DDR4Target, HBM2Target


def _resolve_board_type(target_or_type) -> BoardType:
    if isinstance(target_or_type, BoardType):
        return target_or_type
    if isinstance(target_or_type, DDR4Target):
        return BoardType.DDR4
    if isinstance(target_or_type, HBM2Target):
        return BoardType.HBM2
    raise TypeError("open_board expects a DDR4Target, HBM2Target, or BoardType.")


def open_board(
    target_or_type,
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
    "BoardType",
    "DDR4",
    "HBM2",
    "HBMTemperature",
    "HostInterface",
    "open_board",
]
