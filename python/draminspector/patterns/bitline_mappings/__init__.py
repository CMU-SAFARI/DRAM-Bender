import sys

from ..._mapping_namespace import load_public_mappings, resolve_mapping
from .._core import PatternMapping


_MAPPING_METADATA = {
    "identity": {"name": "identity", "aliases": ("noop", "none")},
}


def _make_pattern_mapping(name: str, aliases: tuple[str, ...], fn) -> PatternMapping:
    return PatternMapping(name=name, aliases=aliases, _apply=fn)


_EXPORTED_MAPPING_NAMES, _BUILTIN_MAPPINGS_BY_KEY = load_public_mappings(
    package=sys.modules[__name__],
    function_attr="map_pattern",
    make_mapping=_make_pattern_mapping,
    globals_dict=globals(),
    metadata_by_module=_MAPPING_METADATA,
    namespace_name="draminspector.patterns.bitline_mappings",
)


def available_mappings() -> tuple[str, ...]:
    return tuple(_EXPORTED_MAPPING_NAMES)


def get_mapping(mapping) -> PatternMapping:
    return resolve_mapping(
        mapping,
        wrapper_cls=PatternMapping,
        make_mapping=_make_pattern_mapping,
        identity_mapping=identity,
        builtins_by_key=_BUILTIN_MAPPINGS_BY_KEY,
        available_names=available_mappings(),
        mapping_kind="bitline_mapping",
        callable_hint="(words: tuple[int, ...]) -> tuple[int, ...]",
    )


__all__ = [
    "PatternMapping",
    "available_mappings",
    "get_mapping",
    *_EXPORTED_MAPPING_NAMES,
]
