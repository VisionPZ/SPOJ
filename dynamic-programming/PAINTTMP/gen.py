#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def holes(n):
    full = (1 << n) - 1
    return [(r, c) for r in range(1 << n) for c in range(1 << n)
            if (r | c) == full]


def brute(n, x, y):
    hole_set = set(holes(n))
    return sum(1 for (r, c) in hole_set if (r + y, c - x) in hole_set)


@lru_cache(None)
def recurse(n, down, right):
    if n == 0:
        return 1 if down == 0 and right == 0 else 0
    side = 1 << n
    if abs(down) >= side or abs(right) >= side:
        return 0
    half = 1 << (n - 1)
    offsets = [(0, half), (half, 0), (half, half)]
    total = 0
    for (lower_row, lower_col) in offsets:
        for (upper_row, upper_col) in offsets:
            total += recurse(n - 1,
                             down - (upper_row - lower_row),
                             right - (upper_col - lower_col))
    return total


def oracle(n, x, y):
    return recurse(n, y, -x)


def make_input(cases, separate):
    lines = [str(len(cases))]
    for index, (size, right, down) in enumerate(cases):
        if separate and index > 0:
            lines.append("")
        lines.extend((str(size), str(right), str(down)))
    return "\n".join(lines) + "\n"


def make_output(cases):
    return "\n".join(str(oracle(size, right, down))
                     for size, right, down in cases) + "\n"


def write(name, cases, separate=False):
    (ROOT / "in" / (name + ".txt")).write_text(make_input(cases, separate))
    (ROOT / "out" / (name + ".out")).write_text(make_output(cases))


def worked_example():
    size, right, down = 2, 2, 2
    hole_set = set(holes(size))
    agree = sorted((r, c, r + down, c - right)
                   for (r, c) in hole_set
                   if (r + down, c - right) in hole_set)
    print("n=%d x=%d y=%d holes=%d agree=%d" %
          (size, right, down, len(hole_set), len(agree)))
    for lower_row, lower_col, upper_row, upper_col in agree:
        print("(%d,%d) -> (%d,%d)" %
              (lower_row, lower_col, upper_row, upper_col))


assert oracle(2, 2, 2) == 3
assert brute(2, 2, 2) == 3
assert oracle(0, 0, 0) == 1
assert brute(0, 0, 0) == 1
assert oracle(0, 1, 0) == 0
assert oracle(0, 0, 1) == 0
for size in range(0, 101):
    assert oracle(size, 0, 0) == 3 ** size
    assert oracle(size, 1 << size, 0) == 0
    assert oracle(size, 0, 1 << size) == 0

random.seed(1704)
for _ in range(400):
    size = random.randint(0, 7)
    right = random.randint(0, 1 << size)
    down = random.randint(0, 1 << size)
    assert brute(size, right, down) == oracle(size, right, down)

SAMPLE = [(2, 2, 2)]
assert make_input(SAMPLE, False) == "1\n2\n2\n2\n"
assert make_output(SAMPLE) == "3\n"


def build():
    write("1_sample", SAMPLE)
    edges = [
        (0, 0, 0), (0, 1, 0), (0, 0, 1),
        (1, 0, 0), (1, 1, 1), (1, 2, 2),
        (2, 0, 0), (2, 2, 2), (2, 3, 3),
        (5, 32, 0), (5, 0, 32), (5, 31, 31),
        (100, 0, 0), (100, 1 << 100, 1 << 100),
    ]
    write("2_edges", edges, True)
    wide = [
        (100, 0, 0),
        (100, (1 << 100) - 1, 0),
        (100, 0, (1 << 100) - 1),
        (100, (1 << 100) - 1, (1 << 100) - 1),
        (100, 1 << 99, 1 << 99),
        (100, (1 << 99) - 1, 1 << 99),
        (99, (1 << 99) - 1, 0),
        (50, (1 << 50) - 1, (1 << 50) - 1),
    ]
    write("3_wide", wide, True)
    mixed = []
    for _ in range(60):
        size = random.randint(0, 12)
        mixed.append((size, random.randint(0, 1 << size),
                      random.randint(0, 1 << size)))
    for _ in range(140):
        size = random.randint(80, 100)
        mixed.append((size, random.randint(0, 1 << size),
                      random.randint(0, 1 << size)))
    write("4_random", mixed, True)
    io_cases = []
    for _ in range(2000):
        size = 100
        io_cases.append((size, random.randint(0, 1 << size),
                         random.randint(0, 1 << size)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()
if __name__ == "__main__":
    worked_example()
