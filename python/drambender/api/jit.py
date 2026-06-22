"""JIT-engine diagnostics for `@program_template`.

All functions are pass-throughs to :mod:`drambender._jit`. They're collected
here so users can introspect per-run timings, manage the on-disk plugin cache,
and dump lowering stats without reaching into a private module.

Typical use::

    from drambender.api.jit import (
        clear_template_caches,
        get_last_template_run_stats,
        set_jit_cache_dir,
    )

    my_template(...)  # first call: compiled_cold
    stats = get_last_template_run_stats()
    print(stats.mode, stats.compile_s)
"""

from .._jit import (
    clear_lowering_stats,
    clear_template_caches,
    get_jit_cache_dir,
    get_last_lowering_stats,
    get_last_template_run_stats,
    get_last_template_run_stats_dict,
    set_jit_cache_dir,
)

__all__ = [
    "clear_lowering_stats",
    "clear_template_caches",
    "get_jit_cache_dir",
    "get_last_lowering_stats",
    "get_last_template_run_stats",
    "get_last_template_run_stats_dict",
    "set_jit_cache_dir",
]
