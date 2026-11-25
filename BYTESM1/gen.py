#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LIMIT = 100002000
SEEDS = (1, 3, 9)


def digit_sum(value):
    total = 0
    while value:
        total += value % 10
        value //= 10
    return total


def river(seed):
    values = []
    current = seed
    while current <= LIMIT:
        values.append(current)
        current += digit_sum(current)
    return values


RIVERS = {seed: river(seed) for seed in SEEDS}


def seed_for(value):
    remainder = value % 9
    if remainder in (1, 2, 4, 5, 7, 8):
        return 1
    if remainder in (3, 6):
        return 3
    return 9


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    answers = []
    for remembered in tokens[1:1 + case_count]:
        chosen = seed_for(remembered)
        stones = RIVERS[chosen]
        index = bisect.bisect_left(stones, remembered)
        current = remembered
        while current != stones[index]:
            if current < stones[index]:
                current += digit_sum(current)
            else:
                index += 1
        answers.append(f"{chosen} {current}")
    return "\n".join(answers) + "\n"


SAMPLE_IN = """2
29
42
"""
SAMPLE_OUT = """1 107
3 111
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n1\n") == "1 1\n"
assert oracle("1\n3\n") == "3 3\n"
assert oracle("1\n9\n") == "9 9\n"
assert oracle("1\n99106702\n") == "1 100001117\n"


def write(name, values):
    input_text = str(len(values)) + "\n" + "".join(f"{value}\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 8, 9, 10, 27, 42])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(99900000, 100000000) for _ in range(50)])
    write("4_random", [rng.randint(1, 100000000) for _ in range(50)])
    write("5_io", [rng.randint(99000000, 100000000) for _ in range(50)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
