#!/usr/bin/env python3
"""Single-sided RowHammer across a range of victim rows."""

import argparse
import sys
import time

import numpy as np

import drambender
from drambender.api import DDR4Target, HostInterface, open_board

ROW_BYTES = 8192
ROW_WORDS = ROW_BYTES // 4


def count_bitflips(mask: np.ndarray) -> int:
    return int(np.unpackbits(mask.view(np.uint8), bitorder="little").sum())


def preview_bitflips(mask: np.ndarray, *, limit: int = 8) -> list[tuple[int, int, int]]:
    bit_indices = np.flatnonzero(np.unpackbits(mask.view(np.uint8), bitorder="little"))
    preview = []
    for bit_index in bit_indices[:limit]:
        word_index = int(bit_index) // 32
        cacheline = word_index // 16
        word_in_cacheline = word_index % 16
        bit_in_word = int(bit_index) % 32
        preview.append((cacheline, word_in_cacheline, bit_in_word))
    return preview


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Single-sided RowHammer sweep over a range of victim rows."
    )
    parser.add_argument("--board-id", type=int, default=0)
    parser.add_argument("--instance-id", type=int, default=0)
    parser.add_argument("--bank", type=int, default=0)
    parser.add_argument("--start-row", type=int, default=81,
                        help="First victim row (physical).")
    parser.add_argument("--num-victims", type=int, default=30,
                        help="Number of consecutive victim rows to test.")
    parser.add_argument("--hammer-count", type=int, default=500000)
    args = parser.parse_args()

    target = DDR4Target(
        cachelines_per_row=128,
        column_stride=8,
        words_per_cacheline=16,
    )
    builtin_progs = drambender.builtin_programs.configure(target=target)

    board = open_board(
        target,
        board_id=args.board_id,
        instance_id=args.instance_id,
        host_interface=HostInterface.XDMA,
    )
    board.reset_fpga()

    print(
        f"single_sided_rowhammer: board={args.board_id} instance={args.instance_id} bank={args.bank} "
        f"start_row={args.start_row} num_victims={args.num_victims} "
        f"hammer_count={args.hammer_count}"
    )

    total_vulnerable = 0
    total_bitflips = 0

    t_build = 0.0
    t_execute = 0.0
    t_readback = 0.0
    t_sync = 0.0
    t_count = 0.0
    t_loop_start = time.perf_counter()

    for v in range(args.num_victims):
        victim_physical = args.start_row + v
        aggressor_physical = victim_physical + 1

        t0 = time.perf_counter()
        victim = drambender.rows.Row(
            physical_id=victim_physical,
            row_mapping="MI1",
            data_pattern=0x00000000,
        )
        aggressor = drambender.rows.Row(
            physical_id=aggressor_physical,
            row_mapping="MI1",
            data_pattern=0xFFFFFFFF,
        )
        programs = [
            builtin_progs.write_row(args.bank, victim.logical_id, victim.write_pattern),
            builtin_progs.write_row(args.bank, aggressor.logical_id, aggressor.write_pattern),
            builtin_progs.single_sided_rowhammer(
                args.bank,
                aggressor.logical_id,
                args.hammer_count,
            ),
            builtin_progs.read_row(args.bank, victim.logical_id),
        ]
        t1 = time.perf_counter()
        board.execute(programs)
        t2 = time.perf_counter()
        rb = np.empty(ROW_WORDS, dtype=np.uint32)
        board.receive_into(rb)
        t3 = time.perf_counter()
        board.synchronize()
        t4 = time.perf_counter()
        pattern = np.asarray(victim.write_pattern, dtype=np.uint32)
        expected = np.tile(pattern, ROW_WORDS // len(pattern))
        mask = rb ^ expected
        n_flips = count_bitflips(mask)
        t5 = time.perf_counter()

        t_build    += t1 - t0
        t_execute  += t2 - t1
        t_readback += t3 - t2
        t_sync     += t4 - t3
        t_count    += t5 - t4

        total_bitflips += n_flips
        if n_flips > 0:
            total_vulnerable += 1
            print(
                f"  row {victim_physical:5d} -> {victim.logical_id:5d} "
                f"(aggressor {aggressor_physical} -> {aggressor.logical_id}): "
                f"{n_flips} bitflips"
            )
            preview = preview_bitflips(mask)
            if preview:
                formatted = ", ".join(
                    f"cl={cacheline} word={word} bit={bit}"
                    for cacheline, word, bit in preview
                )
                print(f"    preview: {formatted}")

    t_total = time.perf_counter() - t_loop_start

    print(
        f"\nResult: {total_vulnerable}/{args.num_victims} rows vulnerable, "
        f"{total_bitflips} total bitflips"
    )

    n = args.num_victims
    phases = [
        ("build",    t_build),
        ("execute",  t_execute),
        ("readback", t_readback),
        ("sync",     t_sync),
        ("count",    t_count),
    ]
    print(f"\nRuntime breakdown ({n} victims):")
    for name, dt in phases:
        print(f"  {name:<12} {dt*1e3:10.3f} ms total {dt/n*1e3:10.3f} ms/iter {100*dt/t_total:6.2f}%")
    print(f"  {'TOTAL':<12} {t_total*1e3:10.3f} ms total {t_total/n*1e3:10.3f} ms/iter")

    return 1 if total_vulnerable > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
