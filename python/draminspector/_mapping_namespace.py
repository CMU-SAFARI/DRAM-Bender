"""Shared infrastructure for built-in mapping namespaces.

Both the row-mapping namespace (``draminspector.rows``) and the pattern-mapping
namespaces (``draminspector.patterns.bitline_mappings``,
``draminspector.patterns.dq_mappings``) discover their built-ins by iterating a
package directory of one-file-per-mapping modules. The logic for loading,
registering, validating, and resolving those mappings is identical across the
three namespaces — only the wrapper dataclass (``RowMapping`` /
``PatternMapping``), the per-module function attribute (``map_row`` /
``map_pattern``), and the error messages differ. This module is the single
implementation; the three namespaces parameterize it.
"""

from __future__ import annotations

import importlib
import inspect
import pkgutil
from types import ModuleType
from typing import Any, Callable, TypeVar

T = TypeVar("T")


def validate_unary_callable(fn: Any, *, kind: str, hint: str) -> None:
    """Reject callables that don't take exactly one required positional param.

    Catches typos like ``lambda: 42`` or mis-declared signatures at wrap time
    instead of letting them blow up with a cryptic ``TypeError`` inside the
    trace / VM later.
    """
    try:
        sig = inspect.signature(fn)
    except (TypeError, ValueError) as exc:
        raise TypeError(
            f"{kind} callable must expose an inspectable signature: {exc}"
        ) from exc
    required = [
        p for p in sig.parameters.values()
        if p.default is inspect.Parameter.empty
        and p.kind in (
            inspect.Parameter.POSITIONAL_ONLY,
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
        )
    ]
    if len(required) != 1:
        raise TypeError(
            f"{kind} callable must accept exactly one required positional "
            f"argument {hint}; got signature {sig}."
        )


def load_public_mappings(
    *,
    package: ModuleType,
    function_attr: str,
    make_mapping: Callable[[str, tuple[str, ...], Callable], T],
    globals_dict: dict[str, Any],
    metadata_by_module: dict[str, dict[str, Any]],
    namespace_name: str,
) -> tuple[list[str], dict[str, T]]:
    """Discover every ``package/<name>.py`` module with a ``function_attr``
    callable, wrap it via ``make_mapping(name, aliases, fn)``, and register it
    both in ``globals_dict`` (under ``<name>``) and in a case-insensitive
    keyword index built from the module name + the mapping's ``name`` and
    ``aliases``. Duplicate keys raise ``ImportError``.
    """
    exported_names: list[str] = []
    builtins_by_key: dict[str, T] = {}

    for module_info in sorted(pkgutil.iter_modules(package.__path__),
                              key=lambda item: item.name):
        module_name = module_info.name
        if module_name.startswith("_"):
            continue
        if module_info.ispkg:
            raise ImportError(
                f"{namespace_name} does not support subpackages; "
                f"found {module_name!r}."
            )

        module = importlib.import_module(f"{package.__name__}.{module_name}")
        fn = getattr(module, function_attr, None)
        if fn is None:
            raise ImportError(
                f"{namespace_name} module {module_name!r} must define a "
                f"top-level {function_attr!r} function."
            )
        if not callable(fn):
            raise TypeError(
                f"{namespace_name} module {module_name!r} exported "
                f"{type(fn).__name__} for {function_attr!r}; "
                f"expected a callable."
            )

        metadata = metadata_by_module.get(module_name, {})
        mapping = make_mapping(
            metadata.get("name", module_name),
            tuple(metadata.get("aliases", ())),
            fn,
        )
        globals_dict[module_name] = mapping
        exported_names.append(module_name)

        for key in {module_name, mapping.name, *mapping.aliases}:
            normalized = key.casefold()
            existing = builtins_by_key.get(normalized)
            if existing is not None and existing is not mapping:
                raise ImportError(
                    f"{namespace_name} discovered duplicate mapping "
                    f"key {key!r}."
                )
            builtins_by_key[normalized] = mapping

    return exported_names, builtins_by_key


def resolve_mapping(
    mapping: Any,
    *,
    wrapper_cls: type,
    make_mapping: Callable[[str, tuple[str, ...], Callable], Any],
    identity_mapping: Any,
    builtins_by_key: dict[str, Any],
    available_names: tuple[str, ...],
    mapping_kind: str,
    callable_hint: str,
) -> Any:
    """Normalize a user-supplied mapping spec into a wrapper instance.

    Accepts: ``None`` (→ ``identity_mapping``), an existing ``wrapper_cls``
    instance (pass-through), a name string (looked up in ``builtins_by_key``
    case-insensitively), or a callable (validated and wrapped). Anything else
    raises ``TypeError``.
    """
    if mapping is None:
        return identity_mapping
    if isinstance(mapping, wrapper_cls):
        return mapping
    if isinstance(mapping, str):
        resolved = builtins_by_key.get(mapping.casefold())
        if resolved is None:
            raise ValueError(
                f"Unknown {mapping_kind} {mapping!r}. "
                f"Available mappings: {', '.join(available_names)}."
            )
        return resolved
    if callable(mapping):
        validate_unary_callable(mapping, kind=mapping_kind, hint=callable_hint)
        return make_mapping(
            getattr(mapping, "__name__", "<callable>"),
            (),
            mapping,
        )
    raise TypeError(
        f"{mapping_kind} must be None, a mapping name, a "
        f"{wrapper_cls.__name__}, or a callable."
    )
