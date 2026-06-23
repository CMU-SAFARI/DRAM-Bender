"""ProgramBuilder — Python DSL for authoring DRAM Bender programs.

The DRAM command factories (ACT/NOP/PRE/RD/WR/REF/SEL_CH/ALIGN) live in
`drambender.api.program.instructions` — import them there.
"""

from contextvars import ContextVar
import operator
import time
from typing import Any

from typing import TYPE_CHECKING, cast

from drambender import _core
from drambender._jit import (
    ScalarParamRef,
    ScalarSentinel,
    TemplateCompileError,
    in_trace_mode,
    record_lowering_stats,
)

if TYPE_CHECKING:
    from drambender._core import FinalProgram

from .instructions import (
    NOP,
    _DRAMMiniOp,
    _coerce_python_int,
    _validate_delay_value,
    _validate_operand_value,
    _validate_register_like,
)


_MAX_REGISTERS = 16

_RESERVED_REGISTERS = {
    "CASR": 0,
    "BASR": 1,
    "RASR": 2,
    "CAR": 3,
    "BAR": 4,
    "RAR": 5,
    "PATTERN_REG": 6,
}


_PROGRAM_BUILDER_META: ContextVar[Any | None] = ContextVar(
    "drambender_program_builder_meta",
    default=None,
)


def _set_program_builder_meta(meta: Any):
    return _PROGRAM_BUILDER_META.set(meta)


def _reset_program_builder_meta(token) -> None:
    _PROGRAM_BUILDER_META.reset(token)


class _RegisterFile:
    def __init__(self) -> None:
        self._name_to_id = dict(_RESERVED_REGISTERS)

    def alloc(self, name: str) -> int:
        if not isinstance(name, str):
            raise TypeError("Register names must be strings.")
        if name in self._name_to_id:
            return self._name_to_id[name]

        used = set(self._name_to_id.values())
        for register_id in range(_RESERVED_REGISTERS["PATTERN_REG"] + 1, _MAX_REGISTERS):
            if register_id not in used:
                self._name_to_id[name] = register_id
                return register_id

        raise ValueError(
            f"No free registers remain. Maximum register count is {_MAX_REGISTERS}."
        )

    def resolve(self, register: str | int) -> int:
        if isinstance(register, str):
            return self.alloc(register)

        register_id = operator.index(register)
        if not 0 <= register_id < _MAX_REGISTERS:
            raise ValueError(
                f"Register id {register_id} is out of range [0, {_MAX_REGISTERS})."
            )
        return register_id


def _forbidden_slot_hiding_dram_method(method_name: str):
    """Build a ProgramBuilder method stub that loudly rejects slot-hiding API.

    These command constructors (PRE/ACT/RD/WR/REF/SEL_CH) at module scope are
    fine — they build _DRAMMiniOp values. But calling them as ProgramBuilder
    methods (`p.PRE(...)`) would hide the exact mini-inst slot and inject
    implicit NOPs around the command. DRAM authoring is timing-critical:
    every slot must be authored explicitly via DRAM(...) or DRAMSEQ(...).
    """
    message = (
        f"ProgramBuilder.{method_name}() is forbidden because it hides packed "
        f"DRAM slot layout. Use ProgramBuilder.DRAMSEQ({method_name}(..., delay=...)) "
        "for timed DRAM sequences, or ProgramBuilder.DRAM(...) for exact packed words."
    )

    def _method(self, *args, **kwargs):
        raise NotImplementedError(message)

    _method.__name__ = method_name
    _method.__qualname__ = f"ProgramBuilder.{method_name}"
    _method.__doc__ = message
    return _method


class ProgramBuilder:
    """Python DSL that emits DRAM Bender fabric instructions.

    Typical lifecycle::

        p = ProgramBuilder()
        p.LI(0, "BAR")                       # load-immediate into a register
        p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())   # one 4-slot DRAM word
        p.SLEEP(3)
        final_program = p.conclude()         # -> FinalProgram for board.execute(...)

    Most methods return ``self`` so calls can be chained. Register arguments
    accept a name string (auto-allocated on first use, see :meth:`alloc_reg`)
    or an integer id (0–15).

    Scalar arithmetic and control-flow instructions take one fabric cycle
    (6 ns on the default DDR4 variant). DRAM mini-operations live inside
    :meth:`DRAM` (exact 4-slot packing) or :meth:`DRAMSEQ` (timed sequence);
    see the module docstring of
    ``drambender.api.program.instructions`` for the command factories.
    """

    def __init__(self) -> None:
        self.meta = _PROGRAM_BUILDER_META.get()
        self._registers = _RegisterFile()
        self._ops: list[tuple[Any, ...]] = []

    def alloc_reg(self, name: str) -> int:
        """Allocate (or look up) a named register.

        Returns the integer register id. Idempotent — calling again with the
        same ``name`` returns the existing id. Raises ``ValueError`` if the
        16-register file is exhausted (9 user slots + 7 reserved).
        """
        return self._registers.alloc(name)

    def ADD(self, rs1, rs2, rt):
        """``rt = rs1 + rs2`` (scalar register add). One fabric cycle."""
        return self._emit("ADD", self._resolve_reg(rs1), self._resolve_reg(rs2), self._resolve_reg(rt))

    def ADDI(self, rs1, immediate, rt):
        """``rt = rs1 + immediate`` (scalar add-immediate). One fabric cycle."""
        return self._emit("ADDI", self._resolve_reg(rs1), self._normalize_int(immediate), self._resolve_reg(rt))

    def SUB(self, rs1, rs2, rt):
        """``rt = rs1 - rs2`` (scalar register sub). One fabric cycle."""
        return self._emit("SUB", self._resolve_reg(rs1), self._resolve_reg(rs2), self._resolve_reg(rt))

    def SUBI(self, rs1, immediate, rt):
        """``rt = rs1 - immediate`` (scalar sub-immediate). One fabric cycle."""
        return self._emit("SUBI", self._resolve_reg(rs1), self._normalize_int(immediate), self._resolve_reg(rt))

    def LI(self, immediate, rt):
        """``rt = immediate`` — load a 32-bit immediate into a register. One fabric cycle."""
        return self._emit("LI", self._normalize_int(immediate), self._resolve_reg(rt))

    def MV(self, rs1, rt):
        """``rt = rs1`` — copy a register. One fabric cycle."""
        return self._emit("MV", self._resolve_reg(rs1), self._resolve_reg(rt))

    def SRC(self, rs1, rt):
        """``rt = rotate_right_1(rs1)`` — shift-right-circular by 1 bit. One fabric cycle."""
        return self._emit("SRC", self._resolve_reg(rs1), self._resolve_reg(rt))

    def AND(self, rs1, rs2, rt):
        """``rt = rs1 & rs2`` (bitwise AND). One fabric cycle."""
        return self._emit("AND", self._resolve_reg(rs1), self._resolve_reg(rs2), self._resolve_reg(rt))

    def OR(self, rs1, rs2, rt):
        """``rt = rs1 | rs2`` (bitwise OR). One fabric cycle."""
        return self._emit("OR", self._resolve_reg(rs1), self._resolve_reg(rs2), self._resolve_reg(rt))

    def XOR(self, rs1, rs2, rt):
        """``rt = rs1 ^ rs2`` (bitwise XOR). One fabric cycle."""
        return self._emit("XOR", self._resolve_reg(rs1), self._resolve_reg(rs2), self._resolve_reg(rt))

    def LD(self, rb, offset, rt):
        """``rt = scratch_mem[rb + offset]`` — load from SoftMC scratch memory. One fabric cycle."""
        return self._emit("LD", self._resolve_reg(rb), self._normalize_int(offset), self._resolve_reg(rt))

    def ST(self, rb, offset, rv):
        """``scratch_mem[rb + offset] = rv`` — store to SoftMC scratch memory. One fabric cycle."""
        return self._emit("ST", self._resolve_reg(rb), self._normalize_int(offset), self._resolve_reg(rv))

    def LDWD(self, rs1, offset):
        """Broadcast ``rs1`` into lane ``offset`` of the wide write register.

        ``offset`` indexes into the 16-lane wide pattern used by DRAM ``WR``
        commands. Call 16 times (offsets 0..15) to fully populate a cacheline
        pattern before issuing ``WR``. One fabric cycle per call.
        """
        return self._emit("LDWD", self._resolve_reg(rs1), self._normalize_int(offset))

    def LDPC(self, pc_type, rt):
        """Load a program-counter register into ``rt``.

        ``pc_type`` selects which counter (write, read, pre, act, sel_ch, ref,
        cyc) — see :class:`drambender.api.PCType`. One fabric cycle.
        """
        return self._emit("LDPC", self._normalize_int(pc_type), self._resolve_reg(rt))

    def SRE(self):
        """Enter self-refresh. One fabric cycle."""
        return self._emit("SRE")

    def SRX(self):
        """Exit self-refresh. One fabric cycle."""
        return self._emit("SRX")

    def SLEEP(self, cycles):
        """Idle for ``cycles`` fabric cycles (6 ns each on the default variant).

        ``SLEEP(1)``/``SLEEP(2)`` expand to 1–2 ``DRAM(NOP, NOP, NOP, NOP)``
        cycles (no separate scalar instruction). ``SLEEP(N >= 3)`` emits a
        single ``SMC_SLEEP`` scalar instruction.
        """
        normalized = self._normalize_int(cycles)
        if isinstance(normalized, ScalarParamRef):
            return self._emit("SLEEP", normalized)
        if normalized < 1:
            raise ValueError("SLEEP cycles must be at least 1.")
        if normalized <= 2:
            for _ in range(normalized):
                self.DRAM(NOP(), NOP(), NOP(), NOP())
            return self
        return self._emit("SLEEP", normalized)

    PRE    = _forbidden_slot_hiding_dram_method("PRE")
    ACT    = _forbidden_slot_hiding_dram_method("ACT")
    RD     = _forbidden_slot_hiding_dram_method("RD")
    WR     = _forbidden_slot_hiding_dram_method("WR")
    REF    = _forbidden_slot_hiding_dram_method("REF")
    SEL_CH = _forbidden_slot_hiding_dram_method("SEL_CH")

    def DRAM(self, op0, op1, op2, op3):
        """Emit one fabric instruction with four DRAM mini-ops packed into slots 0–3.

        Each ``op`` must be a mini-op from
        ``drambender.api.program.instructions`` (``PRE``, ``ACT``, ``RD``,
        ``WR``, ``REF``, ``SEL_CH``, ``NOP``). Use ``NOP()`` for unused slots.
        One fabric cycle (6 ns on the default variant).

        Example — a single PRE on this bank::

            p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
        """
        return self._emit(
            "DRAM",
            self._normalize_dram_exact_op(op0, slot_index=0),
            self._normalize_dram_exact_op(op1, slot_index=1),
            self._normalize_dram_exact_op(op2, slot_index=2),
            self._normalize_dram_exact_op(op3, slot_index=3),
        )

    def DRAMSEQ(self, *ops):
        """Emit a timed sequence of DRAM mini-ops with per-op ``delay=N`` slots.

        Each ``op`` is a mini-op created with an explicit ``delay=`` (e.g.
        ``PRE("BAR", delay=11)``). The sequence must end on a 4-slot (fabric-
        cycle) boundary — either by hand-sizing the last delay, or by using
        ``ALIGN()`` as the final item.

        **Rule**: do not use ``DRAMSEQ`` for a *single* DRAM command. For one
        command, use ``p.DRAM(cmd, NOP(), NOP(), NOP())`` + ``p.SLEEP(N-1)``
        instead — that makes the 4-slot packing explicit. ``DRAMSEQ`` is for
        chaining two or more commands, or a single command followed by
        ``ALIGN()``.

        Example — chained PRE+ACT with per-op delays::

            p.DRAMSEQ(PRE("BAR", delay=11), ACT("BAR", "RAR", delay=11), ALIGN())
        """
        if not ops:
            raise ValueError("DRAMSEQ requires at least one timed DRAM operation.")

        sequence_items = tuple(
            self._normalize_dram_sequence_item(op, item_index=index)
            for index, op in enumerate(ops)
        )
        if in_trace_mode():
            return self._emit("DRAMSEQ", *sequence_items)

        self._ops.extend(self._expand_dram_sequence(sequence_items))
        return self

    def LABEL(self, name: str):
        """Place a branch-target label at the current instruction position.

        Labels must be unique within a program; ``BL``/``BEQ``/``JMP`` jump
        to a label by name.
        """
        if not isinstance(name, str):
            raise TypeError("LABEL expects a string label name.")
        return self._emit("LABEL", name)

    def BL(self, rs1, rs2, target: str):
        """Branch to ``target`` if ``rs1 < rs2`` (unsigned). Both paths resolve in 6 cycles."""
        return self._emit("BL", self._resolve_reg(rs1), self._resolve_reg(rs2), self._normalize_label(target))

    def BEQ(self, rs1, rs2, target: str):
        """Branch to ``target`` if ``rs1 == rs2``. Both paths resolve in 6 cycles."""
        return self._emit("BEQ", self._resolve_reg(rs1), self._resolve_reg(rs2), self._normalize_label(target))

    def JMP(self, target: str):
        """Unconditional jump to ``target``. 6 branch-resolution cycles."""
        return self._emit("JMP", self._normalize_label(target))

    JUMP = JMP

    def conclude(self) -> "FinalProgram":
        """Lower the accumulated builder ops to a :class:`FinalProgram`.

        Ready to submit via ``board.execute(program)`` or inspect via
        ``program.trace_dram_commands()``. During ``@program_template`` tracing,
        conclude returns the raw op list instead; that return is not
        user-visible, so the annotation pretends it's always a ``FinalProgram``.
        """
        ops = list(self._ops)
        if in_trace_mode():
            return cast("FinalProgram", ops)

        start = time.perf_counter()
        final_program = _core.lower(ops)
        record_lowering_stats(
            op_count=len(ops),
            lower_s=time.perf_counter() - start,
        )
        return final_program

    def _emit(self, opcode: str, *operands):
        self._ops.append((opcode, *operands))
        return self

    def _resolve_reg(self, register):
        if isinstance(register, str):
            return self._registers.resolve(register)
        return self._normalize_int(register)

    def _normalize_int(self, value):
        if isinstance(value, ScalarSentinel):
            return ScalarParamRef(value.name)
        if isinstance(value, ScalarParamRef):
            return value
        return _coerce_python_int(value, name="operand")

    def _normalize_label(self, value):
        if not isinstance(value, str):
            raise TypeError("Branch targets must be string labels.")
        return value

    def _normalize_dram_exact_op(self, value, *, slot_index: int):
        if not isinstance(value, _DRAMMiniOp):
            raise TypeError(
                f"DRAM slot {slot_index} expects a mini-op created by "
                "NOP()/PRE()/ACT()/RD()/WR()/REF()/SEL_CH()."
            )

        operands = value.operands
        opcode = value.opcode
        if opcode == "ALIGN":
            raise TypeError("ALIGN() is only valid as the final item of DRAMSEQ(...).")
        if value.delay is not None:
            raise TypeError(
                f"Timed DRAM op {opcode}(..., delay=...) is not valid inside DRAM(...). "
                "Use DRAMSEQ(...) for timed DRAM sequences."
            )
        if opcode == "NOP":
            return ("NOP",)
        if opcode == "PRE":
            return (
                "PRE",
                self._resolve_reg(operands[0]),
                self._normalize_int(operands[1]),
                self._normalize_int(operands[2]),
                self._normalize_int(operands[3]),
            )
        if opcode == "ACT":
            return (
                "ACT",
                self._resolve_reg(operands[0]),
                self._normalize_int(operands[1]),
                self._resolve_reg(operands[2]),
                self._normalize_int(operands[3]),
                self._normalize_int(operands[4]),
            )
        if opcode == "RD":
            return (
                "RD",
                self._resolve_reg(operands[0]),
                self._normalize_int(operands[1]),
                self._resolve_reg(operands[2]),
                self._normalize_int(operands[3]),
                self._normalize_int(operands[4]),
                self._normalize_int(operands[5]),
            )
        if opcode == "WR":
            return (
                "WR",
                self._resolve_reg(operands[0]),
                self._normalize_int(operands[1]),
                self._resolve_reg(operands[2]),
                self._normalize_int(operands[3]),
                self._normalize_int(operands[4]),
                self._normalize_int(operands[5]),
            )
        if opcode == "REF":
            return ("REF", self._normalize_int(operands[0]))
        if opcode == "SEL_CH":
            return (
                "SEL_CH",
                self._normalize_int(operands[0]),
                self._normalize_int(operands[1]),
            )
        raise TypeError(f"Unsupported DRAM mini-op {opcode!r}.")

    def _normalize_dram_sequence_item(self, value, *, item_index: int):
        if not isinstance(value, _DRAMMiniOp):
            raise TypeError(
                f"DRAMSEQ item {item_index} expects a timed DRAM mini-op or ALIGN()."
            )

        if value.opcode == "ALIGN":
            return ("ALIGN",)
        if value.opcode == "NOP":
            raise TypeError("NOP() is only valid inside DRAM(...), not DRAMSEQ(...).")
        if value.delay is None:
            raise TypeError(
                f"DRAMSEQ item {item_index} must spell out delay=... explicitly."
            )

        delay = self._normalize_int(value.delay)
        if not isinstance(delay, ScalarParamRef) and delay < 1:
            raise ValueError("DRAM sequence delay values must be at least one slot.")

        exact = self._normalize_dram_exact_op(
            _DRAMMiniOp(value.opcode, value.operands),
            slot_index=item_index,
        )
        return (*exact, delay)

    def _expand_dram_sequence(self, sequence_items: tuple[tuple[Any, ...], ...]):
        if not sequence_items:
            raise ValueError("DRAMSEQ requires at least one timed DRAM operation.")

        align_requested = sequence_items[-1][0] == "ALIGN"
        body = sequence_items[:-1] if align_requested else sequence_items
        if not body:
            raise ValueError("DRAMSEQ requires at least one timed DRAM operation before ALIGN().")

        for item_index, item in enumerate(body):
            if item[0] == "ALIGN":
                raise ValueError("ALIGN() is only valid as the final item of DRAMSEQ(...).")

        total_slots = 0
        expanded: list[tuple[Any, ...]] = []
        for item in body:
            delay = item[-1]
            if isinstance(delay, ScalarParamRef):
                raise TemplateCompileError(
                    "Symbolic delay= values inside DRAMSEQ(...) require template trace mode."
                )
            total_slots += delay
            expanded.append(("DRAM_DELAY", item[:-1], delay))

        remainder = total_slots % 4
        if align_requested:
            if remainder == 0:
                raise ValueError(
                    "ALIGN() is invalid because this DRAMSEQ(...) already ends on a 4-slot boundary."
                )
            expanded.append(("DRAM_ALIGN_PAD", 4 - remainder))
            return expanded

        if remainder != 0:
            raise ValueError(
                "DRAMSEQ(...) would end with implicit tail padding. Either make the last "
                "delay=... land exactly on the 4-slot boundary or add final ALIGN()."
            )

        return expanded


__all__ = [
    "ProgramBuilder",
    "TemplateCompileError",
]
