#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STONE_LIMIT = 1000


def build_grundy():
    values = [0] * STONE_LIMIT
    for stones in range(1, STONE_LIMIT):
        reachable = set()
        for smaller in range(stones):
            reachable.add(values[smaller])
        mex = 0
        while mex in reachable:
            mex += 1
        values[stones] = mex
    counts = []
    for stones in range(STONE_LIMIT):
        row = [0] * STONE_LIMIT
        for smaller in range(stones):
            row[values[smaller]] += 1
        counts.append(row)
    return values, counts


GRUNDY, REACHABLE = build_grundy()


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    lines = []
    for case_index in range(1, case_count + 1):
        pile_count = tokens[cursor]
        cursor += 1
        piles = tokens[cursor:cursor + pile_count]
        cursor += pile_count
        total = 0
        for stones in piles:
            total ^= GRUNDY[stones]
        winning = 0
        if total != 0:
            for stones in piles:
                target = GRUNDY[stones] ^ total
                if target < STONE_LIMIT:
                  winning += REACHABLE[stones][target]
        lines.append(f"Case {case_index}: {winning}")
    return "\n".join(lines) + "\n"


def brute(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    lines = []
    for case_index in range(1, case_count + 1):
        pile_count = tokens[cursor]
        cursor += 1
        piles = tokens[cursor:cursor + pile_count]
        cursor += pile_count
        winning = 0
        for chosen in range(pile_count):
            for reduced in range(piles[chosen]):
                total = 0
                for index, stones in enumerate(piles):
                    total ^= reduced if index == chosen else stones
                if total == 0:
                    winning += 1
        lines.append(f"Case {case_index}: {winning}")
    return "\n".join(lines) + "\n"


SAMPLE = """2
3
11 15 8
3
11 15 7
"""
SAMPLE_OUT = """Case 1: 3
Case 2: 3
"""
SMALL = """4
3
1 2 3
2
7 7
4
4 5 6 7
1
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SMALL) == brute(SMALL)
assert GRUNDY[0] == 0 and GRUNDY[12] == 12
assert oracle("1\n1\n5\n") == "Case 1: 1\n"
assert oracle("1\n3\n1 2 3\n") == "Case 1: 0\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        str(len(piles)) + "\n" + " ".join(str(value) for value in piles) + "\n"
        for piles in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[0], [1], [5, 5], [1, 2, 3], [999] * 4])
    rng = random.Random(20261126)
    write("3_wide", [[rng.randint(0, 999) for _ in range(1000)]
                     for _ in range(20)])
    write("4_random", [[rng.randint(0, 999) for _ in range(rng.randint(1, 100))]
                       for _ in range(200)])
    wide = []
    for _ in range(1000):
        piles = [rng.randint(0, 999) for _ in range(1000)]
        piles[0] = 999
        wide.append(piles)
    write("5_io", wide)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
