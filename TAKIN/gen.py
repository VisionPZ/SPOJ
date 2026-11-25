#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    test_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(test_count):
        tree_count = tokens[cursor]
        capacity = tokens[cursor + 1]
        cursor += 2
        apples = tokens[cursor:cursor + tree_count]
        cursor += tree_count
        best = 0
        for mask in range(1 << tree_count):
            total = 0
            for index in range(tree_count):
                if mask & (1 << index):
                    total += apples[index]
            if total <= capacity and total > best:
                best = total
        answers.append(str(best))
    return "\n".join(answers) + "\n"


SAMPLE_IN = """2
5 6
2 1 2 7 8
5 10
1 2 4 4 6
"""
SAMPLE_OUT = """5
10
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n1 100000000000\n1000000000\n") == "1000000000\n"
assert oracle("1\n3 0\n1000000000 5 7\n") == "0\n"
assert oracle("1\n3 12\n4 4 4\n") == "12\n"
assert oracle("1\n4 9\n2 3 4 9\n") == "9\n"


def write(name, cases):
    lines = [str(len(cases))]
    for capacity, apples in cases:
        lines.append(f"{len(apples)} {capacity}")
        lines.append(" ".join(str(value) for value in apples))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        (0, [1]),
        (100000000000, [1000000000]),
        (1, [10, 20, 30]),
        (100000000000, [1000000000, 1000000000, 1000000000]),
    ])
    write("3_wide", [
        (20000000000, [1000000000] * 10),
        (19999999999, [1000000000] * 10),
        (7, [1000000000, 3, 4]),
    ])
    write("4_random", [
        (rng.randint(0, 200), [rng.randint(0, 100) for _ in range(rng.randint(1, 14))])
        for _ in range(8)
    ])
    write("5_io", [
        (rng.randint(1, 20000000000),
         [rng.randint(0, 1000000000) for _ in range(20)])
        for _ in range(10)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
