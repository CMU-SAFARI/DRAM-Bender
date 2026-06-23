"""Memory-target value objects for Python program construction."""

from dataclasses import dataclass
import operator
from typing import Any

from drambender._jit import ScalarAffineRef, ScalarParamRef, ScalarSentinel


def _coerce_int(value: Any, *, name: str) -> int:
    try:
        return operator.index(value)
    except TypeError as exc:
        raise TypeError(f"{name} must be an integer-compatible value.") from exc


def _check_range(value: int, *, name: str, minimum: int, maximum: int | None = None) -> None:
    if value < minimum:
        raise ValueError(f"{name} must be at least {minimum}.")
    if maximum is not None and value > maximum:
        raise ValueError(f"{name} must be in range {minimum}..{maximum}.")


def _is_symbolic(value: Any) -> bool:
    return isinstance(value, (ScalarSentinel, ScalarParamRef, ScalarAffineRef))


def _validate_int_field(value: Any, *, name: str, minimum: int, maximum: int | None = None) -> None:
    if _is_symbolic(value):
        return
    _check_range(_coerce_int(value, name=name), name=name, minimum=minimum, maximum=maximum)


@dataclass(frozen=True)
class DDR4Target:
    """DDR4 target defaults used by existing Python DRAM Bender programs."""

    cachelines_per_row: int = 128
    column_stride: int = 8
    words_per_cacheline: int = 16
    rank: int = 0

    def __post_init__(self) -> None:
        _validate_int_field(self.cachelines_per_row, name="DDR4Target.cachelines_per_row", minimum=1)
        _validate_int_field(self.column_stride, name="DDR4Target.column_stride", minimum=1)
        _validate_int_field(self.words_per_cacheline, name="DDR4Target.words_per_cacheline", minimum=1)
        _validate_int_field(self.rank, name="DDR4Target.rank", minimum=0)

    @property
    def columns_per_row(self) -> int:
        return self.cachelines_per_row

    def physical_bank(self, bank):
        """Return the bank value used by BAR for DDR4.

        This is intentionally a value-only helper. It emits no DRAM Bender
        instructions and exists so target-aware code can share shape with HBM2.
        """
        return bank


@dataclass(frozen=True)
class HBM2Target:
    """HBM2 target settings for the latest U55 SID bitstream."""

    channel: int = 0
    pseudo_channel: int = 0
    sid: int = 1
    columns_per_row: int = 32
    column_stride: int = 1
    words_per_cacheline: int = 16

    def __post_init__(self) -> None:
        _validate_int_field(self.channel, name="HBM2Target.channel", minimum=0, maximum=15)
        _validate_int_field(self.pseudo_channel, name="HBM2Target.pseudo_channel", minimum=0, maximum=1)
        _validate_int_field(self.sid, name="HBM2Target.sid", minimum=0, maximum=1)
        _validate_int_field(self.columns_per_row, name="HBM2Target.columns_per_row", minimum=1)
        _validate_int_field(self.column_stride, name="HBM2Target.column_stride", minimum=1)
        _validate_int_field(self.words_per_cacheline, name="HBM2Target.words_per_cacheline", minimum=1)

    @property
    def rank(self) -> int:
        return self.pseudo_channel

    @property
    def cachelines_per_row(self) -> int:
        return self.columns_per_row

    @property
    def receive_bytes_per_row(self) -> int:
        return self.columns_per_row * 64

    def physical_bank(self, bank):
        """Return BAR bank value with SID encoded in BAR[4].

        For the latest U55 SID bitstream, logical banks remain 0..15 and the
        stack ID is encoded as bank + 16 * sid. Symbolic JIT banks are kept as
        a narrow affine scalar expression for native template rendering.
        """
        sid = _coerce_int(self.sid, name="HBM2Target.sid")
        offset = 16 * sid
        if isinstance(bank, ScalarSentinel):
            return ScalarAffineRef(bank.name, offset=offset)
        if isinstance(bank, ScalarParamRef):
            return ScalarAffineRef(bank.name, offset=offset)
        if isinstance(bank, ScalarAffineRef):
            return ScalarAffineRef(
                bank.name,
                multiplier=bank.multiplier,
                offset=bank.offset + offset,
            )
        return _coerce_int(bank, name="HBM2Target bank") + offset


def normalize_target(target: Any | None):
    if isinstance(target, (DDR4Target, HBM2Target)):
        return target
    raise TypeError("target must be DDR4Target or HBM2Target.")


__all__ = [
    "DDR4Target",
    "HBM2Target",
    "normalize_target",
]
