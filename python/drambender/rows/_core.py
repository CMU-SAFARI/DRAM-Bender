from collections.abc import Callable
from dataclasses import dataclass

from ..patterns import DataPattern


@dataclass(frozen=True)
class RowMapping:
    name: str
    aliases: tuple[str, ...]
    _physical_to_logical: Callable[[int], int]

    def physical_to_logical(self, physical_id: int) -> int:
        return self._physical_to_logical(physical_id)

    def __call__(self, physical_id: int) -> int:
        return self.physical_to_logical(physical_id)


class Row:
    def __init__(
        self,
        physical_id: int,
        row_mapping=None,
        data_pattern: DataPattern | int | tuple[int, ...] | list[int] = 0xDEADBEEF,
    ) -> None:
        from . import get_row_mapper

        self.physical_id = physical_id
        self.row_mapping = get_row_mapper(row_mapping)
        if isinstance(data_pattern, DataPattern):
            self.data_pattern = data_pattern
        else:
            self.data_pattern = DataPattern(data_pattern)

    @property
    def logical_id(self) -> int:
        return self.row_mapping.physical_to_logical(self.physical_id)

    @property
    def write_pattern(self) -> tuple[int, ...]:
        return self.data_pattern.write_pattern

    def __repr__(self) -> str:
        return (
            "Row("
            f"physical_id={self.physical_id}, "
            f"logical_id={self.logical_id}, "
            f"row_mapping={self.row_mapping.name!r}, "
            f"data_pattern={self.data_pattern!r}"
            ")"
        )


__all__ = ["Row", "RowMapping"]
