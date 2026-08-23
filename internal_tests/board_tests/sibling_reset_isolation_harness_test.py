#!/usr/bin/env python3
"""Offline regression checks for sibling_reset_isolation_test.py."""

from __future__ import annotations

import argparse
import signal
import subprocess
import unittest
from unittest import mock

from internal_tests.board_tests import sibling_reset_isolation_test as harness


class FakeInput:
    def __init__(self) -> None:
        self.data = ""
        self.closed = False

    def write(self, text: str) -> int:
        self.data += text
        return len(text)

    def flush(self) -> None:
        pass

    def close(self) -> None:
        self.closed = True


class FakeProcess:
    next_pid = 5000

    def __init__(self, with_input: bool) -> None:
        self.pid = FakeProcess.next_pid
        FakeProcess.next_pid += 1
        self.returncode: int | None = None
        self.stdin = FakeInput() if with_input else None
        self.signals: list[int] = []
        self.killed = False

    def poll(self) -> int | None:
        return self.returncode

    def send_signal(self, sig: int) -> None:
        self.signals.append(sig)

    def wait(self, timeout: float | None = None) -> int:
        self.returncode = 130
        return self.returncode

    def kill(self) -> None:
        self.killed = True
        self.returncode = -signal.SIGKILL


class SiblingResetIsolationHarnessTest(unittest.TestCase):
    def setUp(self) -> None:
        self.case = harness.make_cases(["0000:01:00.0"], (0,))[0]

    def test_bdf_parser_and_distinct_direction_tags(self) -> None:
        self.assertEqual(harness.parse_bdf("0000:0A:1F.7"), "0000:0a:1f.7")
        for invalid in ("01:00.0", "0000:01:20.0", "0000:gg:00.0"):
            with self.assertRaises(argparse.ArgumentTypeError):
                harness.parse_bdf(invalid)

        cases = harness.make_cases(["0000:01:00.0"], (0, 1))
        self.assertNotEqual(cases[0].active_sha256, cases[1].active_sha256)
        self.assertNotEqual(cases[0].active_sha256, cases[0].reset_sha256)

    def test_delayed_program_has_no_dram_command_before_delay(self) -> None:
        delay_cycles = 10_000
        program = harness.build_delayed_write_read(
            self.case.active_bank,
            self.case.active_row,
            self.case.active_tag,
            delay_cycles,
        )
        result = harness.validate_program(program, delay_cycles)
        self.assertEqual(result["reads"], harness.CACHELINES_PER_ROW)
        self.assertEqual(result["writes"], harness.CACHELINES_PER_ROW)
        self.assertGreaterEqual(
            result["first_dram_ns"], delay_cycles * harness.FABRIC_CYCLE_NS
        )

    def test_overlap_requires_reset_inside_active_session(self) -> None:
        overlap = harness.validate_overlap(
            {"execute_sent_monotonic_ns": 100},
            {
                "reset_started_monotonic_ns": 150,
                "reset_completed_monotonic_ns": 250,
            },
            {"payload_complete_monotonic_ns": 400},
        )
        self.assertGreater(overlap["payload_completed_after_reset_seconds"], 0)

        with self.assertRaisesRegex(RuntimeError, "not wholly contained"):
            harness.validate_overlap(
                {"execute_sent_monotonic_ns": 100},
                {
                    "reset_started_monotonic_ns": 150,
                    "reset_completed_monotonic_ns": 450,
                },
                {"payload_complete_monotonic_ns": 400},
            )

    def test_run_case_checks_hashes_and_timing(self) -> None:
        resetter = FakeProcess(with_input=True)
        active = FakeProcess(with_input=False)
        ready = {"event": "ready", "ready_monotonic_ns": 50}
        armed = {"event": "armed", "execute_sent_monotonic_ns": 100}
        reset_pass = {
            "event": "pass",
            "canary_sha256": self.case.reset_sha256,
            "reset_started_monotonic_ns": 200,
            "reset_completed_monotonic_ns": 300,
        }
        active_pass = {
            "event": "pass",
            "payload_sha256": self.case.active_sha256,
            "payload_complete_monotonic_ns": 500,
        }
        with (
            mock.patch.object(
                harness, "start_child", side_effect=[resetter, active]
            ),
            mock.patch.object(harness, "wait_for_event", side_effect=[ready, armed]),
            mock.patch.object(harness, "send_command") as send_command,
            mock.patch.object(
                harness,
                "finish_child",
                side_effect=[(0, [reset_pass], ""), (0, [active_pass], "")],
            ),
            mock.patch.object(harness.time, "sleep"),
        ):
            record = harness.run_case(self.case, 1000, 1.0, 2.0, 0.0)

        self.assertEqual(record["status"], "pass")
        send_command.assert_called_once_with(resetter, "reset")
        self.assertEqual(record["overlap"]["reset_elapsed_seconds"], 1e-7)

    def test_cleanup_requests_recoverable_shutdown(self) -> None:
        resetter = FakeProcess(with_input=True)
        reset_input = resetter.stdin
        active = FakeProcess(with_input=False)
        errors = harness.cleanup_children(
            [("resetter", resetter), ("active", active)], timeout=0.1
        )
        self.assertEqual(errors, [])
        assert reset_input is not None
        self.assertEqual(reset_input.data, "abort\n")
        self.assertTrue(reset_input.closed)
        self.assertEqual(active.signals, [signal.SIGINT])
        self.assertFalse(resetter.killed)
        self.assertFalse(active.killed)

    def test_cleanup_force_kills_stuck_child(self) -> None:
        active = FakeProcess(with_input=False)

        def timeout_wait(timeout: float | None = None) -> int:
            if not active.killed:
                raise subprocess.TimeoutExpired("fake-active", timeout)
            active.returncode = -signal.SIGKILL
            return active.returncode

        active.wait = timeout_wait  # type: ignore[method-assign]
        errors = harness.cleanup_children([("active", active)], timeout=0.01)
        self.assertEqual(errors, [])
        self.assertTrue(active.killed)

    def test_finish_timeout_defers_to_recoverable_cleanup(self) -> None:
        process = mock.Mock()
        process.communicate.side_effect = subprocess.TimeoutExpired(
            "fake-child", 0.25, output="partial", stderr="diagnostic"
        )
        with self.assertRaisesRegex(RuntimeError, "partial_stdout"):
            harness.finish_child(process, 0.25)
        process.kill.assert_not_called()


if __name__ == "__main__":
    unittest.main()
