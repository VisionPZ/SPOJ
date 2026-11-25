#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def count_tilings(width):
    current = {0: 1}
    for _ in range(width):
        following = {}

        def fill_column(row, occupied, result, ways):
            if row == 4:
                following[result] = following.get(result, 0) + ways
                return
            if occupied & (1 << row):
                fill_column(row + 1, occupied, result, ways)
                return
            if row + 1 < 4 and not occupied & (1 << (row + 1)):
                fill_column(row + 2, occupied | (1 << row) | (1 << (row + 1)), result, ways)
            if not result & (1 << row):
                fill_column(row + 1, occupied | (1 << row), result | (1 << row), ways)

        for mask, ways in current.items():
            if ways:
                fill_column(0, mask, 0, ways)
        current = following
    return current.get(0, 0)


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    lines = []
    for index in range(count):
        lines.append(f"{index + 1} {count_tilings(int(tokens[index + 1]))}")
    return "\n".join(lines) + "\n"


SAMPLE = """3
2
3
7
"""
SAMPLE_OUT = """1 5
2 11
3 781
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert count_tilings(0) == 1
assert count_tilings(1) == 1
assert count_tilings(4) == 36
assert count_tilings(21) == 1752296281


def write(name, widths):
    text = str(len(widths)) + "\n" + "".join(str(width) + "\n" for width in widths)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 1, 2, 3, 4])
    write("3_wide", list(range(1, 22)))
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 21) for _ in range(80)])
    write("5_io", [rng.randint(1, 21) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [2, 3, 7])
build()
