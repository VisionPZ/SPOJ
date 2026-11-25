#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = list(map(int, text.split()))
    count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(count):
        lower = tokens[cursor]
        upper = tokens[cursor + 1]
        target = tokens[cursor + 2]
        cursor += 3
        found = 0
        for number in range(lower, upper + 1):
            bits = bin(number)[2:]
            left_ones = sum(1 for position, digit in enumerate(bits, 1)
                            if digit == "1" and position % 2 == 1)
            right_ones = sum(1 for position, digit in enumerate(bits, 1)
                             if digit == "1" and position % 2 == 0)
            if abs(left_ones - right_ones) == target:
                found += 1
        answers.append(str(found))
    return "".join(answer + "\n" for answer in answers)


def fast_gap(number):
    bits = bin(number)[2:]
    left = sum(1 for position, digit in enumerate(bits, 1)
               if digit == "1" and position % 2 == 1)
    right = sum(1 for position, digit in enumerate(bits, 1)
                if digit == "1" and position % 2 == 0)
    return left - right


SAMPLE = "1\n1 10 2\n"
SAMPLE_OUT = "2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 1 1\n") == "1\n"
assert oracle("1\n19 19 1\n") == "1\n"
assert oracle("1\n7 7 0\n") == "0\n"
assert fast_gap(19) == 1
assert fast_gap(1) == 1


def write(name, cases):
    lines = [str(len(cases))]
    for lower, upper, target in cases:
        lines.append(f"{lower} {upper} {target}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 8, 0), (9, 16, 1), (15, 15, 2), (10000000000000000000 - 299,
          10000000000000000000, 3), (1, 3, 50)])
    rng = random.Random(20261130)
    wide_cases = []
    for _ in range(12):
        lower = rng.randint(1, 10**19 - 2000)
        wide_cases.append((lower, lower + rng.randint(0, 2000), rng.randint(0, 50)))
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(20):
        lower = rng.randint(1, 10**12)
        random_cases.append((lower, lower + rng.randint(0, 1500), rng.randint(0, 30)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(50):
        lower = rng.randint(1, 10**18)
        io_cases.append((lower, lower + 500, rng.randint(0, 25)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
