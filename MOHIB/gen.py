#!/usr/bin/env python3
import random
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(appended, average):
    length = average - appended
    target_sum = length * (average + 1)
    fewest_others = length * (length - 1) // 2
    low, high = 1, target_sum
    while low < high:
        middle = (low + high + 1) // 2
        if target_sum - middle >= fewest_others:
            low = middle
        else:
            high = middle - 1
    candidate = low
    while candidate > 0:
        rest = target_sum - candidate
        most_others = (length - 1) * candidate - fewest_others
        if fewest_others <= rest <= most_others:
            return str(candidate)
        candidate -= 1
    return "0"


def brute_case(appended, average):
    length = average - appended
    target_sum = length * (average + 1)
    universe = range(1, target_sum + 1)
    best = 0
    for group in combinations(universe, length):
        if sum(group) == target_sum and max(group, default=0) > best:
            best = max(group)
    return str(best)


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    cursor = 1
    answers = []
    for _ in range(case_count):
        appended = tokens[cursor]
        average = tokens[cursor + 1]
        cursor += 2
        answers.append(oracle_case(appended, average))
    return "\n".join(answers) + "\n"


SAMPLE = "1\n1 2\n"
SAMPLE_OUT = "3\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(2, 4) == "9"
assert oracle_case(3, 5) == "11"
assert oracle_case(4, 5) == "6"
assert oracle_case(49999, 50000) == "50001"
for appended in range(1, 5):
    for average in range(appended + 1, 9):
        if average - appended <= 4:
            assert oracle_case(appended, average) == brute_case(appended, average)


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(
        f"{appended} {average}\n" for appended, average in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 2), (49999, 50000), (1, 50000), (25000, 50000)])
    write("3_wide", [(appended, 50000) for appended in range(1, 50000, 2500)])
    rng = random.Random(20261126)
    pairs = []
    for _ in range(5200):
        appended = rng.randint(1, 49999)
        average = rng.randint(appended + 1, 50000)
        pairs.append((appended, average))
    write("4_random", pairs[:200])
    write("5_io", pairs[200:])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(1, 2)])
build()
