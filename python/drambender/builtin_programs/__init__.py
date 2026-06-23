import importlib
import pkgutil
from collections.abc import Callable

from ..api.program import FinalProgram
from ..api.program.targets import normalize_target
from ._meta import _TargetBoundTemplate


def _load_templates() -> dict[str, _TargetBoundTemplate]:
    """Discover and validate every shipped builtin program template."""
    templates: dict[str, _TargetBoundTemplate] = {}
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
        if not isinstance(template, _TargetBoundTemplate):
            raise TypeError(
                f"drambender.builtin_programs symbol {module_name!r} must be decorated "
                "with drambender.builtin_programs._meta.program_template."
            )

        templates[module_name] = template
        seen_names.add(module_name)
        globals().pop(module_name, None)

    return templates


_TEMPLATES = _load_templates()


class _ConfiguredPrograms:
    """Bundle of shipped program templates bound to one memory target."""

    single_sided_rowhammer: Callable[..., FinalProgram]
    double_sided_rowhammer: Callable[..., FinalProgram]
    write_row: Callable[..., FinalProgram]
    read_row: Callable[..., FinalProgram]

    def __init__(self, *, target) -> None:
        self.target = normalize_target(target)
        for name, template in _TEMPLATES.items():
            setattr(self, name, template.bind_target(self.target))


def configure(*, target):
    """Bind every shipped program template to an explicit memory target."""
    return _ConfiguredPrograms(target=target)


__all__ = ["configure"]
