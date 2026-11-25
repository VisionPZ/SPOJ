#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """1
4 3
ABCD
ABCD
ABCD
ABCD
1 0 0 3 3
0 0 2 PQRS
1 0 2 3 3
"""
SAMPLE_OUT = """40
58
"""


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        size = int(tokens[cursor])
        query_count = int(tokens[cursor + 1])
        cursor += 2
        grid = [list(tokens[cursor + index]) for index in range(size)]
        cursor += size
        for _ in range(query_count):
            operation = int(tokens[cursor])
            cursor += 1
            if operation == 0:
                selector = int(tokens[cursor])
                target = int(tokens[cursor + 1])
                replacement = tokens[cursor + 2]
                cursor += 3
                if selector == 0:
                    grid[target] = list(replacement)
                else:
                    for row in range(size):
                        grid[row][target] = replacement[row]
            else:
                top = int(tokens[cursor])
                left = int(tokens[cursor + 1])
                bottom = int(tokens[cursor + 2])
                right = int(tokens[cursor + 3])
                cursor += 4
                total = 0
                for row in range(top, bottom + 1):
                    for column in range(left, right + 1):
                        total += ord(grid[row][column]) - 64
                answers.append(str(total))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 3\nA\n1 0 0 0 0\n0 0 0 Z\n1 0 0 0 0\n") == "1\n26\n"
assert oracle("1\n2 2\nAB\nCD\n0 1 0 ZZ\n1 0 0 1 1\n") == "58\n"
assert oracle("1\n3 1\nABC\nDEF\nGHI\n1 1 1 1 1\n") == "5\n"


def random_text(size, query_count, rng, query_bias):
    lines = [f"1\n{size} {query_count}"]
    for _ in range(size):
        lines.append("".join(rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                             for _ in range(size)))
    for _ in range(query_count):
        if rng.random() < query_bias:
            top = rng.randint(0, size - 1)
            left = rng.randint(0, size - 1)
            bottom = rng.randint(top, size - 1)
            right = rng.randint(left, size - 1)
            lines.append(f"1 {top} {left} {bottom} {right}")
        else:
            selector = rng.randint(0, 1)
            target = rng.randint(0, size - 1)
            replacement = "".join(rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                                  for _ in range(size))
            lines.append(f"0 {selector} {target} {replacement}")
    return "\n".join(lines) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", """1
1 5
A
1 0 0 0 0
0 0 0 Z
1 0 0 0 0
0 1 0 B
1 0 0 0 0
""")
    rng = random.Random(20261130)
    write("3_wide", random_text(100, 500, rng, 0.5))
    write("4_random", random_text(20, 200, rng, 0.5))
    io_cases = [random_text(20, 3000, rng, 0.9).splitlines()[1:]
                for _ in range(10)]
    io_text = "10\n" + "\n".join("\n".join(case) for case in io_cases) + "\n"
    write("5_io", io_text)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
