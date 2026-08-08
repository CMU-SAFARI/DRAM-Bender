"""Signal/recovery checks for the Python board bindings (no FPGA required)."""

from __future__ import annotations

import argparse
import importlib.util
import os
from pathlib import Path
import signal
import sys
import threading
import types
from typing import Any


def load_core(extension: Path | None) -> Any:
    if extension is None:
        from drambender import _core

        return _core

    # Load the just-built extension directly. This avoids accidentally testing
    # another editable checkout installed in the same development environment.
    package = types.ModuleType("drambender")
    package.__path__ = []  # type: ignore[attr-defined]
    sys.modules["drambender"] = package
    spec = importlib.util.spec_from_file_location("drambender._core", extension)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load extension: {extension}")
    module = importlib.util.module_from_spec(spec)
    sys.modules["drambender._core"] = module
    spec.loader.exec_module(module)
    return module


_core: Any


def send_sigint_after(delay_seconds: float = 0.1) -> threading.Timer:
    timer = threading.Timer(delay_seconds, os.kill, args=(os.getpid(), signal.SIGINT))
    timer.start()
    return timer


def assert_reusable(board: _core._MockBoard) -> None:
    board.queue_receive_words([0x12345678])
    observed = bytearray(4)
    assert board.receive_into(observed) == len(observed)
    assert int.from_bytes(observed, byteorder=sys.byteorder) == 0x12345678


def test_ctrl_c_during_synchronize() -> None:
    board = _core._MockBoard(5_000)
    board.start_blocked_receive()
    timer = send_sigint_after()
    try:
        board.synchronize()
    except KeyboardInterrupt:
        pass
    else:
        raise AssertionError("synchronize() ignored SIGINT")
    finally:
        timer.join()

    assert board.drain_count == 1
    assert not board.is_closed
    assert_reusable(board)


def test_ctrl_c_during_receive_into() -> None:
    board = _core._MockBoard(5_000)
    board.start_blocked_receive()
    observed = bytearray(4)
    timer = send_sigint_after()
    try:
        board.receive_into(observed)
    except KeyboardInterrupt:
        pass
    else:
        raise AssertionError("receive_into() ignored SIGINT")
    finally:
        timer.join()

    assert board.drain_count == 1
    assert not board.is_closed
    assert_reusable(board)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--extension", type=Path)
    args = parser.parse_args()
    _core = load_core(args.extension)
    test_ctrl_c_during_synchronize()
    test_ctrl_c_during_receive_into()
    print("python interruption recovery: PASS")
