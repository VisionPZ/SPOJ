#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = """3
1 1
2 10
1 100000000
"""
SAMPLE_OUT = """0
4
38379932
"""

COMPLETIONS = {}


def build_completions():
    COMPLETIONS[0] = {0: 1}
    single = {}
    for digit in range(10):
        contribution = digit if digit % 2 == 0 else -digit
        single[contribution] = single.get(contribution, 0) + 1
    current = {0: 1}
    for length in range(1, 11):
        following = {}
        for total, count in current.items():
            for contribution, digit_count in single.items():
                key = total + contribution
                following[key] = following.get(key, 0) + count * digit_count
        current = following
        COMPLETIONS[length] = dict(current)


def count_up_to(value):
    if value <= 0:
        return 0
    digits = [int(char) for char in str(value)]
    total = 0
    running = 0
    for position, digit in enumerate(digits):
        remaining = len(digits) - position - 1
        table = COMPLETIONS[remaining]
        for smaller in range(digit):
            contribution = smaller if smaller % 2 == 0 else -smaller
            needed = running + contribution
            for outcome, count in table.items():
                if needed + outcome > 0:
                    total += count
        running += digit if digit % 2 == 0 else -digit
    if running > 0:
        total += 1
    return total


def brute(lower, upper):
    found = 0
    for value in range(lower, upper + 1):
        even_sum = 0
        odd_sum = 0
        for char in str(value):
            digit = int(char)
            if digit % 2 == 0:
                even_sum += digit
            else:
                odd_sum += digit
        if even_sum > odd_sum:
            found += 1
    return found


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        lower = int(tokens[cursor])
        upper = int(tokens[cursor + 1])
        cursor += 2
        answers.append(str(count_up_to(upper) - count_up_to(lower - 1)))
    return "\n".join(answers) + "\n"


build_completions()
assert oracle(SAMPLE) == SAMPLE_OUT
assert count_up_to(10) == 4
assert brute(2, 10) == 4
assert brute(1, 100) == 44
assert oracle("1\n1 100\n") == "44\n"
assert brute(4563, 4563) == 1


def write(name, ranges):
    text = str(len(ranges)) + "\n" + "".join(
        f"{lower} {upper}\n" for lower, upper in ranges)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (9, 9), (10, 20), (100, 100), (999, 1000), (1, 100)])
    write("3_wide", [
        (1, 100000000),
        (99999999, 100000000),
        (50000000, 60000000),
        (1, 99999999),
    ])
    rng = random.Random(20261201)
    random_ranges = []
    for _ in range(35):
        lower = rng.randint(1, 100000000)
        upper = rng.randint(lower, 100000000)
        random_ranges.append((lower, upper))
    write("4_random", random_ranges)
    write("5_io", [(1, 100000000) for _ in range(35)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
