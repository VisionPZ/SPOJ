#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    first = tokens[1:1 + count]
    second = tokens[1 + count:1 + 2 * count]
    best = 0
    for first_mask in range(1 << count):
        first_zero = [(first_mask >> index) & 1 for index in range(count)]
        total = 0
        for second_index in range(count):
            as_source = 0
            as_target = 0
            for first_index in range(count):
                if math.gcd(first[first_index], second[second_index]) <= 1:
                    continue
                if second[second_index] < first[first_index] and first_zero[first_index] == 0:
                    as_source += 1
                if first[first_index] < second[second_index] and first_zero[first_index] == 1:
                    as_target += 1
            total += max(as_source, as_target)
        best = max(best, total)
    return str(best) + "\n"


SAMPLE = """4
16 3 2 9
12 18 13 4
"""
SAMPLE_OUT = """8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n3\n") == "0\n"
assert oracle("2\n2 3\n4 9\n") == "2\n"
assert oracle("3\n2 4 8\n4 8 16\n") == "6\n"
assert oracle("1\n1000000000\n1000000000\n") == "0\n"


def write(name, first, second):
    input_text = str(len(first)) + "\n" + " ".join(str(value) for value in first) + "\n" + " ".join(str(value) for value in second) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [2, 2, 3, 5], [2, 3, 4, 7])
    write("3_wide", [1000000000, 999999999, 999999998, 2, 3, 4, 6, 10],
          [1000000000, 999999999, 999999998, 4, 6, 9, 12, 15])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(2, 100) for _ in range(8)],
          [rng.randint(2, 100) for _ in range(8)])
    write("5_io", [2 * value for value in range(2, 10)],
          [2 * value for value in range(3, 11)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [16, 3, 2, 9], [12, 18, 13, 4])
build()
