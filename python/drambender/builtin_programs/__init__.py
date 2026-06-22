import importlib
import pkgutil
from collections.abc import Callable

from ..api.program import FinalProgram
from ._meta import _MetaBoundTemplate, normalize_programs_meta


def _load_templates() -> tuple[list[str], list[str], dict]:
    """Discover every ``programs/<name>.py`` module; split into meta-free
    (directly callable, exposed at module level) and meta-dependent
    (accessible only via ``configure(...)``).
    """
    meta_free_names: list[str] = []
    meta_dependent_names: list[str] = []
    templates: dict = {}
    seen_names: set[str] = set()

    for module_info in sorted(pkgutil.iter_modules(__path__), key=lambda item: item.name):
        module_name = module_info.name
        if module_name.startswith("_"):
            continue
        if module_info.ispkg:
            raise ImportError(
                f"drambender.builtin_programs does not support public subpackages; found {module_name!r}."
            )
        if module_name in seen_names:
            raise ImportError(
                f"drambender.builtin_programs discovered duplicate public template name {module_name!r}."
            )

        module = importlib.import_module(f"{__name__}.{module_name}")
        template = getattr(module, module_name, None)
        if template is None:
            raise ImportError(
                f"drambender.builtin_programs module {module_name!r} must define a top-level callable "
                f"named {module_name!r}."
            )
        if not callable(template) and not isinstance(template, _MetaBoundTemplate):
            raise TypeError(
                f"drambender.builtin_programs symbol {module_name!r} must be callable, got "
                f"{type(template).__name__}."
            )

        templates[module_name] = template
        seen_names.add(module_name)
        if isinstance(template, _MetaBoundTemplate):
            meta_dependent_names.append(module_name)
            # Do NOT expose at module level — importing the submodule shadowed
            # the package attribute; remove it so direct access fails loudly.
            globals().pop(module_name, None)
        else:
            meta_free_names.append(module_name)
            # Meta-free templates need no DRAM geometry → expose at module level.
            globals()[module_name] = template

    return meta_free_names, meta_dependent_names, templates


_META_FREE_NAMES, _META_DEPENDENT_NAMES, _TEMPLATES = _load_templates()


class _ConfiguredPrograms:
    """Bundle of program templates bound to a specific ``_ProgramsMeta``."""

    # Shipped templates; runtime binding happens in __init__ via setattr.
    single_sided_rowhammer: Callable[..., FinalProgram]
    double_sided_rowhammer: Callable[..., FinalProgram]
    write_row: Callable[..., FinalProgram]
    write_row_range: Callable[..., FinalProgram]
    read_row: Callable[..., FinalProgram]
    read_row_range: Callable[..., FinalProgram]
    write_cachelines: Callable[..., FinalProgram]
    write_comb_cachelines: Callable[..., FinalProgram]
    write_row_ordered: Callable[..., FinalProgram]
    short_tras_read_row: Callable[..., FinalProgram]
    multipulse_short_tras_read_row: Callable[..., FinalProgram]
    double_act_precharge: Callable[..., FinalProgram]

    def __init__(
        self,
        *,
        cachelines_per_row: int,
        column_stride: int,
        words_per_cacheline: int,
    ) -> None:
        meta = normalize_programs_meta(
            cachelines_per_row=cachelines_per_row,
            column_stride=column_stride,
            words_per_cacheline=words_per_cacheline,
        )
        for name, template in _TEMPLATES.items():
            if isinstance(template, _MetaBoundTemplate):
                setattr(self, name, template.bind_meta(meta))
            else:
                setattr(self, name, template)


def configure(*, cachelines_per_row: int, column_stride: int, words_per_cacheline: int):
    """Bind every program template to an explicit DRAM geometry.

    Required for every meta-dependent template (``write_row``, ``read_row``);
    the returned bundle also carries meta-free templates
    (``single_sided_rowhammer``, ``double_sided_rowhammer``) for one-stop
    access. Parameters are keyword-only and have NO defaults — the caller
    must state the geometry explicitly.
    """
    return _ConfiguredPrograms(
        cachelines_per_row=cachelines_per_row,
        column_stride=column_stride,
        words_per_cacheline=words_per_cacheline,
    )


__all__ = ["configure", *_META_FREE_NAMES]
