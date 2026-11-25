#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_number = 1
    lines = []
    while cursor < len(tokens):
        value_count = tokens[cursor]
        cursor += 1
        values = tokens[cursor:cursor + value_count]
        cursor += value_count
        operation_count = tokens[cursor]
        cursor += 1
        lines.append(f"Case #{case_number}:")
        for _ in range(operation_count):
            kind = tokens[cursor]
            left = tokens[cursor + 1] - 1
            right = tokens[cursor + 2] - 1
            cursor += 3
            if kind == 0:
                for index in range(left, right + 1):
                    values[index] = math.isqrt(values[index])
            else:
                lines.append(str(sum(values[left:right + 1])))
        lines.append("")
        case_number += 1
    return "\n".join(lines) + "\n"


SAMPLE = """5
1 2 3 4 5
5
1 2 4
0 2 4
1 2 4
0 4 5
1 1 5
4
10 10 10 10
3
1 1 4
0 2 3
1 1 4
"""
SAMPLE_OUT = """Case #1:
9
4
6

Case #2:
40
26

"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n16\n3\n1 1 1\n0 1 1\n1 1 1\n") == "Case #1:\n16\n4\n\n"
assert oracle("3\n1 1 1\n2\n0 1 3\n1 1 3\n") == "Case #1:\n3\n\n"
assert oracle("2\n100000000000000000 1\n1\n1 1 2\n") == "Case #1:\n100000000000000001\n\n"
assert math.isqrt(10**18) == 10**9


def write(name, cases):
    parts = []
    for values, operations in cases:
        parts.append(str(len(values)))
        parts.append(" ".join(str(value) for value in values))
        parts.append(str(len(operations)))
        parts.extend(f"{kind} {left} {right}" for kind, left, right in operations)
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([1, 1, 1, 1], [(1, 1, 4), (0, 1, 4), (1, 1, 4)]),
        ([10**18 - 1], [(1, 1, 1), (0, 1, 1), (1, 1, 1), (0, 1, 1), (1, 1, 1)]),
    ])
    wide_values = [10**14] * 1000
    wide_ops = [(1, 1, 1000), (0, 1, 1000), (1, 1, 1000), (0, 500, 1000), (1, 1, 1000)]
    write("3_wide", [(wide_values, wide_ops)])
    rng = random.Random(20261126)
    random_values = [rng.randint(1, 10**12) for _ in range(500)]
    random_ops = []
    for _ in range(500):
        left = rng.randint(1, 500)
        right = rng.randint(left, 500)
        random_ops.append((rng.randint(0, 1), left, right))
    write("4_random", [(random_values, random_ops)])
    io_values = [rng.randint(1, 10**9) for _ in range(200)]
    io_ops = [(1, rng.randint(1, 200), rng.randint(1, 200)) for _ in range(20000)]
    io_ops = [(1, min(left, right), max(left, right)) for _, left, right in io_ops]
    write("5_io", [(io_values, io_ops)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
