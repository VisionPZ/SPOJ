#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def solve_order(drives, order):
    free = 0
    extra = 0
    for index in order:
        old, new = drives[index]
        if free < old:
            extra += old - free
            free = 0
        else:
            free -= old
        free += new
    return extra


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        drive_count = tokens[cursor]
        cursor += 1
        drives = []
        for _ in range(drive_count):
            drives.append((tokens[cursor], tokens[cursor + 1]))
            cursor += 2
        best = None
        for order in itertools.permutations(range(drive_count)):
            value = solve_order(drives, order)
            if best is None or value < best:
                best = value
        answers.append(str(best))
    return "\n".join(answers) + "\n"


def format_cases(cases):
    parts = []
    for drives in cases:
        parts.append(str(len(drives)))
        for old, new in drives:
            parts.append(f"{old} {new}")
    return "\n".join(parts) + "\n"


SAMPLE = """4
6 6
1 7
3 5
3 5
4
2 2
3 3
5 1
5 10
"""
SAMPLE_OUT = """1
5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n5 5\n") == "5\n"
assert oracle("2\n5 1\n1 5\n") == "1\n"
assert oracle("3\n2 2\n3 3\n5 1\n") == "5\n"
assert oracle("1\n1000000000 1000000000\n") == "1000000000\n"


def write(name, cases):
    text = format_cases(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[(1, 1)], [(10, 1), (1, 10)], [(1, 2), (2, 3), (3, 4)],
                      [(5, 5), (5, 5), (5, 5)], [(100, 1)]])
    write("3_wide", [[(10**9, 1), (1, 10**9), (10**9, 10**9)],
                     [(10**9, 10**9), (10**9 - 1, 10**9 - 1)],
                     [(999999999, 1), (1, 999999999), (1000000000, 1)]])
    rng = random.Random(20261126)
    write("4_random", [[(rng.randint(1, 30), rng.randint(1, 30))
                        for _ in range(rng.randint(1, 7))] for _ in range(12)])
    write("5_io", [[(rng.randint(1, 100), rng.randint(1, 100))
                    for _ in range(5)] for _ in range(300)])
    rng_big = random.Random(20270101)
    big_drives = [(rng_big.randint(1, 10**9), rng_big.randint(1, 10**9))
                  for _ in range(1000000)]
    Path("/tmp/FN16SWAP_big.txt").write_text(format_cases([big_drives]))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[(6, 6), (1, 7), (3, 5), (3, 5)],
                   [(2, 2), (3, 3), (5, 1), (5, 10)]])
build()
