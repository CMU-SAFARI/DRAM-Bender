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
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

import numpy as np  # noqa: E402

import drambender  # noqa: E402
from drambender.api import DDR4Target, FinalProgram, ProgramBuilder, program_template  # noqa: E402
from drambender.api.program.instructions import ACT, NOP, PRE, RD, WR  # noqa: E402

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

CACHELINES_PER_ROW = 128
WORDS_PER_CACHELINE = 16
BYTES_PER_CACHELINE = 64
ROW_BYTES = CACHELINES_PER_ROW * BYTES_PER_CACHELINE
WORDS_PER_ROW = ROW_BYTES // 4
COLUMN_STRIDE = 8
DDR4_TARGET = DDR4Target(
    cachelines_per_row=CACHELINES_PER_ROW,
    column_stride=COLUMN_STRIDE,
    words_per_cacheline=WORDS_PER_CACHELINE,
)


@program_template
def build_rowhammer_program(bank: int, victim_row: int, aggressor_row: int,
                            victim_pattern: int, aggressor_pattern: int,
                            hammer_count: int) -> FinalProgram:
    """Build the same instruction sequence as rowhammer_test.cpp."""
    p = ProgramBuilder(target=DDR4_TARGET)
    p.alloc_reg("NUM_HAMMER_REG")
    p.alloc_reg("HAMMER_CTR_REG")

    p.LI(bank, "BAR")
    p.LI(DDR4_TARGET.column_stride, "CASR")
    p.LI(hammer_count, "NUM_HAMMER_REG")
    p.LI(0, "HAMMER_CTR_REG")

    # Initialize victim row.
    p.LI(victim_row, "RAR")
    p.LI(victim_pattern, "PATTERN_REG")
    for word in range(WORDS_PER_CACHELINE):
        p.LDWD("PATTERN_REG", word)

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(2)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    for _ in range(CACHELINES_PER_ROW):
        p.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)
    p.SLEEP(8)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)

    # Initialize aggressor row.
    p.LI(aggressor_row, "RAR")
    p.LI(aggressor_pattern, "PATTERN_REG")
    for word in range(WORDS_PER_CACHELINE):
        p.LDWD("PATTERN_REG", word)

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.LI(0, "CAR")
    p.SLEEP(2)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    for _ in range(CACHELINES_PER_ROW):
        p.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)
    p.SLEEP(8)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)

    # Hammer aggressor.
    p.LI(aggressor_row, "RAR")
    p.LI(0, "HAMMER_CTR_REG")
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(5)

    p.LABEL("HAMMER")
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.ADDI("HAMMER_CTR_REG", 1, "HAMMER_CTR_REG")
    p.SLEEP(1)
    p.DRAM(NOP(), NOP(), NOP(), ACT("BAR", "RAR"))
    p.BL("HAMMER_CTR_REG", "NUM_HAMMER_REG", "HAMMER")

    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)

    # Read victim row back.
    p.LI(victim_row, "RAR")
    p.LI(0, "CAR")
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    p.DRAM(ACT("BAR", "RAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)
    for _ in range(CACHELINES_PER_ROW):
        p.DRAM(RD("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
        p.SLEEP(1)
    p.SLEEP(4)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    p.SLEEP(2)

    return p.conclude()


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
    ap.add_argument("--pci-bdf", required=True)
    ap.add_argument("--xdma-channel", type=int, default=0)
    ap.add_argument("--bank", type=int, default=0)
    ap.add_argument("--start-row", type=int, default=2048)
    ap.add_argument("--num-victims", type=int, default=128)
    ap.add_argument("--hammer-count", type=int, default=250000)
    ap.add_argument("--victim-data", type=lambda x: int(x, 0), default=0x00000000)
    ap.add_argument("--aggressor-data", type=lambda x: int(x, 0), default=0xFFFFFFFF)
    args = ap.parse_args()

    print(f"rowhammer_test: pci_bdf={args.pci_bdf} xdma_channel={args.xdma_channel} "
          f"bank={args.bank} start_row={args.start_row} "
          f"num_victims={args.num_victims} hammer_count={args.hammer_count}")
    print(f"  victim_data=0x{args.victim_data:08x} aggressor_data=0x{args.aggressor_data:08x}")

    board = drambender.api.DDR4(args.pci_bdf, args.xdma_channel)
    board.full_reset()

    row_buffer = np.empty(ROW_BYTES, dtype=np.uint8)
    total_flips = 0
    vulnerable_rows = 0

    for v in range(args.num_victims):
        victim_row = args.start_row + v
        aggressor_row = victim_row + 1

        program = build_rowhammer_program(
            args.bank,
            victim_row,
            aggressor_row,
            args.victim_data,
            args.aggressor_data,
            args.hammer_count,
        )
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
