from __future__ import annotations

from collections.abc import Iterable

from ..api.program import ProgramBuilder
from ..api.program.instructions import NOP, PRE


def _normalize_pattern_words(pattern_words, *, words_per_cacheline: int) -> tuple[int, ...]:
    words = tuple(int(word) & 0xFFFFFFFF for word in pattern_words)
    if len(words) < int(words_per_cacheline):
        raise ValueError("pattern_words is shorter than words_per_cacheline.")
    return words


def _normalize_cacheline_ids(
    cacheline_ids: Iterable[int],
    *,
    cachelines_per_row: int,
) -> list[int]:
    cachelines = sorted({int(cacheline) for cacheline in cacheline_ids})
    if not cachelines:
        raise ValueError("cacheline_ids must contain at least one cacheline.")
    bad = [
        cacheline
        for cacheline in cachelines
        if cacheline < 0 or cacheline >= int(cachelines_per_row)
    ]
    if bad:
        raise ValueError(f"cacheline IDs out of range [0, {cachelines_per_row}): {bad}.")
    return cachelines


def _require_nonnegative_timing(name: str, value: int) -> None:
    if int(value) < 0:
        raise ValueError(f"{name} must be non-negative.")


def _emit_short_tras_precharge(p: ProgramBuilder, tRAS_cycles: int) -> None:
    _require_nonnegative_timing("tRAS_cycles", tRAS_cycles)
    for _ in range(int(tRAS_cycles) // 4):
        p.DRAM(NOP(), NOP(), NOP(), NOP())
    rest = int(tRAS_cycles) % 4
    if rest == 3:
        p.DRAM(NOP(), NOP(), NOP(), PRE("BAR"))
    elif rest == 2:
        p.DRAM(NOP(), NOP(), PRE("BAR"), NOP())
    elif rest == 1:
        p.DRAM(NOP(), PRE("BAR"), NOP(), NOP())
    else:
        p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
