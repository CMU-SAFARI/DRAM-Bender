"""Target-aware wrapper around ``@program_template`` for shipped builtins."""

import functools
import inspect

from ..api.program import program_template as _base_program_template
from ..api.program.targets import normalize_target


def _public_signature(function):
    signature = inspect.signature(function)
    parameters = tuple(signature.parameters.values())[1:]
    return signature.replace(parameters=parameters)


class _TargetBoundTemplate:
    """Non-callable placeholder carrying ``.bind_target(target)``."""

    def __init__(self, function, bind_target):
        self._function = function
        self._bind_target = bind_target
        functools.update_wrapper(self, function)

    def bind_target(self, target):
        """Return a directly callable @program_template bound to ``target``."""
        return self._bind_target(normalize_target(target))

    def __call__(self, *args, **kwargs):
        raise TypeError(
            f"{self._function.__qualname__} is a shipped builtin template and "
            "must be called from a configured bundle. Use "
            "drambender.builtin_programs.configure(target=...) first."
        )

    @property
    def __signature__(self):  # noqa: D401 - pass-through for inspect
        return _public_signature(self._function)


def program_template(function):
    """Decorator for target-dependent builtin program templates.

    The wrapped function must take ``target`` as its first argument. Users do
    not pass that argument directly; ``configure(target=...)`` binds it once
    for every builtin in the returned bundle.
    """
    @functools.lru_cache(maxsize=None)
    def _for_target(target):
        @functools.wraps(function)
        def traced(*args, **kwargs):
            return function(target, *args, **kwargs)
        traced.__signature__ = _public_signature(function)
        return _base_program_template(traced)

    return _TargetBoundTemplate(function, _for_target)


__all__ = [
    "_TargetBoundTemplate",
    "program_template",
]
