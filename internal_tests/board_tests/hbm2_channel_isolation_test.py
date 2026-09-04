#!/usr/bin/env python3
"""HBM2 channel isolation test.

Asserts that HBM channels address distinct physical storage: a write to one
channel must not disturb the same (bank, row, column) on any other channel.

A single write-write-read sequence cannot establish that, so this runs controls
before the assertion:

  Control 1  Same-channel round trip. Write a pattern to the reference channel
             and read it back. If this fails, nothing else in the run means
             anything.

  Control 2  Row decoding within one channel. Write two patterns to two
             adjacent rows of the reference channel and read both back. This
             separates "the channel bits are ignored" from "the address is
             ignored".

  Assertion  Both write orders. Write A then B and read both channels, then
             write B then A and read both. Aliasing is order-dependent -- the
             second write must win in both orders -- so running one order
             cannot distinguish aliasing from a read that never reached DRAM.

Every read is verified across the whole row rather than at a single word, so a
partially written or mixed row is reported instead of being reduced to one
value.

Leftover FPGA state is pinned before the assertion: readback discarding off,
auto-refresh off, and -- decisive for this test -- the command broadcast mask
cleared. A stale broadcast mask fans one command out to several channels and
reproduces the aliasing signature exactly.

This regressed once: a bitstream in which `decode_stage.v` never saw the
`HBM_BENDER` define decoded SEL_CH as ZQ, dropped the channel field, and
collapsed all 16 channels onto channel 0. Bank, row, SID, and pseudo-channel
decoding were unaffected, so a read/write test alone did not catch it.

Exit status: 0 all tested pairs isolated, 1 aliasing or a failed control,
2 invalid arguments.
"""

import argparse
import sys

import numpy as np

import drambender
from drambender.api import (
    HBM2,
    HBM2Target,
    HBM2U50,
    HBM2U50Target,
    HBM2U55C,
    HBM2U55CTarget,
)

BYTES_PER_HBM_COLUMN_PAIR = 64
BYTES_PER_PSEUDO_CHANNEL_CHUNK = 32

PATTERN_A = 0xAAAAAAAA
PATTERN_B = 0xBBBBBBBB
PATTERN_CONTROL_0 = 0x5A5A5A5A
PATTERN_CONTROL_1 = 0xA5A5A5A5

# U55C and U50 both carry a 14-bit row address (ROW_ADDR_WIDTH in the project
# headers). Control 2 uses row + 1, so the last row is not a valid selection.
MAX_ROW_ADDRESS = (1 << 14) - 1

PATTERN_NAMES = {
    PATTERN_A: "0xAAAAAAAA",
    PATTERN_B: "0xBBBBBBBB",
    PATTERN_CONTROL_0: "0x5A5A5A5A",
    PATTERN_CONTROL_1: "0xA5A5A5A5",
}


class ControlFailure(Exception):
    """A control did not hold, so the assertion cannot be interpreted."""


def name_pattern(value: int) -> str:
    return PATTERN_NAMES.get(value, f"0x{value:08X}")


def describe(words: np.ndarray) -> str:
    """One-line summary of a row read, naming the known patterns."""
    values, counts = np.unique(words, return_counts=True)
    if values.size == 1:
        return f"{name_pattern(int(values[0]))} (all {words.size} words)"
    order = np.argsort(counts)[::-1]
    parts = [f"{name_pattern(int(values[i]))}x{int(counts[i])}" for i in order[:4]]
    if values.size > 4:
        parts.append(f"+{values.size - 4} more")
    return "MIXED: " + ", ".join(parts)


def uniform_value(words: np.ndarray) -> int | None:
    """The single value filling the row, or None if the row is not uniform."""
    first = words[0]
    return int(first) if bool(np.all(words == first)) else None


def normalize_readback(raw: np.ndarray, target: HBM2Target) -> np.ndarray:
    """Return the target pseudo-channel's half of the readback as u32 words."""
    columns = raw.reshape(target.columns_per_row, BYTES_PER_HBM_COLUMN_PAIR)
    start = target.pseudo_channel * BYTES_PER_PSEUDO_CHANNEL_CHUNK
    useful = np.ascontiguousarray(
        columns[:, start : start + BYTES_PER_PSEUDO_CHANNEL_CHUNK]
    )
    return useful.view(np.uint32).reshape(-1)


class Session:
    """Program construction and readback for one open board."""

    def __init__(self, board, args: argparse.Namespace, target_cls) -> None:
        self.board = board
        self.args = args
        self._target_cls = target_cls
        self._targets: dict[int, HBM2Target] = {}
        self._programs: dict[int, object] = {}

    def target(self, channel: int) -> HBM2Target:
        if channel not in self._targets:
            self._targets[channel] = self._target_cls(
                channel=channel,
                pseudo_channel=self.args.pseudo_channel,
                sid=self.args.sid,
            )
        return self._targets[channel]

    def programs(self, channel: int):
        if channel not in self._programs:
            self._programs[channel] = drambender.builtin_programs.configure(
                target=self.target(channel)
            )
        return self._programs[channel]

    def run(self, steps: list[tuple]) -> list[np.ndarray]:
        """Execute ('w', ch, row, pattern) / ('r', ch, row) steps in order.

        Returns one u32 array per read step, in step order.
        """
        programs = []
        reads = []
        for step in steps:
            if step[0] == "w":
                _, channel, row, pattern = step
                target = self.target(channel)
                words = (pattern,) * target.words_per_cacheline
                programs.append(
                    self.programs(channel).write_row(self.args.bank, row, words)
                )
            else:
                _, channel, row = step
                programs.append(self.programs(channel).read_row(self.args.bank, row))
                reads.append(channel)

        self.board.execute(programs)

        results = []
        for channel in reads:
            target = self.target(channel)
            raw = np.empty(target.receive_bytes_per_row, dtype=np.uint8)
            self.board.receive_into(raw)
            results.append(normalize_readback(raw, target))
        self.board.synchronize()
        return results


def run_controls(session: Session, channel: int) -> None:
    """Prove the harness reads back what it writes, on the reference channel."""
    row = session.args.row

    (readback,) = session.run(
        [("w", channel, row, PATTERN_CONTROL_0), ("r", channel, row)]
    )
    print(f"  control 1  ch{channel} row {row} round trip -> {describe(readback)}")
    if uniform_value(readback) != PATTERN_CONTROL_0:
        raise ControlFailure(
            f"same-channel round trip on channel {channel} returned "
            f"{describe(readback)}, expected 0x5A5A5A5A; reads and writes do not "
            "work on this channel, so no channel comparison is valid"
        )

    first, second = session.run(
        [
            ("w", channel, row, PATTERN_CONTROL_0),
            ("w", channel, row + 1, PATTERN_CONTROL_1),
            ("r", channel, row),
            ("r", channel, row + 1),
        ]
    )
    print(f"  control 2  ch{channel} row {row} -> {describe(first)}")
    print(f"             ch{channel} row {row + 1} -> {describe(second)}")
    if (
        uniform_value(first) != PATTERN_CONTROL_0
        or uniform_value(second) != PATTERN_CONTROL_1
    ):
        raise ControlFailure(
            f"two rows of channel {channel} did not keep distinct data "
            f"(row {row} -> {describe(first)}, row {row + 1} -> {describe(second)}); "
            "the row address is not being decoded, so a channel-level conclusion "
            "cannot be drawn"
        )


def classify_pair(values: tuple[int | None, ...]) -> str:
    """Classify (a_fwd, b_fwd, a_rev, b_rev) uniform row values.

    Aliasing must follow the write order, so the reverse order is what
    separates a genuine shared location from a read that never reached DRAM.
    """
    if values == (PATTERN_A, PATTERN_B, PATTERN_A, PATTERN_B):
        return "isolated"
    if values == (PATTERN_B, PATTERN_B, PATTERN_A, PATTERN_A):
        return "aliased"
    if values == (PATTERN_B, PATTERN_A, PATTERN_B, PATTERN_A):
        return "swapped"
    if values[0] == values[2] == PATTERN_B:
        return "order-independent"
    return "inconclusive"


def run_pair(session: Session, chan_a: int, chan_b: int, *, verbose: bool) -> str:
    """Run both write orders on one channel pair and classify the outcome."""
    row = session.args.row

    a_fwd, b_fwd = session.run(
        [
            ("w", chan_a, row, PATTERN_A),
            ("w", chan_b, row, PATTERN_B),
            ("r", chan_a, row),
            ("r", chan_b, row),
        ]
    )
    a_rev, b_rev = session.run(
        [
            ("w", chan_b, row, PATTERN_B),
            ("w", chan_a, row, PATTERN_A),
            ("r", chan_a, row),
            ("r", chan_b, row),
        ]
    )

    if verbose:
        print(f"  A-then-B   ch{chan_a} -> {describe(a_fwd)}")
        print(f"             ch{chan_b} -> {describe(b_fwd)}")
        print(f"  B-then-A   ch{chan_a} -> {describe(a_rev)}")
        print(f"             ch{chan_b} -> {describe(b_rev)}")

    return classify_pair(
        tuple(uniform_value(w) for w in (a_fwd, b_fwd, a_rev, b_rev))
    )


VERDICT_TEXT = {
    "isolated": "each channel kept its own data in both write orders",
    "aliased": (
        "the second write won in both orders, so both channels address the same "
        "physical location"
    ),
    "swapped": (
        "each channel returned the other's data in both orders; the channel field "
        "is decoded but mapped to the wrong channel"
    ),
    "order-independent": (
        "channel A returned 0xBBBBBBBB regardless of write order; aliasing would "
        "follow the write order, so the read is not returning what the preceding "
        "writes put in DRAM"
    ),
    "inconclusive": "the readback matches no clean hypothesis; see the reads above",
}


def main() -> int:
    parser = argparse.ArgumentParser(description="HBM2 channel isolation test")
    parser.add_argument("--pci-bdf", required=True)
    parser.add_argument("--board", choices=("u50", "u55c"), default="u55c")
    parser.add_argument("--xdma-channel", type=int, default=0)
    parser.add_argument(
        "--channel-a", type=int, default=0, help="reference channel; carries the controls"
    )
    parser.add_argument(
        "--channel-b",
        type=int,
        default=None,
        help="channel compared against the reference (default: highest channel)",
    )
    parser.add_argument("--pseudo-channel", type=int, default=0)
    parser.add_argument("--sid", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument(
        "--row",
        type=int,
        default=1000,
        help="row under test; row + 1 is used by the row-decoding control",
    )
    parser.add_argument(
        "--sweep",
        action="store_true",
        help="compare the reference channel against every other channel",
    )
    args = parser.parse_args()

    target_cls, board_cls = (
        (HBM2U50Target, HBM2U50)
        if args.board == "u50"
        else (HBM2U55CTarget, HBM2U55C)
    )
    config = target_cls().board_config
    channel_count = config.hbm_channel_count
    if args.channel_b is None:
        args.channel_b = channel_count - 1

    for name, value, limit in (
        ("channel-a", args.channel_a, channel_count),
        ("channel-b", args.channel_b, channel_count),
        ("pseudo-channel", args.pseudo_channel, config.hbm_pseudo_channel_count),
        ("sid", args.sid, config.hbm_sid_count),
    ):
        if not 0 <= value < limit:
            print(
                f"--{name} must be in range 0..{limit - 1} on {config.name}",
                file=sys.stderr,
            )
            return 2
    if not 0 <= args.row < MAX_ROW_ADDRESS:
        print(
            f"--row must be in range 0..{MAX_ROW_ADDRESS - 1} "
            "(row + 1 is used by a control)",
            file=sys.stderr,
        )
        return 2
    if not args.sweep and args.channel_a == args.channel_b:
        print("--channel-a and --channel-b must differ", file=sys.stderr)
        return 2

    partners = (
        [ch for ch in range(channel_count) if ch != args.channel_a]
        if args.sweep
        else [args.channel_b]
    )

    print(
        "hbm2_channel_isolation_test: "
        f"pci_bdf={args.pci_bdf} xdma_channel={args.xdma_channel} "
        f"board={args.board} reference_channel={args.channel_a} "
        f"partners={','.join(str(ch) for ch in partners)} "
        f"pch={args.pseudo_channel} sid={args.sid} bank={args.bank} "
        f"row={args.row}"
    )

    try:
        with board_cls(args.pci_bdf, args.xdma_channel) as board:
            if not isinstance(board, HBM2):
                raise RuntimeError("the selected target did not open an HBM2 board")

            board.full_reset()
            # Leftover experiment state is indistinguishable from the effect
            # under test, so pin all three. The broadcast mask matters most: a
            # stale mask fans one command out to several channels and
            # reproduces the aliasing signature exactly.
            board.discard_readback_data(False)
            if board.broadcast_supported:
                board.set_broadcast_channels([])
            board.set_aref(False)

            session = Session(board, args, target_cls)

            print(f"Controls on channel {args.channel_a}:")
            run_controls(session, args.channel_a)
            print("  controls passed")

            verdicts: dict[int, str] = {}
            for chan_b in partners:
                verbose = not args.sweep
                if verbose:
                    print(f"Channel {args.channel_a} vs channel {chan_b}:")
                verdict = run_pair(session, args.channel_a, chan_b, verbose=verbose)
                verdicts[chan_b] = verdict
                if args.sweep:
                    print(f"  ch{args.channel_a} vs ch{chan_b:<2} -> {verdict}")
                else:
                    print(f"  verdict: {verdict} -- {VERDICT_TEXT[verdict]}")
    except ControlFailure as failure:
        print(f"FAIL: control failed: {failure}", file=sys.stderr)
        return 1
    except Exception as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    broken = {ch: v for ch, v in verdicts.items() if v != "isolated"}
    if broken:
        for chan_b, verdict in sorted(broken.items()):
            print(
                f"FAIL: ch{args.channel_a} vs ch{chan_b}: {verdict} -- "
                f"{VERDICT_TEXT[verdict]}",
                file=sys.stderr,
            )
        return 1

    print(
        f"PASS: channel {args.channel_a} is isolated from "
        f"{len(partners)} other channel(s) in both write orders"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
