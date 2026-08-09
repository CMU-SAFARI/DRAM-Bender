#!/usr/bin/env python3
"""Offline regression checks for the multi-endpoint interrupt harness."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

from tests.board_tests import multi_endpoint_interrupt_test as harness


ENDPOINT = ("0000:01:00.0", 0)


class FakeChild:
    def __init__(self, *, wait_times_out: bool = False) -> None:
        self.pid = 4242
        self.returncode: int | None = None
        self.killed = False
        self.wait_times_out = wait_times_out

    def poll(self) -> int | None:
        return self.returncode

    def kill(self) -> None:
        self.killed = True

    def wait(self, timeout: float | None = None) -> int:
        if self.wait_times_out:
            raise subprocess.TimeoutExpired("fake-child", timeout)
        self.returncode = -9
        return self.returncode


class InterruptHarnessTest(unittest.TestCase):
    def test_operator_keyboard_interrupt_kills_child_and_propagates(self) -> None:
        child = FakeChild()
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "interrupt.jsonl"
            with (
                mock.patch.object(harness, "start_child", return_value=child),
                mock.patch.object(harness, "wait_for_armed", side_effect=KeyboardInterrupt),
                mock.patch.object(Path, "read_text", return_value="TEST-SRCVERSION"),
            ):
                with self.assertRaises(KeyboardInterrupt):
                    harness.run_parent([ENDPOINT], output)

            self.assertTrue(child.killed)
            records = [json.loads(line) for line in output.read_text().splitlines()]
            self.assertEqual([record["type"] for record in records], ["environment"])

    def test_cleanup_timeout_is_logged_without_masking_failure(self) -> None:
        child = FakeChild(wait_times_out=True)
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "interrupt.jsonl"
            with (
                mock.patch.object(harness, "start_child", return_value=child),
                mock.patch.object(
                    harness,
                    "wait_for_armed",
                    side_effect=RuntimeError("synthetic arm failure"),
                ),
                mock.patch.object(Path, "read_text", return_value="TEST-SRCVERSION"),
            ):
                status = harness.run_parent([ENDPOINT], output)

            self.assertEqual(status, 1)
            self.assertTrue(child.killed)
            records = [json.loads(line) for line in output.read_text().splitlines()]
            case = records[1]
            self.assertEqual(case["status"], "fail")
            self.assertIn("synthetic arm failure", case["error"])
            self.assertIn("did not exit within 2.0s", case["cleanup_errors"][0])
            self.assertEqual(records[2], {"type": "summary", "cases": 1, "failures": 1})


if __name__ == "__main__":
    unittest.main()
