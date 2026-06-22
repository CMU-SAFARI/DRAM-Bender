from .._mapping_namespace import load_public_mappings, resolve_mapping
from . import mappings as _mappings
from ._core import Row, RowMapping


_LEGACY_MAPPING_METADATA = {
    "linear": {"name": "Linear", "aliases": ("None",)},
    "sa0": {"name": "SA0", "aliases": ("MI0",)},
    "mi1": {"name": "MI1", "aliases": ()},
}


def _make_row_mapping(name: str, aliases: tuple[str, ...], fn) -> RowMapping:
    return RowMapping(name=name, aliases=aliases, _physical_to_logical=fn)


_EXPORTED_MAPPING_NAMES, _BUILTIN_MAPPINGS_BY_KEY = load_public_mappings(
    package=_mappings,
    function_attr="map_row",
    make_mapping=_make_row_mapping,
    globals_dict=globals(),
    metadata_by_module=_LEGACY_MAPPING_METADATA,
    namespace_name="drambender.rows",
)


def available_mappings() -> tuple[str, ...]:
    return tuple(_EXPORTED_MAPPING_NAMES)


def get_row_mapper(mapping) -> RowMapping:
    return resolve_mapping(
        mapping,
        wrapper_cls=RowMapping,
        make_mapping=_make_row_mapping,
        identity_mapping=linear,  # registered by load_public_mappings above
        builtins_by_key=_BUILTIN_MAPPINGS_BY_KEY,
        available_names=available_mappings(),
        mapping_kind="row mapping",
        callable_hint="(physical_id: int) -> int",
    )


__all__ = [
    "Row",
    "RowMapping",
    "available_mappings",
    "get_row_mapper",
    *_EXPORTED_MAPPING_NAMES,
]
