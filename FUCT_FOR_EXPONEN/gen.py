#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = """5
1 7
2 4
0 9
-3 3
5 -2
"""
SAMPLE_OUT = """1
16
0
-27
0.040000
"""


def int_power(x, n):
    answer = 1
    for _ in range(n):
        answer *= x
    return answer


def fmt(x, n):
    if n >= 0:
        return str(int_power(x, n))
    if x == 0:
        return "inf"
    return "%.6f" % math.pow(float(x), float(n))


def oracle(input_text):
    tokens = input_text.split()
    count = int(tokens[0])
    answers = []
    cursor = 1
    for _ in range(count):
        x = int(tokens[cursor])
        n = int(tokens[cursor + 1])
        cursor += 2
        answers.append(fmt(x, n))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert fmt(2, -1) == "0.500000"
assert fmt(-2, -3) == "-0.125000"
assert fmt(10, 20) == "100000000000000000000"
assert fmt(2, 62) == "4611686018427387904"
assert fmt(0, 0) == "1"
assert fmt(1, -1) == "1.000000"
assert fmt(3, -7) == "0.000457"
assert fmt(10, -10) == "0.000000"


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        "%d %d\n" % case for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    edge_cases = [
        (0, 0), (0, 5), (0, -1), (1, 0), (-1, 1000), (2, 62),
        (10, 100), (2, -1), (-2, -3), (1, -1), (10, -10), (3, -7),
        (100, 0), (-10, 3), (-1, 999), (2, 0), (-2, 0), (7, -2),
    ]
    write("2_edges", edge_cases)
    rng = random.Random(99)
    wide_cases = []
    for _ in range(1000):
        wide_cases.append((rng.randint(-10, 10), rng.randint(-10, 30)))
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(1000):
        random_cases.append((rng.randint(-100, 100), rng.randint(-5, 60)))
    write("4_random", random_cases)
    write("5_io", [(10, 1000)] * 1000)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        print("base 5 exponent -2")
        print("value:", math.pow(5.0, -2.0))
        print("line:", "%.6f" % math.pow(5.0, -2.0))
        raise SystemExit
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(1, 7), (2, 4), (0, 9), (-3, 3), (5, -2)])
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
    (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
    build()
