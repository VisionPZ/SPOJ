#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PERIODS = [1, 3, 3, 6, 12, 24, 12, 24, 24, 24, 24, 48, 48,
           96, 96, 96, 192, 192, 384, 384, 384, 768, 768, 768, 768]


def build_table(limit=2600):
    table = [[0] * (limit + 1) for _ in range(25)]
    for side in range(25):
        mask = 0
        for column in range(limit + 1):
            seen = mask
            for smaller in range(side):
                seen |= 1 << table[smaller][column]
            step = 1
            while step <= side and step <= column:
                seen |= 1 << table[side - step][column - step]
                step += 1
            mex = ((seen + 1) & ~seen).bit_length() - 1
            table[side][column] = mex
            mask |= 1 << mex
    return table


TABLE = build_table()
CYCLES = []
for side in range(25):
    period = PERIODS[side]
    differences = [TABLE[side][column] - column for column in range(len(TABLE[side]))]
    failures = [column for column in range(len(differences) - period)
                if differences[column + period] != differences[column]]
    start = max(failures) + 1 if failures else 0
    assert all(differences[column + period] == differences[column]
               for column in range(start, len(differences) - period))
    CYCLES.append((start, period))


def grundy(first_pile, second_pile):
    smaller = min(first_pile, second_pile)
    larger = max(first_pile, second_pile)
    if larger < len(TABLE[smaller]):
        return TABLE[smaller][larger]
    start, period = CYCLES[smaller]
    index = start + (larger - start) % period
    return larger + TABLE[smaller][index] - index


def oracle(text):
    tokens = [int(value) for value in text.replace("\xa0", " ").split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        row_count = tokens[cursor]
        column_count = tokens[cursor + 1]
        queen_count = tokens[cursor + 2]
        cursor += 3
        nim_sum = 0
        for _ in range(queen_count):
            queen_row = tokens[cursor]
            queen_column = tokens[cursor + 1]
            cursor += 2
            nim_sum ^= grundy(queen_row - 1, queen_column - 1)
        answers.append("YES" if nim_sum else "NO")
    return "\n".join(answers) + "\n"


SAMPLE = ("3\xa0\n5 5 1\xa0\n2 3\xa0\n5 5 2\xa0\n4 4\xa0\n4 4\xa0\n5 5 3\xa0\n"
          "1 2\xa0\n2 1\xa0\n2 2\xa0\n")
SAMPLE_OUT = "NO\nNO\nYES\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert grundy(0, 0) == 0
assert grundy(1, 2) == 0
assert grundy(2, 1) == 0
assert grundy(3, 5) == 0
assert grundy(0, 10) == 10
assert grundy(1, 10) == 11
assert grundy(24, 10 ** 15) > 10 ** 15 - 100


def write(name, cases):
    lines = [str(len(cases))]
    for rows, columns, queens in cases:
        lines.append(f"{rows} {columns} {len(queens)}")
        lines.extend(f"{row} {column}" for row, column in queens)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)

    def case(rows, columns, count, largest_row, largest_column):
        queens = [(rng.randint(1, min(rows, largest_row)),
                   rng.randint(1, min(columns, largest_column))) for _ in range(count)]
        return (rows, columns, queens)

    write("2_edges", [(1, 1, [(1, 1)]), (2, 2, [(1, 1), (2, 2)]),
                      (25, 1500, [(4, 6), (6, 11), (25, 1500)]),
                      (5, 10 ** 15, [(2, 3), (3, 2), (4, 5)])])
    write("3_wide", [case(25, 10 ** 15, 12, 25, 10 ** 15) for _ in range(6)])
    write("4_random", [case(rng.randint(1, 25), rng.randint(1, 3000),
                            rng.randint(1, 20), 25, 3000) for _ in range(40)])
    write("5_io", [case(rng.randint(1, 25), rng.randint(1, 10 ** 15),
                        rng.randint(1, 8), 25, 10 ** 15) for _ in range(500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
