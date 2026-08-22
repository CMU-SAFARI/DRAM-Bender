"""Memory-target value objects for Python program construction."""

from dataclasses import dataclass
import operator
from typing import Any, ClassVar

from drambender._jit import ScalarAffineRef, ScalarParamRef, ScalarSentinel

from ..._core import BoardConfig
from ..board_configs import U200, U50, U55C


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
    """Alveo U200 DDR4 target."""

    cachelines_per_row: int = 128
    column_stride: int = 8
    words_per_cacheline: int = 16
    rank: int = 0

    _board_config: ClassVar[BoardConfig] = U200

    def __post_init__(self) -> None:
        _validate_int_field(self.cachelines_per_row, name="DDR4Target.cachelines_per_row", minimum=1)
        _validate_int_field(self.column_stride, name="DDR4Target.column_stride", minimum=1)
        _validate_int_field(self.words_per_cacheline, name="DDR4Target.words_per_cacheline", minimum=1)
        _validate_int_field(self.rank, name="DDR4Target.rank", minimum=0)

    @property
    def columns_per_row(self) -> int:
        return self.cachelines_per_row

    @property
    def board_config(self) -> BoardConfig:
        """Immutable hardware assumptions for the U200 bitstream."""
        return self._board_config

    @property
    def instruction_capacity(self) -> int:
        return self.board_config.instruction_capacity

    @property
    def dram_inst_latency_ns(self) -> float:
        """Duration of one DRAM command slot, in nanoseconds."""
        return self.board_config.dram_command_slot_ns

    @property
    def dram_slots_per_fabric_cycle(self) -> int:
        return self.board_config.dram_slots_per_fabric_cycle

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
    :class:`HBM2U55Target`, which select the corresponding board
    configuration.
    """

    channel: int = 0
    pseudo_channel: int = 0
    sid: int = 0
    columns_per_row: int = 32
    column_stride: int = 1
    words_per_cacheline: int = 16

    _board_config: ClassVar[BoardConfig | None] = None

    def __post_init__(self) -> None:
        if type(self) is HBM2Target:
            raise TypeError(
                "HBM2Target is abstract; use HBM2U50Target or HBM2U55Target."
            )
        name = type(self).__name__
        config = self.board_config
        _validate_int_field(
            self.channel,
            name=f"{name}.channel",
            minimum=0,
            maximum=config.hbm_channel_count - 1,
        )
        _validate_int_field(
            self.pseudo_channel,
            name=f"{name}.pseudo_channel",
            minimum=0,
            maximum=config.hbm_pseudo_channel_count - 1,
        )
        _validate_int_field(
            self.sid,
            name=f"{name}.sid",
            minimum=0,
            maximum=config.hbm_sid_count - 1,
        )
        _validate_int_field(self.columns_per_row, name=f"{name}.columns_per_row", minimum=1)
        _validate_int_field(self.column_stride, name=f"{name}.column_stride", minimum=1)
        _validate_int_field(self.words_per_cacheline, name=f"{name}.words_per_cacheline", minimum=1)

    @property
    def rank(self) -> int:
        return self.pseudo_channel

    @property
    def board_config(self) -> BoardConfig:
        """Immutable hardware assumptions for this target's bitstream."""
        config = type(self)._board_config
        if config is None:
            raise TypeError(
                "HBM2Target is abstract; use HBM2U50Target or HBM2U55Target."
            )
        return config

    @property
    def instruction_capacity(self) -> int:
        return self.board_config.instruction_capacity

    @property
    def dram_inst_latency_ns(self) -> float:
        """Duration of one DRAM command slot, in nanoseconds."""
        return self.board_config.dram_command_slot_ns

    @property
    def dram_slots_per_fabric_cycle(self) -> int:
        return self.board_config.dram_slots_per_fabric_cycle

    @property
    def num_sids(self) -> int:
        """Compatibility alias for the configured HBM SID count."""
        return self.board_config.hbm_sid_count

    @property
    def broadcast_supported(self) -> bool:
        return self.board_config.broadcast_supported

    @property
    def power_telemetry_supported(self) -> bool:
        return self.board_config.power_telemetry_supported

    @property
    def cachelines_per_row(self) -> int:
        return self.columns_per_row

    @property
    def receive_bytes_per_row(self) -> int:
        return self.columns_per_row * 64

    def physical_bank(self, bank):
        """Return BAR bank value with SID encoded in BAR[4].

        Logical banks remain 0..15 and the stack ID is encoded as
        bank + 16 * sid. Single-SID boards (U50) always have sid == 0, so the
        bank passes through unchanged. Symbolic JIT banks are kept as a narrow
        affine scalar expression for native template rendering.
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


@dataclass(frozen=True)
class HBM2U50Target(HBM2Target):
    """Alveo U50 HBM2 target."""

    _board_config: ClassVar[BoardConfig] = U50


@dataclass(frozen=True)
class HBM2U55Target(HBM2Target):
    """Alveo U55C HBM2 target."""

    _board_config: ClassVar[BoardConfig] = U55C


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
