#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    pos = 1
    lines = []
    for _ in range(case_count):
        degree = tokens[pos]
        pos += 1
        left = tokens[pos:pos + degree + 1]
        pos += degree + 1
        right = tokens[pos:pos + degree + 1]
        pos += degree + 1
        result = [0] * (2 * degree + 1)
        for left_index, left_value in enumerate(left):
            for right_index, right_value in enumerate(right):
                result[left_index + right_index] += left_value * right_value
        lines.append(" ".join(str(value) for value in result))
    return "\n".join(lines) + "\n"


SAMPLE = "2\n2\n1 2 3\n3 2 1\n2\n1 0 1\n2 1 0\n"
SAMPLE_OUT = "3 8 14 8 3\n2 1 2 1 0\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n7\n11\n") == "77\n"
assert oracle("1\n1\n0 0\n1000 1000\n") == "0 0 0\n"
assert oracle("1\n2\n1000 1000 1000\n1000 1000 1000\n") == "1000000 2000000 3000000 2000000 1000000\n"
assert sum([1, 2, 3]) == 6


def write(name, cases):
    chunks = [str(len(cases))]
    for degree, left, right in cases:
        chunks.append(str(degree))
        chunks.append(" ".join(str(value) for value in left))
        chunks.append(" ".join(str(value) for value in right))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def make_case(rng, degree):
    return degree, [rng.randint(0, 1000) for _ in range(degree + 1)], \
                   [rng.randint(0, 1000) for _ in range(degree + 1)]


def build():
    rng = random.Random(20261125)
    write("2_edges", [(0, [0], [0]), (0, [1], [1000]),
                      (1, [0, 0], [1000, 1000]), (1, [1, 1], [1000, 1000])])
    write("3_wide", [make_case(rng, 500)])
    write("4_random", [make_case(rng, degree) for degree in (1, 3, 17, 64, 200)])
    write("5_io", [make_case(rng, 1000) for _ in range(4)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, [1, 2, 3], [3, 2, 1]), (2, [1, 0, 1], [2, 1, 0])])
build()
