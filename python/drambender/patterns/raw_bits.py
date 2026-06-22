from __future__ import annotations

from collections.abc import Iterable

import numpy as np


UINT32_ONES = np.uint32(0xFFFFFFFF)
TARGET_MASKS = ("quad3", "quad3_plus_boundaries", "window_r4")


def bits_per_cacheline(words_per_cacheline: int) -> int:
    return int(words_per_cacheline) * 32


def bits_per_row(cachelines_per_row: int, words_per_cacheline: int) -> int:
    return int(cachelines_per_row) * bits_per_cacheline(words_per_cacheline)


def row_word_count(cachelines_per_row: int, words_per_cacheline: int) -> int:
    return int(cachelines_per_row) * int(words_per_cacheline)


def uniform_cacheline_words(value: int, words_per_cacheline: int) -> tuple[int, ...]:
    word = 0xFFFFFFFF if int(value) else 0
    return tuple(word for _ in range(int(words_per_cacheline)))


def uniform_row_words(
    value: int,
    *,
    cachelines_per_row: int,
    words_per_cacheline: int,
) -> np.ndarray:
    word = np.uint32(0xFFFFFFFF if int(value) else 0)
    return np.full(
        row_word_count(cachelines_per_row, words_per_cacheline),
        word,
        dtype=np.uint32,
    )


def all_ones_except_zero_cacheline_words(
    bit_in_cacheline: int,
    *,
    words_per_cacheline: int,
) -> tuple[int, ...]:
    bit_in_cacheline = int(bit_in_cacheline)
    bits = bits_per_cacheline(words_per_cacheline)
    if bit_in_cacheline < 0 or bit_in_cacheline >= bits:
        raise ValueError(f"bit_in_cacheline must be in [0, {bits}).")

    words = np.full(int(words_per_cacheline), UINT32_ONES, dtype=np.uint32)
    word_index = bit_in_cacheline // 32
    bit_index = bit_in_cacheline % 32
    words[word_index] = np.uint32(int(words[word_index]) & ~(1 << bit_index))
    return tuple(int(word) for word in words)


def responsible_bit_cacheline_words(
    *,
    island_bit_in_cacheline: int,
    responsible_bit_in_cacheline: int,
    same_cacheline: bool,
    words_per_cacheline: int,
) -> tuple[int, ...]:
    if same_cacheline:
        words = list(
            all_ones_except_zero_cacheline_words(
                island_bit_in_cacheline,
                words_per_cacheline=words_per_cacheline,
            )
        )
    else:
        words = list(uniform_cacheline_words(1, words_per_cacheline))

    responsible_bit_in_cacheline = int(responsible_bit_in_cacheline)
    bits = bits_per_cacheline(words_per_cacheline)
    if responsible_bit_in_cacheline < 0 or responsible_bit_in_cacheline >= bits:
        raise ValueError(f"responsible_bit_in_cacheline must be in [0, {bits}).")

    word_index = responsible_bit_in_cacheline // 32
    bit_index = responsible_bit_in_cacheline % 32
    words[word_index] = int(words[word_index]) & ~(1 << bit_index)
    return tuple(words)


def comb_cacheline_words(
    local_bit: int,
    *,
    words_per_cacheline: int,
) -> tuple[int, ...]:
    """Return all-one cacheline words with one local bit cleared."""
    return all_ones_except_zero_cacheline_words(
        local_bit,
        words_per_cacheline=words_per_cacheline,
    )


def expected_comb_row_words(
    local_bit: int,
    selected_cachelines: Iterable[int],
    *,
    cachelines_per_row: int,
    words_per_cacheline: int,
) -> np.ndarray:
    """Return the expected all-one row after selected cachelines get one zero."""
    row = np.full(
        row_word_count(cachelines_per_row, words_per_cacheline),
        np.uint32(0xFFFFFFFF),
        dtype=np.uint32,
    )
    pattern = np.array(
        comb_cacheline_words(local_bit, words_per_cacheline=words_per_cacheline),
        dtype=np.uint32,
    )
    for cacheline in selected_cachelines:
        cacheline = int(cacheline)
        if cacheline < 0 or cacheline >= int(cachelines_per_row):
            raise ValueError(f"cacheline must be in [0, {cachelines_per_row}).")
        start = cacheline * int(words_per_cacheline)
        row[start:start + int(words_per_cacheline)] = pattern
    return row


def bit_positions_where_differs(observed: np.ndarray, expected: np.ndarray) -> list[int]:
    if observed.shape != expected.shape:
        raise ValueError(
            f"observed shape {observed.shape} does not match expected shape {expected.shape}."
        )

    diff = np.bitwise_xor(
        observed.astype(np.uint32, copy=False),
        expected.astype(np.uint32, copy=False),
    )
    positions: list[int] = []
    for word_index, raw_mask in enumerate(diff):
        mask = int(raw_mask)
        while mask:
            low_bit = mask & -mask
            bit_index = low_bit.bit_length() - 1
            positions.append(word_index * 32 + bit_index)
            mask ^= low_bit
    return positions


def increment_counts(counts: np.ndarray, bit_positions: Iterable[int]) -> None:
    for bit in bit_positions:
        counts[int(bit)] += 1


def self_collapse_from_all_ones_flip_list(
    target_bit: int,
    flip_bits_vs_all_ones: set[int],
) -> bool:
    return int(target_bit) not in flip_bits_vs_all_ones


def relative_cacheline_map(
    selected_cachelines: Iterable[int],
    *,
    cachelines_per_row: int,
    relative_window: int,
) -> dict[int, int]:
    """Map each unambiguous victim cacheline to its relative selected source."""
    selected = {int(cacheline) for cacheline in selected_cachelines}
    mapping: dict[int, int] = {}
    for victim_cacheline in range(int(cachelines_per_row)):
        candidates = [
            source
            for source in selected
            if abs(victim_cacheline - source) <= int(relative_window)
        ]
        if len(candidates) == 1:
            source = candidates[0]
            mapping[victim_cacheline] = victim_cacheline - source
    return mapping


def quad3_local_bits(vulnerable_bit: int, *, bits_per_cacheline: int) -> list[int]:
    local = int(vulnerable_bit) % int(bits_per_cacheline)
    quad_start = (local // 4) * 4
    residue = local % 4
    return [quad_start + r for r in range(4) if r != residue]


def candidate_local_bits(
    vulnerable_bit: int,
    *,
    bits_per_cacheline: int,
    mask: str,
) -> list[int]:
    local = int(vulnerable_bit) % int(bits_per_cacheline)
    base = set(quad3_local_bits(vulnerable_bit, bits_per_cacheline=bits_per_cacheline))
    if mask == "quad3":
        candidates = base
    elif mask == "quad3_plus_boundaries":
        quad_start = (local // 4) * 4
        candidates = base | {quad_start - 1, quad_start + 4}
    elif mask == "window_r4":
        candidates = set(range(local - 4, local + 5))
        candidates.discard(local)
    else:
        raise ValueError(f"unknown target mask: {mask}")
    return sorted(bit for bit in candidates if 0 <= bit < int(bits_per_cacheline))


def target_rule_description(mask: str) -> str:
    if mask == "quad3":
        return "other residues in the same 4-bit local group inside each selected responsible cacheline"
    if mask == "quad3_plus_boundaries":
        return "quad3 plus one local bit before and after the 4-bit group when in range"
    if mask == "window_r4":
        return "local +/-4-bit window around the vulnerable bit, excluding the vulnerable bit itself"
    raise ValueError(f"unknown target mask: {mask}")


__all__ = [
    "TARGET_MASKS",
    "UINT32_ONES",
    "all_ones_except_zero_cacheline_words",
    "bit_positions_where_differs",
    "bits_per_cacheline",
    "bits_per_row",
    "candidate_local_bits",
    "comb_cacheline_words",
    "expected_comb_row_words",
    "increment_counts",
    "quad3_local_bits",
    "relative_cacheline_map",
    "responsible_bit_cacheline_words",
    "row_word_count",
    "self_collapse_from_all_ones_flip_list",
    "target_rule_description",
    "uniform_cacheline_words",
    "uniform_row_words",
]
