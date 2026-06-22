"""Hardware interface: Board classes, board-type enums, and factory."""

from .._core import (
    Board,
    BoardType,
    DDR4,
    HBM2,
    HBMTemperature,
    HostInterface,
    open_board,
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
