"""DRAM command factories for use with ProgramBuilder.DRAM / DRAMSEQ.

Typical use:

    from drambender.api.program.instructions import *
    from drambender.api import ProgramBuilder

    p = ProgramBuilder()
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.DRAMSEQ(ACT("BAR", "RAR", delay=12))

Every factory here returns a `_DRAMMiniOp` — the interop type that
ProgramBuilder's DRAM / DRAMSEQ methods accept. Delay is optional on
factories used inside DRAM(...) and required inside DRAMSEQ(...).
"""

from dataclasses import dataclass
import operator
from typing import Any

from drambender._jit import (
    ScalarParamRef,
    ScalarSentinel,
)


@dataclass(frozen=True)
class _DRAMMiniOp:
    opcode: str
    operands: tuple[Any, ...]
    delay: Any | None = None


def _coerce_python_int(value, *, name: str) -> int:
    try:
        return operator.index(value)
    except TypeError as exc:
        raise TypeError(f"{name} must be an integer-compatible value.") from exc


def _validate_operand_value(value, *, name: str):
    if isinstance(value, (ScalarSentinel, ScalarParamRef)):
        return value
    return _coerce_python_int(value, name=name)


def _validate_register_like(value, *, name: str):
    if isinstance(value, str):
        return value
    return _validate_operand_value(value, name=name)


def _validate_delay_value(value, *, name: str):
    if value is None:
        return None
    normalized = _validate_operand_value(value, name=name)
    if not isinstance(
        normalized,
        (ScalarSentinel, ScalarParamRef),
    ) and normalized < 1:
        raise ValueError(f"{name} must be at least one slot.")
    return normalized


def NOP() -> _DRAMMiniOp:
    """No-op mini-instruction. Only valid inside :meth:`ProgramBuilder.DRAM`
    as filler for unused slots — never inside :meth:`ProgramBuilder.DRAMSEQ`
    (use a larger ``delay=`` on a real command instead).
    """
    return _DRAMMiniOp("NOP", ())


def ALIGN() -> _DRAMMiniOp:
    """Pad the current :meth:`ProgramBuilder.DRAMSEQ` up to the next 4-slot
    fabric boundary. Only valid as the **last** item of a ``DRAMSEQ(...)``
    call, and only when the preceding delays don't already sum to a multiple
    of 4 slots.
    """
    return _DRAMMiniOp("ALIGN", ())


def PRE(bar, *, ibar=0, pall=0, rank=0, delay=None) -> _DRAMMiniOp:
    """Precharge (close) a DRAM row.

    ``bar`` — register holding the bank address. ``ibar=1`` auto-increments
    ``bar`` by ``BASR`` after the command fires. ``pall=1`` precharges every
    bank on this rank (precharge-all). ``rank`` selects the DRAM rank.
    ``delay=N`` is required inside :meth:`ProgramBuilder.DRAMSEQ` and forbidden
    inside :meth:`ProgramBuilder.DRAM`; it pads the mini-op with ``N-1``
    trailing NOP slots.
    """
    return _DRAMMiniOp(
        "PRE",
        (
            _validate_register_like(bar, name="PRE bar"),
            _validate_operand_value(ibar, name="PRE ibar"),
            _validate_operand_value(pall, name="PRE pall"),
            _validate_operand_value(rank, name="PRE rank"),
        ),
        _validate_delay_value(delay, name="PRE delay"),
    )


def ACT(bar, rar, *, ibar=0, irar=0, rank=0, delay=None) -> _DRAMMiniOp:
    """Activate (open) a DRAM row.

    ``bar`` and ``rar`` are registers holding the bank and row addresses.
    ``ibar=1`` auto-increments ``bar`` by ``BASR`` after firing; ``irar=1``
    auto-increments ``rar`` by ``RASR``. ``rank`` selects the DRAM rank.
    See :func:`PRE` for ``delay=`` semantics. Remember: DDR4 needs tRP
    (~18 ns) after the last PRE on this bank before this ACT fires.
    """
    return _DRAMMiniOp(
        "ACT",
        (
            _validate_register_like(bar, name="ACT bar"),
            _validate_operand_value(ibar, name="ACT ibar"),
            _validate_register_like(rar, name="ACT rar"),
            _validate_operand_value(irar, name="ACT irar"),
            _validate_operand_value(rank, name="ACT rank"),
        ),
        _validate_delay_value(delay, name="ACT delay"),
    )


def RD(bar, car, *, ibar=0, icar=0, rank=0, ap=0, delay=None) -> _DRAMMiniOp:
    """Column read from an already-activated row.

    ``bar``/``car`` are registers holding the bank and column addresses.
    ``ibar=1`` auto-steps ``bar`` by ``BASR``; ``icar=1`` auto-steps ``car``
    by ``CASR`` (useful for sequential column reads within a row). ``ap=1``
    issues READ-with-auto-precharge (closes the row after the read).
    See :func:`PRE` for ``delay=`` semantics.
    """
    return _DRAMMiniOp(
        "RD",
        (
            _validate_register_like(bar, name="RD bar"),
            _validate_operand_value(ibar, name="RD ibar"),
            _validate_register_like(car, name="RD car"),
            _validate_operand_value(icar, name="RD icar"),
            _validate_operand_value(rank, name="RD rank"),
            _validate_operand_value(ap, name="RD ap"),
        ),
        _validate_delay_value(delay, name="RD delay"),
    )


def WR(bar, car, *, ibar=0, icar=0, rank=0, ap=0, delay=None) -> _DRAMMiniOp:
    """Column write to an already-activated row.

    Same kwargs as :func:`RD`. The 16-lane data to write must be staged first
    via :meth:`ProgramBuilder.LDWD` into the wide ``PATTERN_REG``. Remember
    DDR4 needs tRCD (~18 ns) after the ACT before the first WR fires on that
    row.
    """
    return _DRAMMiniOp(
        "WR",
        (
            _validate_register_like(bar, name="WR bar"),
            _validate_operand_value(ibar, name="WR ibar"),
            _validate_register_like(car, name="WR car"),
            _validate_operand_value(icar, name="WR icar"),
            _validate_operand_value(rank, name="WR rank"),
            _validate_operand_value(ap, name="WR ap"),
        ),
        _validate_delay_value(delay, name="WR delay"),
    )


def REF(*, rank=0, delay=None) -> _DRAMMiniOp:
    """DRAM auto-refresh command to the given rank.

    All banks must be precharged before issuing REF. See :func:`PRE` for
    ``delay=`` semantics.
    """
    return _DRAMMiniOp(
        "REF",
        (_validate_operand_value(rank, name="REF rank"),),
        _validate_delay_value(delay, name="REF delay"),
    )


def SEL_CH(channel, *, pseudo_channel=0, delay=None) -> _DRAMMiniOp:
    """Select an HBM2 channel / pseudo-channel for subsequent DRAM commands.

    DDR4 programs don't need this. See :func:`PRE` for ``delay=`` semantics.
    """
    return _DRAMMiniOp(
        "SEL_CH",
        (
            _validate_operand_value(channel, name="SEL_CH channel"),
            _validate_operand_value(pseudo_channel, name="SEL_CH pseudo_channel"),
        ),
        _validate_delay_value(delay, name="SEL_CH delay"),
    )


__all__ = [
    "ACT",
    "ALIGN",
    "NOP",
    "PRE",
    "RD",
    "REF",
    "SEL_CH",
    "WR",
]
