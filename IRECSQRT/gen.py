#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LIMIT = 1 << 64


def oracle_case(index, modulus):
    if index == 0:
        return 1 % modulus
    numerator = (pow(2, index, 3 * modulus) + 1) * (pow(2, index - 1, 3 * modulus) + 1)
    return (numerator % (3 * modulus)) // 3


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    lines = []
    for position in range(count):
        index = tokens[1 + 2 * position]
        modulus = tokens[2 + 2 * position]
        lines.append(str(oracle_case(index, modulus)))
    return "\n".join(lines) + "\n"


SAMPLE = """10
0 10
1 10
2 10
3 10
10 10
100 100
1000 1000
10000 10000
100000 100000
9876543210123456789 1234567890987654321
"""
SAMPLE_OUT = """1
2
5
5
5
51
251
6251
6251
657422418465782775
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(4, 7) == ((2 ** 4 + 1) * (2 ** 3 + 1) // 3) % 7
assert oracle_case(0, 1) == 0
assert oracle_case(1, 3) == 2
assert oracle_case(40, (1 << 64) - 1) == ((2 ** 40 + 1) * (2 ** 39 + 1) // 3) % ((1 << 64) - 1)


def write(name, cases):
    text = str(len(cases)) + "".join(f"\n{index} {modulus}" for index, modulus in cases) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 1), (1, 1), (2, 2), (0, 3), (3, 3 ** 20), (5, 2 ** 63), (7, (1 << 64) - 1)])
    write("3_wide", [(LIMIT - 1, LIMIT - 1), (LIMIT - 2, 3 ** 40), (10 ** 18, 10 ** 18), (123456789, 987654321)])
    rng = random.Random(20261126)
    wide = [(rng.randrange(LIMIT), rng.randrange(1, LIMIT)) for _ in range(200)]
    write("4_random", wide)
    write("5_io", [(rng.randrange(LIMIT), rng.randrange(1, LIMIT)) for _ in range(50000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_tokens = SAMPLE.split("\n")[1:]
write("1_sample", [(int(parts[0]), int(parts[1])) for parts in (line.split() for line in sample_tokens if line)])
build()
