#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def zeros_up_to(limit):
    if limit <= 0:
        return 0
    digits = str(limit)

    @lru_cache(None)
    def walk(pos, tight, started):
        if pos == len(digits):
            return (1, 0)
        bound = int(digits[pos]) if tight else 9
        count = 0
        zeros = 0
        for digit in range(bound + 1):
            sub_count, sub_zeros = walk(
                pos + 1, bool(tight and digit == bound), bool(started or digit != 0))
            count += sub_count
            zeros += sub_zeros
            if started and digit == 0:
                zeros += sub_count
        return (count, zeros)

    return walk(0, True, False)[1]


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    cursor = 1
    for _ in range(case_count):
        start = tokens[cursor]
        end = tokens[cursor + 1]
        cursor += 2
        answers.append(str(zeros_up_to(end) - zeros_up_to(start - 1)))
    return "\n".join(answers) + "\n"


def brute_case(start, end):
    return sum(str(value).count('0') for value in range(start, end + 1))


for low in range(1, 12):
    for high in range(low, 130):
        assert zeros_up_to(high) - zeros_up_to(low - 1) == brute_case(low, high)

SAMPLE = "2\n1 10\n1 100\n"
SAMPLE_OUT = "1\n11\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert zeros_up_to(999) - zeros_up_to(0) == 189
assert zeros_up_to(1234) - zeros_up_to(999) == 154
assert zeros_up_to(9) - zeros_up_to(0) == 0


def write(name, ranges):
    lines = [str(len(ranges))]
    lines.extend(f"{start} {end}" for start, end in ranges)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 9), (1, 10), (9, 10), (10, 10),
                      (1, 100), (100, 100), (999999, 1000000)])
    write("3_wide", [(1, 1000000000), (999999999, 1000000000),
                     (500000000, 1000000000), (1, 999999999)])
    rng = random.Random(20261126)
    ranges = []
    for _ in range(100):
        start = rng.randint(1, 1000000000)
        end = rng.randint(start, 1000000000)
        ranges.append((start, end))
    write("4_random", ranges)
    ranges = []
    for _ in range(1000):
        start = rng.randint(1, 1000000000)
        end = rng.randint(start, 1000000000)
        ranges.append((start, end))
    write("5_io", ranges)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
