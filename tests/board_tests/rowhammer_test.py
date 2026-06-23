#!/usr/bin/env python3
"""Single-sided RowHammer test.

For each victim row in [start_row, start_row + num_victims):
  1. Initialize victim row with DATA pattern
  2. Initialize aggressor row (victim + 1) with ~DATA pattern
  3. Hammer the aggressor row N times
  4. Read back the victim row
  5. Report bitflips
"""

import argparse
import sys
from functools import partial
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

import numpy as np  # noqa: E402

import drambender  # noqa: E402
from tests.jit_benchmark.workloads import (  # noqa: E402
    CACHELINES_PER_ROW,
    ROW_BYTES,
    build_rowhammer_program_compiled,
)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

WORDS_PER_ROW = ROW_BYTES // 4


# ---------------------------------------------------------------------------
# Bitflip analysis (vectorized)
# ---------------------------------------------------------------------------

def get_bitflip_indices(observed_bytes: np.ndarray, expected_pattern: int) -> np.ndarray:
    """Return global bit indices of all flipped bits."""
    observed_u32 = observed_bytes.view(np.uint32)
    expected_u32 = np.full(len(observed_u32), expected_pattern, dtype=np.uint32)
    flips = observed_u32 ^ expected_u32
    bits = np.unpackbits(flips.view(np.uint8), bitorder="little")
    return np.flatnonzero(bits).astype(np.int64)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description="Single-sided RowHammer test")
    ap.add_argument("--board-id", type=int, default=0)
    ap.add_argument("--instance-id", type=int, default=0)
    ap.add_argument("--bank", type=int, default=0)
    ap.add_argument("--start-row", type=int, default=0)
    ap.add_argument("--num-victims", type=int, default=64)
    ap.add_argument("--hammer-count", type=int, default=150000)
    ap.add_argument("--victim-data", type=lambda x: int(x, 0), default=0x00000000)
    ap.add_argument("--aggressor-data", type=lambda x: int(x, 0), default=0xFFFFFFFF)
    args = ap.parse_args()

    print(f"rowhammer_test: board={args.board_id} instance={args.instance_id} "
          f"bank={args.bank} start_row={args.start_row} "
          f"num_victims={args.num_victims} hammer_count={args.hammer_count}")
    print(f"  victim_data=0x{args.victim_data:08x} aggressor_data=0x{args.aggressor_data:08x}")

    board = drambender.api.DDR4(args.board_id, args.instance_id)
    board.reset_fpga()

    # Build template once, bind fixed args
    hammer = partial(
        build_rowhammer_program_compiled,
        bank=args.bank,
        victim_pattern=args.victim_data,
        aggressor_pattern=args.aggressor_data,
        hammer_count=args.hammer_count,
    )

    row_buffer = np.empty(ROW_BYTES, dtype=np.uint8)
    total_flips = 0
    vulnerable_rows = 0

    for v in range(args.num_victims):
        victim_row = args.start_row + v
        aggressor_row = victim_row + 1

        program = hammer(victim_row=victim_row, aggressor_row=aggressor_row)
        board.execute(program)
        board.receive_into(row_buffer)
        board.synchronize()

        flip_indices = get_bitflip_indices(row_buffer, args.victim_data)
        n_flips = len(flip_indices)
        total_flips += n_flips

        if n_flips > 0:
            vulnerable_rows += 1
            print(f"  row {victim_row:5d}: {n_flips} bitflips (aggressor={aggressor_row})")
            for bit_idx in flip_indices[:16]:
                word_idx = int(bit_idx) // 32
                bit_in_word = int(bit_idx) % 32
                cl = word_idx // 16
                print(f"    cl={cl} word={word_idx % 16} bit={bit_in_word}")

        done = v + 1
        if done % 10 == 0 or done == args.num_victims:
            print(f"\r  [{done}/{args.num_victims} tested, "
                  f"{vulnerable_rows} vulnerable, {total_flips} total bitflips]",
                  end="", flush=True)

    print(f"\n\nResult: {vulnerable_rows}/{args.num_victims} rows vulnerable, "
          f"{total_flips} total bitflips")
    return 1 if vulnerable_rows > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
