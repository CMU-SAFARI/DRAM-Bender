"""Metadata-aware wrapper around ``@program_template``.

Program templates in this package fall into two categories:

* Meta-free: e.g. ``single_sided_rowhammer``. They take only user-supplied
  integers and are decorated with the base ``@program_template`` directly.
* Meta-dependent: e.g. ``write_row``, ``read_row``. They refer
  to ``p.meta.cachelines_per_row`` etc. inside the builder; each distinct
  meta produces a distinct JIT specialization.

Meta-dependent templates cannot be called with an implicit default — the
researcher must state the DRAM geometry explicitly. This module provides
``@program_template`` for that case: the decorated object is **not** directly
callable; instead the only way to obtain a usable program builder is through
``draminspector.builtin_programs.configure(...)``, which binds every meta-dependent
template to the supplied ``_ProgramsMeta``.
"""

from dataclasses import dataclass
import functools
import inspect

from ..api.program import program_template as _base_program_template
from ..api.program.builder import _reset_program_builder_meta, _set_program_builder_meta


@dataclass(frozen=True)
class _ProgramsMeta:
    cachelines_per_row: int
    column_stride: int
    words_per_cacheline: int


def normalize_programs_meta(
    *,
    cachelines_per_row=128,
    column_stride=8,
    words_per_cacheline=16,
) -> _ProgramsMeta:
    return _ProgramsMeta(
        cachelines_per_row=cachelines_per_row,
        column_stride=column_stride,
        words_per_cacheline=words_per_cacheline,
    )


class _MetaBoundTemplate:
    """Non-callable placeholder carrying ``.bind_meta(meta)``.

    Direct invocation raises ``TypeError`` with guidance — silently using a
    default DRAM geometry would produce the wrong instruction sequence (wrong
    cacheline count, wrong column stride) with no indication to the caller.
    """

    def __init__(self, function, bind_meta):
        self._function = function
        self._bind_meta = bind_meta
        functools.update_wrapper(self, function)

    def bind_meta(self, meta: _ProgramsMeta):
        """Return a directly-callable @program_template bound to `meta`."""
        return self._bind_meta(meta)

    def __call__(self, *args, **kwargs):
        raise TypeError(
            f"{self._function.__qualname__} is meta-dependent and cannot be "
            f"called directly. Obtain a configured bundle via "
            f"draminspector.builtin_programs.configure(cachelines_per_row=..., "
            f"column_stride=..., words_per_cacheline=...) and call the "
            f"template from there."
        )

    @property
    def __signature__(self):  # noqa: D401 - pass-through for inspect
        return inspect.signature(self._function)


def program_template(function):
    """Decorator for meta-dependent program templates.

    Equivalent to ``@draminspector.api.program_template`` except: (a) tracing
    happens with a freshly-set DRAM meta (cachelines_per_row, column_stride,
    words_per_cacheline) instead of a hidden default; (b) the decorated name
    is not directly callable — caller must go through ``configure(...)``.
    """
    @functools.lru_cache(maxsize=None)
    def _for_meta(meta: _ProgramsMeta):
        @functools.wraps(function)
        def traced(*args, **kwargs):
            token = _set_program_builder_meta(meta)
            try:
                return function(*args, **kwargs)
            finally:
                _reset_program_builder_meta(token)
        return _base_program_template(traced)

    return _MetaBoundTemplate(function, _for_meta)
