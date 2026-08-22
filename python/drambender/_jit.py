from collections.abc import Mapping
from contextvars import ContextVar
from dataclasses import asdict, dataclass
import functools
import hashlib
import inspect
import json
import operator
import os
from pathlib import Path
import shutil
import shlex
import subprocess
import time
from typing import Any
import warnings

from . import _core


_TRACE_MODE: ContextVar[bool | None] = ContextVar(
    "drambender_program_template_trace_mode",
    default=None,
)

# DRAM command slot duration recorded by ProgramBuilder.conclude() during
# template tracing, so compiled specializations inherit the target's timing.
_TRACE_DRAM_INST_LATENCY: ContextVar[float | None] = ContextVar(
    "drambender_program_template_trace_dram_inst_latency",
    default=None,
)

_DEFAULT_DRAM_INST_LATENCY = _core.get_board_config(
    _core.BoardType.U200
).dram_command_slot_ns


_CODEGEN_VERSION = 6
_PLUGIN_ABI_VERSION = 1
_DEFAULT_COMPILER = "g++"
_MIN_GXX_MAJOR = 11
_COMPILE_FLAGS = ("-std=c++20", "-O3", "-fPIC", "-shared")


class TemplateCompileError(RuntimeError):
    """Raised when a decorated template uses unsupported parameter behavior."""


@dataclass(frozen=True)
class ScalarParamRef:
    name: str


@dataclass(frozen=True)
class ScalarAffineRef:
    name: str
    multiplier: int = 1
    offset: int = 0


@dataclass(frozen=True)
class LoweringStats:
    op_count: int
    lower_s: float


_LAST_LOWERING_STATS: LoweringStats | None = None


class _SentinelBase:
    def __init__(self, name: str) -> None:
        self.name = name

    def _unsupported(self, action: str):
        raise TemplateCompileError(
            f"Template parameter {self.name!r} was used in unsupported way: {action}. "
            "V1 templates only support direct parameter substitution in builder calls."
        )

    def __bool__(self):
        return self._unsupported("truthiness")

    def __index__(self):
        return self._unsupported("integer coercion")

    def __int__(self):
        return self._unsupported("integer coercion")

    def __add__(self, other):
        return self._unsupported("arithmetic")

    def __radd__(self, other):
        return self._unsupported("arithmetic")

    def __sub__(self, other):
        return self._unsupported("arithmetic")

    def __rsub__(self, other):
        return self._unsupported("arithmetic")

    def __mul__(self, other):
        return self._unsupported("arithmetic")

    def __rmul__(self, other):
        return self._unsupported("arithmetic")

    def __floordiv__(self, other):
        return self._unsupported("arithmetic")

    def __rfloordiv__(self, other):
        return self._unsupported("arithmetic")

    def __mod__(self, other):
        return self._unsupported("arithmetic")

    def __rmod__(self, other):
        return self._unsupported("arithmetic")

    def __lshift__(self, other):
        return self._unsupported("bit shifting")

    def __rlshift__(self, other):
        return self._unsupported("bit shifting")

    def __rshift__(self, other):
        return self._unsupported("bit shifting")

    def __rrshift__(self, other):
        return self._unsupported("bit shifting")

    def __and__(self, other):
        return self._unsupported("bitwise arithmetic")

    def __rand__(self, other):
        return self._unsupported("bitwise arithmetic")

    def __or__(self, other):
        return self._unsupported("bitwise arithmetic")

    def __ror__(self, other):
        return self._unsupported("bitwise arithmetic")

    def __xor__(self, other):
        return self._unsupported("bitwise arithmetic")

    def __rxor__(self, other):
        return self._unsupported("bitwise arithmetic")

    def __invert__(self):
        return self._unsupported("bitwise arithmetic")

    def __lt__(self, other):
        return self._unsupported("comparison")

    def __le__(self, other):
        return self._unsupported("comparison")

    def __gt__(self, other):
        return self._unsupported("comparison")

    def __ge__(self, other):
        return self._unsupported("comparison")

    def __repr__(self) -> str:
        return f"<template-parameter {self.name}>"


class ScalarSentinel(_SentinelBase):
    pass


def make_template_trace_arguments(
    arguments: Mapping[str, Any],
) -> tuple[dict[str, Any], tuple[str, ...]]:
    traced_arguments: dict[str, Any] = {}
    scalar_names: list[str] = []

    for name, value in arguments.items():
        if isinstance(value, bool):
            raise TemplateCompileError(
                f"Template parameter {name!r} uses bool; templates only accept int "
                "scalars (patchable) or non-int values baked in at trace time."
            )

        if _is_scalar_like(value):
            _coerce_template_int(value, name=name)
            scalar_names.append(name)
            traced_arguments[name] = ScalarSentinel(name)
            continue

        # Non-scalar values (tuples, lists of ints, etc.) are not patchable —
        # they flow through untouched and get baked into the specialization
        # at trace time. Each distinct value shape produces its own compile.
        traced_arguments[name] = value

    return traced_arguments, tuple(scalar_names)


def set_trace_mode(enabled: bool):
    return _TRACE_MODE.set(enabled)


def reset_trace_mode(token) -> None:
    _TRACE_MODE.reset(token)


def in_trace_mode() -> bool:
    return bool(_TRACE_MODE.get())


def record_trace_dram_inst_latency(latency_ns: float) -> None:
    _TRACE_DRAM_INST_LATENCY.set(latency_ns)


def record_lowering_stats(*, op_count: int, lower_s: float) -> None:
    global _LAST_LOWERING_STATS
    _LAST_LOWERING_STATS = LoweringStats(op_count=op_count, lower_s=lower_s)


def get_last_lowering_stats() -> LoweringStats | None:
    return _LAST_LOWERING_STATS


def clear_lowering_stats() -> None:
    global _LAST_LOWERING_STATS
    _LAST_LOWERING_STATS = None


class TemplateEnvironmentError(RuntimeError):
    """Raised when the native JIT environment is unavailable."""


@dataclass(frozen=True)
class _CompilerInfo:
    command: tuple[str, ...]
    executable: str
    version: str


@dataclass(frozen=True)
class _CompiledSpecialization:
    plugin: Any
    cache_key: str
    plugin_path: str
    scalar_names: tuple[str, ...]
    dram_inst_latency: float = _DEFAULT_DRAM_INST_LATENCY

    def instantiate(self, arguments: Mapping[str, Any]):
        kwargs = {name: arguments[name] for name in self.scalar_names}
        program = self.plugin.instantiate(kwargs)
        program.default_dram_inst_latency = self.dram_inst_latency
        return program


@dataclass(frozen=True)
class TemplateRunStats:
    mode: str
    cache_key: str
    cache_dir: str
    trace_s: float = 0.0
    codegen_s: float = 0.0
    compile_s: float = 0.0
    plugin_load_s: float = 0.0
    instantiate_s: float = 0.0
    total_s: float = 0.0
    cache_hit: bool = False
    disk_cache_hit: bool = False
    plugin_path: str | None = None


_LAST_TEMPLATE_RUN_STATS: TemplateRunStats | None = None
_CACHE_DIR_OVERRIDE: Path | None = None
_REGISTERED_TEMPLATE_CACHES: list[dict[tuple[Any, ...], _CompiledSpecialization | None]] = []
_FALLBACK_WARNED: set[str] = set()


def get_jit_cache_dir() -> Path:
    if _CACHE_DIR_OVERRIDE is not None:
        return _CACHE_DIR_OVERRIDE

    env_value = os.environ.get("DRAMBENDER_JIT_CACHE_DIR")
    if env_value:
        return Path(env_value).expanduser().resolve()

    return _repo_root() / "build" / "jit-cache"


def set_jit_cache_dir(path: str | Path | None) -> Path:
    global _CACHE_DIR_OVERRIDE

    if path is None:
        _CACHE_DIR_OVERRIDE = None
    else:
        _CACHE_DIR_OVERRIDE = Path(path).expanduser().resolve()
    return get_jit_cache_dir()


def clear_template_caches(*, clear_disk: bool = False) -> None:
    for cache in _REGISTERED_TEMPLATE_CACHES:
        cache.clear()

    if clear_disk:
        shutil.rmtree(get_jit_cache_dir(), ignore_errors=True)


def get_last_template_run_stats() -> TemplateRunStats | None:
    return _LAST_TEMPLATE_RUN_STATS


def get_last_template_run_stats_dict() -> dict[str, Any] | None:
    stats = get_last_template_run_stats()
    if stats is None:
        return None
    return asdict(stats)


def program_template(function=None):
    if function is None:
        return lambda decorated: program_template(decorated)

    global _REGISTERED_TEMPLATE_CACHES

    signature = inspect.signature(function)
    in_memory_cache: dict[tuple[Any, ...], _CompiledSpecialization | None] = {}
    _REGISTERED_TEMPLATE_CACHES.append(in_memory_cache)

    @functools.wraps(function)
    def wrapper(*args, **kwargs):
        global _LAST_TEMPLATE_RUN_STATS

        total_start = time.perf_counter()
        bound = signature.bind(*args, **kwargs)
        bound.apply_defaults()
        normalized_arguments = dict(bound.arguments)

        shape_key = _shape_key(function, normalized_arguments)
        cached = in_memory_cache.get(shape_key)
        if cached is None and shape_key in in_memory_cache:
            result = _call_with_arguments(function, signature, normalized_arguments)
            _LAST_TEMPLATE_RUN_STATS = TemplateRunStats(
                mode="interpreted_fallback",
                cache_key=repr(shape_key),
                cache_dir=str(get_jit_cache_dir()),
                total_s=time.perf_counter() - total_start,
                cache_hit=True,
            )
            return result
        if cached is not None:
            instantiate_start = time.perf_counter()
            result = cached.instantiate(normalized_arguments)
            _LAST_TEMPLATE_RUN_STATS = TemplateRunStats(
                mode="compiled_hot",
                cache_key=cached.cache_key,
                cache_dir=str(get_jit_cache_dir()),
                instantiate_s=time.perf_counter() - instantiate_start,
                total_s=time.perf_counter() - total_start,
                cache_hit=True,
                disk_cache_hit=True,
                plugin_path=cached.plugin_path,
            )
            return result

        trace_start = time.perf_counter()
        trace_ops, scalar_names, dram_inst_latency = _trace_template(
            function,
            signature,
            normalized_arguments,
        )
        trace_s = time.perf_counter() - trace_start
        try:
            specialization, load_stats = _load_or_compile_specialization(
                function=function,
                trace_ops=trace_ops,
                scalar_names=scalar_names,
                dram_inst_latency=dram_inst_latency,
            )
        except TemplateEnvironmentError as err:
            in_memory_cache[shape_key] = None
            qualname = function.__qualname__
            if qualname not in _FALLBACK_WARNED:
                _FALLBACK_WARNED.add(qualname)
                warnings.warn(
                    f"drambender JIT fell back to interpreted mode for "
                    f"{qualname}: {err}. Subsequent calls for this template "
                    f"will also use the interpreted path. See "
                    f"TemplateRunStats.mode=='interpreted_fallback'.",
                    RuntimeWarning,
                    stacklevel=2,
                )
            result = _call_with_arguments(function, signature, normalized_arguments)
            _LAST_TEMPLATE_RUN_STATS = TemplateRunStats(
                mode="interpreted_fallback",
                cache_key=repr(shape_key),
                cache_dir=str(get_jit_cache_dir()),
                trace_s=trace_s,
                total_s=time.perf_counter() - total_start,
            )
            return result

        in_memory_cache[shape_key] = specialization
        instantiate_start = time.perf_counter()
        result = specialization.instantiate(normalized_arguments)
        _LAST_TEMPLATE_RUN_STATS = TemplateRunStats(
            mode="compiled_cold" if load_stats["compiled"] else "compiled_warm_disk",
            cache_key=specialization.cache_key,
            cache_dir=str(get_jit_cache_dir()),
            trace_s=trace_s,
            codegen_s=load_stats["codegen_s"],
            compile_s=load_stats["compile_s"],
            plugin_load_s=load_stats["plugin_load_s"],
            instantiate_s=time.perf_counter() - instantiate_start,
            total_s=time.perf_counter() - total_start,
            disk_cache_hit=load_stats["disk_cache_hit"],
            plugin_path=specialization.plugin_path,
        )
        return result

    wrapper.clear_cache = in_memory_cache.clear
    wrapper.cache_size = lambda: len(in_memory_cache)

    return wrapper


def _is_scalar_like(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _coerce_template_int(value: Any, *, name: str) -> int:
    try:
        return operator.index(value)
    except TypeError as exc:
        raise TypeError(f"{name} must be an integer-compatible value.") from exc


def _shape_key(function, arguments: Mapping[str, Any]) -> tuple[Any, ...]:
    shape = [function.__module__, function.__qualname__, function.__code__.co_firstlineno]
    for name, value in arguments.items():
        if isinstance(value, int) and not isinstance(value, bool):
            shape.append((name, "scalar"))
        elif isinstance(value, (tuple, list)):
            shape.append((name, "seq", tuple(value)))
        else:
            shape.append((name, repr(value)))
    return tuple(shape)


def _trace_template(function, signature: inspect.Signature, arguments: Mapping[str, Any]) -> tuple[list[tuple[Any, ...]], tuple[str, ...], float]:
    trace_arguments, scalar_names = make_template_trace_arguments(arguments)
    token = set_trace_mode(True)
    latency_token = _TRACE_DRAM_INST_LATENCY.set(None)
    try:
        result = _call_with_arguments(function, signature, trace_arguments)
        dram_inst_latency = _TRACE_DRAM_INST_LATENCY.get()
    finally:
        _TRACE_DRAM_INST_LATENCY.reset(latency_token)
        reset_trace_mode(token)

    if not isinstance(result, list):
        raise TemplateCompileError(
            f"Template {function.__qualname__} did not return ProgramBuilder.conclude()."
        )

    if dram_inst_latency is None:
        dram_inst_latency = _DEFAULT_DRAM_INST_LATENCY
    return result, scalar_names, dram_inst_latency


def _call_with_arguments(function, signature: inspect.Signature, arguments: Mapping[str, Any]):
    positional: list[Any] = []
    keywords: dict[str, Any] = {}

    for name, parameter in signature.parameters.items():
        value = arguments[name]
        if parameter.kind in (
            inspect.Parameter.POSITIONAL_ONLY,
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
        ):
            positional.append(value)
        elif parameter.kind == inspect.Parameter.VAR_POSITIONAL:
            positional.extend(value)
        elif parameter.kind == inspect.Parameter.KEYWORD_ONLY:
            keywords[name] = value
        elif parameter.kind == inspect.Parameter.VAR_KEYWORD:
            keywords.update(value)

    return function(*positional, **keywords)


def _load_or_compile_specialization(*, function, trace_ops, scalar_names, dram_inst_latency=_DEFAULT_DRAM_INST_LATENCY) -> tuple[_CompiledSpecialization, dict[str, Any]]:
    metadata = _specialization_metadata(
        function=function,
        trace_ops=trace_ops,
        scalar_names=scalar_names,
        dram_inst_latency=dram_inst_latency,
    )
    cache_dir = get_jit_cache_dir()
    cache_dir.mkdir(parents=True, exist_ok=True)

    stem = metadata["key"]
    source_path = cache_dir / f"{stem}.cpp"
    shared_path = cache_dir / f"{stem}.so"
    metadata_path = cache_dir / f"{stem}.json"
    disk_cache_hit = shared_path.exists()
    codegen_s = 0.0
    compile_s = 0.0

    if not disk_cache_hit:
        codegen_start = time.perf_counter()
        source_path.write_text(
            _render_plugin_source(trace_ops, scalar_names),
            encoding="utf-8",
        )
        metadata_path.write_text(json.dumps(metadata, indent=2, sort_keys=True), encoding="utf-8")
        codegen_s = time.perf_counter() - codegen_start

        compile_start = time.perf_counter()
        _compile_plugin(source_path, shared_path)
        compile_s = time.perf_counter() - compile_start

    plugin_load_start = time.perf_counter()
    plugin = _core.load_program_plugin(
        str(shared_path),
        list(scalar_names),
        [],
        [],
    )
    plugin_load_s = time.perf_counter() - plugin_load_start

    return _CompiledSpecialization(
        plugin=plugin,
        cache_key=stem,
        plugin_path=str(shared_path),
        scalar_names=scalar_names,
        dram_inst_latency=dram_inst_latency,
    ), {
        "codegen_s": codegen_s,
        "compile_s": compile_s,
        "plugin_load_s": plugin_load_s,
        "compiled": not disk_cache_hit,
        "disk_cache_hit": disk_cache_hit,
    }


def _specialization_metadata(*, function, trace_ops, scalar_names, dram_inst_latency=_DEFAULT_DRAM_INST_LATENCY) -> dict[str, Any]:
    serialized_trace = _serialize(trace_ops)
    key_material = {
        "template": {
            "module": function.__module__,
            "qualname": function.__qualname__,
            "firstlineno": function.__code__.co_firstlineno,
            "bytecode_sha256": hashlib.sha256(function.__code__.co_code).hexdigest(),
        },
        "trace": serialized_trace,
        "schema": {
            "scalars": list(scalar_names),
        },
        "timing": {
            "dram_inst_latency": dram_inst_latency,
        },
        "codegen_version": _CODEGEN_VERSION,
        "plugin_abi_version": _PLUGIN_ABI_VERSION,
        "compiler": _compiler_identity(),
        "compile_flags": list(_COMPILE_FLAGS),
        "drambender_core": _core_freshness_marker(),
    }
    key = hashlib.sha256(
        json.dumps(key_material, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    key_material["key"] = key
    return key_material


def _serialize(value):
    if isinstance(value, ScalarAffineRef):
        return {
            "kind": "scalar_affine",
            "name": value.name,
            "multiplier": value.multiplier,
            "offset": value.offset,
        }
    if isinstance(value, ScalarParamRef):
        return {"kind": "scalar_param", "name": value.name}
    if isinstance(value, tuple):
        return [_serialize(item) for item in value]
    if isinstance(value, list):
        return [_serialize(item) for item in value]
    return value


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _packaged_jit_include_dir() -> Path:
    return Path(__file__).resolve().parent / "include"


def _has_packaged_jit_headers(include_dir: Path) -> bool:
    return (
        (include_dir / "drambender" / "api" / "program" / "program.h").is_file()
        and (include_dir / "drambender" / "api" / "program" / "instruction.h").is_file()
        and (include_dir / "program_template_plugin.h").is_file()
    )


def _jit_include_dirs() -> tuple[Path, ...]:
    packaged_include_dir = _packaged_jit_include_dir()
    if _has_packaged_jit_headers(packaged_include_dir):
        return (packaged_include_dir,)

    repo_root = _repo_root()
    source_include_dir = repo_root / "include"
    source_bindings_dir = repo_root / "src" / "bindings" / "python"
    if (
        (source_include_dir / "drambender" / "api" / "program" / "program.h").is_file()
        and (source_include_dir / "drambender" / "api" / "program" / "instruction.h").is_file()
        and (source_bindings_dir / "program_template_plugin.h").is_file()
    ):
        return (source_include_dir, source_bindings_dir)

    raise TemplateEnvironmentError(
        "DRAMBender JIT headers are unavailable. Expected packaged headers at "
        f"{packaged_include_dir} or source-tree headers under {source_include_dir} "
        f"and {source_bindings_dir}. Reinstall the drambender wheel or run from a "
        "complete source checkout."
    )


def _split_compiler_command(value: str) -> tuple[str, ...]:
    try:
        command = tuple(shlex.split(value))
    except ValueError as exc:
        raise TemplateEnvironmentError(
            f"Invalid compiler command {value!r}."
        ) from exc
    if not command:
        raise TemplateEnvironmentError("Compiler command must not be empty.")
    return command


def _candidate_compiler_commands() -> list[tuple[str, tuple[str, ...], bool]]:
    cxx_value = os.environ.get("CXX")
    if cxx_value:
        return [("CXX", _split_compiler_command(cxx_value), True)]

    return [("default g++", (_DEFAULT_COMPILER,), False)]


def _resolve_executable(command: tuple[str, ...]) -> str:
    executable = command[0]
    if os.sep in executable:
        path = Path(executable).expanduser()
        if path.exists():
            return str(path.resolve())
        raise TemplateEnvironmentError(f"Compiler executable {executable!r} was not found.")

    resolved = shutil.which(executable)
    if resolved is None:
        raise TemplateEnvironmentError(f"Compiler executable {executable!r} was not found on PATH.")
    return str(Path(resolved).resolve())


def _validate_compiler(command: tuple[str, ...], executable: str) -> str:
    probe_source = f"""
#if !defined(__GNUC__) || defined(__clang__)
#error "DRAMBender JIT requires G++ {_MIN_GXX_MAJOR} or newer."
#endif
#if __GNUC__ < {_MIN_GXX_MAJOR}
#error "DRAMBender JIT requires G++ {_MIN_GXX_MAJOR} or newer."
#endif
#include <span>
int main() {{
  int values[] = {{1, 2, 3}};
  std::span<int> span(values);
  return static_cast<int>(span.size()) == 3 ? 0 : 1;
}}
""".strip()

    try:
        subprocess.run(
            [
                *command,
                "-std=c++20",
                "-x",
                "c++",
                "-",
                "-c",
                "-o",
                os.devnull,
            ],
            input=probe_source,
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        raise TemplateEnvironmentError(
            f"Compiler executable {executable!r} was not found."
        ) from exc
    except subprocess.CalledProcessError as exc:
        details = (exc.stderr or exc.stdout or "").strip()
        message = f"{' '.join(command)} is not a supported JIT compiler. "
        message += f"DRAMBender JIT requires G++ {_MIN_GXX_MAJOR}+ with C++20 <span> support."
        if details:
            message += f"\nCompiler output:\n{details}"
        raise TemplateEnvironmentError(message) from exc

    try:
        result = subprocess.run(
            [*command, "--version"],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError) as exc:
        raise TemplateEnvironmentError("Failed to query the template compiler.") from exc

    return result.stdout.splitlines()[0] if result.stdout else executable


def _resolve_compiler() -> _CompilerInfo:
    errors: list[str] = []
    for source, command, explicit in _candidate_compiler_commands():
        try:
            executable = _resolve_executable(command)
            version = _validate_compiler(command, executable)
            return _CompilerInfo(command=command, executable=executable, version=version)
        except TemplateEnvironmentError as exc:
            if explicit:
                raise TemplateEnvironmentError(
                    f"{source}={os.environ.get(source)!r} is not usable for the "
                    f"DRAMBender JIT. {exc}"
                ) from exc
            errors.append(f"{' '.join(command)}: {exc}")

    details = "\n  - ".join(errors)
    raise TemplateEnvironmentError(
        f"No suitable JIT compiler found. DRAMBender JIT requires G++ "
        f"{_MIN_GXX_MAJOR}+ with C++20 <span> support. Set CXX=/path/to/g++-11-or-newer "
        f"to choose one explicitly."
        + (f"\nTried:\n  - {details}" if details else "")
    )


def _compiler_identity() -> dict[str, str]:
    compiler = _resolve_compiler()
    return {
        "command": " ".join(compiler.command),
        "executable": compiler.executable,
        "version": compiler.version,
    }


def _core_freshness_marker() -> dict[str, int | str]:
    core_path = Path(_core.__file__).resolve()
    stat = core_path.stat()
    return {
        "path": str(core_path),
        "mtime_ns": stat.st_mtime_ns,
        "size": stat.st_size,
    }


def _compile_plugin(source_path: Path, shared_path: Path) -> None:
    compiler = _resolve_compiler()
    command = [
        *compiler.command,
        *_COMPILE_FLAGS,
    ]
    for include_dir in _jit_include_dirs():
        command.extend(("-I", str(include_dir)))
    command.extend((str(source_path), "-o", str(shared_path)))

    try:
        subprocess.run(command, check=True, capture_output=True, text=True)
    except FileNotFoundError as exc:
        raise TemplateEnvironmentError(
            f"Template compiler {compiler.executable} was not found."
        ) from exc
    except subprocess.CalledProcessError as exc:
        raise TemplateEnvironmentError(
            "Failed to compile the native program template plugin.\n"
            f"stdout:\n{exc.stdout}\n"
            f"stderr:\n{exc.stderr}"
        ) from exc


def _render_plugin_source(trace_ops, scalar_names) -> str:
    scalar_indices = {name: index for index, name in enumerate(scalar_names)}

    lines = [
        "#include <cstddef>",
        "#include <cstdint>",
        "#include <exception>",
        "#include <stdexcept>",
        '#include "drambender/api/program/program.h"',
        '#include "drambender/api/program/instruction.h"',
        '#include "program_template_plugin.h"',
        "",
        "extern \"C\" uint32_t drambender_template_plugin_abi_version() {",
        f"  return {_PLUGIN_ABI_VERSION};",
        "}",
        "",
        "extern \"C\" int instantiate(",
        "    const int32_t* scalars,",
        "    size_t scalar_count,",
        "    const DRAMBenderIntArrayArg* arrays,",
        "    size_t array_count,",
        "    DRAMBender::FinalProgram** out_program) {",
        "  (void)arrays;",
        "  try {",
        "    if (out_program == nullptr) {",
        "      return -1;",
        "    }",
        f"    if (scalar_count != {len(scalar_names)}) {{",
        "      return -2;",
        "    }",
        "    if (array_count != 0) {",
        "      return -3;",
        "    }",
        "    DRAMBender::Program p;",
    ]
    for op_index, op in enumerate(trace_ops):
        lines.append(
            _indent_cpp(_render_cpp_op(op, scalar_indices, op_index), "    ")
        )
    lines.extend(
        [
            "    *out_program = new DRAMBender::FinalProgram(p.conclude());",
            "    return 0;",
            "  } catch (...) {",
            "    return -5;",
            "  }",
            "}",
            "",
        ]
    )
    return "\n".join(lines)


def _render_cpp_value(value, scalar_indices) -> str:
    if isinstance(value, ScalarAffineRef):
        base = f"static_cast<int>(scalars[{scalar_indices[value.name]}])"
        if value.multiplier == 0:
            expr = "0"
        elif value.multiplier == 1:
            expr = base
        elif value.multiplier == -1:
            expr = f"(-{base})"
        else:
            expr = f"({value.multiplier} * {base})"
        if value.offset > 0:
            expr = f"({expr} + {value.offset})"
        elif value.offset < 0:
            expr = f"({expr} - {-value.offset})"
        return expr
    if isinstance(value, ScalarParamRef):
        return f"static_cast<int>(scalars[{scalar_indices[value.name]}])"
    if isinstance(value, str):
        return json.dumps(value)
    return str(int(value))


def _render_cpp_mininst(op, scalar_indices) -> str:
    opcode = op[0]

    if opcode == "NOP":
        return "DRAMBender::SMC_NOP()"
    if opcode == "PRE":
        return (
            "DRAMBender::SMC_PRE("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}, "
            f"{_render_cpp_value(op[4], scalar_indices)})"
        )
    if opcode == "ACT":
        return (
            "DRAMBender::SMC_ACT("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}, "
            f"{_render_cpp_value(op[4], scalar_indices)}, "
            f"{_render_cpp_value(op[5], scalar_indices)})"
        )
    if opcode == "RD":
        return (
            "DRAMBender::SMC_READ("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}, "
            f"{_render_cpp_value(op[4], scalar_indices)}, "
            f"{_render_cpp_value(op[5], scalar_indices)}, "
            f"{_render_cpp_value(op[6], scalar_indices)})"
        )
    if opcode == "WR":
        return (
            "DRAMBender::SMC_WRITE("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}, "
            f"{_render_cpp_value(op[4], scalar_indices)}, "
            f"{_render_cpp_value(op[5], scalar_indices)}, "
            f"{_render_cpp_value(op[6], scalar_indices)})"
        )
    if opcode == "REF":
        return (
            "DRAMBender::SMC_REF("
            f"{_render_cpp_value(op[1], scalar_indices)})"
        )
    if opcode == "SEL_CH":
        return (
            "DRAMBender::SMC_SEL_CH("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)})"
        )
    raise TemplateCompileError(f"Unsupported recorded DRAM mini-op {opcode!r}.")

def _render_cpp_dramseq(op, scalar_indices, op_index: int) -> str:
    items = op[1:]
    if not items:
        raise TemplateCompileError("Recorded DRAMSEQ cannot be empty.")

    align_requested = items[-1][0] == "ALIGN"
    body = items[:-1] if align_requested else items
    if not body:
        raise TemplateCompileError(
            "Recorded DRAMSEQ must contain at least one timed DRAM op before ALIGN()."
        )

    lines = [
        "{",
        f"  int dramseq_slots_{op_index} = 0;",
    ]
    for item_index, item in enumerate(body):
        if item[0] == "ALIGN":
            raise TemplateCompileError(
                "Recorded DRAMSEQ contains ALIGN() before the final position."
            )

        delay_expr = _render_cpp_value(item[-1], scalar_indices)
        delay_name = f"dram_delay_{op_index}_{item_index}"
        lines.extend(
            [
                f"  const int {delay_name} = {delay_expr};",
                f"  if ({delay_name} < 1) {{",
                '    throw std::runtime_error("DRAM sequence delay values must be at least one slot.");',
                "  }",
                "  p.add_mininst("
                f"{_render_cpp_mininst(item[:-1], scalar_indices)}, "
                f"{delay_name});",
                f"  dramseq_slots_{op_index} += {delay_name};",
            ]
        )

    remainder_name = f"dramseq_remainder_{op_index}"
    lines.append(f"  const int {remainder_name} = dramseq_slots_{op_index} % 4;")
    if align_requested:
        lines.extend(
            [
                f"  if ({remainder_name} == 0) {{",
                '    throw std::runtime_error("ALIGN() is invalid because this DRAMSEQ(...) already ends on a 4-slot boundary.");',
                "  }",
                f"  p.add_DRAM_wait(4 - {remainder_name});",
            ]
        )
    else:
        lines.extend(
            [
                f"  if ({remainder_name} != 0) {{",
                '    throw std::runtime_error("DRAMSEQ(...) would end with implicit tail padding. Either make the last delay=... land exactly on the 4-slot boundary or add final ALIGN().");',
                "  }",
            ]
        )
    lines.append("}")
    return "\n".join(lines)


def _render_cpp_op(op, scalar_indices, op_index: int) -> str:
    opcode = op[0]

    if opcode == "ADD":
        return (
            "p.add_inst(DRAMBender::SMC_ADD("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}));"
        )
    if opcode == "ADDI":
        return (
            "p.add_inst(DRAMBender::SMC_ADDI("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"static_cast<uint32_t>({_render_cpp_value(op[2], scalar_indices)}), "
            f"{_render_cpp_value(op[3], scalar_indices)}));"
        )
    if opcode == "SUB":
        return (
            "p.add_inst(DRAMBender::SMC_SUB("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}));"
        )
    if opcode == "SUBI":
        return (
            "p.add_inst(DRAMBender::SMC_SUBI("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"static_cast<uint32_t>({_render_cpp_value(op[2], scalar_indices)}), "
            f"{_render_cpp_value(op[3], scalar_indices)}));"
        )
    if opcode == "LI":
        return (
            "p.add_inst(DRAMBender::SMC_LI("
            f"static_cast<uint32_t>({_render_cpp_value(op[1], scalar_indices)}), "
            f"{_render_cpp_value(op[2], scalar_indices)}));"
        )
    if opcode == "MV":
        return (
            "p.add_inst(DRAMBender::SMC_MV("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}));"
        )
    if opcode == "SRC":
        return (
            "p.add_inst(DRAMBender::SMC_SRC("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}));"
        )
    if opcode == "AND":
        return (
            "p.add_inst(DRAMBender::SMC_AND("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}));"
        )
    if opcode == "OR":
        return (
            "p.add_inst(DRAMBender::SMC_OR("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}));"
        )
    if opcode == "XOR":
        return (
            "p.add_inst(DRAMBender::SMC_XOR("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}));"
        )
    if opcode == "LD":
        return (
            "p.add_inst(DRAMBender::SMC_LD("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}));"
        )
    if opcode == "ST":
        return (
            "p.add_inst(DRAMBender::SMC_ST("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}));"
        )
    if opcode == "LDWD":
        return (
            "p.add_inst(DRAMBender::SMC_LDWD("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}));"
        )
    if opcode == "LDPC":
        return (
            "p.add_inst(DRAMBender::SMC_LDPC("
            f"static_cast<DRAMBender::PC_TYPE>({_render_cpp_value(op[1], scalar_indices)}), "
            f"{_render_cpp_value(op[2], scalar_indices)}));"
        )
    if opcode == "SRE":
        return "p.add_inst(DRAMBender::SMC_SRE());"
    if opcode == "SRX":
        return "p.add_inst(DRAMBender::SMC_SRX());"
    if opcode == "SLEEP":
        cycles_name = f"sleep_cycles_{op_index}"
        cycles_expr = _render_cpp_value(op[1], scalar_indices)
        return "\n".join(
            [
                f"const int {cycles_name} = {cycles_expr};",
                f"if ({cycles_name} < 1) {{",
                '  throw std::runtime_error("SLEEP cycles must be at least 1.");',
                "}",
                f"if ({cycles_name} <= 2) {{",
                f"  for (int i = 0; i < {cycles_name}; ++i) {{",
                "    p.add_inst(DRAMBender::all_nops());",
                "  }",
                "} else {",
                "  p.add_inst(DRAMBender::SMC_SLEEP("
                f"static_cast<uint32_t>({cycles_name})));",
                "}",
            ]
        )
    if opcode == "PRE":
        return (
            "p.add_mininst(DRAMBender::SMC_PRE("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}, "
            f"{_render_cpp_value(op[4], scalar_indices)}), "
            f"{_render_cpp_value(op[5], scalar_indices)});"
        )
    if opcode == "ACT":
        return (
            "p.add_mininst(DRAMBender::SMC_ACT("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}, "
            f"{_render_cpp_value(op[4], scalar_indices)}, "
            f"{_render_cpp_value(op[5], scalar_indices)}), "
            f"{_render_cpp_value(op[6], scalar_indices)});"
        )
    if opcode == "RD":
        return (
            "p.add_mininst(DRAMBender::SMC_READ("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}, "
            f"{_render_cpp_value(op[4], scalar_indices)}, "
            f"{_render_cpp_value(op[5], scalar_indices)}, "
            f"{_render_cpp_value(op[6], scalar_indices)}), "
            f"{_render_cpp_value(op[7], scalar_indices)});"
        )
    if opcode == "WR":
        return (
            "p.add_mininst(DRAMBender::SMC_WRITE("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)}, "
            f"{_render_cpp_value(op[4], scalar_indices)}, "
            f"{_render_cpp_value(op[5], scalar_indices)}, "
            f"{_render_cpp_value(op[6], scalar_indices)}), "
            f"{_render_cpp_value(op[7], scalar_indices)});"
        )
    if opcode == "REF":
        return (
            "p.add_mininst(DRAMBender::SMC_REF("
            f"{_render_cpp_value(op[1], scalar_indices)}), "
            f"{_render_cpp_value(op[2], scalar_indices)});"
        )
    if opcode == "SEL_CH":
        return (
            "p.add_mininst(DRAMBender::SMC_SEL_CH("
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}), "
            f"{_render_cpp_value(op[3], scalar_indices)});"
        )
    if opcode == "DRAM":
        return (
            "p.add_inst("
            f"{_render_cpp_mininst(op[1], scalar_indices)}, "
            f"{_render_cpp_mininst(op[2], scalar_indices)}, "
            f"{_render_cpp_mininst(op[3], scalar_indices)}, "
            f"{_render_cpp_mininst(op[4], scalar_indices)});"
        )
    if opcode == "DRAM_DELAY":
        return (
            "p.add_mininst("
            f"{_render_cpp_mininst(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)});"
        )
    if opcode == "DRAMSEQ":
        return _render_cpp_dramseq(op, scalar_indices, op_index)
    if opcode == "DRAM_ALIGN_PAD":
        return f"p.add_DRAM_wait({_render_cpp_value(op[1], scalar_indices)});"
    if opcode == "LABEL":
        return f"p.add_label({_render_cpp_value(op[1], scalar_indices)});"
    if opcode == "BL":
        return (
            "p.add_branch(DRAMBender::Program::BR_TYPE::BL, "
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)});"
        )
    if opcode == "BEQ":
        return (
            "p.add_branch(DRAMBender::Program::BR_TYPE::BEQ, "
            f"{_render_cpp_value(op[1], scalar_indices)}, "
            f"{_render_cpp_value(op[2], scalar_indices)}, "
            f"{_render_cpp_value(op[3], scalar_indices)});"
        )
    if opcode == "JMP":
        return (
            "p.add_branch(DRAMBender::Program::BR_TYPE::JUMP, 0, 0, "
            f"{_render_cpp_value(op[1], scalar_indices)});"
        )
    raise TemplateCompileError(f"Unsupported recorded opcode {opcode!r}.")


def _indent_cpp(source: str, prefix: str) -> str:
    return "\n".join(prefix + line if line else line for line in source.splitlines())


__all__ = [
    "ScalarAffineRef",
    "ScalarParamRef",
    "TemplateCompileError",
    "TemplateRunStats",
    "LoweringStats",
    "clear_template_caches",
    "clear_lowering_stats",
    "get_jit_cache_dir",
    "get_last_lowering_stats",
    "get_last_template_run_stats",
    "get_last_template_run_stats_dict",
    "program_template",
    "set_jit_cache_dir",
]
