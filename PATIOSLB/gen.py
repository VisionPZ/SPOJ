#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        row = tokens[cursor]
        slab_count = tokens[cursor + 1]
        cursor += 2
        lengths = tokens[cursor:cursor + slab_count]
        cursor += slab_count
        target = row - 1
        best = None
        for size in range(slab_count + 1):
            for group in itertools.combinations(range(slab_count), size):
                if sum(lengths[index] + 1 for index in group) == target:
                    candidate = tuple(sorted((lengths[index] for index in group), reverse=True))
                    if best is None or candidate > best:
                        best = candidate
        if best is None:
            answers.append("-1")
        else:
            answers.append(" ".join(str(value) for value in best))
    return "\n".join(answers) + "\n"


SAMPLE = """2
100
9
20 40 30 24 31 18 55 40 23
50
4
2 0 30 40
"""
SAMPLE_OUT = """55 23 18
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n4\n2\n2 3\n") == "2\n"
assert oracle("1\n8\n2\n2 3\n") == "3 2\n"
assert oracle("1\n2\n1\n0\n") == "0\n"
assert oracle("1\n5\n2\n1 1\n") == "1 1\n"


def write(name, cases):
    lines = [str(len(cases))]
    for row, lengths in cases:
        lines.append(str(row))
        lines.append(str(len(lengths)))
        lines.append(" ".join(str(value) for value in lengths))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(1, [5]), (6, [2, 3]), (50, [30, 20]), (12, [5, 5, 5])])
    write("3_wide", [(160, [80, 70, 60, 50, 40, 30, 20, 10, 5, 4, 3, 2, 1, 1, 1, 1])])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 120), [rng.randint(0, 40) for _ in range(14)])
                       for _ in range(4)])
    slabs = [rng.randint(10, 60) for _ in range(16)]
    row = sum(slabs) + len(slabs) + 1
    write("5_io", [(row, slabs), (100, [55, 40, 30, 24, 31, 18, 55, 40, 23])])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(100, [20, 40, 30, 24, 31, 18, 55, 40, 23]), (50, [2, 0, 30, 40])])
build()
