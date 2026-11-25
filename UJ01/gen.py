#!/usr/bin/env python3
import math
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def period(first_step, second_step):
    common = first_step * second_step // math.gcd(first_step, second_step)
    values = set()
    multiple = first_step
    while multiple <= common:
        values.add(multiple)
        multiple += first_step
    multiple = second_step
    while multiple <= common:
        values.add(multiple)
        multiple += second_step
    return common, sorted(values)


def oracle(text):
    tokens = text.split()
    position = 0
    case_count = int(tokens[position])
    position += 1
    answers = []
    for _ in range(case_count):
        first_step = int(tokens[position])
        second_step = int(tokens[position + 1])
        target = int(tokens[position + 2])
        position += 3
        length, values = period(first_step, second_step)
        cycles, offset = divmod(target - 1, len(values))
        answers.append(str(cycles * length + values[offset]))
    return "\n".join(answers) + "\n"


def brute(target, first_step, second_step):
    values = set()
    number = 1
    while len(values) < target:
        if number % first_step == 0 or number % second_step == 0:
            values.add(number)
        number += 1
    return sorted(values)[target - 1]


SAMPLE = """4
3 5 2
3 5 3
2 3 4
2 3 6
"""
SAMPLE_OUT = """5
6
6
9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
for first_step in range(1, 9):
    for second_step in range(1, 9):
        length, values = period(first_step, second_step)
        assert len(values) == length // first_step + length // second_step - 1
        if len(values) >= 5:
            assert brute(5, first_step, second_step) == values[4]
assert oracle("1\n1 1 1000000000\n") == "1000000000\n"
assert oracle("1\n1000 999 1\n") == "999\n"


def write(name, cases):
    lines = [str(len(cases))]
    for first_step, second_step, target in cases:
        lines.append(f"{first_step} {second_step} {target}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1, 1), (1, 1, 1000000000), (1000, 999, 1), (7, 7, 3), (1, 1000, 1000000000)])
    rng = random.Random(20261126)
    write("3_wide", [(1000, 999, 1000000000), (997, 991, 1000000000), (1, 2, 1000000000)])
    write("4_random", [(rng.randrange(1, 1001), rng.randrange(1, 1001), rng.randrange(1, 1000000001)) for _ in range(400)])
    pairs = [(rng.randrange(1, 1001), rng.randrange(1, 1001)) for _ in range(40)]
    write("5_io", [(first_step, second_step, rng.randrange(1, 1000000001)) for first_step, second_step in (pairs[rng.randrange(40)] for _ in range(20000))])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
