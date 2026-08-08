#!/usr/bin/env python3
"""Regression checks for the explicit Python target API."""

from __future__ import annotations

import importlib

import drambender.builtin_programs as builtin_programs
import drambender.api.board as board_api
from drambender.api import (
    BoardType,
    DDR4,
    DDR4Target,
    HBM2Target,
    HostInterface,
    ProgramBuilder,
    open_board,
    program_template,
)
from drambender.api.program.instructions import ACT, NOP, PRE, RD, SEL_CH, WR


def _assert(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def _tiny_program(*, target):
    p = ProgramBuilder(target=target)
    p.LI(target.physical_bank(2), "BAR")
    p.LI(7, "RAR")
    p.LI(0, "CAR")
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(3)
    p.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
    p.SLEEP(1)
    p.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
    return p.conclude()


def _dram_events(program, command: str):
    return [
        event
        for event in program.trace_dram_commands().events
        if event.command == command
    ]


def _assert_row_events(program, *, bank: int, rank: int, commands: tuple[str, ...]) -> None:
    for event in program.trace_dram_commands().events:
        if event.command in commands:
            _assert(event.bank == bank, f"{event.command} bank {event.bank}, expected {bank}")
            _assert(event.rank == rank, f"{event.command} rank {event.rank}, expected {rank}")


def test_builder_requires_explicit_target() -> None:
    for call in (lambda: ProgramBuilder(), lambda: ProgramBuilder(target=None)):
        try:
            call()
        except TypeError as exc:
            _assert("target=DDR4Target" in str(exc), f"unclear target error: {exc}")
        else:
            raise AssertionError("ProgramBuilder without an explicit target should fail")


def test_explicit_ddr4_target_builds() -> None:
    program = _tiny_program(target=DDR4Target())
    _assert(len(program.instructions()) > 0, "explicit DDR4 target produced no instructions")
    _assert_row_events(program, bank=2, rank=0, commands=("PRE", "ACT", "WR", "RD"))


def test_target_rank_default_and_explicit_override() -> None:
    p = ProgramBuilder(target=DDR4Target(rank=1))
    p.LI(0, "BAR")
    p.LI(0, "RAR")
    p.LI(0, "CAR")
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.DRAM(RD("BAR", "CAR", rank=0), NOP(), NOP(), NOP())
    events = p.conclude().trace_dram_commands().events

    pre_event = next(event for event in events if event.command == "PRE")
    act_event = next(event for event in events if event.command == "ACT")
    rd_event = next(event for event in events if event.command == "RD")
    _assert(pre_event.rank == 1, f"PRE used rank {pre_event.rank}, expected 1")
    _assert(act_event.rank == 1, f"ACT used rank {act_event.rank}, expected 1")
    _assert(rd_event.rank == 0, f"explicit RD rank override failed: {rd_event.rank}")


def test_hbm2_target_selects_channel_bank_and_rank() -> None:
    target = HBM2Target(channel=3, pseudo_channel=1, sid=1)
    p = ProgramBuilder(target=target)
    p.LI(target.physical_bank(2), "BAR")
    p.LI(9, "RAR")
    p.LI(0, "CAR")
    p.DRAM(SEL_CH(target), NOP(), NOP(), NOP())
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.DRAM(WR("BAR", "CAR"), NOP(), NOP(), NOP())
    p.DRAM(RD("BAR", "CAR"), NOP(), NOP(), NOP())
    program = p.conclude()

    sel_event = _dram_events(program, "SEL_CH")[0]
    _assert(sel_event.channel == 3, f"SEL_CH channel {sel_event.channel}, expected 3")
    _assert(
        sel_event.pseudo_channel == 1,
        f"SEL_CH pseudo-channel {sel_event.pseudo_channel}, expected 1",
    )
    _assert_row_events(program, bank=18, rank=1, commands=("PRE", "ACT", "WR", "RD"))


def test_legacy_sel_ch_and_ddr4_rejection() -> None:
    legacy = SEL_CH(4, pseudo_channel=1)
    _assert(legacy.operands == (4, 1), f"legacy SEL_CH operands are {legacy.operands}")
    try:
        SEL_CH(DDR4Target())
    except TypeError as exc:
        _assert("DDR4Target" in str(exc), f"unclear DDR4 SEL_CH error: {exc}")
    else:
        raise AssertionError("SEL_CH(DDR4Target()) should fail")


def test_open_board_accepts_targets_and_board_type() -> None:
    calls = []
    original_native_open_board = board_api._native_open_board

    def fake_native_open_board(board_type, pci_bdf, xdma_channel, host_interface):
        calls.append((board_type, pci_bdf, xdma_channel, host_interface))
        return object()

    board_api._native_open_board = fake_native_open_board
    try:
        open_board(DDR4Target(), "0000:01:00.0", 0, HostInterface.XDMA)
        open_board(HBM2Target(), "0000:81:00.0", 1, HostInterface.XDMA)
        open_board(BoardType.DDR4, "0001:01:00.0", 2, HostInterface.XDMA)
    finally:
        board_api._native_open_board = original_native_open_board

    _assert(
        calls == [
            (BoardType.DDR4, "0000:01:00.0", 0, HostInterface.XDMA),
            (BoardType.HBM2, "0000:81:00.0", 1, HostInterface.XDMA),
            (BoardType.DDR4, "0001:01:00.0", 2, HostInterface.XDMA),
        ],
        f"unexpected open_board dispatch calls: {calls}",
    )

    try:
        open_board(object(), "0000:01:00.0", 0)
    except TypeError as exc:
        _assert("DDR4Target" in str(exc), f"unclear open_board type error: {exc}")
    else:
        raise AssertionError("open_board(object(), ...) should fail")


def test_native_board_selector_requires_complete_bdf() -> None:
    try:
        DDR4(0, 0)
    except TypeError:
        pass
    else:
        raise AssertionError("integer probe-order selector should not be accepted")

    try:
        DDR4("01:00.0")
    except ValueError as exc:
        _assert("dddd:bb:ss.f" in str(exc), f"unclear invalid-BDF error: {exc}")
    else:
        raise AssertionError("domain-less PCI address should not be accepted")


def test_builtins_are_configured_only() -> None:
    _assert(
        not hasattr(builtin_programs, "write_row"),
        "write_row should not be exported directly from drambender.builtin_programs",
    )
    direct_write_row = importlib.import_module("drambender.builtin_programs.write_row").write_row
    try:
        direct_write_row(0, 0, (0xDEADBEEF,) * 16)
    except TypeError as exc:
        _assert("configure(target=...)" in str(exc), f"unclear direct builtin error: {exc}")
    else:
        raise AssertionError("direct builtin write_row call should fail")


def test_configured_ddr4_builtins() -> None:
    target = DDR4Target()
    programs = builtin_programs.configure(target=target)
    pattern = (0xDEADBEEF,) * target.words_per_cacheline
    write_program = programs.write_row(2, 7, pattern)
    read_program = programs.read_row(2, 7)
    hammer_program = programs.single_sided_rowhammer(2, 8, 4)
    double_program = programs.double_sided_rowhammer(2, 8, 10, 4)

    _assert(len(_dram_events(write_program, "SEL_CH")) == 0, "DDR4 write emitted SEL_CH")
    _assert(len(_dram_events(write_program, "WR")) == target.columns_per_row, "DDR4 write row width mismatch")
    _assert(len(_dram_events(read_program, "RD")) == target.columns_per_row, "DDR4 read row width mismatch")
    _assert_row_events(write_program, bank=2, rank=0, commands=("PRE", "ACT", "WR"))
    _assert_row_events(read_program, bank=2, rank=0, commands=("PRE", "ACT", "RD"))
    _assert_row_events(hammer_program, bank=2, rank=0, commands=("PRE", "ACT"))
    _assert_row_events(double_program, bank=2, rank=0, commands=("PRE", "ACT"))


def test_configured_hbm2_builtins() -> None:
    target = HBM2Target(channel=3, pseudo_channel=1, sid=1)
    programs = builtin_programs.configure(target=target)
    pattern = (0xDEADBEEF,) * target.words_per_cacheline
    write_program = programs.write_row(2, 7, pattern)
    read_program = programs.read_row(2, 7)
    hammer_program = programs.single_sided_rowhammer(2, 8, 4)
    double_program = programs.double_sided_rowhammer(2, 8, 10, 4)

    for program in (write_program, read_program, hammer_program, double_program):
        sel_events = _dram_events(program, "SEL_CH")
        _assert(len(sel_events) == 1, "HBM2 builtin should emit one SEL_CH")
        _assert(sel_events[0].channel == 3, f"HBM2 SEL_CH channel {sel_events[0].channel}")
        _assert(sel_events[0].pseudo_channel == 1, f"HBM2 SEL_CH pch {sel_events[0].pseudo_channel}")
        _assert_row_events(program, bank=18, rank=1, commands=("PRE", "ACT", "WR", "RD"))

    _assert(len(_dram_events(write_program, "WR")) == target.columns_per_row, "HBM2 write row width mismatch")
    _assert(len(_dram_events(read_program, "RD")) == target.columns_per_row, "HBM2 read row width mismatch")


@program_template
def _jit_hbm2_physical_bank_template(bank: int):
    target = HBM2Target(channel=0, pseudo_channel=1, sid=1)
    p = ProgramBuilder(target=target)
    p.LI(target.physical_bank(bank), "BAR")
    p.LI(0, "RAR")
    p.DRAM(SEL_CH(target), NOP(), NOP(), NOP())
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    return p.conclude()


def test_jit_physical_bank_affine_scalar() -> None:
    program = _jit_hbm2_physical_bank_template(5)
    pre_event = _dram_events(program, "PRE")[0]
    _assert(pre_event.bank == 21, f"JIT physical bank {pre_event.bank}, expected 21")
    _assert(pre_event.rank == 1, f"JIT target rank {pre_event.rank}, expected 1")


def main() -> int:
    tests = (
        test_builder_requires_explicit_target,
        test_explicit_ddr4_target_builds,
        test_target_rank_default_and_explicit_override,
        test_hbm2_target_selects_channel_bank_and_rank,
        test_legacy_sel_ch_and_ddr4_rejection,
        test_open_board_accepts_targets_and_board_type,
        test_native_board_selector_requires_complete_bdf,
        test_builtins_are_configured_only,
        test_configured_ddr4_builtins,
        test_configured_hbm2_builtins,
        test_jit_physical_bank_affine_scalar,
    )
    for test in tests:
        test()
        print(f"PASS: {test.__name__}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
