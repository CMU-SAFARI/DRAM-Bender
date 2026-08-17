"""Memory-target value objects for Python program construction."""

from dataclasses import dataclass
import operator
from typing import Any, ClassVar

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
    """Shared base for HBM2 targets.

    This class is abstract. Use :class:`HBM2U50Target` or
    :class:`HBM2U55Target`, which set the per-board capabilities (SID count,
    broadcast support, and instruction buffer depth).
    """

    channel: int = 0
    pseudo_channel: int = 0
    sid: int = 0
    columns_per_row: int = 32
    column_stride: int = 1
    words_per_cacheline: int = 16

    # Per-board capabilities. Subclasses override these class attributes.
    num_sids: ClassVar[int] = 1
    broadcast_supported: ClassVar[bool] = False
    instruction_capacity: ClassVar[int] = 32768

    def __post_init__(self) -> None:
        if type(self) is HBM2Target:
            raise TypeError(
                "HBM2Target is abstract; use HBM2U50Target or HBM2U55Target."
            )
        name = type(self).__name__
        _validate_int_field(self.channel, name=f"{name}.channel", minimum=0, maximum=15)
        _validate_int_field(self.pseudo_channel, name=f"{name}.pseudo_channel", minimum=0, maximum=1)
        _validate_int_field(self.sid, name=f"{name}.sid", minimum=0, maximum=self.num_sids - 1)
        _validate_int_field(self.columns_per_row, name=f"{name}.columns_per_row", minimum=1)
        _validate_int_field(self.column_stride, name=f"{name}.column_stride", minimum=1)
        _validate_int_field(self.words_per_cacheline, name=f"{name}.words_per_cacheline", minimum=1)


@dataclass(frozen=True)
class HBM2U50Target(HBM2Target):
    """Alveo U50 HBM2 target: 1 SID, no broadcast, 32 K instruction buffer."""

    num_sids: ClassVar[int] = 1
    broadcast_supported: ClassVar[bool] = False
    instruction_capacity: ClassVar[int] = 32768


@dataclass(frozen=True)
class HBM2U55Target(HBM2Target):
    """Alveo U55C HBM2 target: 2 SIDs, broadcast, 128 K instruction buffer."""

    num_sids: ClassVar[int] = 2
    broadcast_supported: ClassVar[bool] = True
    instruction_capacity: ClassVar[int] = 131072

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
    "HBM2U50Target",
    "HBM2U55Target",
    "normalize_target",
]
