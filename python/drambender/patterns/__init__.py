from . import bitline_mappings, dq_mappings, raw_bits
from ._core import DataPattern, PatternMapping


def available_bitline_mappings() -> tuple[str, ...]:
    return bitline_mappings.available_mappings()


def available_dq_mappings() -> tuple[str, ...]:
    return dq_mappings.available_mappings()


def get_bitline_mapper(mapping) -> PatternMapping:
    return bitline_mappings.get_mapping(mapping)


def get_dq_mapper(mapping) -> PatternMapping:
    return dq_mappings.get_mapping(mapping)


__all__ = [
    "DataPattern",
    "PatternMapping",
    "available_bitline_mappings",
    "available_dq_mappings",
    "bitline_mappings",
    "dq_mappings",
    "get_bitline_mapper",
    "get_dq_mapper",
    "raw_bits",
]
