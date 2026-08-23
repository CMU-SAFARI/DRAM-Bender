#!/usr/bin/env python3
"""Read-write integrity test for DRAM Bender.

Writes a rotating pattern to every row in a bank, reads each row back
immediately, and verifies byte-by-byte.  Python equivalent of
internal_tests/board_tests/rw_test.cpp.
"""

import argparse
import sys

import numpy as np

import drambender
from drambender.api import DDR4Target, ProgramBuilder
from drambender.api.program.instructions import *

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BYTES_PER_CACHELINE = 64
DEFAULT_PATTERN = 0xDEADBEEF


# ---------------------------------------------------------------------------
# Program
# ---------------------------------------------------------------------------

def parse_u32(text: str) -> int:
    try:
        value = int(text, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid 32-bit pattern: {text!r}") from exc
    if not 0 <= value <= 0xFFFFFFFF:
        raise argparse.ArgumentTypeError("pattern must be in range 0..0xffffffff")
    return value


def build_rw_program(bank: int, num_rows: int, num_cls: int,
                     pattern: int) -> drambender.api.FinalProgram:
    target = DDR4Target(cachelines_per_row=num_cls, column_stride=8)

    p = ProgramBuilder(target=target)
    p.alloc_reg("PATTERN_REG")
    p.alloc_reg("NUM_ROWS_REG")
    p.alloc_reg("NUM_COLS_REG")
    p.alloc_reg("LOOP_COLS_REG")
    p.alloc_reg("TEMP_PATTERN_REG")

    p.LI(num_rows, "NUM_ROWS_REG")
    p.LI(bank, "BAR")
    p.LI(target.column_stride, "CASR")
    p.LI(num_cls, "NUM_COLS_REG")
    p.LI(pattern, "PATTERN_REG")
    for index in range(target.words_per_cacheline):
        p.LDWD("PATTERN_REG", index)

    p.LI(0, "RAR")
    p.LABEL("ROW_BEGIN")
    p.LI(0, "CAR")

    # Write: precharge + activate
    p.DRAMSEQ(PRE("BAR", delay=11), ACT("BAR", "RAR", delay=11), ALIGN())

    # Write loop
    p.LI(0, "LOOP_COLS_REG")
    p.LABEL("WRITE_BEGIN")
    p.DRAM(WR("BAR", "CAR", icar=1), NOP(), NOP(), NOP())
    p.SRC("PATTERN_REG", "PATTERN_REG")
    for index in range(target.words_per_cacheline):
        p.LDWD("PATTERN_REG", index)
    p.ADDI("LOOP_COLS_REG", 1, "LOOP_COLS_REG")
    p.BL("LOOP_COLS_REG", "NUM_COLS_REG", "WRITE_BEGIN")

    # Scramble pattern: pattern *= 3
    p.MV("PATTERN_REG", "TEMP_PATTERN_REG")
    p.ADD("PATTERN_REG", "TEMP_PATTERN_REG", "PATTERN_REG")
    p.ADD("PATTERN_REG", "TEMP_PATTERN_REG", "PATTERN_REG")
    for index in range(target.words_per_cacheline):
        p.LDWD("PATTERN_REG", index)

    p.SLEEP(1)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    # Read-back: precharge + activate
    p.LI(0, "CAR")
    p.DRAMSEQ(PRE("BAR", delay=11), ACT("BAR", "RAR", delay=11), ALIGN())

    # Read loop
    p.LI(0, "LOOP_COLS_REG")
    p.LABEL("READ_BEGIN")
    p.DRAMSEQ(RD("BAR", "CAR", icar=1, delay=7), ALIGN())
    p.ADDI("LOOP_COLS_REG", 1, "LOOP_COLS_REG")
    p.BL("LOOP_COLS_REG", "NUM_COLS_REG", "READ_BEGIN")

    p.SLEEP(1)
    p.DRAM(PRE("BAR"), NOP(), NOP(), NOP())
    # Next row
    p.ADDI("RAR", 1, "RAR")
    p.BL("RAR", "NUM_ROWS_REG", "ROW_BEGIN")

    p.SLEEP(3)  # tRP cushion after the last iteration's closing PRE
    return p.conclude()


# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

def build_expected_row_u32(pattern: int, num_cls: int) -> np.ndarray:
    """Build expected uint32 words for one row, fully vectorized.

    Each cacheline = 16 uint32 words filled with the same rotated pattern.
    Returns shape (num_cls * 16,) as uint32.
    """
    words_per_cl = BYTES_PER_CACHELINE // 4  # 16

    # Vectorized rotate-right: pattern >> shift | pattern << (32 - shift)
    # Rotation amounts: 0, 1, 2, ..., num_cls-1 (mod 32)
    shifts = np.arange(num_cls, dtype=np.uint32) % 32
    p = np.uint32(pattern)
    cl_patterns = (p >> shifts) | (p << (np.uint32(32) - shifts))
    cl_patterns = cl_patterns.astype(np.uint32)

    return np.repeat(cl_patterns, words_per_cl)


def find_bitflips(observed_bytes: np.ndarray, expected_u32: np.ndarray) -> np.ndarray:
    """Return global bit indices of all flipped bits, fully vectorized.

    Sparse strategy: XOR → find nonzero words → unpack only those to bits.
    """
    observed_u32 = observed_bytes.view(np.uint32)
    flips = observed_u32 ^ expected_u32

    nonzero_word_indices = np.flatnonzero(flips)
    if len(nonzero_word_indices) == 0:
        return np.array([], dtype=np.int64)

    # Unpack only the nonzero words to individual bits
    nonzero_bytes = flips[nonzero_word_indices].view(np.uint8)
    bits = np.unpackbits(nonzero_bytes, bitorder="little")

    # Map local bit positions → global bit indices
    local_bit_indices = np.flatnonzero(bits)
    local_word = local_bit_indices // 32
    local_bit = local_bit_indices % 32
    return nonzero_word_indices[local_word].astype(np.int64) * 32 + local_bit.astype(np.int64)


def verify_row(observed_bytes: np.ndarray, expected_u32: np.ndarray,
               bank: int, row: int, max_reports: int = 32) -> int:
    """Compare observed readback against expected pattern. Returns bitflip count."""
    flip_indices = find_bitflips(observed_bytes, expected_u32)
    if len(flip_indices) == 0:
        return 0

    for i, bit_idx in enumerate(flip_indices[:max_reports]):
        word_idx = int(bit_idx) // 32
        bit_in_word = int(bit_idx) % 32
        cl = word_idx // 16
        word_in_cl = word_idx % 16
        observed_u32 = observed_bytes.view(np.uint32)
        print(
            f"  Bitflip: bank={bank} row={row} cl={cl} word={word_in_cl} "
            f"bit={bit_in_word} "
            f"expected=0x{expected_u32[word_idx]:08x} "
            f"read=0x{observed_u32[word_idx]:08x}",
            file=sys.stderr,
        )

    return len(flip_indices)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description="DRAM read-write integrity test")
    ap.add_argument("--pci-bdf", required=True)
    ap.add_argument("--xdma-channel", type=int, default=0)
    ap.add_argument("--bank", type=int, default=0)
    ap.add_argument("--num-rows", type=int, default=65536)
    ap.add_argument("--num-cls", type=int, default=128)
    ap.add_argument("--pattern", type=parse_u32, default=DEFAULT_PATTERN,
                    help="Initial 32-bit write pattern, decimal or 0x-prefixed hex.")
    args = ap.parse_args()

    row_bytes = args.num_cls * BYTES_PER_CACHELINE
    total_bytes = args.num_rows * row_bytes
    print(f"rw_test: pci_bdf={args.pci_bdf} xdma_channel={args.xdma_channel} bank={args.bank} "
          f"rows={args.num_rows} cls={args.num_cls} pattern=0x{args.pattern:08x} "
          f"bytes/row={row_bytes}")

    board = drambender.api.DDR4(args.pci_bdf, args.xdma_channel)
    board.full_reset()
    board.execute(build_rw_program(args.bank, args.num_rows, args.num_cls, args.pattern))

    buf = np.empty(row_bytes, dtype=np.uint8)
    total_bad = 0
    pat = args.pattern
    step = max(1, args.num_rows // 200)

    for row in range(args.num_rows):
        board.receive_into(buf)
        expected = build_expected_row_u32(pat, args.num_cls)
        total_bad += verify_row(buf, expected, args.bank, row)
        pat = (pat * 3) & 0xFFFFFFFF
        done = row + 1
        if done == args.num_rows or done % step == 0:
            pct = 100.0 * done / args.num_rows
            bar = "=" * (40 * done // args.num_rows)
            print(f"\r[{bar:<40s}] {pct:6.2f}% ({done}/{args.num_rows})",
                  end="", flush=True)

    board.synchronize()
    print()

    if total_bad == 0:
        print(f"PASS: {total_bytes} bytes verified")
        return 0
    print(f"FAIL: {total_bad} mismatches in {total_bytes} bytes", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
