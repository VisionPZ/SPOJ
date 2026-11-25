#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def order_cost(cell_count, releases, order):
    emptied = {0, cell_count + 1}
    total = 0
    for cell in order:
        left_edge = max(value for value in emptied if value < cell)
        right_edge = min(value for value in emptied if value > cell)
        total += right_edge - left_edge - 2
        emptied.add(cell)
    return total


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for case_number in range(1, case_count + 1):
        cell_count = int(tokens[cursor]); cursor += 1
        release_count = int(tokens[cursor]); cursor += 1
        releases = []
        for _ in range(release_count):
            releases.append(int(tokens[cursor])); cursor += 1
        best = 0
        if release_count:
            best = min(order_cost(cell_count, releases, order)
                       for order in itertools.permutations(releases))
        answers.append(f"Case #{case_number}: {best}")
    return "\n".join(answers) + "\n"


SAMPLE = """2
8 1
3
20 3
3 6 14
"""
SAMPLE_OUT = """Case #1: 7
Case #2: 35
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n10 1\n5\n") == "Case #1: 9\n"
assert oracle("1\n20 3\n3 6 14\n") == "Case #1: 35\n"
assert oracle("1\n100 2\n1 100\n") == "Case #1: 197\n"
for cells in range(1, 16):
    for release in range(1, cells + 1):
        expected = f"Case #1: {cells - 1}\n"
        assert oracle(f"1\n{cells} 1\n{release}\n") == expected


def write(name, cases):
    lines = [str(len(cases))]
    for cell_count, releases in cases:
        lines.append(f"{cell_count} {len(releases)}")
        lines.append(" ".join(str(value) for value in releases))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, [1]), (2, [2]), (10, [5]), (20, [3, 6, 14]),
                      (100, [1, 100])])
    write("3_wide", [(10000, [1000, 2000, 3000, 4000, 5000, 6000, 7000]),
                     (9999, [1, 2, 3, 9997, 9998, 9999])])
    rng = random.Random(20261126)
    cases = []
    for _ in range(40):
        cell_count = rng.randint(1, 10000)
        size = rng.randint(1, 7)
        releases = sorted(rng.sample(range(1, cell_count + 1), size))
        cases.append((cell_count, releases))
    write("4_random", cases)
    cases = []
    for _ in range(100):
        cell_count = rng.randint(1, 10000)
        size = rng.randint(1, 7)
        releases = sorted(rng.sample(range(1, cell_count + 1), size))
        cases.append((cell_count, releases))
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(8, [3]), (20, [3, 6, 14])])
build()
