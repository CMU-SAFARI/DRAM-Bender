from collections.abc import Sequence

from draminspector.api import FinalProgram, ProgramBuilder, program_template
from draminspector.api.program.instructions import ACT, ALIGN, NOP, PRE, RD, WR


BYTES_PER_CACHELINE = 64
CACHELINES_PER_ROW = 128
ROW_BYTES = BYTES_PER_CACHELINE * CACHELINES_PER_ROW
WORDS_PER_ROW = ROW_BYTES // 4


def build_tiny_scalar_program_plain(bank: int, row: int, delay: int) -> FinalProgram:
    p = ProgramBuilder()
    # After the ACT, SLEEP(6) = 36 ns meets tRAS before the closing PRE; the
    # closing PRE is then followed by SLEEP(3) = 18 ns for tRP so any program
    # submitted back-to-back sees the bank fully precharged.
    return (
        p.LI(bank, "BAR")
        .LI(row, "RAR")
        .DRAMSEQ(
            PRE("BAR", delay=delay),
            ACT("BAR", "RAR", delay=delay),
            ALIGN(),
        )
        .SLEEP(6)
        .DRAM(PRE("BAR"), NOP(), NOP(), NOP())
        .SLEEP(3)
        .conclude()
    )


build_tiny_scalar_program_compiled = program_template(build_tiny_scalar_program_plain)


def tiny_scalar_cases(count: int) -> list[dict[str, int]]:
    return [
        {
            "bank": 0,
            "row": index,
            "delay": 11 + (2 * (index % 2)),
        }
        for index in range(count)
    ]


def build_pattern_program_plain(pattern_words: Sequence[int]) -> FinalProgram:
    p = ProgramBuilder()
    p.alloc_reg("PATTERN_REG")
    for index, value in enumerate(pattern_words):
        p.LI(value, "PATTERN_REG")
        p.LDWD("PATTERN_REG", index)
    return p.conclude()


build_pattern_program_compiled = program_template(build_pattern_program_plain)


def pattern_cases(count: int, *, length: int = 4) -> list[dict[str, list[int]]]:
    cases: list[dict[str, list[int]]] = []
    for base in range(count):
        pattern = [
            ((base + 1) * 0x11111111 + index * 0x01010101) & 0xFFFFFFFF
            for index in range(length)
        ]
        cases.append({"pattern_words": pattern})
    return cases


def build_rowhammer_program_plain(
    bank: int,
    victim_row: int,
    aggressor_row: int,
    victim_pattern: int,
    aggressor_pattern: int,
    hammer_count: int,
) -> FinalProgram:
    p = ProgramBuilder()
    p.alloc_reg("PATTERN_REG")
    p.alloc_reg("NUM_HAMMER_REG")
    p.alloc_reg("HAMMER_CTR_REG")

    p.LI(bank, "BAR")
    p.LI(8, "CASR")
    p.LI(hammer_count, "NUM_HAMMER_REG")
    p.LI(0, "HAMMER_CTR_REG")

    p.LI(victim_row, "RAR")
    p.LI(victim_pattern, "PATTERN_REG")
    for index in range(16):
        p.LDWD("PATTERN_REG", index)
    p.DRAMSEQ(PRE("BAR", delay=11), ACT("BAR", "RAR", delay=11), ALIGN())
    p.LI(0, "CAR")
    p.DRAMSEQ(
        *(WR("BAR", "CAR", icar=1, delay=7) for _ in range(CACHELINES_PER_ROW - 1)),
        WR("BAR", "CAR", icar=1, delay=15),
        PRE("BAR", delay=11),
        ALIGN(),
    )

    p.LI(aggressor_row, "RAR")
    p.LI(aggressor_pattern, "PATTERN_REG")
    for index in range(16):
        p.LDWD("PATTERN_REG", index)
    p.DRAMSEQ(PRE("BAR", delay=11), ACT("BAR", "RAR", delay=11), ALIGN())
    p.LI(0, "CAR")
    p.DRAMSEQ(
        *(WR("BAR", "CAR", icar=1, delay=7) for _ in range(CACHELINES_PER_ROW - 1)),
        WR("BAR", "CAR", icar=1, delay=15),
        PRE("BAR", delay=11),
        ALIGN(),
    )

    p.LI(aggressor_row, "RAR")
    p.LI(0, "HAMMER_CTR_REG")
    p.DRAMSEQ(ACT("BAR", "RAR", delay=23), ALIGN())
    p.LABEL("HAMMER")
    p.DRAMSEQ(PRE("BAR", delay=3), ALIGN())
    p.ADDI("HAMMER_CTR_REG", 1, "HAMMER_CTR_REG")
    p.DRAMSEQ(ACT("BAR", "RAR", delay=3), ALIGN())
    p.BL("HAMMER_CTR_REG", "NUM_HAMMER_REG", "HAMMER")
    p.DRAMSEQ(PRE("BAR", delay=11), ALIGN())

    p.LI(victim_row, "RAR")
    p.LI(0, "CAR")
    p.DRAMSEQ(
        PRE("BAR", delay=11),
        ACT("BAR", "RAR", delay=11),
        *(RD("BAR", "CAR", icar=1, delay=7) for _ in range(CACHELINES_PER_ROW - 1)),
        RD("BAR", "CAR", icar=1, delay=11),
        PRE("BAR", delay=11),
        ALIGN(),
    )
    return p.conclude()


build_rowhammer_program_compiled = program_template(build_rowhammer_program_plain)


def rowhammer_cases(
    count: int,
    *,
    bank: int = 0,
    start_row: int = 0,
    hammer_count: int = 250_000,
    victim_pattern: int = 0x00000000,
    aggressor_pattern: int = 0xFFFFFFFF,
) -> list[dict[str, int]]:
    return [
        {
            "bank": bank,
            "victim_row": start_row + index,
            "aggressor_row": start_row + index + 1,
            "victim_pattern": victim_pattern,
            "aggressor_pattern": aggressor_pattern,
            "hammer_count": hammer_count,
        }
        for index in range(count)
    ]
