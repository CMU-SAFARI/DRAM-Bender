from collections.abc import Callable, Sequence
from dataclasses import dataclass
import operator
from typing import Any


def _coerce_word(value, *, index: int | None = None) -> int:
    try:
        return operator.index(value)
    except TypeError as exc:
        location = "" if index is None else f" at index {index}"
        raise TypeError(
            f"data_pattern word{location} must be an integer-compatible value "
            f"(got {type(value).__name__})."
        ) from exc


def _normalize_pattern_words(value, *, words_per_cacheline) -> tuple[int, ...]:
    if isinstance(value, (str, bytes, bytearray)):
        raise TypeError("data_pattern must not be a string-like value.")
    if isinstance(value, Sequence):
        words = tuple(_coerce_word(w, index=i) for i, w in enumerate(value))
        if not words:
            raise ValueError("data_pattern sequences must contain at least one word.")
        return words
    word = _coerce_word(value)
    return tuple(word for _ in range(words_per_cacheline))


def _normalize_mapped_pattern(value, *, name: str) -> tuple[int, ...]:
    if isinstance(value, (str, bytes, bytearray)):
        raise TypeError(f"{name} must not return a string-like value.")
    words = tuple(value)
    if not words:
        raise ValueError(f"{name} must return at least one word.")
    return words


@dataclass(frozen=True)
class PatternMapping:
    name: str
    aliases: tuple[str, ...]
    _apply: Callable[[tuple[int, ...]], object]

    def apply(self, words: tuple[int, ...]) -> tuple[int, ...]:
        words = tuple(words)
        if not words:
            return ()
        return _normalize_mapped_pattern(
            self._apply(words),
            name=f"{self.name}.apply(...)",
        )

    def __call__(self, words: tuple[int, ...]) -> tuple[int, ...]:
        return self.apply(words)


class DataPattern:
    def __init__(
        self,
        data_pattern=0xDEADBEEF,
        *,
        words_per_cacheline: int = 16,
        dq_mapping: PatternMapping | str | Callable[[tuple[int, ...]], Any] | None = None,
        bitline_mapping: PatternMapping | str | Callable[[tuple[int, ...]], Any] | None = None,
    ) -> None:
        from . import get_bitline_mapper, get_dq_mapper

        self.words_per_cacheline = words_per_cacheline
        self._logical_pattern = _normalize_pattern_words(
            data_pattern,
            words_per_cacheline=self.words_per_cacheline,
        )
        self.bitline_mapping = get_bitline_mapper(bitline_mapping)
        self.dq_mapping = get_dq_mapper(dq_mapping)

    @property
    def logical_pattern(self) -> tuple[int, ...]:
        return self._logical_pattern

    @property
    def write_pattern(self) -> tuple[int, ...]:
        pattern = self._logical_pattern
        pattern = self.bitline_mapping.apply(pattern)
        pattern = self.dq_mapping.apply(pattern)
        return pattern

    def __repr__(self) -> str:
        logical_words = ", ".join(f"0x{word:08X}" for word in self.logical_pattern)
        write_words = ", ".join(f"0x{word:08X}" for word in self.write_pattern)
        return (
            "DataPattern("
            f"logical_pattern=({logical_words}), "
            f"write_pattern=({write_words}), "
            f"bitline_mapping={self.bitline_mapping.name!r}, "
            f"dq_mapping={self.dq_mapping.name!r}"
            ")"
        )


__all__ = ["DataPattern", "PatternMapping"]
