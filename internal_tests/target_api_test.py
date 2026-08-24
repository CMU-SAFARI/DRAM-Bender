#!/usr/bin/env python3
"""Regression checks for the explicit Python target API."""

from __future__ import annotations

import argparse
import importlib
import importlib.util
from pathlib import Path
import sys


def _load_built_extension(extension: Path | None) -> None:
    """Make this test use the extension built by its CMake test target."""
    if extension is None:
        return

    package_dir = Path(__file__).resolve().parents[1] / "python" / "drambender"
    package_spec = importlib.util.spec_from_file_location(
        "drambender",
        package_dir / "__init__.py",
        submodule_search_locations=[str(package_dir)],
    )
    if package_spec is None or package_spec.loader is None:
        raise RuntimeError(f"cannot load Python package from {package_dir}")

    package = importlib.util.module_from_spec(package_spec)
    sys.modules["drambender"] = package

    core_spec = importlib.util.spec_from_file_location("drambender._core", extension)
    if core_spec is None or core_spec.loader is None:
        raise RuntimeError(f"cannot load extension: {extension}")
    core = importlib.util.module_from_spec(core_spec)
    sys.modules["drambender._core"] = core
    core_spec.loader.exec_module(core)
    package_spec.loader.exec_module(package)


_argument_parser = argparse.ArgumentParser()
_argument_parser.add_argument("--extension", type=Path)
_arguments = _argument_parser.parse_args()
_load_built_extension(_arguments.extension)

import drambender.builtin_programs as builtin_programs
import drambender._core as native_core
import drambender.api.board as board_api
from drambender.api import (
    BoardConfig,
    BoardType,
    DDR4,
    DDR4Target,
    HBM2Target,
    HBM2U50Target,
    HBM2U55CTarget,
    HostInterface,
    MemoryType,
    ProgramBuilder,
    board_configs,
    get_board_config,
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


def test_board_configs_are_bound_immutable_defaults() -> None:
    expected = (
        (
            board_configs.U200,
            "U200",
            BoardType.U200,
            MemoryType.DDR4,
            32768,
            1.5,
            0,
            0,
            0,
            False,
            False,
        ),
        (
            board_configs.U50,
            "U50",
            BoardType.U50,
            MemoryType.HBM2,
            32768,
            5 / 3,
            16,
            2,
            1,
            False,
            False,
        ),
        (
            board_configs.U55C,
            "U55C",
            BoardType.U55C,
            MemoryType.HBM2,
            131072,
            5 / 3,
            16,
            2,
            2,
            True,
            True,
        ),
    )

    for (
        config,
        name,
        board_type,
        memory_type,
        instruction_capacity,
        command_slot_ns,
        hbm_channel_count,
        hbm_pseudo_channel_count,
        hbm_sid_count,
        broadcast_supported,
        power_telemetry_supported,
    ) in expected:
        _assert(isinstance(config, BoardConfig), f"{name} is not a BoardConfig")
        _assert(config.name == name, f"unexpected config name {config.name}")
        _assert(config.board_type == board_type, f"{name} board type mismatch")
        _assert(config.memory_type == memory_type, f"{name} memory type mismatch")
        _assert(
            config.instruction_capacity == instruction_capacity,
            f"{name} instruction capacity mismatch",
        )
        _assert(
            config.dram_command_slot_ns == command_slot_ns,
            f"{name} slot duration mismatch",
        )
        _assert(
            config.dram_slots_per_fabric_cycle == 4,
            f"{name} DRAM slot count mismatch",
        )
        _assert(
            config.readback_buffer_capacity == 1024,
            f"{name} readback capacity mismatch",
        )
        _assert(
            config.hbm_channel_count == hbm_channel_count,
            f"{name} HBM channel count mismatch",
        )
        _assert(
            config.hbm_pseudo_channel_count == hbm_pseudo_channel_count,
            f"{name} HBM pseudo-channel count mismatch",
        )
        _assert(
            config.hbm_sid_count == hbm_sid_count,
            f"{name} HBM SID count mismatch",
        )
        _assert(
            config.broadcast_supported is broadcast_supported,
            f"{name} broadcast mismatch",
        )
        _assert(
            config.power_telemetry_supported is power_telemetry_supported,
            f"{name} power telemetry mismatch",
        )
        resolved = get_board_config(board_type)
        _assert(resolved.board_type == config.board_type, f"{name} registry lookup mismatch")

    try:
        board_configs.U200.instruction_capacity = 1
    except AttributeError:
        pass
    else:
        raise AssertionError("BoardConfig properties must be immutable")

    board = native_core._MockBoard()
    try:
        _assert(
            board.board_config.board_type == BoardType.U200,
            "live board should expose the config used by its C++ implementation",
        )
    finally:
        board.close()


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
    target = HBM2U55CTarget(channel=3, pseudo_channel=1, sid=1)
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


def test_explicit_sel_ch_and_ddr4_rejection() -> None:
    explicit = SEL_CH(4, pseudo_channel=1)
    _assert(
        explicit.operands == (4, 1),
        f"explicit SEL_CH operands are {explicit.operands}",
    )
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
        open_board(HBM2U55CTarget(), "0000:81:00.0", 1, HostInterface.XDMA)
        open_board(BoardType.U200, "0001:01:00.0", 2, HostInterface.XDMA)
        open_board(board_configs.U50, "0000:82:00.0", 3, HostInterface.XDMA)
    finally:
        board_api._native_open_board = original_native_open_board

    _assert(
        calls == [
            (BoardType.U200, "0000:01:00.0", 0, HostInterface.XDMA),
            (BoardType.U55C, "0000:81:00.0", 1, HostInterface.XDMA),
            (BoardType.U200, "0001:01:00.0", 2, HostInterface.XDMA),
            (BoardType.U50, "0000:82:00.0", 3, HostInterface.XDMA),
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
    target = HBM2U55CTarget(channel=3, pseudo_channel=1, sid=1)
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
    target = HBM2U55CTarget(channel=0, pseudo_channel=1, sid=1)
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


def test_hbm2_board_variant_capabilities() -> None:
    ddr4 = DDR4Target()
    _assert(
        ddr4.board_config is board_configs.U200,
        "DDR4 target should use U200 config",
    )
    _assert(
        ddr4.instruction_capacity == ddr4.board_config.instruction_capacity,
        "DDR4 instruction capacity must come from its board config",
    )

    u50 = HBM2U50Target(channel=2, sid=0)
    _assert(
        u50.board_config is board_configs.U50,
        "U50 target should use U50 config",
    )
    _assert(
        u50.num_sids == u50.board_config.hbm_sid_count,
        "U50 SID count must come from config",
    )
    _assert(
        u50.broadcast_supported is u50.board_config.broadcast_supported,
        "U50 broadcast capability must come from config",
    )
    _assert(
        u50.instruction_capacity == u50.board_config.instruction_capacity,
        "U50 instruction capacity must come from config",
    )

    try:
        HBM2U50Target(sid=1)
    except ValueError as exc:
        _assert("sid" in str(exc), f"U50 sid=1 should be rejected: {exc}")
    else:
        raise AssertionError("HBM2U50Target(sid=1) should fail")

    try:
        HBM2U50Target(channel=u50.board_config.hbm_channel_count)
    except ValueError as exc:
        _assert(
            "channel" in str(exc),
            f"U50 channel bound should come from config: {exc}",
        )
    else:
        raise AssertionError("HBM2U50Target accepted a channel beyond its board config")

    try:
        HBM2U50Target(pseudo_channel=u50.board_config.hbm_pseudo_channel_count)
    except ValueError as exc:
        _assert(
            "pseudo_channel" in str(exc),
            f"U50 pseudo-channel bound should come from config: {exc}",
        )
    else:
        raise AssertionError("HBM2U50Target accepted a pseudo-channel beyond its board config")

    u55 = HBM2U55CTarget(channel=2, sid=1)
    _assert(
        u55.board_config is board_configs.U55C,
        "U55C target should use U55C config",
    )
    _assert(
        u55.num_sids == u55.board_config.hbm_sid_count,
        "U55C SID count must come from config",
    )
    _assert(
        u55.broadcast_supported is u55.board_config.broadcast_supported,
        "U55C broadcast capability must come from config",
    )
    _assert(
        u55.power_telemetry_supported is u55.board_config.power_telemetry_supported,
        "U55C power telemetry capability must come from config",
    )
    _assert(
        u55.instruction_capacity == u55.board_config.instruction_capacity,
        "U55C instruction capacity must come from config",
    )

    try:
        HBM2Target()
    except TypeError as exc:
        _assert("abstract" in str(exc), f"HBM2Target should be abstract: {exc}")
    else:
        raise AssertionError("HBM2Target() should fail")


def test_vm_default_latency_follows_target() -> None:
    hbm2_slot_ns = 5 / 3

    ddr4_program = _tiny_program(target=DDR4Target())
    _assert(
        ddr4_program.default_dram_inst_latency == 1.5,
        f"DDR4 default latency {ddr4_program.default_dram_inst_latency}, expected 1.5",
    )

    u50_program = _tiny_program(target=HBM2U50Target())
    _assert(
        u50_program.default_dram_inst_latency == hbm2_slot_ns,
        f"U50 default latency {u50_program.default_dram_inst_latency}, expected 5/3",
    )

    # The JIT path must carry the target latency through compiled plugins.
    jit_program = _jit_hbm2_physical_bank_template(5)
    _assert(
        jit_program.default_dram_inst_latency == hbm2_slot_ns,
        f"JIT default latency {jit_program.default_dram_inst_latency}, expected 5/3",
    )

    # The traced timestamps scale with the default, and an explicit value
    # still overrides it.
    default_trace = u50_program.trace_dram_commands()
    override_trace = u50_program.trace_dram_commands(dram_inst_latency=1.5)
    default_last = default_trace.events[-1].time_ns
    override_last = override_trace.events[-1].time_ns
    _assert(
        abs(default_last - override_last * hbm2_slot_ns / 1.5) < 1e-9,
        f"trace timestamps did not scale: {default_last} vs {override_last}",
    )


def main() -> int:
    tests = (
        test_board_configs_are_bound_immutable_defaults,
        test_builder_requires_explicit_target,
        test_explicit_ddr4_target_builds,
        test_target_rank_default_and_explicit_override,
        test_hbm2_target_selects_channel_bank_and_rank,
        test_hbm2_board_variant_capabilities,
        test_explicit_sel_ch_and_ddr4_rejection,
        test_open_board_accepts_targets_and_board_type,
        test_native_board_selector_requires_complete_bdf,
        test_builtins_are_configured_only,
        test_configured_ddr4_builtins,
        test_configured_hbm2_builtins,
        test_jit_physical_bank_affine_scalar,
        test_vm_default_latency_follows_target,
    )
    for test in tests:
        test()
        print(f"PASS: {test.__name__}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
