"""Canonical board configurations exposed by the native API.

The objects in this module are immutable views of the C++ configuration
registry.  They are shared by board opening and program targets so Python does
not maintain a second set of hardware constants.
"""

from typing import Final

from .._core import BoardConfig, BoardType, get_board_config


U200: Final[BoardConfig] = get_board_config(BoardType.U200)
U50: Final[BoardConfig] = get_board_config(BoardType.U50)
U55C: Final[BoardConfig] = get_board_config(BoardType.U55C)


__all__ = ["U200", "U50", "U55C"]
