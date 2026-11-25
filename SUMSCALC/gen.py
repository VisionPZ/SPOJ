#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\n4\n5\n6\n"
SAMPLE_OUT = "10 20 16 30 100\n15 30 25 55 225\n21 42 36 91 441\n"


def build_tables(max_n):
    sum_first = [0] * (max_n + 1)
    sum_even = [0] * (max_n + 1)
    sum_odd = [0] * (max_n + 1)
    sum_squares = [0] * (max_n + 1)
    sum_cubes = [0] * (max_n + 1)
    running_first = 0
    running_even = 0
    running_odd = 0
    running_squares = 0
    running_cubes = 0
    for i in range(1, max_n + 1):
        running_first += i
        running_even += 2 * i
        running_odd += 2 * i - 1
        running_squares += i * i
        running_cubes += i * i * i
        sum_first[i] = running_first
        sum_even[i] = running_even
        sum_odd[i] = running_odd
        sum_squares[i] = running_squares
        sum_cubes[i] = running_cubes
    return sum_first, sum_even, sum_odd, sum_squares, sum_cubes


def oracle(input_text):
    tokens = input_text.split()
    case_count = int(tokens[0])
    numbers = [int(t) for t in tokens[1:1 + case_count]]
    tables = build_tables(max(numbers) if numbers else 0)
    lines = []
    for n in numbers:
        lines.append("%d %d %d %d %d" % (
            tables[0][n], tables[1][n], tables[2][n], tables[3][n], tables[4][n]))
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n1\n") == "1 2 1 1 1\n"
assert oracle("1\n2\n") == "3 6 4 5 9\n"
assert oracle("1\n10\n") == "55 110 100 385 3025\n"


def write(name, numbers):
    input_text = "%d\n%s\n" % (len(numbers), "\n".join(str(n) for n in numbers))
    (ROOT / "in" / ("%s.txt" % name)).write_text(input_text)
    (ROOT / "out" / ("%s.out" % name)).write_text(oracle(input_text))


def build():
    write("2_edges", [1, 2, 3, 10000, 9999, 100, 5000, 2, 1])
    write("3_wide", [10000] * 20 + [1] * 20 + [4999, 5001, 8000, 2000, 7500])
    rng = random.Random(20190108)
    write("4_random", [rng.randint(1, 10000) for _ in range(500)])
    write("5_io", [rng.randint(1, 10000) for _ in range(200000)])


if __name__ == "__main__":
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [4, 5, 6])
    build()
