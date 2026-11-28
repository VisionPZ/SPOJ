#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(lengths):
    ordered = sorted(lengths)
    count = len(ordered)
    total = 0
    for longest in range(2, count):
        for middle in range(1, longest):
            limit = ordered[longest] - ordered[middle]
            left = bisect.bisect_left(ordered, limit, 0, middle)
            total += left
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        stick_count = tokens[cursor]
        cursor += 1
        if stick_count == 0:
            break
        lengths = tokens[cursor:cursor + stick_count]
        cursor += stick_count
        answers.append(str(oracle_case(lengths)))
    return "\n".join(answers) + "\n"


def brute_case(lengths):
    total = 0
    ordered = sorted(lengths)
    for first in range(len(ordered)):
        for second in range(first + 1, len(ordered)):
            for third in range(second + 1, len(ordered)):
                if ordered[first] + ordered[second] < ordered[third]:
                    total += 1
    return total


SAMPLE = """3
4 2 10
3
1 2 3
4
5 2 9 6
0
"""
SAMPLE_OUT = """1
0
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
for small in ([3, 4, 10], [1, 2, 3], [5, 2, 9, 6], [1, 1, 1, 2]):
    assert oracle_case(small) == brute_case(small)
assert oracle_case([1, 1, 2, 3, 5]) == brute_case([1, 1, 2, 3, 5])
assert oracle_case([1] * 3) == 0


def write(name, cases):
    parts = []
    for lengths in cases:
        parts.append(str(len(lengths)))
        parts.append(" ".join(str(value) for value in lengths))
    input_text = "\n".join(parts) + "\n0\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [[1, 1, 1], [1, 1, 2], [1000000, 1, 1000000],
                      [1, 2, 3], [1, 2, 4], [5, 5, 5, 5, 5]])
    write("3_wide", [[1] * 2000, [1000000] * 2000,
                     list(range(1, 2001))])
    rng = random.Random(20261126)
    wide = []
    for _ in range(6):
        wide.append([rng.randint(1, 1000000) for _ in range(2000)])
    write("4_random", wide)
    many = [[rng.randint(1, 40) for _ in range(rng.randint(3, 60))]
            for _ in range(400)]
    write("5_io", many)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
